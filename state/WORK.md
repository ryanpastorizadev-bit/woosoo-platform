---
status: canonical
scope: ecosystem
---

# Active Work State

<!-- Consult this file only after the docs/cases resume check. -->
<!-- It is a cache; docs/cases/<task-slug>.md is authoritative. -->
<!-- Rewrite the fields below when task state changes.          -->
<!-- Last updated: 2026-05-31 — Backlog reorg: 3 buckets (A stabilization / B deploy-readiness / C deferred); -->
<!-- gate model corrected to staging→main (nexus dev→staging already merged via #157); 4 missing live cases captured. -->

---

## Current Task

```yaml
task_id:      tab-case-010
status:       queued
tier:         3
app:          tablet-ordering-pwa
specialist:   chuya-frontend
branch:       agent/tab-case-010 (to be created)
description:  Use canonical order_id everywhere + consume order.details.updated (live order refresh); fix preparing→in_progress
case_file:    docs/cases/tab-case-010.md (to be created from _TEMPLATE)
next_action:  Contrarian first — review tablet order_id usage, useBroadcasts.ts consumption of order.details.updated, preparing→in_progress mapping
last_agent:   executioner — 2026-06-01 — NEX-CASE-013 APPROVED; DEP-004 confirmed; TAB-CASE-010 unblocked
```

## Reconciliation Findings (2026-05-30)

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
role:         executioner — 2026-06-01 — NEX-CASE-013 APPROVED
left_off:     NEX-CASE-013 full chain complete (438 tests, 6 regression guards). DEP-004 confirmed.
              TAB-CASE-010 unblocked. State files (DONE/DEPS/QUEUE/WORK) all updated.
              NEX-CASE-013 branch uncommitted — PR to be raised against staging.
files_open:   docs/cases/nex-case-013-pos-order-detail-sync.md (status: COMPLETE)
```

## On Completion of Next Task

```text
GATE MODEL (2026-05-31): nexus dev→staging ALREADY merged (nexus PR #157). Bucket A now gates
staging→main ONLY. See state/QUEUE.md for the authoritative three-bucket backlog.

BUCKET A — Stabilization (gates staging→main):
1. ✅ INFRA-CASE-003 — APPROVED 2026-06-01
2. ✅ TAB-CASE-009 — APPROVED 2026-06-01
3. ✅ NEX-CASE-013 — APPROVED 2026-06-01 (branch uncommitted; PR to be raised)
4. TAB-CASE-010 (tablet consumer, T3) — **queued → chuya-frontend** (DEP-004 confirmed)
→ staging→main promotion waits for TAB-CASE-010 APPROVED

BUCKET B — Deploy readiness (NON-gating ops; gates the actual Pi rollout):
→ NEX-CASE-011 POS config (disable 3rd-party POS printer on Pi — BT-only; NO Nexus code change),
  NEX-CASE-007 Pi step (`php artisan pos:setup-payment-trigger`; code already on dev+staging),
  INFRA-CASE-002 (Stage-B Pi verify), INFRA-CASE-001 (Pi migration on hardware), PRN-REBUILD-APK

BUCKET C — Deferred features (do NOT gate any promotion):
→ PLT-CASE-003, KDS epic (#137/#143-#148), telemetry #152, #184, #30, #19, NEX-CASE-010,
  NEX-CASE-012 (admin UI), tablet-screen-ui-ux-review
```

---
