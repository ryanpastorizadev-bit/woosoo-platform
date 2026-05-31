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

<!-- Reconciled 2026-05-30 against GitHub Issues (13 open: nexus 10, tablet 1, print-bridge 1, platform 1) -->
<!-- + docs/cases/* + DONE.md. Merge gate = Bucket A ONLY. Bucket C must NOT gate dev→staging→main.       -->

### Bucket A — Stabilization (GATES the dev → staging → main merge)

| Priority | Case ID | App | Description | Tier | Dep | Status | GH |
|---|---|---|---|---|---|---|---|
| P1 | NEX-CASE-011 | woosoo-nexus | Duplicate order printing (BT + POS) — investigate & fix | 3 | none | queued | #140 |
| P2 | NEX-CASE-005 | woosoo-nexus | Legacy non-idempotent print path — `client_submission_id` absent (investigate JOINT with #140) | 2 | none | queued | — |
| P1 | NEX-CASE-007 | woosoo-nexus | POS payment outbox / SessionReset blast-radius + `last_seen_at` middleware | 3 | none | complete-landed | #152 (backend) |
| P2 | INFRA-CASE-003 | woosoo-platform | Pi Docker build fails — `npm ci` drops WiFi (ECONNRESET/ETIMEDOUT) | 2 | none | queued | #136 |

### Bucket C — Deferred (post-stabilization release; do NOT gate the merge)

| Priority | Case ID | App | Description | Tier | Dep | Status | GH |
|---|---|---|---|---|---|---|---|
| P3 | PLT-CASE-003 | woosoo-platform | Cross-app orchestration (deps confirmed) | 3 | DEP-001,DEP-002,DEP-003 | deferred | — |
| P3 | KDS-EPIC | woosoo-nexus | Kitchen Display System v1.0 (PR-0A…PR-7) | 3 | none | deferred | #137,#143,#144,#145,#146,#147,#148 |
| P3 | — | woosoo-nexus | Device telemetry feature (battery/online detail) | 2 | none | deferred | #152 |
| P3 | — | tablet-ordering-pwa | POS→tablet discount sync & active-order hydration | 2 | none | deferred | #184 |
| P4 | — | woosoo-print-bridge | Exclude side items from print; larger receipt text | 2 | none | deferred | #30 |
| P3 | — | woosoo-platform | Pi Control Panel — local ops/deploy dashboard | 2 | none | deferred | #19 |
| P3 | NEX-CASE-010 | woosoo-nexus | Immutable-image production migration | 3 | none | blocked | — |

---

## Completed (recent — prune after 7 days)

| Case ID | App | Completed | Evidence |
|---|---|---|---|
| NEX-CASE-007 | woosoo-nexus | 2026-05-21 | POS payment outbox; per-order SessionReset blast-radius removed; authenticated-device last_seen_at middleware. Executioner APPROVED. Merged to remote dev; `pos:setup-payment-trigger` deploy still pending |
| NEX-CASE-002 | woosoo-nexus | 2026-05-30 | Pulse routes — cannot-reproduce; route/gate/permission correct; gating test PulseRouteAuthTest added; 432 tests pass; pre-merge-check OK. Executioner APPROVED |
| NEX-CASE-008 | woosoo-nexus | 2026-05-2x | TransientToken 500 on /refresh + /logout (admin web session hits device endpoint). Marked done in queue; **DONE.md row pending verification backfill** |
| NEX-CASE-009 | woosoo-nexus | 2026-05-2x | Restore admin Menus Course/Group/Image filters. Marked done in queue; **DONE.md row pending verification backfill** |
| NEX-CASE-004 | woosoo-nexus | 2026-05-20 | 6 tests (25 assertions) pass; safeLoadDeviceTable() catches Throwable; 200+null table when POS down. Executioner APPROVED |
| NEX-CASE-006 | woosoo-nexus | 2026-05-20 | HealthBroadcastingTest + VerifyIntegrityCommandTest; /api/health broadcasting check; PR #120 merged to staging. APPROVED (retrospective) |
| TAB-CASE-004 | tablet-ordering-pwa | 2026-05-18 | build-info.json prerender fix; PR #158 merged to staging. Executioner APPROVED |
| TAB-CASE-005 | tablet-ordering-pwa | 2026-05-19 | typecheck exit 0, lint 0 errors, build exit 0; PackageCard.vue + packageSelection.vue; 9 UI changes. Executioner APPROVED |
| TAB-CASE-006 | tablet-ordering-pwa | 2026-05-20 | typecheck exit 0; eslint 0 errors; build exit 0; :meats="decorateMeats" one-line fix. Executioner APPROVED |
| PLT-CASE-008 | woosoo-platform | 2026-05-20 | PR #10 merged; PROTOCOL.md + docs multi-repo terminology; deploy scripts hardened (require_var guards, REVERB_HOST=reverb). APPROVED |
| PLT-CASE-009 | woosoo-platform | 2026-05-19 | REVERB_HOST set_env corrected to Docker DNS `reverb`; local checks green; Executioner APPROVED. Pi runtime verification remains operational follow-up. |
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
