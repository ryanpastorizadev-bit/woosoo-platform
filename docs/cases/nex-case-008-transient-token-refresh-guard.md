---
status: canonical
last_reviewed: 2026-05-23
scope: woosoo-nexus
---

# CASE: nex-case-008-transient-token-refresh-guard

## Run State
- task_slug: nex-case-008-transient-token-refresh-guard
- tier: 3
- branch: agent/nex-case-008-transient-token-refresh-guard
- status: IN_PROGRESS
- last_completed_agent: specialist:ranpo-backend
- next_agent: verifier
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-23

## Handoff
- Phase in progress: n/a
- Done so far: Contrarian + Specialist complete. instanceof guards added to refresh() and logout(). 2 new tests added. pre-merge: 430 passed (1510 assertions), 0 failures.
- Exact next action: Verifier runs pre-merge-check.ps1 -App woosoo-nexus and confirms both new tests pass and all prior tests are still green. Then Executioner verdict.
- Working-tree state: 2 files committed in woosoo-nexus on branch agent/nex-case-008-transient-token-refresh-guard (commit 7b9d5d9).
- Risks / do-not-redo: do not weaken auth; do not change the happy path for PersonalAccessToken callers; 401 is the correct response for wrong caller type (not 403)

## Tier
3

## Branch
agent/nex-case-008-transient-token-refresh-guard

## Problem

`POST /api/devices/refresh` and `POST /api/devices/logout` crash with
`Undefined property: Laravel\Sanctum\TransientToken::$id` (HTTP 500) when an admin
web session (cookie-based Sanctum web guard) hits either endpoint.

Real tablet devices authenticate with a `PersonalAccessToken` — they are never
affected. The crash only fires when a non-Device principal (e.g. admin signed into
the Laravel admin panel) calls a device-only endpoint. This was surfaced during Pi
gate testing for tab-case-007 when the refresh endpoint was exercised from a browser
while an admin session cookie was active.

Source: identified 2026-05-23 during tab-case-007 Pi gate preparation.

## Contrarian Review

**Contrarian completed: 2026-05-23. Tier escalated to 3.**

### 7-Question Analysis

1. **Correct scope?** Yes — `DeviceAuthApiController` lives in `woosoo-nexus`. Specialist:
   `ranpo-backend`. One app only. ✓

2. **Already exists?** Not a duplicate. NEX-CASE-004 fixed the `authenticate()` (login) path
   with `safeLoadDeviceTable()`. This is the `refresh()` and `logout()` paths — a different
   failure class in the same controller. Not previously addressed.

3. **Scope right?** Narrow. Two method bodies, two new tests. No new routes, no session
   behavior changes, no contract changes.

4. **Tier?** **3.** `contracts/auth-session.contract.md` (canonical) is explicit: "Auth changes
   are Tier 3: require a Contrarian risk analysis and Executioner opus review."
   `DeviceAuthApiController` is an auth endpoint. The change only adds defensive guards
   (returns 401 for wrong caller), but the contract tier is non-negotiable.

5. **Risk of the fix?** Low within Tier 3 constraints.
   - Happy path for `PersonalAccessToken` callers is unchanged.
   - 500 → 401 for admin web sessions is a security improvement (crash is worse than rejected).
   - No auth is weakened.
   - No change to token issuance, revocation, or session lifecycle.

6. **Risk of NOT fixing?** Moderate. Any Pi gate test that calls `POST /api/devices/refresh`
   from a browser admin session will 500. Not a tablet runtime issue (tablets use device tokens),
   but a test-environment cleanliness concern. In a misuse scenario, an admin could accidentally
   void their own session state via a 500 instead of getting a clean 401.

7. **Alternatives considered?**
   - Route middleware restricting to device-token guard only: more correct architecturally but
     a larger change with more surface area. The guard approach keeps the fix minimal.
   - Conclusion: `instanceof` guards in method bodies are the safest, smallest fix.

**Verdict: Proceed. Specialist may begin.**

## Investigation

- `currentAccessToken()` returns `TransientToken` (no `$id` property) for cookie-based Sanctum
  sessions. `PersonalAccessToken` has `$id`.
- `refresh()` body: crashes at `$currentToken->id` when `$currentToken` is `TransientToken`.
- `logout()` body: same crash pattern.
- The `Device` model check and `PersonalAccessToken` check are both needed because:
  a) `auth()->user()` could return a non-Device principal (admin User)
  b) Even if the user is a Device, `currentAccessToken()` could theoretically return a
     non-PAT in some Sanctum edge cases.
- `use App\Models\Device;` and `use Laravel\Sanctum\PersonalAccessToken;` are already imported
  in the controller (per draft audit — confirm in actual file before editing).

## Root Cause

`refresh()` and `logout()` in `DeviceAuthApiController` do not guard against non-Device
principals or non-PersonalAccessToken token types before accessing `->id` on the token.
Sanctum's web guard returns `TransientToken` which has no `id` property, causing a fatal
property access on `null`-typed field → HTTP 500.

## Proposed Fix

**`woosoo-nexus/app/Http/Controllers/Api/V1/Auth/DeviceAuthApiController.php`**

Add `use Illuminate\Http\JsonResponse;` to imports if not already present.

`refresh()` — add at the top of the method body:
```php
if (!($device instanceof Device) || !($currentToken instanceof PersonalAccessToken)) {
    return response()->json(['message' => 'Unauthorized'], 401);
}
```

`logout()` — add at the top of the method body:
```php
if (!($device instanceof Device)) {
    return response()->json(['message' => 'Unauthorized'], 401);
}
```
In the token deletion block, guard: only delete token if `$currentToken instanceof PersonalAccessToken`.

**`woosoo-nexus/tests/Feature/Api/V1/DeviceTokenLifecycleTest.php`**

Add `use App\Models\User;` to imports if not already present.

Add two tests after `test_valid_token_can_refresh`:
```php
public function test_refresh_returns_401_when_called_with_web_session(): void
{
    $admin = User::factory()->admin()->create();
    $response = $this->actingAs($admin, 'web')
        ->postJson('/api/devices/refresh');
    $response->assertStatus(401);
}

public function test_logout_returns_401_when_called_with_web_session(): void
{
    $admin = User::factory()->admin()->create();
    $response = $this->actingAs($admin, 'web')
        ->postJson('/api/devices/logout');
    $response->assertStatus(401);
}
```

Note: verify exact line numbers in the actual file before inserting — the draft cites
`refresh()` at ~310-312, `logout()` at ~335-345, and test insert point after line 164.
These may have shifted.

## Specialist Output

Completed: 2026-05-23

### Files Changed

- `woosoo-nexus/app/Http/Controllers/Api/V1/Auth/DeviceAuthApiController.php`
  - Added `use Illuminate\Http\JsonResponse;` import
  - `refresh()`: added `instanceof Device` + `instanceof PersonalAccessToken` guards; returns 401 for non-device or web-session callers; happy path byte-for-byte unchanged; return type declared `JsonResponse`
  - `logout()`: added `instanceof Device` guard; token deletion only runs when `instanceof PersonalAccessToken`; returns 401 for non-device callers; return type declared `JsonResponse`

- `woosoo-nexus/tests/Feature/Api/V1/DeviceTokenLifecycleTest.php`
  - Added `use App\Models\User;` import
  - Added `test_refresh_returns_401_when_called_with_web_session()` after `test_valid_token_can_refresh()`
  - Added `test_logout_returns_401_when_called_with_web_session()` after the refresh test

### Pre-Merge Check Result

Command: `.\scripts\pre-merge-check.ps1 -App woosoo-nexus`

```
Tests: 430 passed (1510 assertions)
Duration: 222.71s
```

All 430 tests passed. 0 failures. Both new tests confirmed green:
- `refresh returns 401 when called with web session` — PASS
- `logout returns 401 when called with web session` — PASS

All 5 pre-existing DeviceTokenLifecycleTest tests — PASS.

### Auth Contract Compliance

- No auth weakened — guards only reject non-Device/non-PAT callers, never permit less-privileged callers
- Happy path for PersonalAccessToken callers is byte-for-byte unchanged
- 401 (not 403) is the correct status for wrong caller type on a device-only endpoint
- No secrets printed or logged
- No CSRF protection disabled
- No stateful domain config changed

### Commit

Repository: woosoo-nexus  
Branch: agent/nex-case-008-transient-token-refresh-guard  
Commit: `7b9d5d9` — `fix(auth): guard refresh() and logout() against TransientToken crash`

## Files Changed

- `woosoo-nexus/app/Http/Controllers/Api/V1/Auth/DeviceAuthApiController.php`
- `woosoo-nexus/tests/Feature/Api/V1/DeviceTokenLifecycleTest.php`

## Verification

```powershell
.\scripts\pre-merge-check.ps1 -App woosoo-nexus
```

Result: 430 passed (1510 assertions), 0 failures.

Both new tests green:
- `test_refresh_returns_401_when_called_with_web_session` — PASS
- `test_logout_returns_401_when_called_with_web_session` — PASS

## Executioner Verdict

PENDING — Tier 3 requires opus model for Executioner review.

## Remaining Risks

- Line numbers in `DeviceAuthApiController.php` must be confirmed before editing.
- `User::factory()->admin()` factory state must exist in the test suite — confirm or use
  an equivalent factory state available in the nexus test suite.
- If `use Illuminate\Http\JsonResponse;` is already imported, do not add a duplicate.
