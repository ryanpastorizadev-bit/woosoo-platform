---
status: canonical
last_reviewed: 2026-06-05
scope: woosoo-nexus
---

# CASE: nex-case-011-duplicate-order-printing

Client reports submitted orders printing on BOTH the Bluetooth printer and the 3rd-party POS
printer. Investigate from the Nexus side — duplication may originate before the print bridge.
(GitHub Issue: tech-artificer/woosoo-nexus #140 — bug, investigation, printing.)

## Run State
- task_slug: nex-case-011-duplicate-order-printing
- tier: 3
- branch: fix/nex-011-duplicate-print
- status: code-complete
- last_completed_agent: executioner
- next_agent: ops (POS config on Pi) — Bucket B
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-05

## Resolution

**Two distinct duplicate sources — both addressed:**

1. **Code fix (DONE — PR #163, merged 2026-06-04):** Nexus ack paths (`OrderApiController::markPrinted`,
   `PrinterApiController::markPrinted`, `markPrintedBulk`) were re-dispatching `PrintOrder` (a print
   command) on every ack. This caused the print-bridge to receive a second print command on acknowledgment.
   Fix: removed all `PrintOrder::dispatch()` calls from ack paths; added `is_printed` idempotency guard
   to `OrderApiController::markPrinted` (also closes nex-case-005). See full investigation + Executioner
   verdict in `woosoo-nexus/docs/cases/nex-case-011-duplicate-order-printing.md`.

2. **Ops fix (PENDING — Bucket B):** The POS system auto-prints via `create_ordered_menu` stored proc
   regardless of the BT print path. `NEXUS_PRINT_EVENTS_ENABLED` must be confirmed true; the 3rd-party
   Krypton POS printer must be disabled so only the BT thermal printer prints. The POS still needs the
   order mirrored for billing — only the print output is suppressed.

## Handoff
- Phase in progress: code-complete; ops step pending.
- Done so far: root cause proven (two vectors); code fix merged (PR #163); nex-case-005 closed inline.
- Exact next action (ops, on Pi): confirm `NEXUS_PRINT_EVENTS_ENABLED=true`; disable the POS-side
  printer in Krypton/POS config; verify one order → one BT ticket, POS receives order but does not print.
- Working-tree state: PR #163 merged to woosoo-nexus `dev` on 2026-06-04.
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
- `app/Http/Controllers/Api/V1/PrinterApiController.php` (woosoo-nexus) — removed `PrintOrder::dispatch()` from `markPrinted` and `markPrintedBulk`; removed unused import.
- `app/Http/Controllers/Api/V1/OrderApiController.php` (woosoo-nexus) — removed `PrintOrder::dispatch()` from `markPrinted`; added `is_printed` early-return guard (closes nex-005).
- `tests/Feature/PrinterApiTest.php` (woosoo-nexus) — updated tests.
- `woosoo-nexus/docs/cases/nex-case-011-duplicate-order-printing.md` — full investigation + executioner verdict.

## Verification (when a fix is chosen)
- Functional on hardware (ops): submit one order → exactly one ticket, on the BT printer only;
  POS still receives the order for billing but does not print.
- If a Nexus param change: a test asserting `create_ordered_menu` is invoked with the no-print flag;
  `.\scripts\pre-merge-check.ps1 -App woosoo-nexus` exit 0.

## Executioner Verdict
APPROVED 2026-06-04. PR #163 merged to woosoo-nexus `dev`. Three sites changed; tests updated. Remaining risk: bridge-side `is_printed` payload check (see Remaining Risks). POS config (Bucket B) is a deploy prerequisite, not a code gate.

## Remaining Risks
- If suppression is POS-side only, Nexus cannot guarantee single-print by code alone — document the
  POS config as a deploy/ops prerequisite (Bucket B), not a Nexus merge gate.
- Confirm `NEXUS_PRINT_EVENTS_ENABLED` is actually `true` in prod; if `false`, BT isn't printing from
  Nexus at all and the whole model above must be re-checked.
