---
status: canonical
last_reviewed: 2026-06-06
scope: woosoo-nexus
---

# CASE: nex-case-015-tablet-intent-payload-hardening

## Run State
- task_slug: nex-case-015-tablet-intent-payload-hardening
- tier: 2
- branch: agent/nex-case-015-tablet-intent-payload-hardening
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
- Exact next action: Contrarian to scope the fix — does `StoreDeviceOrderRequest` need explicit rejection rules, or is stripping extra fields in the FormRequest sufficient?
- Working-tree state: no edits made.
- Risks / do-not-redo: Do not change the intent-only payload fields (`guest_count`, `package_id`, `items`). Do not touch POS pricing or recalculation logic — that stays server-authoritative regardless.

## Tier
2 — backend validation correctness. No order/print/payment logic; enforces an existing contract property.

## Branch
agent/nex-case-015-tablet-intent-payload-hardening (off `dev`)

## Problem

`StoreDeviceOrderRequest` (`app/Http/Requests/StoreDeviceOrderRequest.php`) currently accepts
client-submitted pricing, discount, and modifier fields (`totals`, `prices`, `discounts`,
`ordered_menu_id`, modifier fields) without rejecting them. The tablet intent-only contract
(`contracts/tablet-api.contract.md`) requires the backend to explicitly reject or strip these
fields. Passive acceptance — even when the backend recalculates server-side — is not sufficient
contract enforcement.

**Contract reference:** `contracts/tablet-api.contract.md` — Backend enforcement gap (NEX-CASE-015).

## Success Criterion
`StoreDeviceOrderRequest` explicitly rejects (400/422) or strips any field outside
`{ guest_count, package_id, items: [{ menu_id, quantity }] }` on the tablet order-submission
route. Verified by a feature test sending a payload with extra pricing/modifier fields and
asserting the extra fields are absent from the persisted `device_orders` row.
