---
status: canonical
last_reviewed: 2026-05-17
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
