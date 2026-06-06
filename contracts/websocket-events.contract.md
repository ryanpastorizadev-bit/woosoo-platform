---
status: canonical
last_reviewed: 2026-06-01
scope: ecosystem
---

# Contract: WebSocket / Reverb Events (woosoo ecosystem)

**Authoritative map of every broadcast event, its channel, its `broadcastAs` name, its producer,
and its consumers. This mirrors the real implementation in `woosoo-nexus/app/Events/**` (producers)
and the consumers listed below — agents must not invent events, names, or channels, and any change
here must be made against the code in the same change.**

Producers: `woosoo-nexus` (Laravel events implementing `ShouldBroadcast[Now]`).
Consumers: `tablet-ordering-pwa` (`composables/useBroadcasts.ts`), the Nexus admin UI
(`woosoo-nexus/resources/js/pages/**`), and `woosoo-print-bridge` (`lib/services/reverb_service.dart`).

---

## Order identifier rule (canonical)

See `contracts/order-state.contract.md` → **Order identifier (canonical)**. In short:
`krypton_woosoo.orders.id` is the global order reference; in the Nexus DB it is
`device_orders.order_id`. **All channels, payloads, and consumers key on `order_id`** — never the
local `device_orders.id`. The order channel is always `orders.{order_id}`.

---

## Channels

| Channel | Keyed by | Purpose |
|---|---|---|
| `orders.{order_id}` | POS `order_id` | Per-order lifecycle to the owning device (terminal + detail sync) |
| `device.{device_id}` | device PK | Device-targeted updates and control |
| `session.{session_id}` | POS session id | Daily POS cashier-session close |
| `service-requests.{order_id}` | POS `order_id` | Per-order service-request notifications |
| `admin.orders` | — | Admin live order feed + print-bridge print trigger |
| `admin.service-requests` | — | Admin service-request feed |

---

## Events

**Marker legend:** ✅ implemented & consuming · ⏳ planned/blocked (not yet produced or consumed) ·
❌ broadcast but no consumer anywhere · — not applicable.

| `broadcastAs` | Producer event class | Channel(s) | Tablet | Admin UI | Print-bridge | Payload |
|---|---|---|---|---|---|---|
| `order.created` | `Order/OrderCreated` | admin.orders, orders.{order_id}, device.{id} | ✅ orders.{order_id} | ✅ | ✅ admin.orders | `OrderBroadcastPayload` |
| `order.updated` | `Order/OrderStatusUpdated` | device.{id}, orders.{order_id}, admin.orders | ✅ device.{id} | ✅ | ✅ admin.orders | `{order: OrderBroadcastPayload}` |
| `order.details.updated` | `Order/OrderDetailsUpdated` | orders.{order_id}, admin.orders | ✅ orders.{order_id} | ⏳ planned | — | `{order: OrderBroadcastPayload}` |
| `order.completed` | `Order/OrderCompleted` | orders.{order_id}, admin.orders | ✅ orders.{order_id} | ✅ | — | `OrderBroadcastPayload` |
| `order.voided` | `Order/OrderVoided` | orders.{order_id}, admin.orders | ✅ orders.{order_id} | ✅ | — | `OrderBroadcastPayload` |
| `order.cancelled` | `Order/OrderCancelled` | orders.{order_id}, admin.orders | ✅ orders.{order_id} | ✅ | — | minimal order |
| `order.printed` | `Order/OrderPrinted` **+** `PrintOrder` **+** `PrintRefill` ⚠️ | admin.orders (+orders.{order_id} for OrderPrinted) | — | ✅ | ✅ admin.orders | varies per producer |
| `payment.completed` | `Order/PaymentCompleted` | device.{id}, orders.{order_id} | ❌ none | ❌ none | ❌ none | order |
| `session.reset` | `SessionReset` | session.{session_id} | ✅ session.{id} | — | — | `{session_id, version}` |
| `service-request.notification` | `ServiceRequest/ServiceRequestNotification` | service-requests.{order_id}, admin.service-requests | ✅ | ✅ (2 pages) | — | `{service_request}` |
| `device.control` | `AppControlEvent` | device.{id} | ✅ device.{id} | — | — | `{action, payload, deviceId}` |
| `menu.updated` | `Menu/MenuUpdated` | device.{id} | ❌ none | ❌ none | ❌ none | menu |
| `package.updated` | `Menu/PackageUpdated` | device.{id} | ❌ none | ❌ none | ❌ none | package |
| `table-service` | `TableService` | service-requests | ❌ none | ❌ none | ❌ none | service |

`OrderBroadcastPayload` = `woosoo-nexus/app/Helpers/OrderBroadcastPayload.php` (carries `order_id`,
`status`, `guest_count`, `subtotal`/`tax`/`discount`/`total`, `items`, `table`, …).

---

## Terminal-status → tablet session lifecycle

`order.completed` / `order.voided` / `order.cancelled` on `orders.{order_id}` (and `order.updated`
with a terminal status on `device.{id}`) → the tablet's id-guarded handler
(`currentOrderId === eventOrderId`) calls `triggerSessionEnd()` → `sessionStore.end()` (clears
order/session, mutex-guarded, idempotent via `SessionEnd.startTransition`) → routes to
`/order/session-ended` → returns to welcome for the next guest. **Per-order** terminal events reset
**one** tablet; **`session.reset`** (daily POS close) resets every tablet on that session.

---

## Event — `order.details.updated` (POS→device live sync)

Dispatched when the POS edits an existing order's details under `krypton_woosoo.orders.id`
(guest_count, totals, items; incl. `order_checks`). See `docs/cases/nex-case-013-*` (producer) and
`docs/cases/tab-case-010-*` (consumer).
- Class: `App\Events\Order\OrderDetailsUpdated implements ShouldBroadcastNow`
- `broadcastOn`: `Channel('orders.'.$order->order_id)`, `Channel('admin.orders')`
- `broadcastAs`: `order.details.updated`
- `broadcastWith`: `['order' => OrderBroadcastPayload::make($order)]`
- Tablet: updates displayed order details from the payload (read-only; **never recomputes pricing**).

---

## Broadcast architecture (shipped via NEX-CASE-013)

> **Status: IN PROGRESS — infrastructure exists, dispatch-site migration pending.**
> `OrderBroadcaster.php` and `BroadcastEvent.php` exist in `app/Broadcasting/`. The 5 legacy
> dispatch sites (`ConsumePosPaymentStatusEvents`, `ForceEndSession`, `MonitoringController`,
> `OrderController`, etc.) have **NOT** been migrated to route through `OrderBroadcaster` — that is
> a tracked non-blocking follow-up from NEX-CASE-013. Until migration is complete, the "single
> boundary" below describes the **target**, not the current enforced state. Shared consumer
> constants (`events.ts` / `events.dart`) also remain a future hardening item.

To keep events accurate and easy to change as consumers grow (Kitchen Display System next), the
**target** is that all order broadcasts route through **one boundary** instead of being dispatched
from multiple sites.

1. **Single broadcaster** — `app/Broadcasting/OrderBroadcaster.php` with intent methods
   (`created`, `statusChanged`, `detailsUpdated`, `finalized`, `printRequested`). It is the ONLY
   place that resolves the canonical **`order_id`**, builds the payload (`OrderBroadcastPayload`),
   selects channels, and fires events. Domain code states *what changed*; the broadcaster owns
   *who is notified and how*.
2. **Event registry** — `app/Broadcasting/BroadcastEvent.php` (enum): each case owns its
   `broadcastAs` name + channels + payload type. No free-string event names scattered across event
   classes. Mirrored to a **shared constants module** imported by every consumer
   (`events.ts` / `events.dart`) so names can't drift (e.g. `in_progress` vs `preparing`).
3. **Standard envelope** — `{ event, version, order_id, occurred_at, data }`; `order_id` always
   POS; `version` lets `data` evolve without breaking older consumers.
4. **Channels stay flat (on-prem, single branch/station)** — no per-branch/per-station channel
   sprawl. Customer device = `orders.{order_id}`; everything operational (admin + **KDS** +
   print-bridge) shares `admin.orders`.

### Kitchen Display System (KDS) consumer
On-premise, **single branch, single station (the kitchen)**. The KDS subscribes to **`admin.orders`**
and renders all orders in the current POS session — no new channel needed. It consumes (via the
shared constants): `order.created`, `order.status.changed`, `order.details.updated`,
`order.cancelled`/`order.voided`. Accuracy comes from every event flowing through the single
broadcaster + canonical payload, keyed on `order_id`.

### Event-name de-collision (planned)
The registry assigns the three print producers distinct names — `order.print.requested`
(initial), `order.print.refill`, `order.print.acked` — replacing the shared `order.printed`. This
is cross-app (touches print-bridge + admin consumers), so it is phased and tracked with NEX-CASE-011.

## Known issues (tracked; do not "fix" silently)

- **`order.printed` name collision.** Three distinct events (`OrderPrinted`, `PrintOrder`,
  `PrintRefill`) all broadcast `order.printed` on `admin.orders`. **Partially resolved:** NEX-CASE-011
  PR #163 (merged 2026-06-04) removed the spurious `PrintOrder::dispatch()` calls from all ack
  paths and added `is_printed` idempotency in `OrderApiController`. The event-name de-collision
  (renaming to `order.print.requested` / `order.print.refill` / `order.print.acked`) remains
  planned but not yet implemented — tracked in the Event-name de-collision section above.
- **Dead consumer.** Admin `Orders/Index.vue` subscribes `admin.print` → `.order.printed`, but no
  producer broadcasts on `admin.print` (all go to `admin.orders`). Minor nexus cleanup.
- **Dead producers (no consumer anywhere):** `payment.completed`, `menu.updated`,
  `package.updated`, `table-service`. Classification pending (wire a consumer vs stop emitting).
- **`preparing` vs `in_progress`.** The tablet keys a kitchen toast on `preparing`; the enum value
  is `in_progress`. Cosmetic; fixed alongside **tab-case-010**.

---

## Scalability & concurrency (target: 15–20 tablets, single on-prem branch)

Load profile: ~25 persistent WS connections (≤20 tablets + admin + KDS + print-bridge), ~80 channel
subscriptions, human-paced event rate, peak ≈ 20 near-simultaneous submits at seating. This is
**well within single-node Reverb** (`REVERB_SCALING_ENABLED=false`). Requirements to keep it so:

1. **Per-order scoping is the scalability property — preserve it.** Terminal/detail events go to
   `orders.{order_id}` (fan-out = 1 tablet), never a global broadcast. `admin.orders` is the only
   fan-in (admin + KDS + print-bridge); keep its consumers tolerant of all order events.
2. **Broadcaster payloads must be cheap.** Build `OrderBroadcastPayload` with eager-loaded relations
   (no N+1 per broadcast) and keep each payload **< `REVERB_MAX_REQUEST_SIZE` (10 KB)** — bound the
   `items` array. The single `OrderBroadcaster` is per-request (not a global lock); it does not
   serialize concurrent submits.
3. **Consumers: single-worker + idempotent.** Every POS outbox consumer runs `everyFiveSeconds` +
   `withoutOverlapping(3)` with an indexed outbox and a `whereNull(processed_at)` claim — mirrors
   `pos:consume-payment-status-events`. A poll fallback runs `everyMinute()->withoutOverlapping()`.
4. **Submit concurrency.** ~20 simultaneous submits rely on `client_submission_id` idempotency +
   `DurableRefillGuard`; ensure POS + local DB connection sizing is not the serialization point.
5. **Liveness at scale.** With 20 tablets, a silently-dead socket (zombie) is materially more likely
   and is customer-facing (stuck tablet). **TAB-CASE-009** (WS silent-death detector) is a
   scalability-reliability prerequisite for the 20-tablet target, not optional polish.
6. **Pi resource budget.** Reverb + 5s scheduler consumers + PHP-FPM + MySQL + Redis + Pulse share
   one Pi; keep consumers lean and retain the existing `scheduler-memory-monitor`.

**Growth path (not needed at this scale):** beyond ~100 connections or multi-branch, set
`REVERB_SCALING_ENABLED=true` (Redis pub/sub — already wired) and move order broadcasts to queued
`ShouldBroadcast` + a dedicated worker.

## Rules

- Channels, payloads, and consumers key on `order_id` (POS), never local `device_orders.id`.
- One `broadcastAs` name = one producer event (no name overloading — see the `order.printed` issue).
- The tablet renders POS-authoritative order details; it never sends or recomputes state/pricing.
- Adding/renaming an event or channel is a contract change — update this file **and** the code, and
  re-verify every listed consumer.
