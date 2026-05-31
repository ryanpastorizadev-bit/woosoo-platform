---
status: canonical
last_reviewed: 2026-05-31
scope: woosoo-nexus
---

# CASE: nex-case-005-legacy-print-path

Order submission hitting legacy non-idempotent print event path in production — `client_submission_id` absent from request.

## Run State
- task_slug: nex-case-005-legacy-print-path
- tier: 2
- branch: agent/nex-case-005-legacy-print-path
- status: COMPLETE
- last_completed_agent: contrarian
- next_agent: none
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-31 23:25
- resolution: CLOSED-OBE (cannot-reproduce class; legacy warning path gone, dedupe in place). User decision 2026-05-31.

## Handoff
- Phase in progress: none — Contrarian not yet started
- Done so far: Triaged from RAW-20260519-002 (intake 2026-05-19)
- Exact next action: Contrarian to assess scope — determine which submit path omits `client_submission_id` and whether a silent idempotency failure is occurring downstream at the print bridge.
- Working-tree state: no changes
- Risks / do-not-redo: PRN-CASE-001 fixed print determinism on the print-bridge side; this is the upstream Laravel submit path. Do not conflate. Do not modify order submission logic without Contrarian gate.

## Tier
2

## Branch
agent/nex-case-005-legacy-print-path

## Problem

Production log 2026-05-19 18:54:
```
Legacy non-idempotent print event path used
```

A request reached the order/print dispatch without a `client_submission_id`. No confirmed functional order failure at time of observation, but the warning indicates a code path that bypasses idempotency guarantees added by PRN-CASE-001.

Source: RAW-20260519-002.

**Separation from PRN-CASE-001:** that case fixed the print bridge receiver to handle duplicate events. This case is the upstream cause — the Laravel submit path that emits without an idempotency key.

## Contrarian Review
Investigated jointly with NEX-CASE-011 (2026-05-31, read-only). Conclusion: **this case is largely
out-of-date (OBE)** and is **not** the cause of the BT+POS duplicate (that is 011/H1). One genuine
residual remains. Recommend close-as-OBE or a small, bounded idempotency hardening — user's call.

## Investigation (read-only, 2026-05-31)
- **The 2026-05-19 warning string `"Legacy non-idempotent print event path used"` no longer exists in
  the code** (grep of `woosoo-nexus/app/` finds no match). The specific legacy emitter that logged it
  appears to have been removed/refactored since intake → that symptom is OBE.
- **Print-event creation is now idempotent.** `PrintTicketService::createInitialPrintEvent` /
  `createRefillPrintEvent` key on `idempotency_key` (`"initial:{order}:{csid}"` / `"refill:…"`), check
  for an existing row, and reuse it ([PrintTicketService.php:17-114](../../woosoo-nexus/app/Services/PrintTicketService.php));
  `idempotency_key` is `unique` ([migration 2026_05_11_000000](../../woosoo-nexus/database/migrations/2026_05_11_000000_add_idempotency_to_print_events_table.php)).
- **Residual gap:** when the client omits `client_submission_id`, the initial path generates a fresh
  one server-side — `$submissionId = $clientSubmissionId ?: (string) Str::uuid()`
  ([OrderService.php:155](../../woosoo-nexus/app/Services/Krypton/OrderService.php)). A per-call random
  UUID means two *separate* HTTP submit retries (same logical order, new DeviceOrder row) can produce
  different idempotency keys → in principle two BT `print_events`. In practice the new-order retry is
  guarded elsewhere (409-conflict handling / DurableRefillGuard), so the exposure is narrow.

## Root Cause
No active "legacy non-idempotent path" remains. The only residual is the **server-generated UUID
fallback** weakening cross-retry idempotency when the tablet omits `client_submission_id`. This does
**not** cause the BT-and-POS duplicate (NEX-CASE-011/H1).

## Proposed Fix (optional, pending decision)
Either:
- **Close as OBE** (the reported warning path is gone, dedupe is in place), OR
- **Small hardening (ranpo-backend, Tier 2):** require/propagate a stable `client_submission_id` from
  the tablet so the `Str::uuid()` fallback is never the idempotency basis across retries; add a test
  asserting two retries of a key-less submit do not create two `print_events`. Coordinate with the
  tablet contract (tablet must send a stable key) — note one-app rule.

## Files Changed
None (investigation read-only).

## Verification (if hardening is chosen)
- Test: two submits of the same logical order without a client-supplied key produce exactly one
  `print_events` row. `.\scripts\pre-merge-check.ps1 -App woosoo-nexus` exit 0.

## Executioner Verdict
<!-- pending decision gate -->

## Remaining Risks
- Requiring a stable `client_submission_id` touches the tablet→backend contract; if pursued, the
  tablet change is a separate app/case (one-app rule).
