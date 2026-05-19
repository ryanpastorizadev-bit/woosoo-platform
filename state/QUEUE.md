---
status: canonical
scope: ecosystem
---

# Task Queue

<!-- Sorted by priority. Agents pull the first row where status=queued AND dep is none or confirmed. -->
<!-- Add rows when triaged from inbox. Update status as work progresses.                           -->
<!-- Prune completed rows weekly — move summary to docs/archive/.                                  -->
<!-- Last pruned: 2026-05-17                                                                       -->

---

## Pull Rule

Take the **first** row where:
- `status` = `queued`
- `Dep` = `none` **OR** the referenced dep ID is `confirmed` in `state/DEPS.md`

If all queued rows are blocked: report to user, list what must be resolved.

---

## Active Queue

| Priority | Case ID | App | Description | Tier | Dep | Status |
|---|---|---|---|---|---|---|
| P2 | TAB-CASE-001 | tablet-ordering-pwa | Order & session determinism | 2 | none | done |
| P2 | TAB-CASE-002 | tablet-ordering-pwa | Validated review follow-ups (dedup/reconnect/types/a11y) | 2 | none | done |
| P1 | NEX-CASE-003 | woosoo-nexus | Missing stored procedure — order retrieval broken (prod POS DB) | 3 | none | done |
| P1 | NEX-CASE-004 | woosoo-nexus | Device login returns HTTP 500 | 3 | none | queued |
| P2 | NEX-CASE-002 | woosoo-nexus | Pulse routes broken | 2 | none | queued |
| P2 | NEX-CASE-005 | woosoo-nexus | Legacy non-idempotent print path — client_submission_id absent | 2 | none | queued |
| P2 | PLT-CASE-008 | woosoo-platform | Docker MySQL/Redis not resolving | infra | none | queued |
| P3 | PLT-CASE-003 | woosoo-platform | Cross-app orchestration (post-single-app) | 3 | DEP-001,DEP-002,DEP-003 | queued |

---

## Completed (recent — prune after 7 days)

| Case ID | App | Completed | Evidence |
|---|---|---|---|
| TAB-CASE-002 | tablet-ordering-pwa | 2026-05-19 | Findings #3/#4/#6/#7: ce81a37 (nexus) / 1291632 (pwa). 382/382 tests, typecheck clean. Executioner APPROVED |
| tablet-package-ui-redesign | tablet-ordering-pwa | 2026-05-19 | fbd789f+c371d0f on staging. 382/382 tests, full pipeline green. Executioner APPROVED |
| TAB-CASE-001 | tablet-ordering-pwa | 2026-05-19 | All 4 fixes: offline contract, dead composables, Pinia-only persistence, bootstrap redirect. 382 tests pass, vue-tsc clean, build complete. Executioner APPROVED |
| TAB-CASE-003 | tablet-ordering-pwa | 2026-05-18 | PWA kiosk stale-shell auto-update; Tier 3 complete. 365 tests pass, typecheck/lint/build/generate PASSED. Executioner APPROVED |
| PRN-CASE-001 | woosoo-print-bridge | 2026-05-18 | Print determinism: 6 reliability fixes, 104 tests pass, flutter analyze clean. Executioner APPROVED |
| PRN-CASE-002 | woosoo-print-bridge | 2026-05-18 | Queue retention/purge TTL policy, 108 tests pass |
| NEX-CASE-001 | woosoo-nexus | 2026-05-18 | Security hardening (branch scoping, broadcast auth, GET→POST): 396 tests passed, routes verified POST, Executioner APPROVED |
| PLT-CASE-002 | woosoo-platform | 2026-05-17 | Hook surface verifier checks passed; Executioner APPROVED |
| PLT-CASE-001 | woosoo-platform | 2026-05-17 | Orchestration system verifier scans passed; Executioner APPROVED |
| PLT-CASE-004 | woosoo-platform | 2026-05-17 | Documentation-truth remediation verifier scans passed; Executioner APPROVED |
| PLT-CASE-005 | woosoo-platform | 2026-05-17 | Agent-def git-repo wording truth fix; stale-phrasing scan no matches; Executioner APPROVED |

---
<!--
PRIORITY: P1 (Critical/blocker) | P2 (High) | P3 (Standard) | P4 (Low)
STATUS:   queued | in_progress | blocked | needs_verification | verified | done
TIER:     1 | 2 | 3

PRIORITY GUIDE:
  P1 → Critical severity or production-impacting
  P2 → High severity or dependency-unlocking
  P3 → Standard features and bugs
  P4 → Low severity, nice-to-have

To add a task: run intake → triage → the triage hook appends a row here automatically.
-->
