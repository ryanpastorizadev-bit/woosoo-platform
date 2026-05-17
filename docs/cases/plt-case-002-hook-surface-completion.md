---
status: canonical
last_reviewed: 2026-05-17
scope: woosoo-platform
---

# CASE: PLT-CASE-002 — Canonical Hook Surface Completion

## Run State
- task_slug: plt-case-002-hook-surface-completion
- tier: 2
- branch: main
- status: IN_PROGRESS
- last_completed_agent: specialist:dazai-docs
- next_agent: verifier
- active_runner: codex
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-17

## Handoff
- Phase in progress: verifier
- Done so far: Added the missing canonical hook files, added inbox files, expanded the AGENTS.md trigger map after hooks existed, normalized state table wording to App terminology, removed pending rows from DONE.md, and kept contract references on existing `contracts/*.contract.md`.
- Exact next action: Verifier should run the stale-phrase scan, hook existence check, chain-order check, and root/nested git status scope review.
- Working-tree state:
  - AGENTS.md — trigger map expanded to all installed hooks
  - hooks/status.md — created
  - hooks/intake.md — created
  - hooks/triage.md — created
  - hooks/verify.md — created
  - hooks/review.md — created
  - hooks/unlock.md — created
  - hooks/handover.md — created
  - inbox/RAW.md — created
  - inbox/TRIAGED.md — created
  - PROTOCOL.md — scan-triggering wording tightened without changing routing semantics
  - docs/README.md — scan-triggering heading wording tightened
  - docs/RESUME_PROTOCOL.md — scan-triggering helper wording tightened
  - state/WORK.md — active cache updated to PLT-CASE-002
  - state/QUEUE.md — App wording and active row updated
  - state/DEPS.md — Provider App / Consumer App wording updated
  - state/DONE.md — pending row removed
- Risks / do-not-redo:
  - Do not make `state/WORK.md` authoritative; the case file remains the durable source.
  - Do not create a new contract index in this case.
  - Do not change Verifier before Executioner ordering.
  - Do not touch app code.

---

## Tier
2 — Standard

## Branch
main
<!-- Orchestration/docs work runs on main per team convention. App feature work uses agent/<slug> branches. -->

## Problem

PLT-CASE-001 repaired the canonical protocol but intentionally left the full hook surface as follow-up work. Only `hooks/work.md` and `hooks/execute.md` existed, while the trigger map needed to support status, intake, triage, verify, review, unlock, and handover as real hook files.

## Contrarian Review

**Conducted:** 2026-05-17

1. **Correct app or platform scope?** Yes. This is `woosoo-platform` orchestration only.
2. **Already exists?** Partially. `work.md` and `execute.md` exist; the remaining hook files and inbox files were missing.
3. **Scope exact?** Yes. Complete hook and inbox surface while preserving repaired protocol rules.
4. **What breaks if wrong?** Agents may route to missing hooks, trust stale cache state, skip Verifier, or write completions before approval.
5. **Simpler path?** Add only missing hooks/inbox and normalize state wording. Do not redesign the protocol.
6. **Contract/auth/state/payment/print impact?** No. Docs/orchestration only.
7. **Split required?** No. Single platform orchestration case.

**Decision:** Proceed as Tier 2. Specialist: dazai-docs.

## Investigation

- `AGENTS.md` listed only `work.md` and `execute.md` as installed hooks.
- `state/QUEUE.md`, `state/DEPS.md`, and `state/DONE.md` still used legacy app-scope wording in table columns or comments.
- `state/DONE.md` contained a pending PLT-CASE-001 row despite saying only Executioner-approved completions belong there.
- Existing protocol docs already preserve `docs/cases/<task-slug>.md` as authoritative and `state/WORK.md` as cache only.

## Proposed Fix

1. Create the missing hook files with canonical app/cross-app terminology.
2. Add inbox files for raw and triaged intake.
3. Expand `AGENTS.md` trigger map only after hook files exist.
4. Normalize state table columns to App terminology.
5. Remove pending rows from `state/DONE.md`.
6. Keep Verifier before Executioner and avoid inventing a new contract index.

## Files Changed

- AGENTS.md
- hooks/status.md
- hooks/intake.md
- hooks/triage.md
- hooks/verify.md
- hooks/review.md
- hooks/unlock.md
- hooks/handover.md
- hooks/work.md
- hooks/execute.md
- inbox/RAW.md
- inbox/TRIAGED.md
- PROTOCOL.md
- docs/README.md
- docs/RESUME_PROTOCOL.md
- state/WORK.md
- state/QUEUE.md
- state/DEPS.md
- state/DONE.md
- docs/cases/plt-case-002-hook-surface-completion.md

## Verification

- [x] Stale protocol phrase scan returns no matches.
  - Command: required `rg` scan for stale path/order/source-of-truth/contract-index phrases.
  - Output: no matches.
- [x] Hook existence check returns all true.
  - Output: nine `True` lines for work/status/intake/triage/execute/verify/review/unlock/handover.
- [x] Chain-order scan confirms Verifier before Executioner.
  - Output: AGENTS.md, CLAUDE.md, PROTOCOL.md, and hooks/execute.md show Tier 2/3 as `Contrarian → Specialist → Verifier → Executioner`.
- [x] Git status scope review confirms no app code was touched by this case.
  - Root status includes PLT-CASE-001 repair changes plus PLT-CASE-002 hook/inbox/state/docs changes.
  - Nested app worktrees remain dirty from other work; PLT-CASE-002 did not touch app code.

## Specialist Handoff

Task: PLT-CASE-002
App: woosoo-platform
Tier: 2
Files read: AGENTS.md, state/WORK.md, state/QUEUE.md, state/DEPS.md, state/DONE.md, ...2 more
Finding: The repaired protocol was canonical, but the missing hooks and stale state table wording kept the surface incomplete.
Decision: Added the missing hook and inbox files, expanded routing, normalized state tables, and preserved case-file authority.
Risks: Root worktree includes prior PLT-CASE-001 repair changes, and nested app worktrees are already dirty from other work; this case did not clean or validate unrelated changes.
Deps: none
Next action: Verifier reruns the required scans and reviews root/nested git status before Executioner verdict.
Validation: Stale-phrase scan, hook existence check, chain-order scan, and git status scope review.

## Executioner Verdict

PENDING

## Remaining Risks

- PLT-CASE-001 remains a separate repair case awaiting verifier/executioner closure.
