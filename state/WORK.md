---
status: canonical
scope: ecosystem
---

# Active Work State

<!-- Consult this file only after the docs/cases resume check. -->
<!-- It is a cache; docs/cases/<task-slug>.md is authoritative. -->
<!-- Rewrite the fields below when task state changes.          -->
<!-- Last updated: 2026-05-20 by executioner — TAB-CASE-006 APPROVED; TAB-CASE-005 visual fixes pending Docker rebuild; NEX-CASE-004 at Specialist -->

---

## Current Task

```
task_id:      nex-case-004-device-login-500 (P1, at Specialist)
status:       in_progress
tier:         3
app:          woosoo-nexus
description:  Contrarian complete. Specialist (ranpo-backend) must add try/catch null-fallback
              around $device->table()->first() in authenticate() + feature tests (currently zero).
case_file:    docs/cases/nex-case-004-device-login-500.md
```

## Next Action

```
PLT-CASE-009: APPROVED by Executioner (2026-05-19). Code gate closed.
  Post-deploy on Pi: deploy.sh → docker compose logs mysql redis → docker compose ps.

NEX-CASE-004: Specialist (ranpo-backend) — two deliverables:
  1. try/catch null-fallback around $device->table()->first(['id', 'name']) in authenticate()
  2. Feature tests: successful login with POS down → 200 + null table; device not found → 404;
     device unregistered → 403. (Currently ZERO tests for DeviceAuthApiController@authenticate.)
  Scope: authenticate() ONLY. Do NOT touch register(), lookupByIp(), or token issuance logic.
  Branch: agent/nex-case-004-device-login-500

QUEUE NEXT after NEX-CASE-004: NEX-CASE-002 (Pulse routes broken, P2, Tier 2)
```

## Blocking Dependencies

```
none
```

## Last Agent

```
role:         contrarian
date:         2026-05-19
left_off:     PLT-CASE-009 Executioner APPROVED — REVERB_HOST fix closed for code review.
              Pi Fix B (deploy.sh redeploy + mysql/redis log pull) still required on device.
              NEX-CASE-004 Contrarian complete — root cause: $device->table()->first() in
              authenticate() uses POS connection (Table::$connection='pos') with no try/catch.
              POS failure → uncaught QueryException → 500. Specialist next.
files_open:   docs/cases/nex-case-004-device-login-500.md
              docs/cases/plt-case-008-docker-mysql-redis.md
              state/WORK.md
```

## On Completion of Next Task

```text
→ PLT-CASE-009 + NEX-CASE-003 Executioner APPROVED → NEX-CASE-004 Contrarian
→ NEX-CASE-004 complete → PLT-CASE-003 (cross-app orchestration, P3)
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
