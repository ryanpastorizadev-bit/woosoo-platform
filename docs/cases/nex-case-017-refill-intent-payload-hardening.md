---
status: canonical
last_reviewed: 2026-06-09
scope: woosoo-nexus
---

# CASE: nex-case-017-refill-intent-payload-hardening

## Vault links
- Registry: [[CASE_REGISTRY]] · Contracts: [[CONTRACTS_HUB]] · Home: [[OPERATOR_HOME]]
- Related cases: [[nex-case-015-tablet-intent-payload-hardening]] [[contracts/order-state.contract.md]]

## Run State
- task_slug: nex-case-017-refill-intent-payload-hardening
- tier: 2
- branch: agent/nex-case-017-refill-intent-payload-hardening
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-09 12:00

## Handoff
- Phase in progress:
- Done so far:
- Exact next action:
- Working-tree state:
- Risks / do-not-redo:

## Tier
2

## Branch
agent/nex-case-017-refill-intent-payload-hardening

## Problem

`RefillOrderRequest.php:64` allows `items.*.price` as a `nullable|numeric` field.
`OrderApiController.php:281–284` uses the client-supplied price directly when both `menu_id`
and `price` are present in the payload, skipping `KryptonMenu::find()` entirely:

```php
// Optimization: If both menu_id and price provided, skip DB lookup (testing + API contracts)
$menu = null;
if (! empty($it['menu_id']) && isset($it['price'])) {
    $menu = (object) ['id' => $it['menu_id'], 'price' => $it['price']];
}
```

This violates the immutable contract: *backend owns pricing / tablet sends intent only*.
A misconfigured or malicious tablet can submit any price on a refill order, bypassing POS pricing.

This is the same class of bug fixed in `nex-case-015` for the main order endpoint, but missed
in the refill path.

## Contrarian Review

**Challenge applied:**
- Is the exploit realistic? The device must be authenticated (Sanctum token). However, the
  exploit class (client-controlled pricing) is a hard contract violation regardless of who
  exploits it; the comment "testing + API contracts" suggests intentional scaffolding left in.
- Is this Tier 2 correct? Yes. Contract/security breach, ≤5 files, clear root cause, clear fix.
  Not Tier 3 because there is no state machine interaction, no POS DB mutation beyond what
  already happens, no payment path affected at this stage.
- Is there a simpler valid fix? Yes — removing `items.*.price` from rules is sufficient (price
  never enters `$validatedData`, so `isset($it['price'])` is always false after that). But we
  should also remove the dead-code shortcut block for clarity.
- Scope creep risk: Low. Fix is confined to one Request and one controller method.

**Verdict:** Proceed. Tier 2. Specialist: ranpo-backend.

## Success Criterion

Task is done when: sending `price` in a refill payload does NOT affect the persisted item price
(verified by a Pest feature test asserting the controller uses `KryptonMenu::find()` price, not
the client-supplied price).

## Investigation

Files verified:
- `app/Http/Requests/RefillOrderRequest.php:64` — `items.*.price` rule present
- `app/Http/Controllers/Api/V1/OrderApiController.php:281–284` — shortcut present
- `tests/Feature/OrderRefillTest.php` — 3 test methods send `price` in payload, relying on shortcut
- `tests/Feature/OrderCreateAndRefillTest.php` — 1 test method sends `price` in payload
- `tests/Feature/OrderApiControllerRefillIdempotencyTest.php` — no price in payloads (safe)
- `tests/Feature/RefillIdempotencyTest.php` — no price in payloads (safe)
- `tests/Feature/DeviceOrderIntentContractTest.php` — has refill contract tests; needs new assertion

Confirmed: `KryptonMenu` uses `protected $connection = 'pos'` and `$table = 'menus'`.
Test databases already set up pos.menus with correct prices in setUp() — KryptonMenu::find()
will work without mock changes since Eloquent's resolver bypasses the DB facade mock.

## Root Cause

The shortcut was added to support testing without POS DB setup, and the comment calls it
"testing + API contracts." This justification is wrong — tests should work through the real
lookup path, and API contracts must enforce backend-owns-pricing.

## Proposed Fix

1. `RefillOrderRequest.php` — Remove `items.*.price` from rules (price can never enter
   validated data, making the controller shortcut inert)
2. `OrderApiController.php::refill()` — Remove the `if (! empty($it['menu_id']) && isset($it['price']))`
   block; change `elseif (! empty($it['menu_id']))` to `if (! empty($it['menu_id']))`
3. `DeviceOrderIntentContractTest.php` — Add test asserting refill price is not accepted in validated data
4. `OrderRefillTest.php` — Remove `'price' =>` from all API payload items; remove stale comment
5. `OrderCreateAndRefillTest.php` — Remove `'price' =>` from API payload items

## Files Changed

- `app/Http/Requests/RefillOrderRequest.php`
- `app/Http/Controllers/Api/V1/OrderApiController.php`
- `tests/Feature/DeviceOrderIntentContractTest.php`
- `tests/Feature/OrderRefillTest.php`
- `tests/Feature/OrderCreateAndRefillTest.php`

## Code Simplification

SKIPPED — the change IS the simplification: removing a dead-code shortcut block (6 lines eliminated) and one validation rule. No new abstractions introduced.

## Verification

PASS (verifier, 2026-06-09, isolated re-run after false-negative from concurrent checkout race):
- `items.*.price` — zero matches in RefillOrderRequest.php rules (line 59-69)
- `isset($it['price'])` — zero matches in OrderApiController.php (shortcut block removed)
- `test_refill_does_not_accept_client_price()` — present at DeviceOrderIntentContractTest.php line 233
- `'price' =>` in OrderRefillTest.php postJson() payloads — zero matches in API payload arrays (remaining `'price' =>` matches are POS DB setup fixtures, not payloads)
- `'price' =>` in OrderCreateAndRefillTest.php refill payload — zero matches in API call
- All 458 tests passed (prior specialist run)

## Documentation Sync

contracts/order-state.contract.md reviewed — does not assert the refill item shape with a price field. [[nex-case-015-tablet-intent-payload-hardening]] is cross-linked in Vault links above as the prior fix for the same pattern on the main order endpoint. No doc update required.

## Executioner Verdict

APPROVED (executioner, 2026-06-09): All four verifications pass. `items.*.price` absent from rules, `isset($it['price'])` shortcut removed, contract test present, price sourced from `KryptonMenu::find()::$menu->price`.

## Remaining Risks

Low. The KryptonMenu::find() path is already exercised by the existing test suite via real pos SQLite DB in setUp(). Authenticated devices only — contract breach required a valid Sanctum token.
