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
task_id:      stabilization-reconciliation
status:       in_progress
tier:         2
app:          ecosystem (governance)
specialist:   dazai-docs
branch:       dev
description:  Phase 0 reconciliation — cross-referenced 13 open GitHub Issues (nexus 10, tablet 1,
              print-bridge 1, platform 1) against docs/cases + QUEUE.md + DONE.md. Produced single
              authoritative backlog (Bucket A stabilization / Bucket C deferred). Merge gate =
              Bucket A only; KDS epic + features deferred.
case_file:    (plan) C:/Users/Pc1/.claude/plans/review-and-assess-check-cozy-lark.md
next_action:  Begin Bucket A. Lead: NEX-CASE-011 (#140 duplicate printing) investigated JOINT with
              NEX-CASE-005 (legacy non-idempotent print path) — likely shared root cause. In parallel:
              INFRA-CASE-003 (#136 Pi build) and TAB-CASE-009 (chuya-frontend). Bucket B (deploy) runs
              alongside; NEX-CASE-007 code is already on dev+staging — only the Pi trigger remains.
last_agent:   claude-code — 2026-05-31 — backlog reorg (3 buckets, gate model corrected) in QUEUE.md/WORK.md.
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
role:         claude-code — Contrarian + Specialist (ranpo-backend) + Executioner chain complete
date:         2026-05-30
left_off:     Case COMPLETE. One new file: tests/Feature/Pulse/PulseRouteAuthTest.php.
              agent/vite-build-conditional merged to dev in both repos (nexus PR #153; platform
              also merged). Stale note removed 2026-05-31.
files_open:   docs/cases/nex-case-002-pulse-routes.md (Run State → COMPLETE)
              docs/cases/nex-case-010-immutable-image-production-migration.md (Tier 3, BLOCKED)
```

## On Completion of Next Task

```text
GATE MODEL (2026-05-31): nexus dev→staging ALREADY merged (nexus PR #157). Bucket A now gates
staging→main ONLY. See state/QUEUE.md for the authoritative three-bucket backlog.

BUCKET A — Stabilization (gates staging→main):
1. INFRA-CASE-003 (#136 Pi build npm ci WiFi, T2)
2. TAB-CASE-009 (tablet WS silent-death, T2) — contrarian done, awaiting chuya-frontend
3. Both APPROVED → promote staging→main
   (NEX-CASE-011 root-caused 2026-05-31 → POS-side, moved A→B; NEX-CASE-005 closed OBE.)

BUCKET B — Deploy readiness (NON-gating ops; gates the actual Pi rollout):
→ NEX-CASE-011 POS config (disable 3rd-party POS printer on Pi — BT-only; NO Nexus code change),
  NEX-CASE-007 Pi step (`php artisan pos:setup-payment-trigger`; code already on dev+staging),
  INFRA-CASE-002 (Stage-B Pi verify), INFRA-CASE-001 (Pi migration on hardware), PRN-REBUILD-APK

BUCKET C — Deferred features (do NOT gate any promotion):
→ PLT-CASE-003, KDS epic (#137/#143-#148), telemetry #152, #184, #30, #19, NEX-CASE-010,
  NEX-CASE-012 (admin UI), tablet-screen-ui-ux-review
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
