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

<!-- Reconciled 2026-05-31 (refresh of 2026-05-30) against GitHub Issues + PR state + docs/cases/* + DONE.md.   -->
<!-- GATE MODEL (set 2026-05-31): nexus dev→staging ALREADY merged (nexus PR #157). Bucket A now gates         -->
<!-- staging→main ONLY (the production-facing promotion). Bucket B = deploy readiness (non-gating ops).        -->
<!-- Bucket C (features) must NOT gate any promotion. Three live cases were missing pre-refresh: INFRA-001/002, -->
<!-- prn-rebuild-apk, tablet-screen-ui-ux-review — now captured. NEX-CASE-007 is code-complete on dev/staging;  -->
<!-- only its Pi runtime step remains → moved A→B.                                                              -->
<!-- 2026-06-04: NEX-CASE-011 corrected to dual-fix (code PR #163 + POS config); NEX-CASE-014 added (SESSION_DOMAIN). -->

### Bucket A — Stabilization (GATES the staging → main merge)

<!-- ✅ EMPTY as of 2026-06-02 — every stabilization gate is APPROVED + merged to dev:
     NEX-CASE-013 (+ PR #160 POS-detail-refresh fix), TAB-CASE-010, TAB-CASE-009, INFRA-CASE-003.
     The staging→main promotion is UNBLOCKED. -->

_(empty — all stabilization gates cleared; promote `dev → staging → main`)_

### Bucket B — Deploy readiness (restaurant rollout prerequisites; NON-gating ops, not code bugs)

<!-- These don't gate the merge but DO gate the actual Pi/restaurant deployment. Run after the relevant code lands. -->
<!-- ▶ Ordered execution sequence: docs/deployment/RELEASE_RUNBOOK_order-id-pos-sync.md (deploy → triggers → POS printer → APK → smoke test). -->
<!-- Code is on `main` (2026-06-02); these are Pi-side ops requiring hardware access. -->
<!-- Pi deploy DECISION: NEX-CASE-013 extended pos:setup-payment-trigger — re-run it on the Pi installs the new order-detail trigger too. -->
<!-- NEX-CASE-001/002: now folded into Step 1 (deploy-all.sh) verification on the Pi.                                                       -->

| Priority | Case ID | App | Description | Tier | Dep | Status | GH |
|---|---|---|---|---|---|---|---|
| P1 | NEX-CASE-011 | woosoo-nexus / POS | **Dual fix — code done, ops pending.** (1) **Code — PR #163 merged 2026-06-04:** removes `PrintOrder::dispatch()` from all `markPrinted` ack paths; adds `is_printed` idempotency guard; closes nex-005 inline. (2) **POS config (Bucket B — ops, on Pi):** confirm `NEXUS_PRINT_EVENTS_ENABLED=true`; disable 3rd-party Krypton printer (BT-only). Case: `nex-case-011-duplicate-order-printing.md` | 3 | none | code-merged; POS config pending (Bucket B) | #140 |
| P1 | NEX-CASE-014 | woosoo-nexus | SESSION_DOMAIN host-binding — COMPLETE 2026-06-05. SESSION_DOMAIN emitted empty; WOOSOO_ENV profile switch (local\|staging\|production) drives APP_ENV/APP_DEBUG/LOG_LEVEL; SESSION_SECURE_COOKIE derives from WOOSOO_SCHEME. Operator step: clear SESSION_DOMAIN in live .env + set WOOSOO_ENV=production + re-run apply-woosoo-config.sh. Case: `nex-case-014-session-domain-login-419.md` | 2 | none | code-merged → dev | — |
| P1 | NEX-CASE-007 (deploy) | woosoo-nexus | Code merged to dev+staging. Run `php artisan pos:setup-payment-trigger` on the Pi POS env; confirm `pos:consume-payment-status-events` scheduler runs | 3 | none | code-landed; Pi step pending | #152 |
| P2 | INFRA-CASE-004 | woosoo-platform | **Re-scoped → one robust deploy command + secure env.** `deploy.sh`/`deploy-all.sh` hardened: retry on git fetch/composer/build, composer hydration (bind-mount vendor gap), tablet UI cache-bust, unbypassable doctor gate; `.env`+backups `chmod 600`; docs collapsed to one config truth (`./woosoo.env` via `init-woosoo-env.sh`); check.sh dedup. Merged platform PR #45 2026-06-06. Case: `infra-case-004-script-flow-unification.md` | 2 | none | merged → dev; Pi runtime = Bucket B | #45 |
| P2 | INFRA-CASE-002 | woosoo-platform | Deploy stability wrappers — Stage A on dev; **Stage B Pi runtime verification pending** | 2 | none | in_progress (verifier:Pi) | — |
| P2 | INFRA-CASE-001 | woosoo-platform | Pi platform-root migration (compose/docker/scripts) — built on dev box, **untested on Pi hardware** | 3 | none | in_progress (specialist:infra) | — |
| P3 | PRN-REBUILD-APK | woosoo-print-bridge | Rebuild Flutter release APK from current repo + SCP/install on Pi tablet | 3 | none | in_progress (verifier) | — |

### Bucket B-follow — Post-promotion correctness (non-gating but should land soon)

<!-- Captured 2026-06-03 from dev-branch audit. Not blocking promotion; should be tracked before Bucket C work begins. -->

| Priority | Case ID | App | Description | Tier | Dep | Status | GH |
|---|---|---|---|---|---|---|---|
| P2 | TAB-CASE-011 | tablet-ordering-pwa | Active-order recovery filter — **COMPLETE 2026-06-07** (landed tablet `dev` PR #199). Case: `tab-case-011-active-order-recovery-filter.md` | 2 | none | complete | — |
| P2 | NEX-CASE-015 | woosoo-nexus | Intent-only device order payload — **COMPLETE 2026-06-07** (merged PR #178 `f3f79d8`). Case: `nex-case-015-tablet-intent-payload-hardening.md` | 2 | none | complete | — |
| P3 | PLT-CASE-EXECUTIONER-SIMPLIFIER-GATE | woosoo-platform | Add reject clause to `executioner.md`: missing `## Code Simplification` without documented reason → REJECTED. Case: `plt-case-executioner-simplifier-gate.md` | 1 | none | queued | — |
| P3 | PLT-CASE-CHAIN-DOC-SYNC | woosoo-platform | Sync `AGENTS.md` inline summary (omits scribe) + `hooks/execute.md` + `PROTOCOL.md` to the 6-step chain. Case: `plt-case-chain-doc-sync.md` | 1 | none | queued | — |

### Bucket C — Deferred (post-stabilization features; do NOT gate any promotion)

| Priority | Case ID | App | Description | Tier | Dep | Status | GH |
|---|---|---|---|---|---|---|---|
| P3 | PLT-CASE-003 | woosoo-platform | Cross-app orchestration — **deferred by priority, not dep-blocked** (DEP-001/002/003 all `confirmed`) | 3 | none (deps confirmed) | deferred | — |
| P3 | KDS-EPIC | woosoo-nexus | Kitchen Display System v1.0 (PR-0A…PR-7). Spec: `docs/cases/kds-implementation-plan.md`. Gate: complete plt-case-stability-remediation Pi ops first | 3 | none | deferred | #137,#143,#144,#145,#146,#147,#148 |
| P3 | — | woosoo-nexus | Device telemetry feature (battery/online detail) | 2 | none | deferred | #152 |
| P3 | — | tablet-ordering-pwa | POS→tablet discount sync & active-order hydration | 2 | none | deferred | #184 |
| P4 | — | woosoo-print-bridge | Exclude side items from print; larger receipt text | 2 | none | deferred | #30 |
| P3 | — | woosoo-platform | Pi Control Panel — local ops/deploy dashboard | 2 | none | deferred | #19 |
| P3 | NEX-CASE-010 | woosoo-nexus | Immutable-image production migration | 3 | none | blocked | — |
| P3 | NEX-CASE-012 | woosoo-nexus | Woosoo Admin UI prototype impl (Tablet Categories + Packages → Vue 3 SFCs) | 2 | none | deferred | — |
| P4 | tablet-screen-ui-ux-review | tablet-ordering-pwa | UI/UX polish — dup table-name, floating support affordance, weak disabled states | 2 | none | blocked (chuya-frontend) | — |

> **Low-priority archival follow-ups** (from `docs/archive/agent-sessions-2026-05.md`; non-gating; no case file):
> - **woosoo-nexus** — `HealthController::check()` duplicates the inline `checkBroadcastingIntegrity()` in `routes/api.php`. It is **NOT** a safe-delete orphan: `MonitoringController.php:41` calls it. Treat only as a future consolidation candidate, with that caller in scope. (Corrects the archived log's "delete route-unbound orphan" claim.)
> - **tablet-ordering-pwa** — Plan D (customer-safe error handling) is **landed** on `dev`: `classifyError()` is wired through every `stores/Order.ts` catch branch. Residual: `components/feedback/ConnectionBlockingOverlay.vue` (Plan D.3) is missing — a UX-completeness item, not a raw-error leak. Add the overlay if/when the connection-blocking UX is prioritized.

---

## Completed (recent — prune after 7 days)

| Case ID | App | Completed | Evidence |
|---|---|---|---|
| TAB-CASE-010 | tablet-ordering-pwa | 2026-06-02 | Canonical `order_id` (setOrderId uses order_id; channel+guard on order_id) + `order.details.updated` handler → `applyDetailsUpdate` (guest_count/total, no recompute) + `preparing`→`in_progress` + doc-comment repoint. typecheck clean; pre-merge-check OK. Executioner APPROVED. Merged to dev (tablet PR #196). |
| NEX-CASE-013 | woosoo-nexus | 2026-06-01 | OrderStatusUpdated + orders.{order_id} channel fix; OrderBroadcaster + BroadcastEvent enum; POS detail triggers + woosoo_order_detail_outbox; pos:consume-order-detail-events; OrderDetailsUpdated. 438/438 tests. Executioner APPROVED. DEP-004 confirmed. **Follow-up PR #160: refreshDetailFromPos re-reads POS values before broadcast (P1 review fix) — 438/1537 green.** |
| TAB-CASE-009 | tablet-ordering-pwa | 2026-06-01 | Silent-death watchdog in useBroadcasts.ts: 30s tick, 180s threshold, touchLastEvent() on all 7 handlers. 73 files / 408 tests pass, typecheck+lint clean. Executioner APPROVED. |
| INFRA-CASE-003 | tablet-ordering-pwa + woosoo-nexus | 2026-06-01 | `.npmrc` (fetch-retries=5, fetch-timeout=600s) + tablet Dockerfile COPY fix. docker build exit 0; npm config verified inside image. Executioner APPROVED. Pi wlan0 test is Bucket B deploy-gate. |
| NEX-CASE-005 | woosoo-nexus | 2026-05-31 | Closed **OBE** (not Executioner — cannot-reproduce class). Root-caused jointly with #011: the legacy "non-idempotent print event path" warning string no longer exists in code; print-event creation is idempotent (`idempotency_key` unique, reuse-on-match). Narrow residual (`Str::uuid()` fallback when tablet omits `client_submission_id`) is guarded by 409/refill-guard; not pursued. Removed from Bucket A |
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
