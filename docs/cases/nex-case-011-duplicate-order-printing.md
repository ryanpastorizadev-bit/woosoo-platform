---
status: canonical
last_reviewed: 2026-05-30
scope: woosoo-nexus
---

# CASE: nex-case-011-duplicate-order-printing

Client reports submitted orders printing on BOTH the Bluetooth printer and the 3rd-party POS
printer. Investigate from the Nexus side — duplication may originate before the print bridge.
(GitHub Issue: tech-artificer/woosoo-nexus #140 — bug, investigation, printing.)

## Run State
- task_slug: nex-case-011-duplicate-order-printing
- tier: 3
- branch: agent/nex-case-011-duplicate-order-printing
- status: IN_PROGRESS
- last_completed_agent: none
- next_agent: contrarian
- active_runner: none
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-30

## Handoff
- Phase in progress: triage only — registered from GH #140 during Phase 0 reconciliation
- Done so far: case stub created; classified Tier 3 (printer duplicate prevention is high-risk per AGENTS.md)
- Exact next action: Contrarian — run JOINT with NEX-CASE-005. Determine whether duplication is
  (a) duplicate EVENTS (idempotency: missing `client_submission_id` → repeated print-event /
  `ordered_menu` inserts) or (b) dual ROUTING (both BT and POS print routes enabled by config).
- Working-tree state: none yet (no code touched)
- Risks / do-not-redo: do not "fix" by disabling a route blindly — confirm intended print mode first

## Tier
3

## Branch
agent/nex-case-011-duplicate-order-printing

## Problem
A tablet/customer order is submitted. The order appears to print through the Bluetooth printer
AND the same order also prints through the 3rd-party POS printer. Expected: only the intended
print route executes (BT-only, POS-only, explicit dual-print only if configured, or disabled).

Strong hypothesis: shared root cause with **NEX-CASE-005** (legacy non-idempotent print path —
`client_submission_id` absent). If the legacy path fires, a retry/double-submit can create two
print events for one order. Investigate the two cases together.

## Contrarian Review
<!-- pending -->

## Investigation
<!-- pending — start: trace order submit → print-event creation → reserve/ack lifecycle; check
     reserve idempotency keyed on client_submission_id; check print-routing config (BT vs POS). -->

## Root Cause
<!-- pending -->

## Proposed Fix
<!-- pending -->

## Files Changed
<!-- pending -->

## Verification
<!-- pending — reproduce duplicate on a test order pre-fix; confirm single print post-fix;
     assert print-event/ordered_menu idempotency under retry (no duplicate inserts). -->

## Executioner Verdict
<!-- pending -->

## Remaining Risks
<!-- pending -->
