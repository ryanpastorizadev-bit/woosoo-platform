---
status: under-review
last_reviewed: 2026-06-15
scope: ecosystem
---

# Doc-Alignment Enforcement Recommendation

**Author:** platform agent session, 2026-06-15 (reconciled against `dev`)
**For review by:** Ryan (platform lead)
**Scope:** Woosoo orchestration system — preventive doc-closure gate across the six tracked doc types
**Action required:** Review and approve; a subsequent scribe case applies the rule + lesson.

> **Reconciliation note (2026-06-15):** This document was first drafted on a branch that predated
> ~6 weeks of `dev` governance work. It has been rewritten to match the current `dev` reality:
> `docs/LESSONS.md` already exists (entries **L-001…L-016**, two-tier model + automated
> `recurrence-check`), the tooling-improvement program is already merged (PR #57), and
> `dev` already has **detection** tooling for case/state drift
> (`plt-case-non-complete-audit-2026-06-08`, the registry status classifier, vault orphan lint).
> What `dev` still lacks — and what this recommendation supplies — is a **preventive closure gate**
> at the Executioner → Contrarian boundary. The earlier draft's stale claims ("no LESSONS.md",
> a colliding "L-001", a "## Lessons in AGENTS.md" section) have been removed.

---

## Prior art already on `dev` (do not duplicate)

| Mechanism | Where | What it does |
|---|---|---|
| Lessons ledger (two-tier) | `docs/LESSONS.md` → promote to `docs/AGENT_DEFAULT_INSTRUCTIONS.md § Extended Rules` | Records recurring failures + guards; L-001…L-016 exist |
| Recurrence-check gate | `scripts/recurrence-check.{ps1,sh}` via `pre-merge-check` | Fails the merge gate if a guarded pattern reappears |
| Case status classifier | `scripts/lib/case-status-classify.ps1`, `scripts/case-status.ps1` | Classifies each case file's status by anchored leading token |
| Non-COMPLETE audit | `docs/cases/plt-case-non-complete-audit-2026-06-08.md` | Cross-tracks every non-COMPLETE case against `WORK.md`/`QUEUE.md`/`DONE.md`/`DEPS.md` |
| Vault orphan lint | `scripts/obsidian-lint.ps1` | Flags orphaned/broken-link docs |
| Workflow-bypass guard | `docs/LESSONS.md` **L-016** | No implementation without a case file + full chain |

These are **detection / audit** tools — they find drift after the fact. The gap below is **prevention**.

---

## Root-Cause Analysis

### Primary root cause

**APPROVED and handover are not atomic.** The 4-agent chain ends when the Executioner issues
`APPROVED`. The state-sync step — appending to `state/DONE.md`, marking the `state/QUEUE.md`
row `done`, and clearing `state/WORK.md` — lives in `hooks/handover.md` and runs **only when the
operator explicitly types "handover."** No agent in the chain checks that `DONE.md` was updated or
that the case file reached `status: COMPLETE`, and the Executioner auto-reject list contains no
such check. When the operator moves to the next task without triggering handover, the case stays
open in the state files indefinitely. The `recurrence-check` gate does not cover this, and the
non-COMPLETE audit catches it only on a later manual sweep.

### Secondary contributors

1. **Scribe phase has no enforcement check.** `AGENTS.md` marks the scribe docs-sync phase
   "mandatory for code-specialist tasks," but the Executioner auto-reject list in
   `docs/AGENT_USAGE_GUIDE.md` has no "Documentation Sync section empty" condition. The rule
   exists in prose; the gate does not.
2. **Case-file lifecycle has a detection layer but no closing gate.** The status classifier and
   non-COMPLETE audit *find* stale/orphaned case files, but nothing *forces* a case to reach
   `COMPLETE` + a `DONE.md` row at the moment of approval.

### Evidence

This recommendation does **not** re-derive case counts — `plt-case-non-complete-audit-2026-06-08`
already owns that catalog on `dev`. The pattern it documents (case files whose status diverges from
`WORK.md`/`QUEUE.md`/`DONE.md`) is exactly the failure this preventive gate is meant to stop at the
source. The historical trigger (`state/WORK.md` reconciliation, 2026-05-30) noted
`NEX-CASE-001/008/009` and others as "APPROVED but missing canonical DONE.md rows — flagged for a
verification backfill," confirming the drift is recurring, not one-off.

---

## Enforcement per Doc Type

| Doc type | Drift | Preventive enforcement step | Wired to (existing role) |
|---|---|---|---|
| `docs/cases/<slug>.md` | Reaches APPROVED but never set to `status: COMPLETE`; orphaned files | Executioner reads `## Run State`; **REJECT** if `status ≠ COMPLETE` or `next_agent ≠ done` at verdict time | **Executioner** auto-reject |
| `state/DONE.md` | APPROVED cases missing rows | Executioner `APPROVED` verdict MUST carry a `HANDOVER REQUIRED` line; **Contrarian** pre-task check confirms the previous case has a `DONE.md` row before a new task starts | **Executioner** verdict + **Contrarian** gate |
| `state/QUEUE.md` | Completed rows never set to `done` | Covered by the Contrarian pre-task check: the prior case's QUEUE row must read `done` before the next chain begins (`hooks/handover.md` Step 2 already performs the write) | **Contrarian** gate |
| `state/WORK.md` | Cache left pointing at a closed case | Same Contrarian check catches a stale `task_id` by comparing `WORK.md` against the case file status | **Contrarian** gate |
| `memory/MEMORY.md` | Does not exist | Out of scope; revisit only if memory infrastructure is added | — |
| `docs/LESSONS.md` | No closure/DONE-drift lesson yet | Append **L-017** (below) in the existing ledger format; if it recurs after the gate lands, promote to `AGENT_DEFAULT_INSTRUCTIONS.md § Extended Rules` and wire a `recurrence-check` detector | **scribe** (ledger append) |

### Exact text — Executioner auto-reject additions (`docs/AGENT_USAGE_GUIDE.md`)

Add to the **Auto-rejects if any of the following** list:

```
- Case file `## Run State → status` is not `COMPLETE` (or `next_agent` is not `done`) at verdict time
- Code-specialist task: case file `## Documentation Sync` section is empty, absent, or still
  contains template placeholder text
```

### Exact text — Contrarian pre-task closure check (`hooks/work.md`, before the Step 4 challenge)

```
[ ] 0. Previous-task closure check: if state/WORK.md shows a `task_id` other than the current
       task, read docs/cases/<that-slug>.md and confirm `status: COMPLETE` AND a state/DONE.md
       row exists for it AND its state/QUEUE.md row reads `done`. If any is missing, halt; report
       the unclosed task by ID and instruct the operator to run `handover` before starting new work.
```

---

## Proposed Immutable Rule (`AGENTS.md` → `## Immutable Rules`)

Per the governance-hardening precedent, any new Immutable Rule must be mirrored verbatim into
`.cursor/rules/woosoo.mdc`.

```
- **Task closure is atomic.** A task is DONE only when ALL three are true:
  (1) the case file `## Run State → status: COMPLETE` and `next_agent: done`;
  (2) `state/DONE.md` has an APPROVED row for this case;
  (3) `state/QUEUE.md` row for this case shows `status: done`.
  The Executioner `APPROVED` verdict must include a "HANDOVER REQUIRED" instruction, and the
  Executioner REJECTS if the case file Run State is not COMPLETE at verdict time. The Contrarian
  halts and reports any unclosed prior task before starting a new one.
```

---

## Drafted Lesson — L-017 (append to `docs/LESSONS.md § Ledger`, in the existing format)

```md
### L-017 — Task closure not atomic: APPROVED without state-file sync
- Tags: #process #governance #docs
- Symptom: A case reaches Executioner APPROVED, but `state/DONE.md` has no row, the
  `state/QUEUE.md` row never flips to `done`, and the case file never reaches `status: COMPLETE`.
  Drift is only caught later by the non-COMPLETE audit.
- Root cause: `hooks/handover.md` (the DONE.md/QUEUE/WORK sync) is a separate operator-triggered
  step, not part of the agent chain. The chain ends at APPROVED; no gate verifies closure, so when
  the operator starts the next task without typing "handover", state diverges.
- Guard: "Task closure is atomic" Immutable Rule (AGENTS.md + `.cursor/rules/woosoo.mdc`).
  Executioner auto-rejects if the case file is not `COMPLETE` and its APPROVED verdict carries a
  HANDOVER REQUIRED line. Contrarian step-0 halts a new task until the prior case shows
  `COMPLETE` + a DONE.md row + a `done` QUEUE row.
- Evidence: `state/WORK.md` reconciliation (2026-05-30, NEX-CASE-001/008/009 missing DONE rows);
  `plt-case-non-complete-audit-2026-06-08` (recurring catalog of case/state drift).
- Promoted: candidate — promote to `AGENT_DEFAULT_INSTRUCTIONS.md § Extended Rules` + a
  `recurrence-check` detector if drift recurs after the gate lands.
```

---

## Implementation Scope (for the follow-on scribe case)

This document is read-only. After approval, create `plt-case-doc-closure-gate` to apply:

| Change | File |
|---|---|
| Add "Task closure is atomic" Immutable Rule | `AGENTS.md` + mirror in `.cursor/rules/woosoo.mdc` |
| Add two Executioner auto-reject bullets | `docs/AGENT_USAGE_GUIDE.md` |
| Add HANDOVER REQUIRED to the Executioner verdict format | `docs/AGENT_USAGE_GUIDE.md` |
| Add Contrarian step-0 closure check | `hooks/work.md` |
| Append L-017 | `docs/LESSONS.md` |
| Backfill missing rows | `state/DONE.md` (NEX-CASE-008/009 and any others the non-COMPLETE audit lists) |

**Out of scope:** CI/CD changes, pre-commit hooks, cron; memory infrastructure; bulk case-file
cleanup (owned by `plt-case-non-complete-audit-2026-06-08`).

---

## Verification Checklist (for reviewer)

- [ ] No claim contradicts current `dev` (LESSONS.md exists; L-017 is the next free number; the
      rule is genuinely absent from `AGENTS.md` and `AGENT_DEFAULT_INSTRUCTIONS.md`)
- [ ] Every enforcement step names an existing role + file (`hooks/work.md`, `AGENT_USAGE_GUIDE.md`,
      `AGENTS.md`) — no new agents or skills
- [ ] L-017 matches the `docs/LESSONS.md` entry format exactly
- [ ] The Immutable Rule is plain English and mirrored to `.cursor/rules/woosoo.mdc`
- [ ] Builds on dev's existing detection tooling rather than duplicating it
