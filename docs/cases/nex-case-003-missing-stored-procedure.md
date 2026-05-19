---
status: IN_PROGRESS
last_reviewed: 2026-05-19
scope: woosoo-nexus
---

# CASE: nex-case-003-missing-stored-procedure

Production order retrieval broken — `get_open_orders_for_session` stored procedure missing on POS DB.

## Run State
- task_slug: nex-case-003-missing-stored-procedure
- tier: 3
- branch: agent/nex-case-003-missing-stored-procedure
- status: IN_PROGRESS
- last_completed_agent: contrarian
- next_agent: specialist (ranpo-backend)
- active_runner: none
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-19

## Handoff
- Phase in progress: Specialist (ranpo-backend) — awaiting assignment
- Done so far: Contrarian analysis complete (2026-05-19). Risk inventory written (R1–R6). Recommended path: Eloquent inline over proc recreation.
- Exact next action: Specialist must (1) confirm the actual 500 source, (2) choose Eloquent inline vs proc, (3) remove `env('APP_ENV')` call (R5), (4) plan UI fallback (R3).
- Working-tree state: no changes (docs only so far)
- Risks / do-not-redo: Do NOT create the stored procedure before confirming the 500 source. Do NOT touch the Krypton DB schema without explicit sign-off.

## Tier
3

## Branch
agent/nex-case-003-missing-stored-procedure

## Problem

`get_open_orders_for_session` stored procedure does not exist on the POS DB (`krypton_woosoo`).

Production log 2026-05-19 17:44:
```
SQLSTATE[42000]: 1305 PROCEDURE krypton_woosoo.get_open_orders_for_session does not exist
```

Order retrieval endpoint returns HTTP 500 in production. The pos connection schema does not have this procedure; this is a schema/migration gap, not a container-down symptom (Docker MySQL/Redis issues are tracked separately under PLT-CASE-008).

Source: RAW-20260519-001.

## Contrarian Review

**Completed: 2026-05-19. next_agent → specialist (ranpo-backend).**

### Primary Challenge: The 500 Is Not Explained by the Missing Proc

The catch block at `OrderRepository::getOpenOrdersForSession()` (lines 143–148) already catches
`\Exception` — which covers `Illuminate\Database\QueryException` — logs a warning, and returns
`collect([])`. Under that code path the dashboard should NOT 500. The SQLSTATE[42000] log entry
is the *warning log*, not the 500 cause.

**The 500's actual source is unconfirmed.** Before any proc is created, the Specialist must
confirm where the 500 originates: is it the proc catch misfiring, a different code path in
`DashboardController::index()`, or a downstream Vue render error on a malformed payload?

### Risk Inventory

**R1 — Schema ownership on a shared POS DB (highest risk)**
`krypton_woosoo` is the Krypton vendor POS system. We do not own its schema. Adding a stored
procedure to a vendor-managed DB risks being silently dropped on any POS upgrade or schema
migration. Any proc we create must be treated as fragile and require a re-deploy runbook
step.

**R2 — Unknown proc contract (what should it return?)**
No definition for `get_open_orders_for_session` exists in the codebase (no `.sql` files, no
migration). We don't know the expected columns. The alternative approach — replace the proc
call with a direct Eloquent query on the `Order` model filtered by `session_id` — is safer
because it stays in code we own and is already what the test env does:
```php
return Order::where('session_id', $sessionId)->get();
```
The Specialist must decide: recreate the proc (vendor-DB risk) or inline Eloquent (app-code
approach, already proven in tests).

**R3 — Silent data degradation already in production**
The current catch returns `collect([])` silently. Dashboard `openOrders` panel shows nothing
with no user-visible error. Operations staff are flying blind. Regardless of the fix
chosen, a visible fallback message or alert is needed at the UI layer.

**R4 — Test bypass hides the real path**
```php
if (app()->environment('testing') || env('APP_ENV') === 'testing') {
    return Order::where('session_id', $sessionId)->get();
}
```
Tests never exercise the stored procedure path. Any proc fix will be untested by the test
suite unless the test bypass is removed or a dedicated proc integration test is added.
The `FakeOrderRepository` returns `collect([])` unconditionally — it doesn't mirror the
bypass logic.

**R5 — `env()` in application code (Spatie guideline violation)**
Line 138 calls `env('APP_ENV')` directly inside a repository method. Per Spatie standards
and Laravel conventions, `env()` must not be used outside config files.
`app()->environment('testing')` is already the correct check; the `env()` call is
redundant and should be removed regardless of the fix chosen.

**R6 — Contrarian flag on preemption priority**
NEX-CASE-003 preempts PLT-CASE-003 (P1 vs P3). If `openOrders` is genuinely silenced by the
catch and the 500 comes from elsewhere, urgency may be P2 not P1. Confirm the 500 source
before treating this as full production outage. PLT-CASE-003 is unblocked and waiting — do
not delay it indefinitely.

### Contrarian Verdict

Do not create or restore the stored procedure until:
1. The actual 500 source is confirmed (not assumed to be the proc).
2. A decision is made: proc recreation vs. Eloquent inline (R2).
3. The `env('APP_ENV')` call (R5) is removed as part of the same change.
4. A UI-level fallback is planned (R3).

Recommended path to Specialist: **prefer the Eloquent inline approach** — it removes the
vendor-DB dependency, is already tested implicitly, and aligns with the existing test
environment behaviour. The proc recreation path requires a separate runbook and re-deploy risk.

## Investigation

**Call chain:**

```
GET /dashboard
 └─ DashboardController::index()       [app/Http/Controllers/Admin/DashboardController.php:111]
     └─ OrderRepository::getOpenOrdersForSession($session->id)
         ├─ [testing] Order::where('session_id', $sessionId)->get()
         └─ [production] Order::fromQuery("CALL get_open_orders_for_session(?)", [$sessionId])
              ↓ throws QueryException: SQLSTATE[42000] 1305
              ↓ caught by catch(\Exception $e) → Log::warning() → returns collect([])
```

The procedure `get_open_orders_for_session` is called only from `getOpenOrdersForSession()`.
No other call sites exist in the codebase. The result `$openOrders` is passed to
`Inertia::render('Dashboard', ['openOrders' => $openOrders, ...])` — an empty collection is
valid JSON, so the Inertia serialisation is not the 500 source.

No `.sql` file or migration defining this procedure exists anywhere in the repository.
`FakeOrderRepository` stubs it as returning `collect([])` unconditionally.

## Root Cause

**Probable:** The stored procedure `get_open_orders_for_session` was never created in the
production `krypton_woosoo` DB — a schema/deployment gap, not a container issue.

**Unresolved:** The 500 HTTP response. Given the catch block, the dashboard page should not
500 from the missing proc alone. The actual 500 trigger is a separate investigation item that
the Specialist must confirm before writing any fix.

## Proposed Fix

## Files Changed

## Verification

## Executioner Verdict

## Remaining Risks
