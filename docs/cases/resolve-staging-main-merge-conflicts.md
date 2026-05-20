---
status: under-review
last_reviewed: 2026-05-19
scope: woosoo-print-bridge
---

# CASE: resolve-staging-main-merge-conflicts

## Run State
- task_slug: resolve-staging-main-merge-conflicts
- tier: 3
- branch: staging
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: copilot
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-19 00:40

## Handoff
- Phase in progress:
- Done so far:
- Exact next action:
- Working-tree state (list edited files explicitly; cross-check with `git status`):
- Risks / do-not-redo:

## Tier
3

## Branch
staging

## Problem
Resolve the in-progress merge of origin/main into staging for woosoo-print-bridge without dropping either PRN-CASE-003 reservation safety changes or PR #20 polling reliability changes. Conflicts are limited to the seven merge-conflicted files reported by git status.

## Contrarian Review

### Tier
3

### Assumptions Challenged
- A straight `--ours` or `--theirs` on every conflicted file would be unsafe because `polling_service.dart` must keep main's `_tick(DeviceConfig cfg, {bool bypassSkip = false})` signature for the already-merged `forceTick()` call to compile.
- The merge is scoped to `woosoo-print-bridge/**`; no backend or tablet contract edits are allowed.
- Verification must be real: `flutter analyze` and the full `flutter test` suite must both run clean before commit/push.

### Risks
- This is Tier 3 because it touches queue/retry behavior and duplicate-print prevention in the print relay.
- Dropping `HttpStatusException` or `nextReservationAttemptAt` would silently weaken transient/non-transient reservation handling and could reintroduce hot-loop reserve retries or lose dead-letter routing.
- Dropping `bypassSkip` or `_tickInFlight` would break polling reliability and can either fail compilation (`forceTick`) or reintroduce overlapping poll ticks.
- Incorrect conflict resolution in `app_controller.dart` can violate reserve → ack → failed idempotency and re-open duplicate-print risk.

### Hidden Failure Boundaries
- Reservation failures must still differentiate transient network/5xx errors from terminal 4xx statuses while preserving 409/404 special handling.
- Persisted cooldown deadlines must remain capped and honored so stale local state does not suppress work forever.
- ACK backlog visibility and polling skip-bypass behavior must survive the merge even though most changes landed outside the conflicted hunks.
- Contract to honor: `contracts/printer-relay.contract.md`.

### Assigned Specialist
- relay-ops

### Affected App
- woosoo-print-bridge

### Candidate Skills
- systematic-debugging (only if analyze/test verification fails)

### Branch
staging

### Recommendation
Proceed

## Investigation
- Verified the merge left seven unmerged files plus a cleanly merged `lib/state/app_state.dart` change from `origin/main`.
- Confirmed whole-file resolutions were safe for `.agents.md`, the print-bridge audit doc, `print_job.dart`, `api_service.dart`, and `polling_service.dart` based on the user-supplied branch intent and direct file inspection.
- Inspected every conflict hunk in `lib/state/app_controller.dart` and `test/unit/app_controller_process_queue_test.dart` before editing.

## Root Cause
The branches changed the same queue, polling, and audit/test areas for different but related reliability work. Git could not automatically reconcile HEAD's reservation retry/dead-letter changes with `origin/main`'s polling reliability updates and formatting differences.

## Proposed Fix
- Keep staging's typed reservation handling (`HttpStatusException`, `nextReservationAttemptAt`, dead-letter routing, cooldown capping) wherever those semantics were at risk.
- Keep main's polling `_tick` signature and in-flight guard so `forceTick()` still compiles and overlapping polls stay blocked.
- Preserve main's clean merge in `lib/state/app_state.dart` and resolve test conflicts in favor of the newer reservation coverage plus harmless staging formatting.

## Files Changed
- `.agents.md` — resolved add/add by taking staging's newer status and open-risk text.
- `docs/WOOSOO_PRINT_BRIDGE_PRODUCTION_RELIABILITY_AUDIT_2026-05-14.md` — resolved add/add by taking staging's newer audit version.
- `lib/models/print_job.dart` — resolved to staging so `nextReservationAttemptAt` remains present.
- `lib/services/api_service.dart` — resolved to staging so `HttpStatusException` and safer 503 parsing remain present.
- `lib/services/polling_service.dart` — resolved to main so `_tick(..., {bool bypassSkip = false})` and `_tickInFlight` survive.
- `lib/state/app_controller.dart` — manually resolved all six hunks, preserving reservation retry/dead-letter logic and cooldown-clearing fields.
- `lib/state/app_state.dart` — clean merge from main retained for ACK backlog visibility updates; no manual edit required.
- `test/unit/app_controller_process_queue_test.dart` — manually resolved conflicts, preserving reservation exception coverage and compatible formatting.

## Verification

## Verification Report

### Commands Run
- `git add .`
- `git --no-pager status --short`
- `flutter analyze`
- `flutter test`
- `git --no-pager diff --name-only --diff-filter=U`
- `git --no-pager status --short`

### Results
- `flutter analyze` → `No issues found!`
- `flutter test` → `00:11 +111: All tests passed!`
- `git --no-pager diff --name-only --diff-filter=U` produced no output (no unresolved conflicts remained).
- Final staged status before commit check: `M  lib/services/polling_service.dart`, `M  lib/state/app_state.dart`, `M  test/unit/app_controller_process_queue_test.dart`

### Functional Proof
- `polling_service.dart` now exposes `_tick(DeviceConfig cfg, {bool bypassSkip = false})` and retains `_tickInFlight`, so the already-merged `forceTick()` call compiles and bypasses the WebSocket skip when requested.
- Reservation retry/dead-letter flows stayed intact in `app_controller.dart` and are covered by the preserved/merged queue tests that passed in the full suite.
- The merge no longer contains conflict markers and is staged cleanly for commit.

### Warnings / Suspicious Output
- `flutter test` emits expected logger output from queue/ACK tests, but the suite still ended with `00:11 +111: All tests passed!`.

### Verdict
PASS

## Executioner Verdict

Verdict: APPROVED

### Reason
Tier 3 sequencing was followed and checkpointed: Contrarian risk analysis, Specialist merge resolution, Verifier evidence, then merge commit/push. The final merge preserved both reservation safety (`HttpStatusException`, `nextReservationAttemptAt`, dead-letter routing) and polling reliability (`bypassSkip`, `_tickInFlight`, `forceTick` compatibility), and verification evidence is clean: `flutter analyze` returned `No issues found!` and `flutter test` returned `00:11 +111: All tests passed!`.

### Required Next Action
None.

### Follow-Ups (if APPROVED)
- None.

## Remaining Risks
- No new risks introduced beyond the standing audit items already documented in the print-bridge audit.
