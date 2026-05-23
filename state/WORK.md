---
status: canonical
scope: ecosystem
---

# Active Work State

<!-- Consult this file only after the docs/cases resume check. -->
<!-- It is a cache; docs/cases/<task-slug>.md is authoritative. -->
<!-- Rewrite the fields below when task state changes.          -->
<!-- Last updated: 2026-05-23 — NEX-CASE-009 admin Menus filters -->

---

## Current Task

```
task_id:      nex-case-009-admin-menus-filters (P2, done)
status:       done
tier:         2
app:          woosoo-nexus
specialist:   ranpo-backend
description:  Restore Course/Group/Image filters in admin Menus DataTable by registering
              course, group, has_uploaded_image columns. Adds Uploaded/Missing toolbar toggles.
case_file:    docs/cases/nex-case-009-admin-menus-filters.md
next_action:  Merge agent/nex-case-009-admin-menus-filters to staging in woosoo-nexus.
last_agent:   specialist:ranpo-backend — 2026-05-23 — 3 files changed; typecheck exit 0;
              430 passed (1510 assertions), 0 failures. Executioner APPROVED.
```

## Blocking Dependencies

```
none
```

## Last Agent

```
role:         specialist:ranpo-backend (2026-05-23)
date:         2026-05-23
left_off:     Implementation complete. Branch: agent/nex-case-009-admin-menus-filters.
              Commit 84193ab: feat(menus): restore Course/Group/Image filters in admin Menus DataTable.
              typecheck exit 0; pre-merge-check.ps1 -App woosoo-nexus: 430 passed, 0 failures.
              Executioner APPROVED.
files_open:   docs/cases/nex-case-009-admin-menus-filters.md
              state/WORK.md
```

## On Completion of Next Task

```text
→ NEX-CASE-008 complete → Pi Gate A/B for TAB-CASE-007 → TAB-CASE-007 Executioner
→ NEX-CASE-002 (Pulse routes, P2) → PLT-CASE-003 (cross-app orchestration, P3)
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
