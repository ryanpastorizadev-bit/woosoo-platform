---
status: canonical
last_reviewed: 2026-06-06
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

## Backend enforcement gap (NEX-CASE-015, queued)

`StoreDeviceOrderRequest` currently accepts client-submitted `totals`, `prices`, `discounts`,
`ordered_menu_id`, and modifier fields without rejecting them. The initial-order path
recalculates these server-side, so client values are effectively ignored in practice — but
passive acceptance is not sufficient. The contract requirement is that the backend explicitly
**reject or strip** any field outside the intent-only payload above, making enforcement a code
property rather than a runtime coincidence.

This is tracked under **NEX-CASE-015**. Until that case is complete, agents must not assume
backend enforcement exists — validate intent-only behaviour against live `StoreDeviceOrderRequest`
rules, not this contract.
