---
status: canonical
scope: ecosystem
---

# Active Work State

<!-- Consult this file only after the docs/cases resume check. -->
<!-- It is a cache; docs/cases/<task-slug>.md is authoritative. -->
<!-- Rewrite the fields below when task state changes.          -->
<!-- Last updated: 2026-05-30 — vite-build-conditional specialist:infra → verifier handover -->

---

## Current Task

```yaml
task_id:      infra-vite-build-conditional
status:       done
tier:         2
app:          woosoo-nexus
specialist:   infra
branch:       agent/vite-build-conditional
description:  Make the Vite asset build conditional so public/build is rebuilt only when
              missing/empty or forced — not on every container start. Eliminates the ~63s
              rebuild on crash/OOM auto-restart. In-container build retained (correct per-host
              arch); host-build alternative rejected on cross-arch grounds.
case_file:    docs/cases/infra-vite-build-conditional.md
next_action:  Merge agent/vite-build-conditional to dev in both woosoo-nexus and
              woosoo-platform. Pi operator captures entrypoint logs from first deploy.sh run
              to close deferred Step 7 (Pi parity).
last_agent:   claude-code — 2026-05-30 — Executioner APPROVED. Case COMPLETE. Restart
              rebuild eliminated (90s → 10s); force flag verified; orphan volume cleaned;
              pre-merge-check green.
```

## Blocking Dependencies

```
none
```

## Last Agent

```
role:         claude-code — Specialist (infra) + Verifier + Executioner chain complete
date:         2026-05-30
left_off:     Case COMPLETE, Executioner APPROVED. 3 edits ready to merge:
              (1) woosoo-nexus/docker/docker-entrypoint.sh — conditional build
              (2) compose.yaml — WOOSOO_FORCE_VITE_BUILD passthrough
              (3) scripts/deployment/deploy.sh — pre-build + orphan-volume rm
              Pi parity (Step 7) deferred to first Pi deploy of this branch.
files_open:   docs/cases/infra-vite-build-conditional.md (Run State → COMPLETE)
              docs/cases/nex-case-010-immutable-image-production-migration.md (Tier 3, BLOCKED)
```

## On Completion of Next Task

```text
→ nex-case-010 (immutable-image production migration, Tier 3) once deliberately selected
→ NEX-CASE-002 (Pulse routes, P2) or NEX-CASE-005 (legacy print path, P2)
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
