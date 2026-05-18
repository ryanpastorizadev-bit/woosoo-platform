---
status: canonical
scope: ecosystem
---

# Active Work State

<!-- Consult this file only after the docs/cases resume check. -->
<!-- It is a cache; docs/cases/<task-slug>.md is authoritative. -->
<!-- Rewrite the fields below when task state changes.          -->
<!-- Last updated: 2026-05-18 by executioner (claude-code)       -->

---

## Current Task

```
task_id:      tab-case-001-order-session-determinism
status:       in_progress
tier:         2
app:          tablet-ordering-pwa
specialist:   chuya-frontend
description:  Order submission and session consistency fixes for tablet-ordering-pwa
case_file:    docs/cases/tab-case-001-order-session-determinism.md
```

## Next Action

```
Fix 1 (offline ordering contradiction) COMPLETE — commit ab0dbae on staging in tablet-ordering-pwa.
Proceed to specialist:chuya-frontend for Fix 2: consolidate 4 overlapping order submission
composables (useOrderSubmit.ts, useOrderSubmission.ts, useSubmissionIdempotency.ts,
useOfflineOrderQueue.ts) into single composable with clear responsibilities.
See docs/cases/tab-case-001-order-session-determinism.md ## Proposed Fix → Fix 2.
```

## Blocking Dependencies

```
none
```

## Last Agent

```
role:         specialist:chuya-frontend
date:         2026-05-18
left_off:     Fix 1 done. Removed BackgroundSyncPlugin; both order routes NetworkOnly. Disabled
              submit button when offline; added warning banner. Contract test updated. 366/366
              tests pass, 0 typecheck, 0 lint. Risks: do not re-add BackgroundSyncPlugin; do not
              touch stores/OfflineSync.ts until Fix 2 composable consolidation decision.
files_open:   docs/cases/tab-case-001-order-session-determinism.md, state/WORK.md
```

## On Completion of Next Task

```
→ TAB-CASE-001 completes (all 4 fixes done) → update state/DEPS.md DEP-003 to confirmed
→ PLT-CASE-003 unblocks — start as Contrarian (Tier 3, cross-app orchestration)
→ TAB-CASE-002 also in_progress (parallel) — 7 validated issues, specialist:chuya-frontend
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
