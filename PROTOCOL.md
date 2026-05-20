---
status: canonical
last_reviewed: 2026-05-17
scope: ecosystem
---

# Woosoo Agent Orchestration Protocol

Concise routing reference. Full rules live in `AGENTS.md` and `docs/AGENT_DEFAULT_INSTRUCTIONS.md`.
Read this when you need the routing summary without loading the full AGENTS.md.

---

## Boot Sequence

1. **Resume check first** — derive task slug, check `docs/cases/<task-slug>.md` per `docs/RESUME_PROTOCOL.md`.
   - `IN_PROGRESS` or `BLOCKED`: resume from `## Run State → next_agent`. Do not restart.
   - `COMPLETE`: do not reopen.
   - Absent: start fresh as Contrarian. Create case from `docs/cases/_TEMPLATE.md`.
2. Read `AGENTS.md`, `docs/AI_CONTEXT.md`, `docs/AGENT_DEFAULT_INSTRUCTIONS.md`.
3. Match user phrase → hook (see AGENTS.md § Hook System). Load that hook.
4. Consult `state/WORK.md` for quick routing — it is a cache of the active case Run State, not the authoritative record.
5. If no active task → read `state/QUEUE.md`, pick first unblocked row.
6. Classify task tier before doing anything else.

---

## Task Tiers

| Tier | What it covers | Agent chain |
|---|---|---|
| **1 — Trivial** | Typo, single-line config, comment, README link, label change. No contract/auth/state/payment/print impact. | `Specialist → Executioner` |
| **2 — Standard** | Bug fix, new endpoint, UI component, doc rewrite, API validation, local refactor. One app per task. | `Contrarian → Specialist → Verifier → Executioner` |
| **3 — High-risk** | Order state machine, session lifecycle, payment/pricing, printing, auth/token, API contract change, Reverb/broadcasting, queue/scheduler, race conditions, DB migrations, cross-app, production deployment. | `Contrarian (written risk analysis) → Specialist → Verifier → Executioner` |

**When in doubt, escalate the tier. Never downgrade without written justification.**

---

## Contrarian — Mandatory Challenge Questions

Run before every non-Tier-1 task. Answer all seven. Do not skip.

```
[ ] 1. Is this in the correct app or platform scope? Could it be misattributed?
[ ] 2. Does this already exist somewhere? Check before building.
[ ] 3. Is the scope exactly as described, or narrower/wider than assumed?
[ ] 4. What breaks if this is wrong? Who else consumes this behavior?
[ ] 5. Is there a simpler path to the same outcome?
[ ] 6. Does this touch a contract, auth, state machine, payment, or print flow? → escalate to Tier 3.
[ ] 7. Should this be split into separate case files per app?
```

If any answer changes the scope: update the case file before proceeding.
If cross-app work is confirmed: return `SPLIT_REQUIRED`. Do not modify app code.

---

## Specialist Routing

| Domain | Specialist | App scope |
|---|---|---|
| Backend / API / Auth / POS / Reverb / order state | ranpo-backend | `woosoo-nexus/**` |
| Frontend / Nuxt / PWA / UI / Pinia / tablet flow | chuya-frontend | `tablet-ordering-pwa/**` |
| Printer relay / hardware / heartbeat / station printing | relay-ops | `woosoo-print-bridge/**` |
| Docs / specs / handover / orchestration | dazai-docs | `docs/**`, `*.md` |
| Docker / Nginx / env / deployment / LAN / Pi | infra | `docker/**`, `scripts/**` |

---

## Token Budgets

| Tier | Max files | Notes |
|---|---|---|
| Tier 1 | ≤ 5 | Load only changed path(s) + 1 test |
| Tier 2 | ≤ 12 | Case file + source files + tests + contracts if confirmed |
| Tier 3 | ≤ 25 | Each file beyond 15 must be justified in handoff block |

**Context loading order:**
1. `docs/cases/<task-slug>.md` (resume check — always first)
2. `AGENTS.md`, `docs/AI_CONTEXT.md`, `docs/AGENT_DEFAULT_INSTRUCTIONS.md`
3. Matching hook file
4. `state/WORK.md` (quick routing cache — after resume check and AGENTS.md)
5. Case file for the task (if not already loaded in step 1)
6. `state/DEPS.md` (Status column only unless dep is active)
7. Source files identified in the case
8. Relevant tests
9. `contracts/*.md` — only if contract involvement is confirmed
10. `state/QUEUE.md`, `state/DONE.md` — only for status/handover hooks

**Never load by default:** all case files, all contracts, full repo trees, lock files, archive, unrelated app dirs.

---

## Case File Paths

All case files use the flat path per `docs/RESUME_PROTOCOL.md`:
```
docs/cases/<task-slug>.md
```

Recommended slug format for new cases: `<prefix>-case-<NNN>-<short-description>`
- `nex-case-NNN-*` → woosoo-nexus
- `tab-case-NNN-*` → tablet-ordering-pwa
- `prn-case-NNN-*` → woosoo-print-bridge
- `plt-case-NNN-*` → woosoo-platform

Per-app subdirectories (`docs/cases/nexus/`, `docs/cases/tablet/`, `docs/cases/bridge/`, `docs/cases/platform/`) hold only:
- `TASK_STATUS.md` — per-app task tracking table
- `HANDOVER.md` — per-app handover state

They do **not** hold individual case files.

---

## Dependency Unlock Rule

A dependent task may only proceed when its blocking dependency is `confirmed` in `state/DEPS.md`
with recorded verification evidence.

Never assume a dependency is done based on: plans, comments, intent, unverified code,
untested endpoints, or agent confidence.

If a previously `confirmed` dependency changes: set status → `changed`, mark all consumer
tasks `blocked`, reverify before proceeding.

---

## Concurrent Work Rule

One app per task. This is a multi-repo sibling workspace; "one app" means one of: `woosoo-nexus`, `tablet-ordering-pwa`, `woosoo-print-bridge`, or `woosoo-platform` (orchestration only).

**Allowed:** multiple tasks each touching only one app, no shared contract being changed,
no unconfirmed cross-app dependency between them.

**Not allowed:** frontend depends on unverified backend API, print bridge depends on
unverified backend event, any shared contract/env/auth/order-state change affecting multiple apps.

---

## Failure Signals — Never Ignore

Stop and investigate when you see:
failed tests · build errors · type errors · lint errors affecting correctness · runtime warnings ·
console errors · 401/403/419/422/500 responses · race condition symptoms · duplicate submissions ·
empty state after action · loading state that never resolves · missing env vars · token mismatch ·
app key mismatch · failed queue jobs · failed broadcasts · printer heartbeat failures ·
DB migration warnings · unexpected file changes

---

## Completion Gate

```
No error ≠ working.
Working = verified.
A task is done only when the Executioner returns APPROVED.
```

Executioner verdicts: `APPROVED` · `REJECTED` · `SPLIT_REQUIRED`

---

## Handoff Block Format (between agent phases)

```
## Handoff
Task:         <case ID>
App:          <woosoo-nexus | tablet-ordering-pwa | woosoo-print-bridge | woosoo-platform>
Tier:         <1 | 2 | 3>
Files read:   <list — max 5, then "...N more">
Finding:      <one sentence>
Decision:     <what was decided and why>
Risks:        <any risks discovered>
Deps:         <dependency checks made>
Next action:  <exactly what the next phase must do>
Validation:   <what must be verified and how>
```

---

## Cleanup Before Completion

```
[ ] Remove temp scripts and debug logs (unless intentionally kept — document them)
[ ] Remove dead code, unused imports, unused files
[ ] Remove commented-out experimental code
[ ] No duplicate documentation
[ ] No generated/build artifacts committed (unless expected)
[ ] git diff clean of unrelated changes
```

---

## Pruning Rules (state files)

- `state/DONE.md` > 30 rows: move rows older than 30 days to `docs/archive/DONE_ARCHIVE.md`
- `state/QUEUE.md` completed rows: prune weekly; summary only in archive
- Case files: move to `docs/archive/` after 60 days post-completion
