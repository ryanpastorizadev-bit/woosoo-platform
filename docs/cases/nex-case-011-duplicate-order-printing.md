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
- status: BLOCKED
- last_completed_agent: contrarian
- next_agent: ops (POS config on Pi) — reclassified to QUEUE Bucket B
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-31 23:25

## Resolution (decision 2026-05-31)
**SPLIT confirmed — no Nexus code change.** `create_ordered_menu` is defined only in the Krypton POS
DB (not in any repo we control); the POS prints autonomously from it. Nexus's BT path is correct and
idempotent. Per user decision, reclassified **Bucket A → Bucket B** as an ops/deploy prerequisite:
**disable the 3rd-party POS printer (or set a no-print flag) in the Krypton/POS config on the Pi** so
only the BT thermal printer prints. This gates the restaurant rollout, NOT the Nexus code merge.

## Handoff
- Phase in progress: Contrarian + read-only Investigation COMPLETE; routed to ops (Bucket B).
- Done so far: root cause proven; intent confirmed (BT-only); SPLIT decided.
- Exact next action (ops, on Pi): confirm live `NEXUS_PRINT_EVENTS_ENABLED`; disable the POS-side
  printer in Krypton/POS config; verify one order → one BT ticket, POS receives order but does not print.
- Working-tree state: none (read-only; no code touched in woosoo-nexus)
- Risks / do-not-redo: do NOT disable the Nexus BT `print_events` path — BT is the INTENDED printer.
  Do NOT skip the POS order mirror (`CreateOrderedMenu`) — the POS needs the order for billing.

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
- **Tier 3 confirmed** (printer duplicate prevention, production-impacting, cross-system).
- **Intent (user-confirmed 2026-05-31):** the **BT thermal printer (via woosoo-print-bridge) only**
  should print. The 3rd-party POS printer firing is the bug.
- **Joint with NEX-CASE-005**, but the two are now distinguished (see Root Cause): 011 = cross-system
  duplication (the reported symptom); 005 = a separate, largely-OBE idempotency residual.
- **Likely verdict: SPLIT_REQUIRED.** The unwanted print is POS-side, not in Nexus app code.

## Investigation (read-only, 2026-05-31)
The initial-order path ([app/Services/Krypton/OrderService.php:150-169](../../woosoo-nexus/app/Services/Krypton/OrderService.php)) does TWO independent things per order:
1. **Mirrors the order into the Krypton POS DB** — `CreateOrderedMenu::run()` →
   [app/Actions/Order/CreateOrderedMenu.php:225](../../woosoo-nexus/app/Actions/Order/CreateOrderedMenu.php)
   executes `CALL create_ordered_menu(...)` (a POS stored procedure). The **POS system prints
   autonomously** when the order row lands. There is **no explicit Nexus "print" call to the POS** —
   grep of `app/Services/Krypton/` and `app/Actions/` found none.
2. **Creates a Nexus `print_events` row** — `PrintTicketService::createInitialPrintEvent()`, gated by
   `config('api.print_events_enabled')` (`NEXUS_PRINT_EVENTS_ENABLED`, [config/api.php:20](../../woosoo-nexus/config/api.php),
   default false). The **woosoo-print-bridge polls this and drives the BT printer**.

Ruled out:
- `PrintOrder` is **not** a printer driver — it broadcasts on `admin.orders` as `order.printed`
  for the admin dashboard ([app/Events/PrintOrder.php:31-84](../../woosoo-nexus/app/Events/PrintOrder.php)).
- **Nexus print-event creation is idempotent.** `createInitialPrintEvent` keys on
  `idempotency_key = "initial:{order.id}:{client_submission_id}"`, checks for an existing row, and
  reuses it ([PrintTicketService.php:17-61](../../woosoo-nexus/app/Services/PrintTicketService.php));
  the column is `unique` ([migration 2026_05_11_000000](../../woosoo-nexus/database/migrations/2026_05_11_000000_add_idempotency_to_print_events_table.php)).
  Same-key retries do NOT create a second BT print. → H2 does not explain the "BT **and** POS" symptom.

## Root Cause
**H1 — structural dual-system printing.** When `NEXUS_PRINT_EVENTS_ENABLED=true`, one order produces:
(a) a `print_events` row → **BT printer** (intended), AND (b) a POS-DB insert via `create_ordered_menu`
→ the **3rd-party POS prints itself** (unwanted). Two independent print systems, one order, two
tickets. Nexus's own path is single and idempotent; the duplicate is the POS auto-print, which is
triggered **POS-side** by the stored procedure / POS configuration.

## Proposed Fix (pending decision gate)
Goal = BT-only. The order MUST still be mirrored to the POS (billing), so the POS print must be
suppressed **without** dropping the mirror. Options, in order of preference:
1. **POS-side suppression (most likely correct, but OUT OF NEXUS APP SCOPE → SPLIT_REQUIRED):**
   disable the 3rd-party POS printer in the Krypton/POS configuration, OR have the
   `create_ordered_menu` stored proc accept a "no-print / kitchen-display-only" flag that Nexus can
   pass. The proc is in the POS DB — changing its print behavior is a POS-vendor/DBA task, not a
   Nexus code edit. (Note: `create_ordered_menu` is already called with `is_for_kitchen_display` and
   several boolean flags at [CreateOrderedMenu.php:166-179](../../woosoo-nexus/app/Actions/Order/CreateOrderedMenu.php) —
   investigate whether one of these controls POS printing **before** assuming a vendor change.)
2. **If the proc exposes a print toggle:** the only Nexus-side change is passing that param — a small,
   bounded ranpo-backend edit on `agent/nex-case-011-…` with a test asserting the param is sent.

**Cannot finalize until the two environment confirmations** (Run State → Handoff) are answered.

## Files Changed
None (investigation read-only). Any fix depends on the decision-gate outcome.

## Verification (when a fix is chosen)
- Functional on hardware (ops): submit one order → exactly one ticket, on the BT printer only;
  POS still receives the order for billing but does not print.
- If a Nexus param change: a test asserting `create_ordered_menu` is invoked with the no-print flag;
  `.\scripts\pre-merge-check.ps1 -App woosoo-nexus` exit 0.

## Executioner Verdict
<!-- pending decision gate -->

## Remaining Risks
- If suppression is POS-side only, Nexus cannot guarantee single-print by code alone — document the
  POS config as a deploy/ops prerequisite (Bucket B), not a Nexus merge gate.
- Confirm `NEXUS_PRINT_EVENTS_ENABLED` is actually `true` in prod; if `false`, BT isn't printing from
  Nexus at all and the whole model above must be re-checked.
