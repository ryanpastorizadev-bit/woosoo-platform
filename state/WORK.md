---
status: canonical
scope: ecosystem
---

# Active Work State

<!-- Consult this file only after the docs/cases resume check. -->
<!-- It is a cache; docs/cases/<task-slug>.md is authoritative. -->
<!-- Rewrite the fields below when task state changes.          -->
<!-- Last updated: 2026-05-19 by contrarian — NEX-CASE-003 Contrarian gate COMPLETE (preempts PLT-CASE-003) -->

---

## Current Task

```
task_id:      nex-case-003-missing-stored-procedure
status:       in_progress
tier:         3
app:          woosoo-nexus
specialist:   ranpo-backend
description:  Missing stored procedure — order retrieval broken (prod POS DB)
case_file:    docs/cases/nex-case-003-missing-stored-procedure.md
```

## Next Action

```
Contrarian gate COMPLETE (2026-05-19). Risk analysis written (R1–R6).

Specialist (ranpo-backend) must:
1. Confirm the actual HTTP 500 source — the catch block should already silence the proc error;
   the 500 trigger is unconfirmed.
2. Choose fix path: Eloquent inline (preferred by Contrarian) vs proc recreation (vendor-DB risk).
3. Remove env('APP_ENV') direct call at OrderRepository.php:138 (Spatie/Laravel violation).
4. Plan UI-level fallback for empty openOrders (R3 — ops staff are blind when proc fails silently).
5. Extend test coverage to exercise the production code path (remove or gate the test bypass).

PLT-CASE-003 is preempted by P1. It remains fully unblocked and queued (P3) — resume after
NEX-CASE-003 and NEX-CASE-004 are resolved.
```

## Blocking Dependencies

```
none
```

## Last Agent

```
role:         contrarian
date:         2026-05-19
left_off:     Contrarian analysis complete for NEX-CASE-003.
              Call chain confirmed: DashboardController::index() → OrderRepository::getOpenOrdersForSession()
              → CALL get_open_orders_for_session(?) → SQLSTATE[42000].
              Catch block already present — 500 source unconfirmed.
              Recommended Eloquent inline fix (avoids vendor-DB ownership risk).
              R5: env('APP_ENV') direct call flagged for removal.
files_open:   docs/cases/nex-case-003-missing-stored-procedure.md
              app/Repositories/Krypton/OrderRepository.php
              app/Http/Controllers/Admin/DashboardController.php
```

## On Completion of Next Task

```text
→ NEX-CASE-003 Specialist done → Verifier → Executioner gate
→ Then NEX-CASE-004 (device login 500, P1, Tier 3)
→ Then PLT-CASE-003 (cross-app orchestration, P3, Tier 3)
```

---
<!--
STATUS VALUES:
  queued              Ready, not started
  in_progress         Work underway
  blocked             Waiting on a dependency (see state/DEPS.md)
  needs_verification  Implementation done, not yet verified
  verified            Tested and confirmed
  done                Handover complete — pull next task

TIER VALUES: 1 (Trivial) | 2 (Standard) | 3 (High-risk)

SPECIALIST VALUES: ranpo-backend | chuya-frontend | relay-ops | dazai-docs | infra

CASE FILE PATH: docs/cases/<task-slug>.md
  Recommended task slug prefix: nex-case | tab-case | prn-case | plt-case
  The case file remains the authoritative durable resume point.
-->
