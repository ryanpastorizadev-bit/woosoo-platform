---
status: canonical
last_reviewed: 2026-06-09
scope: woosoo-nexus
---

# CASE: nex-case-019-debug-endpoint-hardening

## Vault links
- Registry: [[CASE_REGISTRY]] · Contracts: [[CONTRACTS_HUB]] · Home: [[OPERATOR_HOME]]
- Related cases: [[nex-case-004-device-login-500]]

## Run State
- task_slug: nex-case-019-debug-endpoint-hardening
- tier: 1
- branch: agent/nex-case-019-debug-endpoint-hardening
- status: IN_PROGRESS
- last_completed_agent: specialist:ranpo-backend
- next_agent: verifier
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-09 12:00

## Tier
1

## Branch
agent/nex-case-019-debug-endpoint-hardening

## Problem

`routes/api.php:378` returns `'Stored procedure call failed: '.$e->getMessage()` when the POS
stored procedure throws. The endpoint is gated by:
```php
if (! (app()->environment('local') || config('app.debug'))) {
    return ApiResponse::error('Debug endpoint disabled', null, 403);
}
```
If `APP_DEBUG=true` is accidentally enabled on a live-like box (has occurred historically —
see nex-case-004 context), this leaks POS DB stored-procedure internals publicly.

## Contrarian Review

**Verdict:** Proceed. Tier 1. The gate is correct; only the error message body needs hardening.
Log the exception details; return a generic string publicly.

## Success Criterion

Task is done when: the debug endpoint returns a generic error string on POS failure and logs
the real exception to Laravel log, not to the HTTP response.

## Proposed Fix

```php
// routes/api.php:376-379
try {
    $rows = DB::connection('pos')->select('CALL get_menus_by_course(?)', [$course]);
} catch (Throwable $e) {
    \Illuminate\Support\Facades\Log::error('[debug/pos] stored proc failed', ['error' => $e->getMessage()]);
    return ApiResponse::error('POS stored procedure failed. Check Laravel log.', null, 500);
}
```

## Files Changed

- `routes/api.php`

## Code Simplification
## Verification
## Documentation Sync
## Executioner Verdict
## Remaining Risks
