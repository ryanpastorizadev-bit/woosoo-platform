---
status: canonical
scope: ecosystem
---

# Active Work State

<!-- Consult this file only after the docs/cases resume check. -->
<!-- It is a cache; docs/cases/<task-slug>.md is authoritative. -->
<!-- Rewrite the fields below when task state changes.          -->
<!-- Last updated: 2026-06-07 — stability remediation runbook persisted; Pi Bucket B is the gate. -->
<!-- Bucket A EMPTY; promotion unblocked. Active orchestration = plt-case-stability-remediation. -->

---

## Current Task

```yaml
task_id:      plt-case-stability-remediation
status:       in_progress
tier:         2
app:          ecosystem (orchestration + Pi ops)
specialist:   operator (Pi) | per-case specialists
branch:       n/a (see sibling case branches in state/QUEUE.md)
description:  Stabilize before KDS — Pi verify NEX-014/NEX-011/INFRA-003; then TAB-CASE-011,
              NEX-CASE-015, docs #156. KDS deferred until gates green.
case_file:    docs/cases/plt-case-stability-remediation.md
next_action:  P0 Pi: NEX-014 re-apply config + verify 419 gone (code already on dev).
              P1a/b Pi: NEX-011 BT-only smoke + INFRA-003 wlan0 rebuild; close #140/#136 if green.
              Then schedule TAB-CASE-011 (tablet). Backlog rows: state/QUEUE.md.
              KDS spec (deferred): docs/cases/kds-implementation-plan.md
last_agent:   cursor — 2026-06-07 — Part A plan review + case file persistence.
```

## Reconciliation Findings (2026-05-30) <!-- historical snapshot — not current state; see state/QUEUE.md -->

```text
DRIFT FOUND between agent-OS tracking and GitHub Issues:
- nex-case-007 (POS outbox/SessionReset) was COMPLETE+APPROVED but absent from QUEUE/DONE → recorded.
  Status: complete-landed on remote dev — still needs `php artisan pos:setup-payment-trigger` deploy.
- GH bug issues #140 (duplicate printing) and #136 (Pi build) had NO case files → registered in queue
  as NEX-CASE-011 and INFRA-CASE-003 (case stub files still to be created from _TEMPLATE).
- KDS epic (#137,#143-#148), telemetry #152, discount-sync #184, print-bridge #30, Pi panel #19
  are FEATURES → Bucket C, explicitly deferred (must NOT gate the dev→staging→main merge).
- DONE.md is under-recorded: NEX-CASE-001/008/009, TAB-CASE-001..004, PRN-CASE-001/002 are APPROVED
  but missing canonical rows → flagged for a verification backfill (not fabricated here).
- Branch divergence: nexus dev +1 / staging +6 (minor); main far behind. Realign before promote.
- Repo orgs: nexus/tablet/print-bridge = tech-artificer; platform = ryanpastorizadev-bit.
```

## Blocking Dependencies

```
none
```

## Last Agent

```
role:         cursor — 2026-06-07 — stability plan + KDS spec persisted to docs/cases/
left_off:     plt-case-stability-remediation.md + kds-implementation-plan.md written; WORK.md
              updated. Next = Pi operator P0 (NEX-014 verify).
files_open:   docs/cases/plt-case-stability-remediation.md, docs/cases/kds-implementation-plan.md
```

## On Completion of Next Task

```text
GATE MODEL (2026-05-31): nexus dev→staging ALREADY merged (nexus PR #157). Bucket A now gates
staging→main ONLY. See state/QUEUE.md for the authoritative three-bucket backlog.

BUCKET A — Stabilization (gates staging→main):
1. ✅ INFRA-CASE-003 — APPROVED 2026-06-01
2. ✅ TAB-CASE-009 — APPROVED 2026-06-01
3. ✅ NEX-CASE-013 — APPROVED 2026-06-01 (nexus PR #160 merged to dev)
4. ✅ TAB-CASE-010 — APPROVED 2026-06-02 (tablet PR #196 merged to dev)
→ BUCKET A CLEAR — staging→main promotion UNBLOCKED. See state/QUEUE.md.

BUCKET B — Deploy readiness (NON-gating ops; gates the actual Pi rollout):
→ NEX-CASE-011 POS config (disable 3rd-party POS printer on Pi — BT-only; NO Nexus code change),
  NEX-CASE-007 Pi step (`php artisan pos:setup-payment-trigger`; code already on dev+staging),
  INFRA-CASE-002 (Stage-B Pi verify), INFRA-CASE-001 (Pi migration on hardware), PRN-REBUILD-APK

BUCKET C — Deferred features (do NOT gate any promotion):
→ PLT-CASE-003, KDS epic (#137/#143-#148), telemetry #152, #184, #30, #19, NEX-CASE-010,
  NEX-CASE-012 (admin UI), tablet-screen-ui-ux-review
```

---
