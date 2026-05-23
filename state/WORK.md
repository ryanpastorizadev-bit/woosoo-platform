---
status: canonical
scope: ecosystem
---

# Active Work State

<!-- Consult this file only after the docs/cases resume check. -->
<!-- It is a cache; docs/cases/<task-slug>.md is authoritative. -->
<!-- Rewrite the fields below when task state changes.          -->
<!-- Last updated: 2026-05-23 — NEX-CASE-008 TransientToken guard -->

---

## Current Task

```
task_id:      nex-case-008-transient-token-refresh-guard (P1, needs_verification)
status:       needs_verification
tier:         3
app:          woosoo-nexus
specialist:   ranpo-backend
description:  Guard refresh() and logout() in DeviceAuthApiController against
              non-Device principals and TransientToken — returns 401 instead of 500.
case_file:    docs/cases/nex-case-008-transient-token-refresh-guard.md
next_action:  VERIFY: run pre-merge-check.ps1 -App woosoo-nexus; confirm 2 new tests PASS,
              all existing device lifecycle tests still PASS. Then Executioner verdict.
last_agent:   specialist:ranpo-backend — 2026-05-23 — Added instanceof guards to refresh()
              and logout(); 2 new tests added to DeviceTokenLifecycleTest.php.
              Pre-merge: 430 passed (1510 assertions), 0 failures.
```

## Blocking Dependencies

```
none
```

## Last Agent

```
role:         specialist:ranpo-backend (2026-05-23)
date:         2026-05-23
left_off:     Implementation complete. Branch: agent/nex-case-008-transient-token-refresh-guard.
              Commit: fix(auth): guard refresh() and logout() against TransientToken crash.
              pre-merge-check.ps1 -App woosoo-nexus: 430 passed, 0 failures.
              Both new tests green. All 5 prior DeviceTokenLifecycleTest tests green.
files_open:   docs/cases/nex-case-008-transient-token-refresh-guard.md
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
