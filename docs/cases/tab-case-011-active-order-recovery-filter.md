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
- status: IN_PROGRESS
- last_completed_agent: none
- next_agent: contrarian
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-06

## Handoff
- Phase in progress: none — queued, not started.
- Done so far: Case registered from dev-branch audit (2026-06-06). Backlog entry in `state/QUEUE.md` (Bucket B-follow).
- Exact next action: Contrarian to confirm the active scope mismatch against `DeviceOrder::scopeActiveOrder()` and scope the fix to `stores/Order.ts` only.
- Working-tree state: no edits made.
- Risks / do-not-redo: Do not invent new order states. Do not change the Nexus active scope — match it, do not redefine it.

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
