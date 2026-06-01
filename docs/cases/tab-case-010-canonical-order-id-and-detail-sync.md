---
status: canonical
last_reviewed: 2026-06-01
scope: tablet-ordering-pwa
---

# CASE: tab-case-010-canonical-order-id-and-detail-sync

Make the tablet use the canonical POS `order_id` consistently, and consume the new
`order.details.updated` event so the displayed order reflects live POS changes (added guest,
new totals, item edits).

## Run State
- task_slug: tab-case-010-canonical-order-id-and-detail-sync
- tier: 3
- branch: agent/tab-case-010-canonical-order-id-and-detail-sync
- status: BLOCKED
- last_completed_agent: contrarian
- next_agent: specialist:chuya-frontend
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-01

## Handoff
- Phase in progress: Contrarian + design complete (plan approved 2026-06-01). BLOCKED on nex-case-013.
- Done so far: identifier inconsistency confirmed in `useBroadcasts.ts` / `orderHelpers.ts`.
- Exact next action: when nex-case-013's DEP is `confirmed` in `state/DEPS.md`, implement the Fix below.
- Working-tree state: none yet (design only).
- Risks / do-not-redo: blocked until the nexus `order.details.updated` event exists. Hard rule: the
  tablet renders POS-authoritative details; it must NEVER recompute pricing/tax/totals.

## Tier
3 — real-time order correctness; consumes a new cross-app event.

## Branch
agent/tab-case-010-canonical-order-id-and-detail-sync

## Problem
1. **Identifier inconsistency:** `handleOrderCreated` stores the **local** id
   (`sessionStore.setOrderId(event.order.id)`), and `extractOrderId` (`utils/orderHelpers.ts`)
   falls back to `id`. Channels are `orders.{order_id}` (POS). When they differ, the tablet
   subscribes to the wrong channel and misses terminal/detail events → stuck session.
2. **No live detail refresh:** when the POS changes the order, the tablet's displayed
   guest_count/totals/items go stale.

## Proposed Fix (decisions confirmed in approved plan)
1. **Canonicalize on `order_id`:**
   - `handleOrderCreated` → `sessionStore.setOrderId(event.order.order_id)` (not `.id`).
   - `extractOrderId` → resolve `order_id` only (drop the `… ?? response.order?.id ?? response.id`
     local-id fallbacks for the canonical reference).
   - Ensure `orderStore.serverOrderId`, the channel auto-subscription, and the match guard
     (`String(currentOrderId) === String(eventOrderId)`) are all the POS `order_id`.
2. **New handler:** subscribe `orders.{order_id}` `.order.details.updated` in `useBroadcasts.ts`
   (alongside the existing `.order.completed/.voided/.cancelled`) → update the order store's
   displayed details from `event.order` (guest_count, subtotal/tax/discount/total, items). Render
   only; **no pricing recompute**.
3. **Companion fix (same file):** the kitchen toast keys on `"preparing"` but the backend enum value
   is `in_progress` (`useBroadcasts.ts:73` type + `:229` `statusMessages`). Align to `in_progress`.
4. Repoint the `useBroadcasts.ts:17` doc comment from `docs/websocket-events.md` to
   `contracts/websocket-events.contract.md`.

## Critical Files
- `composables/useBroadcasts.ts` (id usage, new handler, preparing→in_progress, doc-comment repoint)
- `utils/orderHelpers.ts` (`extractOrderId` canonicalization)
- `stores/Order.ts` (`serverOrderId`, set-from-response), `stores/Session.ts` (`setOrderId`/`getOrderId`)

## Verification
- Unit test: receiving `.order.details.updated` updates store guest_count/total and the UI re-renders
  the POS values (no client recompute).
- Regression Lock: channel subscription + match guard use `order_id`; a terminal event whose
  `order_id` ≠ local `id` still triggers session end (the bug this fixes).
- `preparing`→`in_progress` toast fires on a kitchen-progress update.
- `.\scripts\pre-merge-check.ps1 -App tablet-ordering-pwa` exit 0 (typecheck/lint/test/build).

## Dependency
**Blocked on nex-case-013** (`order.details.updated` event). Proceed only when the DEP is `confirmed`
in `state/DEPS.md`.

## Executioner Verdict
<!-- pending -->

## Remaining Risks
- Switching `setOrderId` to `order_id` must be safe across the create→terminal lifecycle — verify
  `order.created` always carries a populated `order_id` (coordinate with nex-case-013, since
  `device_orders.order_id` is set from the POS mirror and is nullable until then).
