---
status: canonical
last_reviewed: 2026-06-14
scope: ecosystem
---

# Case Registry (summarized wikilink index)

**114 cases** · 91 complete · 21 active/blocked. Auto-generated summary of every case file in docs/cases/; full files remain the durable audit trail (see RESUME_PROTOCOL). Regenerate: scripts/obsidian-case-registry.ps1.

Hub: [[OPERATOR_HOME]] · Dashboard: [[CASE_DASHBOARD]] · Bases: [[CASES.base|CASES.base]] · Index: [[CASE_INDEX]] · Contracts: [[CONTRACTS_HUB]] · Vault: [[VAULT_INDEX]]

## Nexus (`nex-case-*`)

| Case | Status | Updated | Summary |
|------|--------|---------|---------|
| [[nex-case-001-security-auth-hardening]] | ✅ COMPLETE | 2026-05-18 | Tier 3 security and authentication hardening for woosoo-nexus to address critical audit findings before any feature w… |
| [[nex-case-002-pulse-routes]] | ✅ COMPLETE | 2026-05-30 | Laravel Pulse routes broken — errors observed in production logs. |
| [[nex-case-003-missing-stored-procedure]] | ✅ COMPLETE | 2026-05-19 | Production order retrieval broken — get_open_orders_for_session stored procedure missing on POS DB. |
| [[nex-case-004-device-login-500]] | ✅ COMPLETE | 2026-05-20 | Device login endpoint (POST /api/devices/login) returns HTTP 500 in production. |
| [[nex-case-005-legacy-print-path]] | ✅ COMPLETE | 2026-05-31 | Order submission hitting legacy non-idempotent print event path in production — client_submission_id absent from requ… |
| [[nex-case-006-broadcast-integrity]] | ✅ COMPLETE | 2026-05-20 | Broadcasting integrity check — /api/health Reverb key/config consistency + VerifyIntegrityCommand artisan command. |
| [[nex-case-007-pos-payment-outbox-session-reset]] | ✅ COMPLETE | 2026-05-21 | Tablet devices remain on the in-session screen until Nexus dispatches terminal order/session reset events. Current PO… |
| [[nex-case-008-transient-token-refresh-guard]] | ✅ COMPLETE | 2026-05-23 | POST /api/devices/refresh and POST /api/devices/logout crash with |
| [[nex-case-009-admin-menus-filters]] | ✅ COMPLETE | 2026-05-23 | MenuController@index returns course, group, category, is_available, and has_uploaded_image for every menu row, but th… |
| [[nex-case-010-immutable-image-production-migration]] | ⛔ BLOCKED | 2026-05-31 | Track (do NOT yet implement) the migration to immutable production images so served assets come |
| [[nex-case-011-duplicate-order-printing]] | code-complete | 2026-06-05 | Client reports submitted orders printing on BOTH the Bluetooth printer and the 3rd-party POS |
| [[nex-case-012-admin-ui-prototype-impl]] | ✅ COMPLETE | 2026-06-12 | > **CLOSED — Superseded.** Deliverable 3 (Vue SFCs for Packages and Tablet Categories) was |
| [[nex-case-013-pos-order-detail-sync]] | ✅ COMPLETE | 2026-06-01 | Canonicalize the order identifier on order_id and add a POS→device live order-detail sync: |
| [[nex-case-015-tablet-intent-payload-hardening]] | ✅ COMPLETE | 2026-06-07 | StoreDeviceOrderRequest (app/Http/Requests/StoreDeviceOrderRequest.php) currently accepts |
| [[nex-case-016-kds-ui-only]] | ✅ COMPLETE | 2026-06-07 | Kitchen needs an early visual KDS surface for a Samsung Galaxy Tab A11+ target before production feed/write integrati… |
| [[nex-case-017-refill-intent-payload-hardening]] | ✅ COMPLETE | 2026-06-09 | RefillOrderRequest.php:64 allows items.*.price as a nullable/numeric field. |
| [[nex-case-018-kds-fullscreen-hardening]] | ✅ COMPLETE | 2026-06-09 | Display.vue IS coded for fullscreen (100dvw × 100dvh, no AppLayout wrapper, no letterbox). |
| [[nex-case-019-debug-endpoint-hardening]] | ✅ COMPLETE | 2026-06-09 | routes/api.php:378 returns 'Stored procedure call failed: '.$e->getMessage() when the POS |
| [[nex-case-020-admin-ui-audit-fixes]] | ✅ COMPLETE | 2026-06-10 | A 24-item UI/UX + functionality audit across the woosoo-nexus admin panel (POS, Devices, Tablet Categories, Package C… |
| [[nex-case-021-pos-connection-hardening]] | ✅ COMPLETE | 2026-06-09 | GET /pos returned a raw 500 QueryException when the pos connection used krypton_readonly with an empty password (usin… |
| [[nex-case-022-nexus-full-review]] | ✅ COMPLETE | 2026-06-12 | Operator requested a full-stack review of woosoo-nexus: all admin features/pages, backend logic, bugs, edge cases, an… |
| [[nex-case-024-kds-workflow]] | ✅ COMPLETE | 2026-06-10 | Kitchen Display used a 4-step workflow (New → Preparing → Ready → Served) with local-only state mutation (no backend… |
| [[nex-case-025-admin-shell-migration]] | ✅ COMPLETE | 2026-06-10 | The STEP 1 partial shadcn sidebar implementation does not match the spec: |
| [[nex-case-026-kds-visual-polish]] | ✅ COMPLETE | 2026-06-12 | CSS-only KDS visual polish: overdue pulse, item-done affordance, readability tweaks, and dead .is-recall removal. One… |
| [[nex-case-027-admin-pages-ui-redesign]] | ✅ COMPLETE | 2026-06-12 | Admin pages (Orders, POS, Packages, Dining Tiers, Menu Sync, Devices) needed presentational redesign aligned with nex… |
| [[nex-case-028-admin-ui-handoff-completion]] | ✅ COMPLETE | 2026-06-12 | > Continues from nex-case-012 (superseded) and nex-case-027 (6-page redesign). |
| [[nex-case-029-kds-action-payload-optimistic]] | ✅ COMPLETE | 2026-06-12 | KDS advance / recall / toggleItem endpoints returned only { status } (or { done, done_at } for toggle). The board onl… |
| [[nex-case-030-kds-server-authoritative-time]] | ✅ COMPLETE | 2026-06-14 | > KDS P3 closeout. Two rounds on one branch: (1) server-authoritative elapsed time so |
| [[nex-case-031-admin-functional-gap-fill]] | 🟡 IN_PROGRESS | 2026-06-13 | > Functional checklist gap-fill for Laravel/Vue admin console. React prototype handoff ignored; real app is target. |
| [[nex-case-032-packages-dining-tier-consolidation]] | 🟡 IN_PROGRESS | 2026-06-13 | > Schema-level completion of the packages consolidation begun in PR #200. Gives the canonical |

## Tablet (`tab-case-*`)

| Case | Status | Updated | Summary |
|------|--------|---------|---------|
| [[tab-case-001-order-session-determinism]] | ✅ COMPLETE | 2026-05-19 | Order submission and session consistency fixes for tablet-ordering-pwa to address critical determinism issues. |
| [[tab-case-002-validated-review-followups]] | ✅ COMPLETE | 2026-05-19 | Validated follow-up work from a fact-checked review of tablet-ordering-pwa. |
| [[tab-case-003-pwa-kiosk-stale-shell]] | ✅ COMPLETE | 2026-05-18 | Tablet PWA kiosk stale-shell auto-update fix |
| [[tab-case-004-build-info-prerender]] | ✅ COMPLETE | 2026-05-19 | /build-info.json is the PWA update backstop: the service worker and useAppUpdate composable |
| [[tab-case-005-package-card-delta-v2]] | ✅ COMPLETE | 2026-05-19 | Align PackageCard.vue and packageSelection.vue to reference design (classic feast.png): |
| [[tab-case-006-menu-meat-filtering]] | ✅ COMPLETE | 2026-05-19 | Menu screen Meats category shows all items as active/selectable regardless of selected package. |
| [[tab-case-007-table-changed-sync]] | ✅ COMPLETE | 2026-05-23 | Stale-sync gap: the backend dispatches AppControlEvent with action: "table_changed" whenever an admin reassigns or un… |
| [[tab-case-008-begin-feast-token-refresh-fallback]] | ✅ COMPLETE | 2026-05-25 | Tapping "Begin the Feast" could block when the tablet had a stale persisted token. stores/Session.ts::start() attempt… |
| [[tab-case-009-broadcast-silent-death-detector]] | ✅ COMPLETE | 2026-05-31 | The tablet's Echo/Reverb WebSocket can enter a "connected-but-dead" (zombie) state: the client |
| [[tab-case-010-canonical-order-id-and-detail-sync]] | ✅ COMPLETE | 2026-06-02 | Make the tablet use the canonical POS order_id consistently, and consume the new |
| [[tab-case-011-active-order-recovery-filter]] | ✅ COMPLETE | 2026-06-07 | The tablet active-order recovery filter at stores/Order.ts (~line 807) queries only |
| [[tab-case-012-settings-diagnostic-hardening]] | ✅ COMPLETE | 2026-06-09 | pages/settings.vue:1176 renders raw testOrderError text in a <pre> block inside the |

## Print bridge (`prn-*`)

| Case | Status | Updated | Summary |
|------|--------|---------|---------|
| [[prn-case-001-print-determinism]] | ✅ COMPLETE | 2026-05-18 | Print job determinism and reliability fixes for woosoo-print-bridge to address critical print reliability issues. |
| [[prn-case-002-queue-retention-cleanup]] | ✅ COMPLETE | 2026-05-18 |  |
| [[prn-case-003-pr11-review-comments]] | ✅ COMPLETE | 2026-05-19 | PR #11 review comments on the print bridge staging branch need source-verified remediation. |
| [[prn-case-004-error-message-normalization]] | ✅ COMPLETE | 2026-06-09 | lib/ui/screens/queue_screen.dart:146,395 display raw $e exception objects in operator UI. |
| [[prn-rebuild-apk-scp-pi]] | 🟡 IN_PROGRESS | 2026-05-21 | Rebuild the Flutter Android release APK for the print bridge from the current repository state and |
| [[prn-review-staging-build]] | ✅ COMPLETE | 2026-05-20 | Review the woosoo print bridge repository state, pull staging if the remote branch has new |

## Platform (`plt-case-*`)

| Case | Status | Updated | Summary |
|------|--------|---------|---------|
| [[plt-case-001-orchestration-system]] | ✅ COMPLETE | 2026-05-17 | The woosoo-platform orchestration system lacks: |
| [[plt-case-002-hook-surface-completion]] | ✅ COMPLETE | 2026-05-17 | PLT-CASE-001 repaired the canonical protocol but intentionally left the full hook surface as follow-up work. Only hoo… |
| [[plt-case-003-cross-app-orchestration]] | 🟡 IN_PROGRESS | 2026-05-25 | Cross-app orchestration and observability work to be executed after single-app fixes are complete and contracts are f… |
| [[plt-case-004-review-remediation]] | ✅ COMPLETE | 2026-05-17 | The post-implementation review of the orchestration system found documentation-truth defects: |
| [[plt-case-005-agent-def-git-truth]] | ✅ COMPLETE | 2026-05-17 | .claude/agents/ranpo-backend.md:54 instructs the Ranpo Backend specialist that the repo |
| [[plt-case-006-docker-orchestration-root]] | ✅ COMPLETE | 2026-05-18 | Lift Docker orchestration to the platform repo root, fix tablet UI iteration & |
| [[plt-case-007-risk-assessment-challenge]] | ✅ COMPLETE | 2026-05-19 | Contrarian challenge of the Risk Probability Breakdown assessment for tablet-ordering-pwa. |
| [[plt-case-008-gh-issue-9-p1-remediation]] | ✅ COMPLETE | 2026-05-25 | GitHub Issue #9 "Review Critic" identified five P1 (critical) remediation items: |
| [[plt-case-009-docker-mysql-redis]] | ✅ COMPLETE | 2026-05-25 | Docker mysql and redis services not resolving — probable infrastructure root cause for Reverb broadcast failures and… |
| [[plt-case-010-context7-cursor-guide]] | 🟡 IN_PROGRESS | 2026-06-08 | Document how operators use the Context7 MCP plugin in Cursor for up-to-date library documentation. |
| [[plt-case-011-specialist-gates]] | ✅ COMPLETE | 2026-06-07 | Add PRE_EDIT_GATE and POST_EDIT_REVIEW as Specialist-phase gates wired into the execute hook. |
| [[plt-case-agent-tooling-audit]] | ✅ COMPLETE | 2026-06-11 | Platform Agent Tooling Audit — read-only snapshot of agent OS, skill libraries, brainstorming gate, Cursor layer, Obs… |
| [[plt-case-app-audit-nexus-folders]] | ✅ COMPLETE | 2026-05-20 | Audit woosoo-nexus/ for docs and folders that appear outdated, unused, orphaned, duplicated, or otherwise no longer r… |
| [[plt-case-app-audit-platform-docs]] | ✅ COMPLETE | 2026-05-20 | Audit platform-level docs and governance folders for docs and folders that appear outdated, unused, orphaned, duplica… |
| [[plt-case-app-audit-relay-folders]] | ✅ COMPLETE | 2026-05-20 | Audit woosoo-print-bridge/ for docs and folders that appear outdated, unused, orphaned, duplicated, or otherwise no l… |
| [[plt-case-app-audit-tablet-folders]] | ✅ COMPLETE | 2026-05-20 | Audit tablet-ordering-pwa/ for docs and folders that appear outdated, unused, orphaned, duplicated, or otherwise no l… |
| [[plt-case-chain-doc-sync]] | 🟡 IN_PROGRESS | 2026-06-08 | Sync three platform docs to the updated 6-step agent chain: AGENTS.md inline summary (omits scribe), hooks/execute.md… |
| [[plt-case-ecosystem-docs-accuracy]] | ✅ COMPLETE | 2026-06-07 | Apply ecosystem concept accuracy fixes across platform and sibling README files. |
| [[plt-case-executioner-simplifier-gate]] | 🟡 IN_PROGRESS | 2026-06-08 | Make the Executioner reject when ## Code Simplification or ## Hygiene audit lines are missing or skipped without a do… |
| [[plt-case-governance-hardening-2026-06-08]] | ✅ COMPLETE | 2026-06-09 | Consolidated platform-governance hardening combining three intertwined workstreams that were |
| [[plt-case-hygiene-gates]] | ✅ COMPLETE | 2026-06-08 | Formalise code-simplifier as a checkpointed chain phase; dead-code-cleanup runs as its internal final sub-step. |
| [[plt-case-non-complete-audit-2026-06-08]] | 🟡 IN_PROGRESS | 2026-06-08 | Accuracy audit of every **non-COMPLETE** case file in docs/cases/. For each case the audit |
| [[plt-case-obsidian-dataview-hardening]] | 🟡 IN_PROGRESS | 2026-06-10 | Follow-up to [[plt-case-obsidian-operator-wiring]] — operator reported empty Dataview tables and |
| [[plt-case-obsidian-operator-wiring]] | ✅ COMPLETE | 2026-06-08 | Wire Obsidian into the agent boot layer as the operator UI (same files, richer navigation). |
| [[plt-case-obsidian-orchestration-wiring]] | 🟡 IN_PROGRESS | 2026-06-14 | The agent orchestration workflow treats Obsidian as a human-only UI. hooks/work.md Step 0b |
| [[plt-case-stability-remediation]] | 🟡 IN_PROGRESS | 2026-06-08 | Platform orchestration plan: stabilize the restaurant stack on the Pi **before** starting KDS |
| [[plt-case-vault-audit-live-2026-06-14]] | 🟡 IN_PROGRESS | 2026-06-14 | docs/CASE_AUDIT_2026-05-18.md is a static point-in-time snapshot (11 cases, dated 2026-05-18) now |
| [[plt-case-vault-doc-automation]] | ✅ COMPLETE | 2026-06-10 | Widespread vault doc staleness with no single operator-runnable hygiene entry-point. |

## Infra numbered (`infra-case-*`)

| Case | Status | Updated | Summary |
|------|--------|---------|---------|
| [[infra-case-001-pi-platform-migration]] | 🟡 IN_PROGRESS | 2026-05-20 | The Pi currently runs Woosoo from the old single-repo model (woosoo-nexus/ as compose root). |
| [[infra-case-002-deploy-stability-wrappers]] | 🟡 IN_PROGRESS | 2026-05-25 | Deployment from woosoo-platform/ works but has five stability gaps that will bite under pressure: |
| [[infra-case-003-pi-docker-build-npm-ci-wifi]] | ✅ COMPLETE | 2026-06-01 | docker compose up -d --build from /opt/woosoo/woosoo-platform/ fails consistently on the |
| [[infra-case-004-script-flow-unification]] | ✅ COMPLETE | 2026-06-05 | > **Re-scoped 2026-06-05** from "doc/dedup cleanup" to **one robust deploy command + |
| [[infra-case-005-local-pipeline-runner]] | 🟡 IN_PROGRESS | 2026-06-08 | No single command exists for a dev test deploy. After dev-docker-bootstrap.sh completes, the |
| [[infra-case-006-dynamic-lan-host]] | 🟡 IN_PROGRESS | 2026-06-06 | Unified Pi + WSL PUBLIC_HOST / LAN access via scripts/lib/host-network.sh and |
| [[infra-case-007-wsl-pos-db-host]] | ✅ COMPLETE | 2026-06-07 | WSL dev admin POS pages fail with Connection refused on pos DB connection because |
| [[infra-case-008-deployment-env-audit]] | ✅ COMPLETE | 2026-06-07 | Read-only deployment audit remediation: unify operator config paths, document three POS/Reverb |
| [[infra-case-009-deploy-script-hardening]] | 🟡 IN_PROGRESS | 2026-06-07 | Post-audit hardening for Pi deployment scripts: config guard parity, deploy readiness |
| [[infra-case-010-wsl-lan-bridge-runbook]] | ✅ COMPLETE | 2026-06-09 | WSL2 Docker dev stack healthy inside VM but https://192.168.100.7 unreachable from Windows/LAN |

## Infra other (`infra-*`)

| Case | Status | Updated | Summary |
|------|--------|---------|---------|
| [[infra-vite-build-conditional]] | ✅ COMPLETE | 2026-05-30 | Stabilize the Vite asset build so public/build is rebuilt only when needed, not on every |

## Other / intake / audits

| Case | Status | Updated | Summary |
|------|--------|---------|---------|
| [[deployment-codebase-review]] | ✅ COMPLETE | 2026-06-04 | Review the Woosoo platform codebase for deployment issues, missing configuration, and gaps that could hinder smooth D… |
| [[dev-branch-markdown-stabilization-audit-review]] | ✅ COMPLETE | 2026-06-06 | Review the pasted "Dev Branch Markdown Stabilization Audit" plan review against the current source tree and identify… |
| [[HANDOFF-infra-vite-build-conditional]] | - | - | Complete, copy-paste-ready implementation instructions for the infra Specialist. |
| [[kds-implementation-plan]] | 🟡 IN_PROGRESS | 2026-06-11 | Kitchen Display System (KDS) implementation spec for woosoo-nexus. **Deferred** until |
| [[kds-p2-recall]] | ✅ COMPLETE | 2026-06-12 | KDS P2 recall: add served → in_progress recall edge so kitchen staff can re-fire a served order without voiding it. I… |
| [[nex-coderabbit-inline-review-2026-05-22]] | ✅ COMPLETE | 2026-05-22 | CodeRabbit AI left 11 numbered inline comments and 4 nitpick comments on recent PRs. Each needed verification against… |
| [[nexus-colors-backgrounds-fonts]] | ✅ COMPLETE | 2026-05-25 | Nexus needed the approved first UI foundation pass for colors, backgrounds, and fonts. During validation, the require… |
| [[nexus-ui-handoff-visual-implementation]] | ✅ COMPLETE | 2026-06-12 | > **CLOSED — Superseded by [[nex-case-028-admin-ui-handoff-completion]].** The handoff brand-alignment work scoped he… |
| [[nexus-vite-entrypoint-rebuild]] | ✅ COMPLETE | 2026-05-30 | PR comment on woosoo-nexus/docker/docker-entrypoint.sh: the current entrypoint skips npm run build when public/build… |
| [[pi-docker-runtime-diagnostics]] | ✅ COMPLETE | 2026-05-22 | The Raspberry Pi deployment needs production-ready diagnostics that enforce the Docker-only runtime model and catch R… |
| [[pld-cli-hardening]] | ✅ COMPLETE | 2026-06-08 | Four MEDIUM hardening gaps in the pld CLI: |
| [[pr-40-staging-review-findings]] | ✅ COMPLETE | 2026-06-05 | The user requested verification of PR #40 staging review findings before accepting the review. |
| [[prepare-document-context]] | ✅ COMPLETE | 2026-06-04 | The workspace needed a clear, concise root context document for woosoo-platform, |
| [[printed-order-incorrect-time]] | ✅ COMPLETE | 2026-05-25 | Fix paper receipt order time rendering so UTC backend timestamps display as the Android |
| [[public-user-manual-product-spec-look]] | ✅ COMPLETE | 2026-05-30 | The public user manual had the correct content and safe screenshots, but its page styling still felt like a general h… |
| [[public-user-manual-screenshots]] | ✅ COMPLETE | 2026-05-26 | The public user manual explained Nexus and tablet navigation in text, but it did not yet use the real screenshots sup… |
| [[public-user-manual-tablet-screenshots]] | ✅ COMPLETE | 2026-05-26 | The public user manual has Nexus screenshots, but the Tablet Ordering PWA section still needs visual screen guidance… |
| [[public-user-manual-welcome-page]] | ✅ COMPLETE | 2026-05-26 | The public host welcome page only provides certificate setup. Restaurant staff need a safe public user manual for nav… |
| [[redesign-woosoo-nexus-login-page]] | ⛔ BLOCKED | 2026-06-01 | The Nexus login page should be redesigned to match the Woosoo Admin dark warm operations look: near-black surfaces, w… |
| [[replace-in-session-timer-copy]] | ✅ COMPLETE | 2026-05-25 | The customer-facing /order/in-session timer pill displayed Active · ~N min remaining, but the current tablet code mea… |
| [[resolve-staging-main-merge-conflicts]] | ✅ COMPLETE | 2026-05-19 | Resolve the in-progress merge of origin/main into staging for woosoo-print-bridge without dropping either PRN-CASE-00… |
| [[switch-network-reverb-host-drift]] | ✅ COMPLETE | 2026-05-22 | The Pi-home switch reported public_host=192.168.100.42, but the actual .env still contained stale browser-facing values: |
| [[tablet-package-ui-documentation-cleanup]] | ✅ COMPLETE | 2026-05-18 | The merged tablet package-selection UI changed the active customer flow from direct package selection to a meat-previ… |
| [[tablet-package-ui-redesign]] | ✅ COMPLETE | 2026-05-19 | Restyle PackageCard.vue and packageSelection.vue to match reference designs. Add card |
| [[tablet-screen-ui-ux-review]] | ⛔ BLOCKED | 2026-05-20 | Review the tablet-ordering PWA screens for UI/UX inconsistencies and counter-intuitive non-blocking elements, includi… |
| [[woosoo-cloud-portal-sync-plan-review]] | ✅ COMPLETE | 2026-06-04 | Review the proposed Woosoo Cloud Portal local sync module plan for woosoo-nexus, focusing on data correctness, contra… |
| [[woosoo-software-development-documentation-package]] | ✅ COMPLETE | 2026-06-02 | The existing handover manual is useful for restaurant operations, but the project also needs a proper software develo… |

