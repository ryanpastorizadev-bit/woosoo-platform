---
status: COMPLETE
last_reviewed: 2026-05-20
scope: woosoo-nexus
---

# CASE: nex-case-004-device-login-500

Device login endpoint (`POST /api/devices/login`) returns HTTP 500 in production.

## Run State
- task_slug: nex-case-004-device-login-500
- tier: 3
- branch: agent/nex-case-004-device-login-500
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: none
- active_runner: none
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-20

## Handoff
- Phase in progress: COMPLETE
- Done so far: Contrarian (2026-05-19) identified root cause. Specialist implemented `safeLoadDeviceTable()` try/catch on `authenticate()` + full feature test suite. Verifier confirmed 6/6 tests pass (25 assertions). Executioner APPROVED.
- Working-tree state: clean — changes committed to woosoo-nexus repo

## Tier
3

## Branch
agent/nex-case-004-device-login-500

## Problem

`POST /api/devices/login` (`DeviceAuthApiController@authenticate`) returns HTTP 500 in production.

Source: RAW-20260518-002 (first observed 2026-05-18). Deferred at intake pending NEX-CASE-001 (security hardening) completion — NEX-CASE-001 is now COMPLETE.

Possible failure classes (not yet confirmed — reserved for Contrarian):
- Device lookup failure
- Token generation failure
- Data validation / request shape issue

This is separate from NEX-CASE-003 (`get_open_orders_for_session` stored procedure — POS connection gap).

## Contrarian Review

**Contrarian completed: 2026-05-19. Tier escalated: 3 (authentication endpoint — device lockout risk).**

### 7-Question Analysis

1. **Correct scope?** Yes — `DeviceAuthApiController@authenticate` lives in `woosoo-nexus`. Specialist: `ranpo-backend`. ✓

2. **Already exists?** Not a duplicate. NEX-CASE-003 is the stored procedure gap on the POS DB;
   this is the login endpoint 500 in the app controller. They share a root infrastructure
   (POS connection instability) but are separate code defects.

3. **Scope right?** Narrower than the slug suggests. The MySQL/Redis container health is tracked
   under PLT-CASE-009. The 500 here is a code-level failure: `authenticate()` calls
   `$device->table()->first(['id', 'name'])` in its success-path response — `Table` uses
   `$connection = 'pos'` — with no try/catch. POS connection failure throws an uncaught
   `QueryException` → HTTP 500. The auth and token issuance are complete before this call;
   only the response assembly fails.

4. **What breaks if wrong?** This is `POST /api/devices/login` — the entry point for every
   tablet. Wrong fix risks:
   - Locking out all tablets if the fix introduces an auth bypass or breaks token issuance.
   - Silently masking a data error if the table join is load-bearing for the caller.
   - Stale tokens if the token pruning logic (`expires_at` delete) is altered incorrectly.

5. **Simpler path?** Yes. The `table` field in the auth response is **not part of the auth
   contract** — it is convenience metadata. Wrapping `$device->table()->first()` in a
   try/catch returning null on POS failure is the minimal, correct, safe fix. It makes the
   auth endpoint resilient to POS connection issues without touching auth logic.
   The tablet can reload table data after login if null.

6. **Touches contract/auth/state machine?** YES — authentication endpoint. Token issuance and
   device state update (`last_seen_at`, `last_ip_address`) are in scope. **Tier 3 mandatory.**

7. **Split required?** No — the fix is isolated to one null-safe guard around the `table` join.
   However, `Table.php:56` contains an `env('APP_ENV') === 'testing'` violation (same pattern
   as NEX-CASE-003 R5). That is a separate mechanical fix and must not be bundled with the
   auth fix in the same commit.

**Verdict: PROCEED — Tier 3. Specialist: ranpo-backend.**

**Fix path approved:** Add try/catch around `$device->table()->first(['id', 'name'])` in
`authenticate()` — return null on any Throwable. Do NOT touch token issuance, IP resolution,
passcode logic, or device update. Zero changes to the auth flow.

### Risk Inventory

**R1 — Auth endpoint — device lockout risk (highest)**
Any regression in `authenticate()` breaks all tablet logins. The fix must be strictly scoped
to the `table` join in the response. Token issuance is above the fix site and must not be touched.

**R2 — No tests for `authenticate()` (critical coverage gap)**
`grep DeviceAuthApiController *Test.php` → no matches. The Specialist must add feature tests
covering: (a) successful login returns 200 with null table when POS is down, (b) successful
login returns 200 with table when POS is up, (c) device not found returns 404, (d) device
unregistered returns 403. Without tests, regressions are invisible.

**R3 — POS connection is also called by `register()` and `lookupByIp()`**
Both endpoints also call `$device->table()->first()` in their success responses. The same POS
connection risk applies. The fix should be applied consistently to all three methods — but only
after verifying the Specialist's approach is correct for `authenticate()` first. Scope to
`authenticate()` only in this case; follow-up for `register()` and `lookupByIp()` if needed.

**R4 — Token pruning `$device->tokens()->where('expires_at', '<', now())->delete()`**
This line runs before the POS call and has no try/catch. If the `personal_access_tokens` table
is missing the `expires_at` column, this would also 500. However, the migration
`2025_06_22_063628_create_personal_access_tokens_table.php` creates the column at table
creation — not as an ALTER. If the table exists (device auth has worked historically), the
column is present. Low-probability risk; confirmed safe unless `php artisan migrate` was never
run at all.

**R5 — `device_uuid` immutability guard in `Device::booted()`**
`static::updating()` throws `\Exception` if `device_uuid` is dirty. The `$device->update()`
call in `authenticate()` only sets `last_seen_at` and `last_ip_address` — it should not dirty
`device_uuid`. Safe, but Specialist should verify the Device model has no global `$fillable`
gap that could include `device_uuid` unexpectedly.

**R6 — `Table.php:56` env() violation (out of scope)**
`checkTableStatus()` still calls `env('APP_ENV') === 'testing'`. Not called in the login path,
but should be cleaned up as a follow-up (same pattern as NEX-CASE-003 R5).

**R7 — Contrarian flag: is the POS connection failure confirmed?**
The 500 source is inferred by static analysis — `table()->first()` is the only unguarded POS
call in the success path. Confirmation requires a production log entry showing a QueryException
from the `pos` connection during a login request. The Specialist should check
`storage/logs/laravel.log` for `[QueryException]` entries co-located with `POST /api/devices/login`.
If the log shows a different exception class or call site, the fix target may differ.

## Investigation

**Call chain (confirmed by static analysis):**

```
POST /api/devices/login
 └─ DeviceAuthApiController::authenticate()         [line 230]
     ├─ IP resolution                                → safe (pure PHP)
     ├─ Device::where(['ip_address', 'is_active'])   → default DB connection → safe
     ├─ [device not found] → AuditLogService         → fire-and-forget catch → safe
     ├─ [device not found] → return 404              → safe
     ├─ [device unregistered] → AuditLogService      → fire-and-forget catch → safe
     ├─ [device unregistered] → return 403           → safe
     ├─ $device->update([last_seen_at, last_ip])     → default DB → no try/catch ⚠️ (R4)
     ├─ $device->tokens()->where(expires_at)->delete → Sanctum table → no try/catch ⚠️ (R4)
     ├─ $device->createToken(expiresAt: ...)         → Sanctum table → no try/catch ⚠️ (R4)
     └─ return response()->json([
             ...
             'table' => $device->table()->first(['id', 'name'])  ← POS connection → no try/catch 🔴
             ...
        ])
```

**Why `table()->first()` is the prime suspect:**
- `Table::$connection = 'pos'` — confirmed in `app/Models/Krypton/Table.php:18`.
- POS connection was actively failing during the same production window (NEX-CASE-003 log 2026-05-19 17:44).
- All other calls in the success path use the default DB connection (which is functional if device auth worked before).
- Token operations (R4) would cause a total auth system failure, not an intermittent login 500 — the narrower symptom points to the POS call.
- `$device->table()->first()` executes a POS query only when `table_id` is set on the device. Tablets have `table_id` set → every successful tablet login hits the POS DB.

**No existing tests for `authenticate()`:**
`grep -r "DeviceAuthApiController" tests/` → no matches. Full path is untested.

## Root Cause

**Probable (high confidence — static analysis, not confirmed by live log):**

`DeviceAuthApiController::authenticate()` calls `$device->table()->first(['id', 'name'])` in
the success-path JSON response (line 294). `Device::table()` is a `belongsTo(Table::class)`
relation; `Table::$connection = 'pos'`. When the POS DB connection fails (as observed during
the 2026-05-19 production incident), this throws an uncaught `QueryException` → HTTP 500.

The auth flow itself (IP resolution, device lookup, token creation) completes successfully
before this call. The 500 is thrown during response assembly — meaning the device IS
authenticated and a token IS issued, but the response is never returned.

**Cross-ref:** POS connection instability is the infrastructure root cause (PLT-CASE-009).
This case fixes the application-layer guard that must exist regardless of POS health.

**Confirmation required:** Check `storage/logs/laravel.log` for `QueryException` on the `pos`
connection co-located with `POST /api/devices/login` requests.

## Proposed Fix

Wrap `$device->table()->first(['id', 'name'])` in a `private safeLoadDeviceTable(Device $device): mixed` helper that catches `\Throwable` and returns `null` on POS failure. Call it from `authenticate()` only (scope: this method, not `register()` or `lookupByIp()`).

## Files Changed

- `woosoo-nexus/app/Http/Controllers/Api/V1/Auth/DeviceAuthApiController.php`
  - `authenticate()` line 295: `$device->table()->first(['id', 'name'])` → `$this->safeLoadDeviceTable($device)`
  - Added private method `safeLoadDeviceTable()` (lines 483–495): try/catch `\Throwable`, logs warning, returns null
- `woosoo-nexus/tests/Feature/Api/V1/DeviceAuthApiControllerTest.php` (new file — 6 tests, 25 assertions)

Contract impact: **no** — `table` field was already nullable in the response; null is now returned instead of 500 when POS is down.

## Verification

```
php artisan test --filter DeviceAuthApiControllerTest
Tests:    6 passed (25 assertions)
Duration: 15.29s
```

Tests confirmed:
- ✅ 200 + table data when POS is up
- ✅ 200 + null table when device has no table_id
- ✅ 200 + null table when POS is down (key regression test — was previously 500)
- ✅ 404 when device not found
- ✅ 403 when device not yet registered
- ✅ expired tokens pruned, 30-day token issued

## Executioner Verdict

**APPROVED** — 2026-05-20. Fix is minimal, scoped to `authenticate()` only, no auth flow changes, no contract break, full test coverage added where zero existed.

## Remaining Risks

- R3 (deferred): `register()` and `lookupByIp()` still call `$device->table()->first()` without protection (lines 218, 326). Schedule as NEX-CASE-004b or bundle into a follow-up nexus hardening pass.
- R6 (deferred): `Table.php:56` env() violation (`env('APP_ENV') === 'testing'`) — same pattern as NEX-CASE-003 R5. Not in the login path; clean up in a follow-up.
