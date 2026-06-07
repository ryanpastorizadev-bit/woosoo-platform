---
status: canonical
scope: ecosystem
---

# Verified Completions

<!-- Append-only log of tasks that have passed Verifier and received Executioner APPROVED.        -->
<!-- When this file exceeds 30 rows: move entries older than 30 days to docs/archive/DONE_ARCHIVE.md -->
<!-- Last pruned: 2026-05-17                                                                       -->

---

| Case ID | App | Completed | Verification Evidence | Executioner Verdict | Related Dep | Notes |
|---|---|---|---|---|---|---|
| TAB-CASE-011 | tablet-ordering-pwa | 2026-06-07 | Recovery filter five-status param; `active-order-recovery-status-filter.spec.ts` 2 PASS (re-verified); typecheck PASS. PR #199 open (`a2644cd`) — merge to `dev` pending. | APPROVED | none | Clears KDS plan tablet blocker; Pi stability still gates KDS backend. |
| NEX-CASE-016 | woosoo-nexus | 2026-06-07 | `6293bd2` mock KDS UI; `KdsDisplayTest` 3/15 PASS (re-verified 2026-06-07); typecheck/lint/build + pre-merge-check OK per case. Tab A11+ device QA pending. | APPROVED | none | UI-only `/kds` — no backend writes, enum, or Echo. README also in commit (out of case scope). |
| PLT-CASE-011 | woosoo-platform | 2026-06-07 | `12313ad` PRE_EDIT + POST_EDIT hooks; execute.md gates; USAGE_GUIDE + woosoo.mdc; hook existence re-verified. | APPROVED | none | Phase 1 specialist gates; Phase 2 audit playbooks deferred. |
| PLT-CASE-ECOSYSTEM-DOCS-ACCURACY | woosoo-platform | 2026-06-07 | Docs-only gate: 8/8 truth checks PASS; stale-phrase scan clean on canonical set; compose 8 services + `NEXUS_PRINT_EVENTS_ENABLED` default false confirmed in source; commit `0574efe` on dev. | APPROVED | none | Ecosystem concept accuracy → `WOOSOO_ECOSYSTEM_OVERVIEW.md`, root README, AI_CONTEXT, sibling READMEs, portal README. |
| INFRA-CASE-008 | woosoo-platform | 2026-06-07 | `9ec1502` on dev: switch-network config path parity, init-woosoo-env HOME_/RESTO_ secrets, preflight recreate+clear + .env.docker drift WARN, check.sh WSL hints, DEPLOYMENT_GUIDE §3.6/§4.1.3. Verifier: `bash -n` ×7 PASS; 8/8 claims verified. | APPROVED | none | Deployment env audit remediation. No app-repo changes. |
| INFRA-CASE-007 | woosoo-platform | 2026-06-07 | WSL POS host fix in `9ec1502`: bootstrap LAN IP default, host-network POS check/fix, dev-preflight §1c, pipeline health probe, DEPLOYMENT_GUIDE §4.1.2. Verifier PASS (shared gate with infra-case-008). | APPROVED | none | WSL admin `/pos` Connection refused on host.docker.internal. Operator: set DB_POS_PASSWORD + recreate. |
| NEX-CASE-013 | woosoo-nexus | 2026-06-01 | Channel fix: OrderStatusUpdated + orders.{order_id} (silent-drop regression guard). Broadcast layer: OrderBroadcaster + BroadcastEvent enum. POS detail sync: triggers (orders.guest_count + order_checks totals) + woosoo_order_detail_outbox + pos:consume-order-detail-events + OrderDetailsUpdated. 6 new tests (20 assertions) green; 438/438 full suite. | APPROVED | DEP-004 | Provides order.details.updated event. DEP-004 → confirmed. TAB-CASE-010 now unblocked. |
| TAB-CASE-009 | tablet-ordering-pwa | 2026-06-01 | `useBroadcasts.ts` watchdog (30s tick, 180s threshold); `touchLastEvent()` wired to all 7 event handlers + cancelReconnection(); 4 regression-lock tests (zombie/active/not-connected/cleanup); npm run typecheck exit 0; lint 0 errors; 408/408 tests pass | APPROVED | none | WS silent-death detector. Additive to TAB-CASE-001/002 reconnection. Follow-ups: prod threshold tuning + `(window as any)` typing. |
| NEX-CASE-007 | woosoo-nexus | 2026-05-21 | POS-local order/session outbox implemented; per-order SessionReset blast-radius removed; authenticated-device last_seen_at refresh middleware added (case file Run State: COMPLETE, Executioner APPROVED, runner codex) | APPROVED | none | Merged to remote dev; deploy still requires `php artisan pos:setup-payment-trigger` on the Pi/POS-connected environment. Backend half of GH #152. |
| NEX-CASE-002 | woosoo-nexus | 2026-05-30 | Pulse routes cannot-reproduce; PulseRouteAuthTest gating test added; 432 tests pass; pre-merge-check OK | APPROVED | none | Cannot-reproduce + contract-lock test |
| PLT-CASE-002 | woosoo-platform | 2026-05-17 | Stale-phrase scan no matches; 9 hooks exist; Verifier before Executioner confirmed | APPROVED | none | Canonical hook surface completed |
| PLT-CASE-001 | woosoo-platform | 2026-05-17 | Forbidden-phrase scan no matches; reversed chain-order scan no matches; 9 hooks True; zero app code in commits 5ea33b8/ba92667/11111e9; boot order case-before-cache | APPROVED | none | Orchestration system implementation closed (Verifier PASS, resumed by claude-code) |
| PLT-CASE-004 | woosoo-platform | 2026-05-17 | Documentation-truth scans pass; no live "not a git repo"/"runs on main"/"102 passed" assertion in 8 in-scope files; zero app code; .windsurf excluded; one out-of-scope same-class defect flagged not edited | APPROVED | none | Review remediation — git-repo/branch/print-bridge/README/nex-case-001/.windsurf truth fixes |
| PLT-CASE-005 | woosoo-platform | 2026-05-17 | Stale-phrasing grep over .claude/agents/ no matches; corrected git-repo wording present at ranpo-backend.md:54; zero app code; sibling repos untouched | APPROVED | none | Closed PLT-CASE-004 follow-up — agent-def git-repo wording truth fix |
| TAB-CASE-005 | tablet-ordering-pwa | 2026-05-19 | typecheck exit 0, lint 0 errors, nuxt build exit 0; 2 files changed (PackageCard.vue + packageSelection.vue); 9 changes applied | APPROVED | none | Package card delta v2: tap→select, white title, description-as-tagline, View label, italic heading, uppercase inspector CTA, summary opacity |
| NEX-CASE-003 | woosoo-nexus | 2026-05-19 | php artisan test --filter=OrderRepositoryTest 3/3 (9 assertions); full suite 398/398 (1386 assertions); dashboard routes confirmed registered; Eloquent inline replaces proc, env() removed, test bypass removed | APPROVED | none | Missing stored procedure — OrderRepository Eloquent inline fix; is_open filter; Collection return type; Dashboard.vue empty-state |
| TAB-CASE-006 | tablet-ordering-pwa | 2026-05-20 | typecheck exit 0; eslint pages/menu.vue 0 errors 0 warnings; build Nitro exit 0; one-line fix confirmed | APPROVED | none | Menu meats filtering: :meats="decorateMeats" wired to grouped-meats-list; decorateMeats was computed correctly but bypassed by v-else-if branch |
| NEX-CASE-004 | woosoo-nexus | 2026-05-20 | php artisan test --filter DeviceAuthApiControllerTest: 6 passed (25 assertions); safeLoadDeviceTable() catches Throwable from POS connection; authenticate() returns 200 + null table when POS is down | APPROVED | PLT-CASE-008 | Device login 500: uncaught QueryException from table()->first() on POS connection; fixed with try/catch null-fallback; zero test coverage gap closed |
| NEX-CASE-006 | woosoo-nexus | 2026-05-20 | HealthBroadcastingTest (143 lines) + VerifyIntegrityCommandTest (128 lines); /api/health broadcasting key/config consistency; VerifyIntegrityCommand artisan command; merged to staging via PR #120 | APPROVED (retrospective) | none | Broadcast integrity check — was QUARANTINE branch; retrospectively closed |
| PLT-CASE-008 | woosoo-platform | 2026-05-20 | PROTOCOL.md + docs multi-repo terminology corrected; apply-woosoo-config.sh require_var guards + REVERB_HOST=reverb; PR #10 merged | APPROVED | none | GitHub Issue #9 P1 remediation — multi-repo terminology + deploy script hardening |
| PLT-CASE-009 | woosoo-platform | 2026-05-19 | REVERB_HOST set_env corrected to Docker service DNS `reverb`; single set_env/no duplicate checks green; woosoo-nexus full suite 398 passed (1386 assertions) | APPROVED | none | Docker MySQL/Redis code case closed; Pi logs/health checks remain post-deploy operational follow-up |

---
<!--
APPEND FORMAT:
| <CASE-ID> | <app> | <YYYY-MM-DD> | <what was tested and confirmed — one line> | APPROVED | <DEP-NNN or none> | <optional note> |

Only add rows after the Executioner returns APPROVED.
Do not add rows for REJECTED tasks — those go back to in_progress in state/QUEUE.md.

PRUNE RULE: When row count > 30, move rows with completed date older than 30 days to docs/archive/DONE_ARCHIVE.md.
Keep the last 30 rows here for quick reference.
-->
