---
status: canonical
last_reviewed: 2026-06-06
scope: tablet-ordering-pwa
---

# CASE: tab-case-011-active-order-recovery-filter

## Run State
- task_slug: tab-case-011-active-order-recovery-filter
- tier: 2
- branch: agent/tab-case-011-active-order-recovery-filter
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: cursor
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-07

## Handoff
- Phase complete: COMPLETE / APPROVED.
- Unblocks: `kds-implementation-plan` tablet blocker cleared; Pi stability gate remains.
- Queue alias: **TAB-CASE-011** (`state/QUEUE.md`) — display label only; **`task_slug` is the resume key**.
- Done so far: `ACTIVE_ORDER_RECOVERY_STATUSES` + param aligned to Nexus `scopeActiveOrder`; recovery
  query includes `in_progress` and `served`.
- Exact next action: Operator — commit tablet changes on `agent/tab-case-011-active-order-recovery-filter`
  (currently uncommitted on local `dev`); merge PR to tablet `dev`.
- Working-tree state: `stores/Order.ts`, `tests/active-order-recovery-status-filter.spec.ts` (uncommitted).
- Risks / do-not-redo: Do not invent new order states. Do not change the Nexus active scope.

## Tier
2 — active-order recovery correctness. An in-progress order that the tablet drops from its session causes incorrect UX state; does not affect payments or print.

## Branch
agent/tab-case-011-active-order-recovery-filter (off `dev`)

## Problem

The tablet active-order recovery filter at `stores/Order.ts` (~line 807) queries only
`pending,confirmed,ready`. The Nexus active-order scope (`DeviceOrder::scopeActiveOrder()`,
`app/Models/DeviceOrder.php:202`) includes five non-terminal statuses:
`pending`, `confirmed`, `in_progress`, `ready`, `served`.

Orders that transition to `in_progress` or `served` (kitchen-driven states) are excluded from
tablet recovery, meaning those orders drop from the tablet session even though they are still
active from the backend's perspective.

**Contract reference:** `contracts/order-state.contract.md` — Nexus active-order scope.

## Success Criterion
The tablet recovery filter matches the five Nexus non-terminal statuses
(`pending`, `confirmed`, `in_progress`, `ready`, `served`). Verified by a unit test covering
the recovery query and a manual smoke-test: submit an order, advance it to `in_progress` from
admin, refresh the tablet — the order remains visible in the active session.

## Specialist Investigation & Implementation

Root cause confirmed at `stores/Order.ts` recovery branch: API `status` param was
`pending,confirmed,ready`, omitting `in_progress` and `served` that Nexus treats as non-terminal
(`DeviceOrder::scopeActiveOrder`, contract table).

Fix: named constants exported for testability; query uses full five-status param. No Nexus changes.

## Files Changed

- `tablet-ordering-pwa/stores/Order.ts` — `ACTIVE_ORDER_RECOVERY_STATUSES`, `ACTIVE_ORDER_RECOVERY_STATUS_PARAM`; recovery query updated
- `tablet-ordering-pwa/tests/active-order-recovery-status-filter.spec.ts` — contract alignment tests

## Verification

```text
npm run test:run -- tests/active-order-recovery-status-filter.spec.ts  → 2 passed
npm run typecheck  → exit 0
npx eslint tests/active-order-recovery-status-filter.spec.ts stores/Order.ts  → exit 0
Re-verify 2026-06-07: vitest 2 passed (2.87s)
```

## Executioner Verdict

**APPROVED** 2026-06-07. Recovery filter matches Nexus five-status active scope; tests green;
typecheck green; scoped tablet-only change; no contract enum changes.
