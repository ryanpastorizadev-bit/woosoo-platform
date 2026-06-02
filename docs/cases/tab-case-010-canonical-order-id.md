---
status: canonical
last_reviewed: 2026-06-01
scope: tablet-ordering-pwa
---

# CASE: tab-case-010-canonical-order-id

Adopt the canonical POS `order_id` on the tablet: fix `handleOrderCreated` to store `order_id`
(not local `id`), add the `order.details.updated` listener, add `applyDetailsUpdate` to the order
store, and fix the `preparing`→`in_progress` toast.

## Run State
- task_slug: tab-case-010-canonical-order-id
- tier: 3
- branch: agent/tab-case-010-canonical-order-id
- status: IN_PROGRESS
- last_completed_agent: contrarian
- next_agent: specialist:chuya-frontend
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-01

## Handoff
- Phase in progress: Contrarian complete. Ready for chuya-frontend.
- Done so far: All 4 gaps confirmed via code inspection. Contrarian triage complete.
- Exact next action: chuya-frontend implements 4 changes in 2 files. Branch off current
  tablet-ordering-pwa `dev` (or `staging` — check which is ahead). Create the branch first.
- Working-tree state: none yet (design only).
- Risks / do-not-redo:
  - Do NOT change `extractOrderId` in `utils/orderHelpers.ts` — already correct.
  - `applyDetailsUpdate` must NEVER touch order status fields — display-only merge.
  - `order_id` null guard in `handleOrderCreated`: use `event.order.order_id ?? event.order.id`
    as a defensive fallback (backend guarantees non-null, but guard anyway).
  - `"preparing"` fix at line 224 — confirm it only affects the kitchen toast map, not any
    other comparison or handler in the file.

## Tier
3 — real-time channel subscription + Pinia state + broadcast handler.

## Branch
agent/tab-case-010-canonical-order-id

## Problem
1. `handleOrderCreated` (useBroadcasts.ts:215) stores `event.order.id` (local PK) instead of
   `event.order.order_id` (canonical POS id). The session store's `orderId` is used to build
   the channel subscription key and match incoming events — using the wrong id means the tablet
   may subscribe to `orders.null` or the wrong channel.
2. No `order.details.updated` listener exists in `subscribeToOrderChannel()` (lines 462–487).
   DEP-004 is now confirmed — nexus ships this event; tablet must consume it.
3. `stores/Order.ts` has no `applyDetailsUpdate` action. The store can update status
   (`updateOrderStatus`) but cannot merge POS-authoritative detail fields.
4. Kitchen toast notification map keys on `"preparing"` (useBroadcasts.ts:224) but the
   `OrderStatus` enum value is `"in_progress"`. The toast never fires.

## Contrarian Review
- **Tier:** 3 — touches real-time channel subscription and Pinia state.
- **Specialist:** chuya-frontend. Scope: `tablet-ordering-pwa/**`.
- **Candidate skills:** `agent-sequence`, `nuxt-pwa-flow`, `pinia-state-audit`, `test-verification`,
  `dead-code-cleanup`.
- **Cross-app dependency:** DEP-004 is `confirmed` (NEX-CASE-013 APPROVED 2026-06-01).
- **Not a duplicate:** TAB-CASE-001/002 reworked reconnection; TAB-CASE-009 added the watchdog.
  This is the first handler for `order.details.updated` and the first id-canonicalization fix.
- **Scope confirmed:** 4 targeted changes across 2 files. `extractOrderId` already correct — no change.
- **Recommendation:** Proceed.

## Investigation
Verified 2026-06-01 via code inspection:
- `useBroadcasts.ts:215` — `sessionStore.setOrderId(event.order.id)` uses local PK.
- `useBroadcasts.ts:462–487` — `subscribeToOrderChannel()` has no `order.details.updated` listener.
- `useBroadcasts.ts:224` — notification map: `"preparing": "..."` should be `"in_progress"`.
- `stores/Order.ts:1093` — `updateOrderStatus()` updates status only; no detail-merge action.
- `utils/orderHelpers.ts` — `extractOrderId` already prioritizes `order_id` correctly. No change needed.
- `OrderBroadcastPayload` (nexus) — always includes `order_id` (non-null for POS-backed orders).

## Root Cause
The tablet was written before the canonical-id standard was codified. The `OrderCreated` event
originally keyed on the local `id` field. The `order.details.updated` event didn't exist until
NEX-CASE-013. The `"preparing"` string was never aligned to the enum.

## Proposed Fix

### Change 1 — `composables/useBroadcasts.ts` line 215
```ts
// Before:
sessionStore.setOrderId(event.order.id)
// After:
sessionStore.setOrderId(event.order.order_id ?? event.order.id)
```
Null guard retained for defensive coding; backend guarantees `order_id` non-null for POS orders.

### Change 2 — `composables/useBroadcasts.ts` `subscribeToOrderChannel()`
Add after existing listeners:
```ts
channel.listen('.order.details.updated', (event: OrderDetailsUpdatedEvent) => {
  orderStore.applyDetailsUpdate(event.order)
})
```
Add the `OrderDetailsUpdatedEvent` interface near the top of the file alongside the other event
interfaces (mirror the shape of `OrderBroadcastPayload`):
```ts
interface OrderDetailsUpdatedEvent {
  order: {
    order_id: string | null
    guest_count: number | null
    subtotal: number | null
    tax: number | null
    discount: number | null
    total: number | null
    items: OrderItem[]
    // other payload fields from OrderBroadcastPayload
  }
}
```

### Change 3 — `stores/Order.ts` — new `applyDetailsUpdate` action
```ts
applyDetailsUpdate(payload: Partial<OrderBroadcastPayload>): void {
  if (!this.currentOrder) return
  // Display-only merge — NEVER recompute pricing or mutate status
  if (payload.guest_count !== undefined) this.currentOrder.guest_count = payload.guest_count
  if (payload.subtotal !== undefined) this.currentOrder.subtotal = payload.subtotal
  if (payload.tax !== undefined) this.currentOrder.tax = payload.tax
  if (payload.discount !== undefined) this.currentOrder.discount = payload.discount
  if (payload.total !== undefined) this.currentOrder.total = payload.total
  if (payload.items !== undefined) this.currentOrder.items = payload.items
}
```

### Change 4 — `composables/useBroadcasts.ts` line 224 toast fix
```ts
// Before:
'preparing': 'Your order is being prepared'
// After:
'in_progress': 'Your order is being prepared'
```
Confirm no other place in the file uses `"preparing"` as a comparison (it may also appear in the
`OrderUpdatedEvent` interface as a type union — that is a type annotation, not a runtime key, so
it can stay).

## Files Changed
(to be filled by specialist)

## Verification
```bash
cd /path/to/tablet-ordering-pwa
npm run typecheck
npm run lint
npm run test -- --run
```
Regression-lock tests (new):
- `order.details.updated` received → `applyDetailsUpdate` called → `currentOrder.guest_count` updated
- `applyDetailsUpdate` does NOT change `currentOrder.status`
- `handleOrderCreated` calls `setOrderId(order_id)` not `setOrderId(id)`
- `in_progress` toast fires on matching status event

## Executioner Verdict
<!-- pending -->

## Remaining Risks
- `order_id` null in the wild (non-POS orders): null guard handles this.
- Items array merging: if `items` is an empty array vs `undefined`, must not wipe items display.
  Specialist should guard `if (payload.items !== undefined && payload.items.length >= 0)`.
