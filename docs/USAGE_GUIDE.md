---
status: canonical
last_reviewed: 2026-06-06
scope: ecosystem
---

# Usage Guide — Driving the Woosoo 4-Agent System

Operator-facing runbook. This guide **navigates**; the authoritative rules live in the files it
points to (`AGENTS.md`, `docs/AGENT_DEFAULT_INSTRUCTIONS.md`, `docs/RESUME_PROTOCOL.md`,
`PROTOCOL.md`). Where this guide and those files appear to differ, the rule files win.

## 1. How to drive it

You type a short phrase; one chatbox plays all four roles — **Contrarian → Specialist → Verifier
→ Executioner** — and the durable state lives in `docs/cases/<slug>.md`, not the chat. A task is
done only when the **Executioner returns `APPROVED`**.

| You type | What happens |
| -------- | ------------ |
| `intake this: <bug/feature>` | Fresh case — Contrarian challenges, sets tier, picks specialist |
| `work` / `continue` / `next` / `go` | Resume the active/queued task from its last gate |
| `status` | Print in-progress work + last gate |
| `triage` / `make a case` | Convert a raw report into a case file |
| `execute <case>` | Run the implementation chain |
| `verify` / `did it work` | Run the Verifier (tests/build/lint) |
| `review` | Inspect partial/unfinished work |
| `blocked` / `unlock` | Dependency check |
| `handover` / `sync` | Write the post-completion handover |

Full hook map + tiers + routing: `AGENTS.md`. Concise routing reference: `PROTOCOL.md`.

## 2. Continuing from a session summary

A chat summary (or `CLAUDE.local.md`) is **not** durable state — the case file is. To continue
correctly, convert each open item into the case system:

1. Split the summary into individual tasks — **one app each**.
2. `intake this: <one item>` → the Contrarian triages it and creates `docs/cases/<slug>.md`.
3. Backlog with ordering/blockers → rows in `state/QUEUE.md` (+ `state/DEPS.md` for cross-app
   dependencies).
4. `work` / `what's next` resumes from the case files + queue.
5. If the summary is old, the case is created with a **"verify against current code"** note —
   never assume a stale item is still open.

## 3. Common scenarios → where the protocol lives

These are codified and enforced at the gates; this table is the index.

| Scenario | Protocol |
| -------- | -------- |
| **Uncommitted changes** in the working tree | `AGENT_DEFAULT_INSTRUCTIONS.md` → *Working Tree Preservation* (decision tree; stage only your files by path; never `git add .`) |
| **A fix must not recur** | *Regression Lock — A Fix Stays Fixed* (fail-before/pass-after test required) + *Root Cause Proof Standard* |
| **A fix failed / REJECTED** | Revert only the bad file; re-run Verifier clean before fix-forward. Never `git reset --hard` / `git clean -fd` (*Destructive Git Operations Are Absolutely Forbidden*) |
| **Work spans two apps** | Executioner returns `SPLIT_REQUIRED`; split into per-app cases (`AGENTS.md` → Workspace Split Rule) |
| **Interrupted / machine switch** | `git pull && git switch agent/<slug>`, then `resume` — case file's `next_agent` is the resume point (`RESUME_PROTOCOL.md`) |
| **Touching auth/POS/order-state/payment/print/deploy** | Auto-escalates to Tier 3 (deep Contrarian + risk analysis + contract reference) |
| **Test counts look off / "pre-existing" claims** | *Report Rejection Protocol*, *Full-Suite Requirement*, *No "Pre-existing" Hand-Waves* |

## 4. Skills

The Contrarian picks from the **scenario → skill map** in `AGENTS.md` → *Skill Discovery*; the
Specialist loads only those. `agent-sequence` is mandatory every task; `test-verification` and
`dead-code-cleanup` on every code task.

## 5. Cursor Hybrid Workflow (EXPERIMENTAL — Tier 1–2 only)

Use Cursor for the Specialist (code-writing) phase. Claude Code keeps all orchestration gates.
**Tier 3 tasks must use a Claude Code Specialist — do not use Cursor.**
Full rules and rationale: `AGENTS.md § Cursor Specialist Mode`.

### Mandatory session preamble (paste at the start of every Cursor session)

> **Why mandatory:** Cursor has a known bug loading `.cursor/rules` in multi-root workspaces
> (confirmed 2025–2026). Until Phase 2 (per-app repo rules files) lands, this paste-preamble
> is the safety mechanism for Gaps 2 (app boundaries) and 3 (immutable rules). Do not skip it.

```
Woosoo Platform — session rules (mandatory, paste before any other prompt):

IMMUTABLE RULES — never violate:
1. Backend owns truth. Tablet sends only { guest_count, package_id, items:[{menu_id,quantity}] }.
   Never send pricing, tax, modifiers, totals, POS mapping, or order state from the tablet.
2. Order states: pending confirmed in_progress ready served completed cancelled voided archived.
   Terminal: completed|cancelled|voided|archived. Do not invent states.
3. No raw errors in customer UI. Friendly messages only; stack traces go to logs.
4. No hardcoded LAN IPs or Reverb hosts in tablet or bridge code.
5. No secrets in .env without operator review.

APP BOUNDARY — edit only: [INSERT one of: woosoo-nexus/** | tablet-ordering-pwa/** | woosoo-print-bridge/**]
If asked to touch a second app: STOP and request a SPLIT.

TIER 3 STOP LIST — refuse and tell operator to use Claude Code if task touches:
order state · session lifecycle · payment/pricing · printing · auth/tokens · API contracts ·
Reverb/broadcasting · queues · race conditions · DB migrations · cross-app · production deploy

GIT — do NOT: git commit, git add . / -A, git reset --hard, git clean, force-push.
Branch must already be agent/<slug>. Operator stages and commits.

CHECKPOINT (your last action): write ## Specialist Investigation & Implementation to
docs/cases/<slug>.md in the platform repo, and refresh ## Run State:
  last_completed_agent: specialist:<agent-name>
  next_agent: verifier
  active_runner: cursor
  status: IN_PROGRESS
  updated: <YYYY-MM-DD>
If you cannot find the case file: STOP.

PRE_EDIT — before first file edit: complete hooks/pre-edit-gate.md output in chat (files table,
minimal patch, non-goals, risks). Do not edit until done.
POST_EDIT — before checkpoint: complete hooks/post-edit-review.md output (behavior diff, contract
check, rollback).
```

### Step-by-step

1. **Claude Code:** `intake this: <task>` → Contrarian triages, creates `docs/cases/<slug>.md`.
   For Tier 1, run a minimal precheck: slug + case file + Run State — slug/resume discipline is never skipped.
2. Read the case file's `## Contrarian Review` and `## Handoff` blocks — this is Cursor's brief.
3. **Cursor:** open **`woosoo-platform.code-workspace`** (multi-root). Confirm branch `agent/<slug>`.
4. **Cursor:** paste preamble + Contrarian brief. Run **PRE_EDIT_GATE** before first edit. Implement
   — editing only the active app's `<app>/**`. Run **POST_EDIT_REVIEW** before checkpoint.
5. **Cursor:** final action — write Specialist checkpoint to `docs/cases/<slug>.md`.
   **Operator confirms the checkpoint is present before continuing.**
6. **Operator:** `git diff` to review changes; stage specific files by path; commit.
7. **Claude Code:** `verify` → Verifier runs `scripts/pre-merge-check.sh --app <name>`.
8. **Claude Code:** `work` → Executioner returns `APPROVED` / `REJECTED` / `SPLIT_REQUIRED`.

### On REJECTED

`git restore <specific-files>` (restore only Cursor's files — **never** `git restore .`).
Re-run Verifier clean before any fix-forward. If Cursor caused the failure, consider switching to a Claude Code Specialist for fix-forward.

### Context7 documentation lookup

For up-to-date library/framework docs inside Cursor (Nuxt, Laravel, Flutter, etc.), see
[CONTEXT7_GUIDE.md](CONTEXT7_GUIDE.md). Ask library-specific questions in chat or use the
`/docs` command; never paste secrets or `.env` values into Context7 queries.

### Rule sync

`.cursor/rules/woosoo.mdc` mirrors `AGENTS.md § Immutable Rules`. When immutable rules change, update both files. `AGENTS.md` is canonical; the `.mdc` file is a Cursor-side copy.

### Phase 2 (recommended — removes paste-preamble requirement)

Create one case per app repo (`plt-case-NNN-cursor-rules-<app>`) to add a scoped
`.cursor/rules/<app>.mdc` to each of `woosoo-nexus`, `tablet-ordering-pwa`, and
`woosoo-print-bridge`. Each is the platform `.mdc` scoped to that app's paths and verification
commands. Once each app repo has its own rules file and it is verified to load in a single-root
Cursor session, the paste-preamble for that app becomes optional.

---

## 6. How docs stay current — and keep improving (anti-degradation loop)

Nothing auto-updates. `hooks/*.md` are markdown playbooks, not executable hooks; README/CHANGELOG
do not self-write. Currency is **gate-enforced**, and the system is designed to ratchet forward,
not rot:

- **Checkpoint discipline** — every agent writes its output + `## Run State` to the case file
  before handing off. No checkpoint = the phase did not happen.
- **Handover + `state/DONE.md`** — completion is recorded; knowledge is captured, not lost.
- **Regression Lock** — a fixed defect gets a test, so it cannot silently return.
- **Documentation-truth gate** — `dazai-docs` + `documentation-truth-audit` + the Executioner
  **reject** a task whose docs claim things the code doesn't do, link to missing files, or leave
  the case file unupdated. (This is what catches stale inventories and dead links.)
- **Evidence-derived rules** — when a new failure mode appears, add a rule to the *Extended Rules
  (Evidence-Derived from Production Failures)* section of `AGENT_DEFAULT_INSTRUCTIONS.md` so it
  cannot recur. The ruleset only grows tighter.
- **Periodic orchestration audit** — re-run the structural checks (agents/skills/hooks resolve,
  no dead links, docs match code) when the system changes; fix drift immediately.

The rule of thumb: **every fix leaves behind a guard** (a test, a rule, or a corrected doc) so the
same problem cannot return — that is what keeps the system improving rather than degrading.
