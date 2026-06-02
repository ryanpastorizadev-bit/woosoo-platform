---
status: canonical
last_reviewed: 2026-05-31
scope: ecosystem
---

# Contract: Order State (woosoo-nexus)

**Authoritative order lifecycle. This contract mirrors the actual implementation in
`woosoo-nexus/app/Enums/OrderStatus.php` — agents must not invent states or transitions, and any
change here must be made against that enum, not from memory.**

## States (the `OrderStatus` enum)

The backing enum is a string enum with nine cases:

| Case | Stored value | Role |
| ---- | ------------ | ---- |
| `PENDING` | `pending` | Transient. Order created, not yet confirmed. |
| `CONFIRMED` | `confirmed` | Accepted and dispatched to kitchen/print. Default state of a new `DeviceOrder`; the tablet enters in-session here. |
| `IN_PROGRESS` | `in_progress` | Kitchen working the order. |
| `READY` | `ready` | Order prepared. |
| `SERVED` | `served` | Order delivered to the table. |
| `COMPLETED` | `completed` | **Terminal.** Order fulfilled (POS-driven). |
| `CANCELLED` | `cancelled` | **Terminal.** Order cancelled. |
| `VOIDED` | `voided` | **Terminal.** Order voided after confirmation (POS-driven). |
| `ARCHIVED` | `archived` | **Terminal.** Order archived. |

## State machine (`OrderStatus::canTransitionTo`)

```txt
PENDING      → CONFIRMED | VOIDED | CANCELLED
CONFIRMED    → IN_PROGRESS | COMPLETED | VOIDED
IN_PROGRESS  → READY | VOIDED
READY        → SERVED | VOIDED
SERVED       → COMPLETED | VOIDED
COMPLETED    → (terminal — no transitions)
CANCELLED    → (terminal — no transitions)
VOIDED       → (terminal — no transitions)
ARCHIVED     → (terminal — no transitions)
```

Every non-terminal state can transition to `VOIDED`. The four terminal states
(`COMPLETED`, `CANCELLED`, `VOIDED`, `ARCHIVED`) do not transition further.

> **`ARCHIVED` is out-of-band.** It has no incoming row in `canTransitionTo()` — it is **not**
> reachable through the live order lifecycle. It is an administrative/retention state applied by a
> batch/admin housekeeping path (archiving old terminal orders), not by the in-session state
> machine. This is intentional; do not add a runtime transition into `ARCHIVED`.

## Order identifier (canonical)

**`krypton_woosoo.orders.id` (the POS order id) is the single global order reference.** The POS is
the source of truth for identity, so every POS-sourced id is canonical — `orders.id`, `menus.id`,
`sessions.id`, and any id on a related POS table (e.g. `order_checks`).

- In the Nexus DB, the mirror column is **`device_orders.order_id`** (nullable **string**) =
  `krypton_woosoo.orders.id`. The local PK `device_orders.id` is an internal surrogate only.
- **All broadcast channels, payloads, and consumers key on `order_id`** — the order channel is
  always `orders.{order_id}`. No consumer (tablet, admin, print-bridge) may use the local
  `device_orders.id` as the order reference. See `contracts/websocket-events.contract.md`.
- Payloads may include the local `id` for debugging, but `order_id` is the authoritative key.

## What the tablet sees

- The tablet flow is anchored by `CONFIRMED` (in-session) and the terminal signals it reacts to:
  `COMPLETED`, `VOIDED`, `CANCELLED` (per-order terminal status drives the tablet session
  lifecycle). The intermediate kitchen states (`IN_PROGRESS`, `READY`, `SERVED`) and `ARCHIVED`
  are defined in the enum but are backend/POS/kitchen-driven.
- Frontend/tablet display states may exist only if each maps to one of the enum cases above. The
  tablet never owns or sends order state.

## Rules

- **Backend owns truth.** State transitions are authorized server-side; terminal states never
  transition. The tablet sends intent only, never state.
- **Do not invent states.** The nine cases above are the complete set. A new state is a contract
  change that must be applied to `OrderStatus.php` **and** recorded here in the same change.
- A failed local transaction must not leave a partial order state; POS rows remain authoritative.
- When citing transitions in code review, check them against
  `OrderStatus::canTransitionTo()` — that method is the executable source of this table.
