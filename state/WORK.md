---
status: canonical
scope: ecosystem
---

# Active Work State

<!-- Consult this file only after the docs/cases resume check. -->
<!-- It is a cache; docs/cases/<task-slug>.md is authoritative. -->
<!-- Rewrite the fields below when task state changes.          -->
<!-- Last updated: 2026-05-19 by executioner (claude-code) — /review sync       -->

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
Fix 1+2 COMPLETE (ab0dbae, 2111f84). Proceed to specialist:chuya-frontend for Fix 3:
single persistence owner — remove manual localStorage writes in stores/session.js;
use only Pinia with proper hydration. Do not re-add BackgroundSyncPlugin.
Do not re-introduce useOrderSubmission or useOfflineOrderQueue.
See docs/cases/tab-case-001-order-session-determinism.md ## Proposed Fix → Fix 3.
```

## Blocking Dependencies

```
none
```

## Last Agent

```
role:         specialist:chuya-frontend
date:         2026-05-19
left_off:     Fix 2 done. Dead composables removed (useOrderSubmission, useSubmissionIdempotency,
              useOfflineOrderQueue). generateIdempotencyKey() centralised in utils/orderHelpers.ts.
              Unused useOrderSubmission import removed from pages/order/review.vue. Contract tests
              added (order-submit-source-contract.spec.ts). 369/369 tests pass, 0 typecheck, 0 lint.
files_open:   docs/cases/tab-case-001-order-session-determinism.md, state/WORK.md
```

## On Completion of Next Task

```
→ TAB-CASE-001 completes (all 4 fixes done) → update state/DEPS.md DEP-003 to confirmed
→ PLT-CASE-003 unblocks — start as Contrarian (Tier 3, cross-app orchestration)
→ TAB-CASE-002 also in_progress (parallel) — 7 validated findings, specialist:chuya-frontend
  NOTE: CLAUDE_REVIEW_SUMMARY.md suggests findings #2 + #6 may be partially shipped already;
  triage against TAB-CASE-002 case file before starting implementation.
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
