---
status: canonical
last_reviewed: 2026-05-18
scope: tablet-ordering-pwa
---

# CASE: tab-case-002-validated-review-followups

Validated follow-up work from a fact-checked review of tablet-ordering-pwa.

## Run State
- task_slug: tab-case-002-validated-review-followups
- tier: 2
- branch: agent/tab-case-002-validated-review-followups
- status: IN_PROGRESS
- last_completed_agent: contrarian
- next_agent: specialist:chuya-frontend
- active_runner: copilot
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-18

## Handoff
- Phase in progress:
- Done so far:
- Exact next action:
- Working-tree state (list edited files explicitly; cross-check with `git status`):
- Risks / do-not-redo:

## Tier
2

## Branch
agent/tab-case-002-validated-review-followups

## Problem

User submitted a broad tablet-ordering-pwa review. A read-only validation found multiple claims were overstated, but several medium/high issues remain and should be handled as concrete follow-up work.

## Contrarian Review

Proceed as Tier 2, single-app task in `tablet-ordering-pwa/**`. This case tracks implementation-ready follow-ups from validated findings, not the unconfirmed critical claims.

## Investigation

Validated high/medium findings to carry forward:
- Offline queue de-duplication gap (`composables/useOfflineOrderQueue.ts`).
- WebSocket reconnection behavior and long total backoff window (`composables/useBroadcasts.ts`).
- Excessive `any` usage in real-time and order-flow paths (`composables/useBroadcasts.ts`, `stores/Order.ts`).
- Cross-store coupling risk (`stores/Order.ts`, `stores/Session.ts`).
- PIN modal accessibility semantics gap (`pages/index.vue`).
- Potential technical detail propagation in some error paths (`stores/Order.ts`).
- Optional fetch cancellation hardening opportunity in menu fetch flow (`stores/Menu.ts`).

Explicitly not carried forward as confirmed defects:
- Missing await on `sessionStore.end()`.
- SSR localStorage guard absence.
- Refill validation happening after API call.

## Proposed Fix

1. Add deterministic offline queue dedup/idempotency checks for duplicate enqueue paths.
2. Reassess reconnection strategy limits and post-reconnect recovery behavior.
3. Reduce unsafe `any` usage in critical real-time/order state paths.
4. Introduce safer boundaries to reduce circular store coupling where practical.
5. Improve PIN modal accessibility semantics and announcement behavior.
6. Harden customer-safe error messaging paths.
7. Evaluate fetch cancellation support for menu loading flows.

## Files Changed

- None yet (case created from intake/triage).

## Verification

Required before closure:
- `npm run typecheck`
- `npm run lint`
- `npm run test`
- `npm run build`
- `npm run generate`

## Specialist Handoff

Specialist should implement only validated findings in this case and keep scope within `tablet-ordering-pwa/**`.

## Executioner Verdict

Pending.

## Remaining Risks

- Scope creep into previously unconfirmed claims.
- Reconnection behavior changes affecting perceived real-time responsiveness.
- State-store decoupling changes introducing regressions if done without targeted tests.
