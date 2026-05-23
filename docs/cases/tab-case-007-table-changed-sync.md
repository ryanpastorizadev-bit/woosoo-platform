---
status: canonical
last_reviewed: 2026-05-23
scope: tablet-ordering-pwa
---

# CASE: tab-case-007-table-changed-sync

## Run State
- task_slug: tab-case-007-table-changed-sync
- tier: 2
- branch: staging @ 2ccc52f
- status: IN_PROGRESS
- last_completed_agent: verifier
- next_agent: executioner
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-23 10:32

## Handoff
- Phase in progress: n/a
- Done so far: Specialist + Verifier complete on tablet `staging` commit `2ccc52f`; awaiting Pi proof and Executioner verdict
- Exact next action: Confirm known-working `message` delivery on Pi, then run Phase 3 Gate A + Gate B live tests, then Executioner sign-off
- Working-tree state:
  - `tablet-ordering-pwa/composables/useBroadcasts.ts` — modified
  - `tablet-ordering-pwa/tests/broadcasts.table-changed.spec.ts` — new
  - `docs/cases/tab-case-007-table-changed-sync.md` — new (this file)
- Risks / do-not-redo: do not trust payload.table_id; do not force-end active sessions

## Tier
2

## Branch
staging @ 2ccc52f

## Problem

Stale-sync gap: the backend dispatches `AppControlEvent` with `action: "table_changed"` whenever an admin reassigns or unassigns a device's table (`DeviceController.php:409`). The tablet listens to `.device.control` on `device.{deviceId}`, but `DeviceControlEvent.action` in `useBroadcasts.ts` did not include `"table_changed"`, so the `handleDeviceControl` switch silently dropped the event. The device store retained the stale persisted table, allowing session start to proceed on a device that no longer has a valid table assignment.

The session start guard (`Session.ts::start`) already calls `deviceStore.checkTableAssignment()` to re-verify with the server before ordering begins — this is the existing backstop. The remaining gap is that the broadcast should trigger an immediate self-correcting refresh so the local state reflects reality as soon as the admin acts.

## Contrarian Review

- Scope: tablet PWA only. No backend contract changes.
- Risk of force-ending active sessions: rejected by product owner — "a device without a table should not be allowed to start a session" (new sessions only).
- Risk of trusting `payload.table_id` directly: rejected — server refresh is authoritative.
- Risk of double-refresh (reconnect + table_changed): idempotent; harmless.
- Conclusion: Tier 2 fix is appropriate.

## Investigation

- `AppControlEvent.broadcastAs()` returns `"device.control"` → tablet receives as `.device.control`.
- `useBroadcasts.ts:125` `DeviceControlEvent.action` union excluded `"table_changed"`.
- `handleDeviceControl` switch had no `case "table_changed":` → event silently dropped.
- `deviceStore.refresh()` calls `POST /api/devices/refresh` and applies `applyAuthPayload()` — correct mechanism.
- `app:device-control` artisan command exists (`Commands/Test/DeviceControlTest.php`) for Pi delivery testing. Note: it sends a generic payload without `table_id`; the handler calls `refresh()` regardless.

## Root Cause

Missing `"table_changed"` in `DeviceControlEvent.action` union + no handler case in `handleDeviceControl` switch.

## Proposed Fix

1. Extend `DeviceControlEvent.action` union to include `"table_changed"`.
2. Add `case "table_changed":` in `handleDeviceControl`: fire-and-forget `deviceStore.refresh()`, show `ElMessage.warning` if table becomes null, show `ElNotification` otherwise.
3. Unit test: `tests/broadcasts.table-changed.spec.ts` (3 cases, all green).

## Files Changed

- `tablet-ordering-pwa/composables/useBroadcasts.ts` — type union + `case "table_changed":`
- `tablet-ordering-pwa/tests/broadcasts.table-changed.spec.ts` — new unit test (3 tests)

## Verification

Local gate:
- typecheck: **PASS** (tsc --noEmit exit 0)
- lint: **PASS** (eslint 0 errors)
- tests: **PASS** 71/71 files, 391 tests pass, 1 todo — full suite green
- new tests: 3/3 pass (fire refresh, non-null table → notification, null table → warning)

Pi Gate A and Gate B: **PENDING** — must be run on Pi before Executioner verdict.

## Executioner Verdict

PENDING — awaiting Pi Gate A + Gate B live proof.

## Remaining Risks

- Pi proof gates not yet run. If Gate A fails (existing `message` action not delivered), diagnose Reverb/Nginx before relying on `table_changed` delivery.
- Gate B requires real admin flow (unassign, not reassign) to prove null-table branch.
- Active sessions during table unassignment are intentionally not terminated; next session start will be blocked by the existing guard.
