---
status: canonical
last_reviewed: 2026-06-01
scope: woosoo-nexus
---

# CASE: nex-case-013-pos-order-detail-sync

Canonicalize the order identifier on `order_id` and add a POS→device live order-detail sync:
when the POS edits an order (guest_count, totals, items, `order_checks`) under
`krypton_woosoo.orders.id`, broadcast `order.details.updated` to the device on `orders.{order_id}`.

## Run State
- task_slug: nex-case-013-pos-order-detail-sync
- tier: 3
- branch: agent/nex-case-013-pos-order-detail-sync
- status: IN_PROGRESS
- last_completed_agent: contrarian
- next_agent: specialist:ranpo-backend
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-01

## Handoff
- Phase in progress: Contrarian + design complete (plan approved 2026-06-01). Ready for ranpo-backend.
- Done so far: identifier inconsistency root-caused; reuse path (NEX-CASE-007 trigger/outbox/consumer
  + `OrderBroadcastPayload`) identified; event shape decided.
- Exact next action: implement Parts below on `agent/nex-case-013-…`. **First confirm the POS columns**
  that hold guest_count and per-check totals (`orders` vs `order_checks`) — drives the trigger.
- Working-tree state: none yet (design only).
- Risks / do-not-redo: Tier 3 — POS DB trigger + order broadcasts. Reference `contracts/pos-db.contract.md`,
  `contracts/order-state.contract.md`, `contracts/websocket-events.contract.md`. Escalate Specialist to opus
  (POS DB writes + broadcast). Do NOT overload `order.updated`/`order.printed` — use a new distinct event.

## Tier
3 — POS DB trigger install, order broadcasts, cross-app contract.

## Branch
agent/nex-case-013-pos-order-detail-sync

## Problem
1. **Identifier:** the order reference must be `krypton_woosoo.orders.id` (= `device_orders.order_id`)
   everywhere; confirm Nexus never broadcasts/keys on local `device_orders.id`.
2. **Missing sync:** POS-side order edits (extra guest → totals/tax change; item changes;
   `order_checks`) do not reach the tablet. The displayed order goes stale.

## Proposed Fix (decisions confirmed in approved plan 2026-06-01)
**Reuse, do not reinvent:** `SetupPosOrderPaymentTrigger`, `ConsumePosPaymentStatusEvents`,
`SyncPosOrderPaymentStatus`, `PosOrderStatusFinalizer`, `App\Helpers\OrderBroadcastPayload`.

### Phase 1 — Broadcast layer (foundation; no behavior change)
Per `contracts/websocket-events.contract.md` → Target architecture. Adopt the **full layer**:
- `app/Broadcasting/OrderBroadcaster.php` — the single boundary for order broadcasts (intent
  methods: `created`, `statusChanged`, `detailsUpdated`, `finalized`, `printRequested`). Resolves
  canonical `order_id`, builds `OrderBroadcastPayload`, selects channels, fires registry events.
- `app/Broadcasting/BroadcastEvent.php` (enum registry) — owns every `broadcastAs` name + channels;
  mirror to a shared `events.ts`/`events.dart` constants module for consumers.
- Standard envelope `{ event, version, order_id, occurred_at, data }`.
- **Migrate the 4 scattered dispatch sites behind the broadcaster** (`ConsumePosPaymentStatusEvents`,
  `ForceEndSession`, `MonitoringController`, `OrderController`) — pure refactor, events unchanged.
- Channels stay flat (on-prem, single branch/station): device = `orders.{order_id}`; admin + **KDS**
  + print-bridge share `admin.orders`. (KDS is a future consumer; reserve nothing new.)
- De-collision of `order.printed` (→ `order.print.requested`/`.refill`/`.acked`) is cross-app
  (print-bridge + admin) → phase separately under NEX-CASE-011; the registry defines the names.

### Phase 2 — POS detail sync (builds on Phase 1)
1. **ID:** all order channels at `orders.{order_id}`; `order_id` is the canonical payload key.
2. **Detection — trigger + outbox (+ poll fallback):** extend `SetupPosOrderPaymentTrigger` with a
   POS `AFTER UPDATE` trigger on `orders` (detail columns) and `order_checks` → new outbox table
   `woosoo_order_detail_outbox` (keyed `pos_order_id`, upsert, `attempts`/`processed_at`/`failed_at`,
   consume index — mirror the existing outbox schema). Add a poll branch in
   `SyncPosOrderPaymentStatus` (or sibling `pos:sync-order-details`) as completeness backstop.
3. **Consumer:** new `pos:consume-order-detail-events` (mirror `ConsumePosPaymentStatusEvents`:
   scheduled, `withoutOverlapping`, atomic claim of outbox rows). For each: reload the matching
   `device_order`'s POS-derived details (guest_count, totals, items) and dispatch the new event.
4. **Event:** `App\Events\Order\OrderDetailsUpdated implements ShouldBroadcastNow`; `broadcastOn` =
   `Channel('orders.'.$order->order_id)` + `Channel('admin.orders')`; `broadcastAs` =
   `order.details.updated`; `broadcastWith` = `['order' => OrderBroadcastPayload::make($order)]`.
5. **Schedule** the consumer in `routes/console.php`.

## Critical Files
- `app/Console/Commands/SetupPosOrderPaymentTrigger.php` (add detail trigger + outbox table)
- new `app/Console/Commands/ConsumePosOrderDetailEvents.php`
- `app/Console/Commands/SyncPosOrderPaymentStatus.php` (poll fallback)
- new `app/Events/Order/OrderDetailsUpdated.php`
- `app/Helpers/OrderBroadcastPayload.php` (reuse; extend only if a needed field is missing)
- new migration for `woosoo_order_detail_outbox` (POS connection)
- `routes/console.php` (schedule)

## Verification
- Feature test: simulated POS `orders`/`order_checks` UPDATE (guest_count/total) → outbox row →
  consumer dispatches `order.details.updated` on `orders.{order_id}` with refreshed totals
  (`Event::fake`). Idempotency: re-processing a row is a no-op.
- `.\scripts\pre-merge-check.ps1 -App woosoo-nexus` exit 0.
- Deploy step (Bucket B): re-run `php artisan pos:setup-payment-trigger` on the Pi to install the
  new trigger/table; confirm `pos:consume-order-detail-events` is scheduled.

## Dependency
Provides the `order.details.updated` event consumed by **tab-case-010**. Register a DEP
(provider: woosoo-nexus) in `state/DEPS.md`; tab-case-010 stays blocked until it is `confirmed`.

## Scalability (target: 15–20 tablets, single on-prem branch)
Per `contracts/websocket-events.contract.md` → Scalability & concurrency. Non-negotiables for this case:
- **Consumer** mirrors `pos:consume-payment-status-events`: `everyFiveSeconds` + `withoutOverlapping(3)`,
  indexed `woosoo_order_detail_outbox`, `whereNull(processed_at)` claim, idempotent re-process. Poll
  fallback `everyMinute()->withoutOverlapping()`. One tick drains ≈20 active orders trivially.
- **OrderBroadcaster** builds `OrderBroadcastPayload` with eager-loaded relations (no N+1 per
  broadcast); keep each payload **< `REVERB_MAX_REQUEST_SIZE` (10 KB)** — bound the items array.
- Fan-out stays 1 (event → `orders.{order_id}`); `admin.orders` is the only fan-in (admin/KDS/print-bridge).
- Single-node Reverb is sufficient (~25 conns). Growth lever (documented, not now):
  `REVERB_SCALING_ENABLED=true` + Redis + queued broadcasts.
- **Dependency note:** the 20-tablet reliability target also needs **TAB-CASE-009** (WS silent-death
  detector) — a zombie socket at one of 20 tables is customer-facing.

## Executioner Verdict
<!-- pending -->

## Remaining Risks
- POS column discovery (guest_count/total location) must be confirmed before writing the trigger.
- Trigger volume: ensure the trigger condition is narrow (only meaningful detail changes) to avoid
  outbox churn on every POS row touch.
