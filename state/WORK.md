---
status: canonical
scope: ecosystem
---

# Active Work State

<!-- Consult this file only after the docs/cases resume check. -->
<!-- It is a cache; docs/cases/<task-slug>.md is authoritative. -->
<!-- Rewrite the fields below when task state changes.          -->
<!-- Last updated: 2026-06-03 — Bucket A EMPTY; all stabilization gates cleared and merged to dev. -->
<!-- Platform PR #36 (dev→staging) open; deploy docs and contract drift corrected. -->

---

## Current Task

```yaml
task_id:      promote-staging-main
status:       in_progress
tier:         3
app:          ecosystem (governance / release)
specialist:   claude-code (orchestration)
branch:       dev → staging → main
description:  Bucket A CLEAR — NEX-CASE-013 (+PR #160 detail-refresh), TAB-CASE-010, TAB-CASE-009,
              INFRA-CASE-003 all APPROVED + merged to dev. Promote dev→staging→main across all repos.
case_file:    (release) state/QUEUE.md is the authoritative backlog; no per-task case file
next_action:  Platform: merge PR #36 (dev→staging) once review threads resolved; then staging→main.
              App repos (nexus/tablet/print-bridge) are content-equivalent across dev/staging/main already.
              Bucket B Pi ops are the remaining restaurant-rollout gate — see state/QUEUE.md.
last_agent:   claude-code — 2026-06-03 — fixed runbook branch risk, contract drift, WORK.md stale gates.
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
role:         claude-code — 2026-06-03 — doc/governance fixes (this commit)
left_off:     All Bucket A gates merged to dev. TAB-CASE-010 APPROVED (tablet PR #196, 2026-06-02).
              NEX-CASE-013 APPROVED + merged (nexus PR #160 included). Platform PR #36 open (dev→staging).
              Runbook WOOSOO_DEPLOY_BRANCH risk fixed. Contract drift for order.details.updated fixed.
files_open:   state/QUEUE.md (Bucket B Pi ops pending)
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
