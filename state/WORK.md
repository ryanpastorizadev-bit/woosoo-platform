---
status: canonical
scope: ecosystem
---

# Active Work State

<!-- Consult this file only after the docs/cases resume check. -->
<!-- It is a cache; docs/cases/<task-slug>.md is authoritative. -->
<!-- Rewrite the fields below when task state changes.          -->
<!-- Last updated: 2026-05-20 — INFRA-CASE-001 Pi platform migration in progress -->

---

## Current Task

```
task_id:      infra-case-001-pi-platform-migration (P1, in_progress)
status:       in_progress
tier:         3
app:          platform infra (scripts/deployment, compose.yaml)
description:  Migrate Pi from old woosoo-nexus single-repo model to platform-root model.
              First Pi runtime verification of the new orchestration stack.
case_file:    docs/cases/infra-case-001-pi-platform-migration.md
```

## Next Action

```
INFRA-CASE-001: Execute 8-phase Pi deployment runbook (see case file + plan).
  Branch: staging (per user instruction)
  Specialist: infra
  Script fixes applied (woosoo-health.sh, woosoo-backup.sh) — commit + push to Pi.

  Phase 0: Pre-flight inspection on Pi (SSH 192.168.100.42).
  Phase 1: docker compose down (NO --volumes) from old nexus root.
  Phase 2: Clone woosoo-platform; mv woosoo-nexus inside it; clone tablet-ordering-pwa.
  Phase 3: mkcert certs covering 192.168.100.42 + 192.168.1.31; scp to Pi docker/certs/.
  Phase 4: Create /etc/woosoo/woosoo.env (WOOSOO_APPLY_STATIC_IP=false).
  Phase 5: doctor.sh — all green before proceeding.
  Phase 6: apply-woosoo-config.sh + deploy.sh.
  Phase 7: Smoke tests + woosoo-health.sh.

DEFERRED (NEX-CASE-002):
  Pulse routes broken — Contrarian not yet started.
  Branch: agent/nex-case-002-pulse-routes (create in woosoo-nexus)

DEFERRED R3 from NEX-CASE-004: register() and lookupByIp() still call
  $device->table()->first() without POS null-guard (lines 218, 326 in DeviceAuthApiController).
  File as NEX-CASE-004b or bundle in a future nexus hardening pass.
```

## Blocking Dependencies

```
none
```

## Last Agent

```
role:         governance sync (2026-05-20)
date:         2026-05-20
left_off:     Both repos pulled to latest staging (woosoo-nexus a2ec1d5, woosoo-platform 8fd6726).
              3 merged branches deleted in woosoo-nexus.
              NEX-CASE-006 (broadcast integrity, PR #120) closed retrospectively.
              QUEUE.md: NEX-CASE-004 → done; 6 missing completed rows added.
              DONE.md: NEX-CASE-006 + PLT-CASE-008 rows added.
files_open:   docs/cases/nex-case-006-broadcast-integrity.md
              state/QUEUE.md
              state/DONE.md
```

## On Completion of Next Task

```text
→ NEX-CASE-002 complete → PLT-CASE-003 (cross-app orchestration, P3)
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
