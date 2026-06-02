---
status: COMPLETE
task_slug: prn-case-002-queue-retention-cleanup
tier: 2
app: woosoo-print-bridge
branch: staging/orchestration-hooks
created: 2026-05-18
---

# PRN-CASE-002 — Queue Retention / Cleanup Policy

## Run State
- task_slug: prn-case-002-queue-retention-cleanup
- tier: 2
- branch: staging/orchestration-hooks
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: none
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-18

## Investigation

- `lib/services/queue_store.dart`: No purge logic existed. `store.clear()` nukes the whole store.
- `lib/core/constants.dart`: No TTL constants.
- `lib/state/app_controller.dart`: `init()` loads queue then starts timers — ideal insertion point for startup cleanup gate after `_loadPersistedMetrics()`. `SharedPreferences` already imported.
- Baseline suite: `00:10 +102: All tests passed!` (102 tests).

## Implementation

### Files Changed
- `lib/core/constants.dart` — added `successJobTtl`, `deadLetterTtl`, `purgeCheckPeriod`.
- `lib/services/queue_store.dart` — added `purgeCompletedJobs()` and `purgeDeadLetters()`.
- `lib/state/app_controller.dart` — added `_runStartupCleanupIfDue()` and call in `init()`.
- `test/unit/queue_store_cleanup_test.dart` — NEW: 4 tests covering purge logic.

### Safety
- `purgeCompletedJobs` only deletes `success`, `failed`, `cancelled` — never `pending`, `printing`, `printedAwaitingAck`, or `reserved`.
- Purge gate is time-gated (24h) via SharedPreferences key `last_purge_epoch_ms` — runs at most once per day at startup.
- No idempotency guarantees are affected; purge only touches terminal-state rows.

## Verification

- `flutter test`: `00:10 +108: All tests passed!` (108 tests, 0 failures, +6 new)
- `flutter analyze`: `No issues found! (ran in 93.0s)`
