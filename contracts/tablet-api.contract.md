---
status: canonical
last_reviewed: 2026-06-07
scope: ecosystem
---

# Contract: Tablet → Backend API (tablet-ordering-pwa → woosoo-nexus)

**Implementation must be verified against actual code. This document records the contract.**

## Order submission payload (strict, intent-only)

```json
{
  "guest_count": 0,
  "package_id": 0,
  "items": [
    { "menu_id": 0, "quantity": 1 }
  ]
}
```

## Rules
- The tablet sends **intent only**. It must never send pricing, tax, modifiers, totals, POS
  mapping, or order state. The backend computes and owns all of that.
- No invented fields. No invented order states (see `order-state.contract.md`).
- Backend API errors must be converted into client-safe UI messages. Raw technical errors,
  stack traces, and SQL errors must never reach the customer screen.
- The tablet flow must not continue after a critical API failure — it must surface a friendly
  message and stop, not fabricate success.
- No hardcoded LAN IPs or API/Reverb hosts in tablet code.

## Backend enforcement (device order create)

`StoreDeviceOrderRequest` (`woosoo-nexus/app/Http/Requests/StoreDeviceOrderRequest.php`)
**strips** any field outside the intent-only payload in `prepareForValidation()` before rules
run. Only `guest_count`, `package_id`, and `items[{menu_id, quantity}]` reach `validated()`.
Client-submitted `totals`, `prices`, `discounts`, `ordered_menu_id`, and modifier fields are
discarded — not accepted, not persisted from client input.

Landmark: **NEX-CASE-015** — merged to `woosoo-nexus` `dev` via PR #178 (2026-06-07).
Refill path (`RefillOrderRequest`) is a separate route; this contract section applies to the
tablet **initial order** submission only.
