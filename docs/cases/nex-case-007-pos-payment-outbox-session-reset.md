---
status: canonical
last_reviewed: 2026-05-21
scope: woosoo-nexus
---

# CASE: nex-case-007-pos-payment-outbox-session-reset

## Run State
- task_slug: nex-case-007-pos-payment-outbox-session-reset
- tier: 3
- branch: agent/nex-case-007-pos-payment-outbox-session-reset
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: none
- active_runner: codex
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-21 19:50

## Handoff
- Phase in progress: complete
- Done so far: POS-local order/session outbox path implemented; per-order SessionReset blast radius removed; authenticated device last_seen_at refresh middleware added.
- Exact next action: review diff and deploy by running `php artisan pos:setup-payment-trigger` in POS-connected environments.
- Working-tree state: backend app files and this case file modified on `agent/nex-case-007-pos-payment-outbox-session-reset`.
- Risks / do-not-redo: do not reintroduce `SessionReset` on per-order completion; `session.reset` is reserved for staff/admin reset or POS daily session close.

## Tier
3

## Branch
agent/nex-case-007-pos-payment-outbox-session-reset

## Problem
Tablet devices remain on the in-session screen until Nexus dispatches terminal order/session reset events. Current POS payment reconciliation runs once per minute, which is too slow for cashier-driven POS payment or void actions.

## Contrarian Review
- This is not a tablet fix: Nexus owns broadcasts and POS owns payment truth.
- Cross-server MySQL trigger updates are unsafe/impossible for split DB deployments; a POS-local outbox keeps the trigger local to POS.
- Tier 3 because this touches POS DB writes, order terminal state, realtime session reset, and scheduler concurrency.
- Single app scope: `woosoo-nexus/**` app code plus root case documentation only.

## Investigation
- `SetupPosOrderPaymentTrigger.php` currently tries to create a cross-database trigger only when POS and app MySQL endpoints match.
- `SyncPosOrderPaymentStatus.php` polls POS every minute and manually dispatches realtime events because it bypasses Eloquent observers with raw DB updates.
- `DeviceOrderObserver` also dispatches terminal events on Eloquent status updates, so the new consumer must not mix Eloquent updates with explicit dispatch.
- Canonical contracts: POS remains authoritative; order state is `confirmed → completed | voided | cancelled`.

## Root Cause
Nexus has no low-latency, durable signal for POS-side order close/void events in split database deployments, so it falls back to minute-level polling.

## Proposed Fix
- Replace the setup command with POS-local outbox table + trigger setup.
- Add a raw-update terminal finalizer service that performs compare-and-swap local status updates, audit logging, and explicit per-order event dispatch without invoking `DeviceOrderObserver`.
- Add a consumer command scheduled every five seconds with `withoutOverlapping(3)` and `runInBackground()`.
- Keep the minute-level sync as a safety-net reconciler using the same finalizer.
- Reserve `SessionReset` for daily POS `sessions.date_time_closed` outbox rows, not per-order payment rows.
- Update device `last_seen_at` from regular authenticated tablet/device API traffic with a 30-second timestamp throttle.

## Files Changed
- `woosoo-nexus/app/Console/Commands/ConsumePosPaymentStatusEvents.php`
- `woosoo-nexus/app/Console/Commands/SetupPosOrderPaymentTrigger.php`
- `woosoo-nexus/app/Console/Commands/SyncPosOrderPaymentStatus.php`
- `woosoo-nexus/app/Http/Middleware/UpdateDeviceLastSeen.php`
- `woosoo-nexus/app/Services/Pos/PosOrderStatusFinalizer.php`
- `woosoo-nexus/config/devices.php`
- `woosoo-nexus/routes/api.php`
- `woosoo-nexus/routes/api_printer_routes.php`
- `woosoo-nexus/routes/console.php`
- `woosoo-nexus/tests/Feature/Console/PosPaymentOutboxConsumerTest.php`
- `woosoo-nexus/tests/Feature/Console/PosPaymentOutboxSetupTest.php`
- `woosoo-nexus/tests/Feature/Middleware/UpdateDeviceLastSeenTest.php`

## Verification
- RED: `php artisan test tests\Feature\Console\PosPaymentOutboxConsumerTest.php tests\Feature\Console\PosPaymentOutboxSetupTest.php --compact` failed before fixes because per-order completion dispatched `SessionReset`, session-close outbox rows were ignored, and setup did not create the session outbox.
- RED: `php artisan test tests\Feature\Middleware\UpdateDeviceLastSeenTest.php --compact` failed before middleware because authenticated tablet traffic left stale `last_seen_at`.
- GREEN: `php artisan test tests\Feature\Console\PosPaymentOutboxConsumerTest.php tests\Feature\Console\PosPaymentOutboxSetupTest.php tests\Feature\Api\V1\SessionResetAuthTest.php tests\Feature\OrderRealtimeBroadcastTest.php tests\Feature\Middleware\UpdateDeviceLastSeenTest.php tests\Feature\Api\V2\TabletCategoriesApiTest.php tests\Feature\DeviceCreateOrderConflictTest.php --compact` passed: 34 tests, 148 assertions.
- GREEN: `.\scripts\pre-merge-check.ps1 -App woosoo-nexus` passed after `composer test`, `php artisan route:list`, and `php artisan config:clear`.

## Executioner Verdict
APPROVED

## Remaining Risks
- POS schema setup must be run in environments that need the faster outbox path.
- Permanent broadcast failures dead-letter outbox rows via `failed_at`; operations should monitor rows where `failed_at IS NOT NULL`.
- `routes/api.php` was Pint-formatted while adding middleware, so the route diff is larger than the functional change.
