---
status: under-review
last_reviewed: 2026-06-14
scope: ecosystem
---

# Doc-Alignment Enforcement Recommendation

**Author:** platform agent session, 2026-06-14
**For review by:** Ryan (platform lead)
**Scope:** Woosoo orchestration system — doc alignment gates across all six doc types
**Action required:** Review and approve; a subsequent scribe case implements the rule changes in
`AGENTS.md`, `AGENT_USAGE_GUIDE.md`, and adds the `## Lessons` section.

---

## Root-Cause Analysis

### Primary root cause

**APPROVED and handover are not atomic.** The 4-agent chain ends when the Executioner issues
`APPROVED`. The state-sync step — appending to `state/DONE.md`, marking the `state/QUEUE.md`
row `done`, and clearing `state/WORK.md` — lives in `hooks/handover.md` and runs **only when
the operator explicitly types "handover"**. No agent in the current chain checks that DONE.md
was updated, and the Executioner auto-reject list contains no such check. When the operator moves
on to the next task without triggering handover, the case remains open in state files
indefinitely.

### Secondary contributors

1. **Scribe phase has no enforcement check.** `AGENTS.md` states "The scribe docs-sync phase
   (step 4) is mandatory for code-specialist tasks" but the Executioner auto-reject list in
   `AGENT_USAGE_GUIDE.md` does not include "Documentation Sync section empty or missing" as an
   auto-reject condition. The rule exists in prose; the gate does not.

2. **Case files accumulate without lifecycle tracking.** `docs/cases/` grows as intake and triage
   create new files, but there is no mechanism that marks a case file `status: COMPLETE` and no
   check that confirms a DONE.md row was appended when Executioner APPROVED. The result is
   orphaned case files that neither QUEUE.md nor DONE.md reference.

3. **No LESSONS infrastructure.** `AGENTS.md` has no `## Lessons` section and no `LESSONS.md`
   file exists. Recurring failure patterns cannot be formally recorded, so the same drift recurs
   across sessions without a durable lesson being written.

### Evidence (factual — based on file reads in this session)

| Finding | Source |
|---|---|
| `nex-case-008` has case file; no DONE.md row; QUEUE.md "Completed" section carries explicit warning: "DONE.md row pending verification backfill" | `state/QUEUE.md` line 102 |
| `nex-case-009` same warning | `state/QUEUE.md` line 103 |
| `nex-case-005` QUEUE.md Completed section marks "CLOSED OBE" but no DONE.md row | `state/QUEUE.md` line 99 |
| ~20 case files in `docs/cases/` have no corresponding QUEUE.md row and no DONE.md row | `docs/cases/` glob vs QUEUE.md + DONE.md cross-check |
| Named orphans: `tab-case-007`, `tab-case-008`, `infra-case-005`, `infra-case-006`, `infra-case-009`, `prn-case-003`, `plt-case-006`, `plt-case-007`, `plt-case-010`, plus informal-name cases (`tablet-package-ui-redesign`, `tablet-screen-ui-ux-review`, etc.) | `docs/cases/` glob |
| No `memory/` directory exists; no `LESSONS.md` at root or `docs/` | filesystem check |
| `AGENTS.md` `## Immutable Rules` section has no task-closure rule | `AGENTS.md` direct read |
| Executioner auto-reject list (AGENT_USAGE_GUIDE.md) has no "Documentation Sync empty" or "case file not COMPLETE" check | `AGENT_USAGE_GUIDE.md` lines 95–106 |

---

## Enforcement per Doc Type

| Doc type | Drift observed | Proposed enforcement step | Wire to |
|---|---|---|---|
| `docs/cases/<slug>.md` | Case files exist with stale status; never reach `status: COMPLETE`; orphaned files with no QUEUE/DONE row | Executioner MUST read `## Run State` and REJECT if `status ≠ COMPLETE` or `next_agent ≠ done` at time of issuing verdict | **Executioner** — new auto-reject bullet |
| `state/DONE.md` | APPROVED cases missing rows; explicit "pending backfill" warnings not resolved | Executioner APPROVED verdict MUST include a mandatory `HANDOVER REQUIRED` block instructing operator to run `handover` before starting the next task; Contrarian pre-task check confirms DONE.md row exists for the previous case before starting a new one | **Executioner** verdict format + **Contrarian** pre-task check |
| `state/QUEUE.md` | Completed rows not updated to `status: done`; rows sit in "Completed" section indefinitely without migration to DONE.md | `hooks/handover.md` Step 2 already requires the QUEUE row update; enforce via Executioner auto-reject: Contrarian must confirm the prior task's QUEUE row shows `done` before the new task's chain begins | **Executioner** (via Contrarian gate) |
| `state/WORK.md` | Active cache left pointing at a closed case; next task inherits stale `task_id` | `hooks/handover.md` Step 2 already clears WORK.md; same enforcement as QUEUE.md — the Contrarian pre-task check catches a stale WORK.md by comparing `task_id` against the case file status | **Contrarian** pre-task check |
| `memory/MEMORY.md` (does not yet exist) | No memory infrastructure; out of scope | Out of scope for this recommendation. Address in a future `plt-case-memory-infrastructure` case if memory infrastructure is added. | — |
| `AGENTS.md` / Lessons | No LESSONS section or file; recurring failures cannot be formally recorded | Add `## Lessons` section to `AGENTS.md`. The scribe specialist is responsible for drafting an L-0XX entry whenever the Executioner APPROVED verdict carries a systemic finding (a `Follow-Ups` or `Remaining Risks` block that identifies a recurring pattern). Lesson is appended before the operator moves to the next task. | **scribe** post-Executioner step (new responsibility) |

### Executioner auto-reject additions (exact text for AGENT_USAGE_GUIDE.md)

Add these two bullets to the **Auto-rejects if any of the following** list:

```
- Case file `## Run State → status` is not `COMPLETE` and `next_agent` is not `done` at time of
  Executioner verdict
- Code-specialist task: case file `## Documentation Sync` section is empty, absent, or still
  contains template placeholder text
```

### Contrarian pre-task check addition (exact text for hooks/work.md Step 4 or Step 0)

Add as a mandatory first step before the Contrarian's seven-question challenge:

```
[ ] 0. Previous-task closure check: if state/WORK.md shows a `task_id` that is not the current
       task, read docs/cases/<that-slug>.md and confirm `status: COMPLETE` AND a DONE.md row
       exists for it. If either is missing, halt. Report the orphaned task by ID and instruct
       the operator to run `handover` before starting anything new.
```

---

## Proposed Immutable Rule

Add as a new bullet at the end of `## Immutable Rules` in `AGENTS.md`:

```
- **Task closure is atomic.** A task is DONE only when ALL three are true:
  (1) the case file `## Run State → status: COMPLETE` and `next_agent: done`;
  (2) `state/DONE.md` has an APPROVED row for this case;
  (3) `state/QUEUE.md` row for this case shows `status: done`.
  The Executioner APPROVED verdict must include a "HANDOVER REQUIRED" instruction.
  The Executioner REJECTS if the case file Run State is not COMPLETE at time of verdict.
  The Contrarian halts and reports any unclosed prior task before starting a new one.
```

---

## Drafted LESSON Entry (L-001)

Copy this verbatim into a new `## Lessons` section at the end of `AGENTS.md`:

```markdown
## Lessons

### L-001 — Doc-alignment drift: APPROVED and handover must be treated as atomic

**Date recorded:** 2026-06-14
**Scope:** orchestration system (ecosystem)

**Pattern:** Cases receive Executioner APPROVED but state files (`state/DONE.md`,
`state/QUEUE.md`) and the case file itself (`## Run State → status: COMPLETE`) are not
updated. The root cause: `hooks/handover.md` is a separate operator-triggered step, not part of
the 4-agent chain. When the operator moves to the next task without typing "handover", state
diverges indefinitely. The Executioner auto-reject list contained no check for this condition.
The scribe "mandatory" docs-sync requirement existed in prose but had no enforcement gate.

**Evidence found 2026-06-14:**
- `nex-case-008` and `nex-case-009`: QUEUE.md carries explicit "DONE.md row pending
  verification backfill" warnings from a reconciliation pass in 2026-05-30 — never resolved.
- `nex-case-005`: QUEUE.md marks "CLOSED OBE" but no DONE.md row exists.
- ~20 case files in `docs/cases/` have no corresponding QUEUE.md row or DONE.md row (including
  `tab-case-007/008`, `infra-case-005/006/009`, `prn-case-003`, `plt-case-006/007/010`, and
  several informal-name cases).

**Rules added (see AGENTS.md Immutable Rules and AGENT_USAGE_GUIDE.md auto-reject list):**
- Immutable Rule: "Task closure is atomic" — all three closure conditions must be true before
  a task is treated as DONE.
- Executioner auto-reject: case file `status ≠ COMPLETE`; Documentation Sync empty on code task.
- Contrarian pre-task check (step 0): halt if prior task has no DONE.md row or case file
  `status ≠ COMPLETE`.
- Executioner APPROVED verdict format: must carry "HANDOVER REQUIRED" instruction.

**Recurrence prevention:**
The Contrarian now checks prior-task closure before starting any new task. The Executioner
rejects if the case file is not COMPLETE. These two gates make handover non-skippable in
practice even if the operator forgets to type "handover" — the next task's Contrarian catches
the gap and halts.
```

---

## Implementation Scope (for the follow-on scribe case)

This recommendation is a read-only artifact. After operator approval, create a scribe case
(`plt-case-doc-alignment-enforcement`) to apply these changes:

| Change | File | Section |
|---|---|---|
| Add "Task closure is atomic" bullet | `AGENTS.md` | `## Immutable Rules` |
| Add two auto-reject bullets | `docs/AGENT_USAGE_GUIDE.md` | Executioner **Auto-rejects** list |
| Add step 0 previous-task closure check | `hooks/work.md` | Step 0 or new preamble before Step 4 |
| Add HANDOVER REQUIRED to Executioner verdict format | `docs/AGENT_USAGE_GUIDE.md` | **Mandatory End-of-Task Output** template |
| Add `## Lessons` section + L-001 entry | `AGENTS.md` | new section at end of file |
| Backfill DONE.md rows | `state/DONE.md` | Append rows for `nex-case-008`, `nex-case-009` with evidence from their case files |
| Update QUEUE.md Completed rows | `state/QUEUE.md` | Set `nex-case-005`, `nex-case-008`, `nex-case-009` to `done` in Completed section or prune to DONE.md |

**Out of scope for this recommendation:** CI/CD pipeline changes, pre-commit hooks, scheduled cron, changes to individual case files beyond the DONE.md backfill, memory infrastructure.

---

## Verification Checklist (for reviewer)

- [ ] Every file-existence claim (or absence) matches what is actually in the repo
- [ ] Every proposed enforcement step names a specific existing file and section
      (`hooks/work.md`, `AGENT_USAGE_GUIDE.md` auto-reject list, `AGENTS.md` Immutable Rules)
- [ ] The Immutable Rule text is a plain-English bullet — no new scripts or hooks required
- [ ] The LESSON entry is copy-pasteable verbatim into `AGENTS.md`
- [ ] No new agents or skills are proposed; all changes use existing roles
- [ ] The two Executioner auto-reject bullets are expressible as plain conditions
- [ ] No forward estimates — all claims are factual observations from repo reads
