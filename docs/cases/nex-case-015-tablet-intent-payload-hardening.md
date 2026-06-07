---
status: canonical
last_reviewed: 2026-06-06
scope: woosoo-nexus
---

# CASE: nex-case-015-tablet-intent-payload-hardening

## Run State
- task_slug: nex-case-015-tablet-intent-payload-hardening
- tier: 2
- branch: agent/nex-case-015-tablet-intent-payload-hardening
- status: IN_PROGRESS
- last_completed_agent: specialist:ranpo-backend (cursor)
- next_agent: verifier
- active_runner: cursor
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-07

## Handoff
- Phase in progress: Specialist implementation complete; awaiting Verifier full-suite gate.
- Done so far: `StoreDeviceOrderRequest` whitelists intent-only fields via `prepareForValidation()` + slim rules; tests added/updated.
- Exact next action: Verifier run `php artisan test` on branch `agent/nex-case-015-tablet-intent-payload-hardening`; dazai-docs follow-up to remove NEX-CASE-015 gap note from `contracts/tablet-api.contract.md`.
- Working-tree state: committed on `agent/nex-case-015-tablet-intent-payload-hardening` at woosoo-nexus (4 files). Unrelated local edits remain unstaged (`CertificatePathResolver.php`, `certificate.blade.php`).
- Risks / do-not-redo: Do not change intent field names. Do not touch POS pricing/recalculation. Refill path (`RefillOrderRequest`) out of scope for this case.

## Specialist Investigation & Implementation

**Approach:** Strip (not 422-reject) unknown fields in `prepareForValidation()` using `$this->replace()` so only `guest_count`, `package_id`, and `items[{menu_id,quantity}]` reach validation and `$request->validated()`. Removed nullable rules for client pricing/modifier keys — they are no longer accepted at all.

**Files changed (woosoo-nexus):**
- `app/Http/Requests/StoreDeviceOrderRequest.php` — intent-only whitelist
- `tests/Feature/DeviceOrderValidationTest.php` — asserts stripped `validated()` output
- `tests/Feature/DeviceOrderIntentContractTest.php` — strip test added
- `tests/Feature/DeviceOrderIntentPayloadHardeningTest.php` — HTTP test mocks `OrderService`, asserts expanded payload ignores client tampering and persisted order uses server totals

**Self-check (2026-06-07):**
```text
php artisan test --filter="DeviceOrderValidationTest|DeviceOrderIntentContractTest|DeviceOrderIntentPayloadHardeningTest"
Tests: 16 passed (49 assertions)
```

**Hygiene:** Deleted accidental untracked file `query` (garbage one-liner).

**Branch note:** Committed on `agent/nex-case-015-tablet-intent-payload-hardening` (woosoo-nexus).

**Contract doc:** `contracts/tablet-api.contract.md` still lists NEX-CASE-015 as queued — platform docs update deferred to dazai-docs after Executioner APPROVED.

## Tier
2 — backend validation correctness. No order/print/payment logic; enforces an existing contract property.

## Branch
agent/nex-case-015-tablet-intent-payload-hardening (off `dev`)

## Problem

`StoreDeviceOrderRequest` (`app/Http/Requests/StoreDeviceOrderRequest.php`) currently accepts
client-submitted pricing, discount, and modifier fields (`totals`, `prices`, `discounts`,
`ordered_menu_id`, modifier fields) without rejecting them. The tablet intent-only contract
(`contracts/tablet-api.contract.md`) requires the backend to explicitly reject or strip these
fields. Passive acceptance — even when the backend recalculates server-side — is not sufficient
contract enforcement.

**Contract reference:** `contracts/tablet-api.contract.md` — Backend enforcement gap (NEX-CASE-015).

## Success Criterion
`StoreDeviceOrderRequest` explicitly rejects (400/422) or strips any field outside
`{ guest_count, package_id, items: [{ menu_id, quantity }] }` on the tablet order-submission
route. Verified by a feature test sending a payload with extra pricing/modifier fields and
asserting the extra fields are absent from the persisted `device_orders` row.
