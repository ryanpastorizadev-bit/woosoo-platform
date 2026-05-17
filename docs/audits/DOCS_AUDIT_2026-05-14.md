---
status: canonical
last_reviewed: 2026-05-14
scope: ecosystem
---

# Documentation Audit — 2026-05-14

This is the audit trail for the documentation cleanup pass. Every in-scope markdown file across the Woosoo monorepo is listed below with a proposed classification and action. Per the approved plan, **no files are deleted**; this pass is archive-only and reversible.

Classifications:

- **canonical** — current source of truth (`status: canonical` frontmatter)
- **under-review** — not yet finalized (`status: under-review`)
- **supporting** — useful reference; kept in place without canonical frontmatter
- **archive** — superseded; moved to `<scope>/docs/archive/2026-05/` with archived frontmatter
- **already-archived** — already under a `docs/archive/` directory; left in place
- **out-of-scope** — vendor / node_modules / dependency README; not touched

The `Action` column reflects what was done in the 2026-05-14 pass.

## Platform root (`E:\Projects\woosoo-platform\`)

| Path | Classification | Action | Notes |
|---|---|---|---|
| `AGENTS.md` | canonical | Created 2026-05-14 | Ecosystem boot rules |
| `CLAUDE.md` | canonical | Created 2026-05-14 | Claude Code instructions |
| `.github/copilot-instructions.md` | canonical | Created 2026-05-14 | Ecosystem-wide Copilot guardrails |
| `docs/AI_CONTEXT.md` | canonical | Created 2026-05-14 | On-demand business/architecture context |
| `docs/README.md` | canonical | Created 2026-05-14 | Documentation index |
| `docs/WOOSOO_ECOSYSTEM_ENGINEERING_REVIEW_2026-05-14.md` | canonical | Frontmatter added; restructured | One of the four canonical audits |
| `docs/WOOSOO_ROADMAP_REVIEW.md` | under-review | Frontmatter added (`status: under-review`); body untouched | Per user instruction, body needs separate thorough check |
| `docs/audits/DOCS_AUDIT_2026-05-14.md` | canonical | This file | Audit trail |

## woosoo-nexus root (`woosoo-nexus/`)

| Path | Classification | Action | Notes |
|---|---|---|---|
| `.agents.md` | canonical | Frontmatter added | Per-app scope rules (kept as-is) |
| `.ai-context.md` | canonical | Frontmatter added | Pointer to docs/INDEX.md |
| `README.md` | supporting | Frontmatter not added | Standard Laravel repo readme |
| `CHANGELOG.md` | supporting | No change | Generated changelog |
| `CONTRIBUTING.md` | supporting | No change | Contributor guide |
| `WORKSTREAM_DELEGATION_PROMPT.md` | archive | Moved to `docs/archive/2026-05/` | One-off AI delegation prompt, superseded by root `AGENTS.md` |
| `krypton_woosoo_specs.md` | supporting | No change | Vendor POS spec; keep accessible at repo root |

## woosoo-nexus/docs/

| Path | Classification | Action | Notes |
|---|---|---|---|
| `INDEX.md` | canonical | Frontmatter added | Nexus docs index |
| `AGENT_WORKFLOWS.md` | canonical | Frontmatter added | Active workflow guide |
| `AGENT_REVIEW_PROMPT.md` | supporting | No change | Review prompt template |
| `WOOSOO_NEXUS_STABILIZATION_AND_HARDENING_AUDIT_2026-05-14.md` | canonical | Restructured + frontmatter | One of the four canonical audits |
| `END_TO_END_WORKFLOW.md` | supporting | No change | End-to-end flow reference |
| `SCRIPTS_REFERENCE.md` | supporting | No change | Scripts catalog |
| `API_CONTRACT_SYNC.md` | supporting | No change | Active contract sync doc |
| `API_CONTRACT_RESOLUTION_2026-05-10.md` | supporting | No change | Recent (pre-audit) contract resolution; keep for traceability |
| `IMPLEMENTATION_PLAN_SERVER_AUTHORITATIVE_ORDER_TRANSACTION_2026-05-09.md` | supporting | No change | Implementation plan; keep for traceability |
| `LONG_TERM_REQUIREMENTS_2026-05-09.md` | supporting | No change | Requirements snapshot |
| `REVIEW_FINDINGS_2026-05-09.md` | supporting | No change | Findings snapshot |
| `DEVICE_REGISTRATION_IDENTITY_AND_IP_POLICY_2026-04-25.md` | supporting | No change | Active policy doc |
| `SESSION_REDIRECT_AND_SERVICE_REQUEST_POSTMORTEM_2026-04-24.md` | supporting | No change | Postmortem; keep |
| `API_MAP.md` | archive | Moved to `docs/archive/2026-05/` | Ecosystem audit flags as stale |
| `print-events-contract-plan.md` | archive | Moved to `docs/archive/2026-05/` | Superseded by `print-events-contract.md` and the Nexus audit |
| `print-events-contract.md` | supporting | No change | Active print-events contract |
| `printer_app.md` | supporting | No change | Printer operator reference |
| `printer_manual.md` | supporting | No change | Printer operator reference |
| `printer_readme.md` | supporting | No change | Printer operator reference |
| `api/DeviceApiController.md` | supporting | No change | Controller reference |
| `api/DeviceOrderApiController.md` | supporting | No change | Controller reference |
| `api/DeviceOrderManagementApiController.md` | supporting | No change | Controller reference |
| `api/OrderApiController.md` | supporting | No change | Controller reference |
| `api/PrinterApiController.md` | supporting | No change | Controller reference |
| `api/ServiceRequestApiController.md` | supporting | No change | Controller reference |
| `architecture/ARCHITECTURE.md` | supporting | No change | Architecture reference |
| `deployment/production-docker.md` | supporting | No change | Production deployment reference |
| `deployment/tablet-update-contract.md` | supporting | No change | Active tablet update contract |
| `operations/scripts-reference.md` | supporting | No change | Operations scripts reference |
| `standards/access-and-integration-rules.md` | supporting | No change | Active standards |
| `standards/documentation-governance.md` | supporting | No change | Active standards |
| `standards/documentation-inventory.md` | supporting | No change | Active standards |
| `standards/documentation-pr-checklist.md` | supporting | No change | Active standards |
| `archive/**` (all files) | already-archived | No change | Pre-existing archive tree (audits, deprecated-deployment, experiments, historical, migrations, raspberry-pi) |

## tablet-ordering-pwa root (`tablet-ordering-pwa/`)

| Path | Classification | Action | Notes |
|---|---|---|---|
| `.agents.md` | canonical | Frontmatter added | Per-app scope rules |
| `.ai-context.md` | canonical | Frontmatter added | Brief context pointer |
| `README.md` | supporting | No change | Repo readme |
| `CASE_FILE.md` | archive | Moved to `docs/archive/2026-05/` | Superseded by Tablet audit |
| `QUICK_REF_ISSUES.md` | archive | Moved to `docs/archive/2026-05/` | Issues snapshot, superseded by audit |
| `BLOATING_ANALYSIS.md` | archive | Moved to `docs/archive/2026-05/` | Superseded by audit |
| `BLOATING_ANALYSIS_COMPLETE.md` | archive | Moved to `docs/archive/2026-05/` | Superseded by audit |
| `COMPREHENSIVE_ISSUE_ANALYSIS.md` | archive | Moved to `docs/archive/2026-05/` | Superseded by audit |
| `DEVELOPMENT_SETUP_DIAGNOSIS.md` | archive | Moved to `docs/archive/2026-05/` | One-off diagnosis |
| `DOCUMENTATION_INDEX.md` | archive | Moved to `docs/archive/2026-05/` | Superseded by platform `docs/README.md` |
| `EXECUTIVE_BRIEF.md` | archive | Moved to `docs/archive/2026-05/` | Snapshot brief, superseded by audit |
| `PRODUCTION_ARCHITECTURE_GUIDE.md` | archive | Moved to `docs/archive/2026-05/` | Superseded by audit |
| `PRODUCTION_DEPLOYMENT_CHECKLIST.md` | archive | Moved to `docs/archive/2026-05/` | Superseded by `docs/deployment/tablet-update-contract.md` |
| `QUICK_REFERENCE.md` | archive | Moved to `docs/archive/2026-05/` | Snapshot reference |
| `SETUP_SUMMARY.md` | archive | Moved to `docs/archive/2026-05/` | One-off setup summary |

## tablet-ordering-pwa/docs/

| Path | Classification | Action | Notes |
|---|---|---|---|
| `TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md` | canonical | Restructured + frontmatter | One of the four canonical audits |
| `AGENT_WORKFLOWS.md` | canonical | Frontmatter added | Active workflow guide |
| `AGENT_QUALITY_GATE.md` | canonical | Frontmatter added | Quality gate (active) |
| `DATA_MODEL.md` | supporting | No change | Data model reference |
| `API_TRACE_REFERENCE.md` | supporting | No change | API trace reference |
| `WORKFLOW.md` | supporting | No change | Workflow notes |
| `EXAMPLES.md` | supporting | No change | Examples |
| `browse-menus.md` | supporting | No change | Active feature spec |
| `OFFLINE_SYNC_RUNBOOK.md` | supporting | No change | Operational runbook |
| `SESSION_END_UX_RUNBOOK.md` | supporting | No change | Operational runbook |
| `deployment/tablet-update-contract.md` | supporting | No change | Active deployment contract |
| `server/trusted-proxies-and-nginx.md` | supporting | No change | Server config reference |
| `IMPLEMENTATION-SUMMARY.md` | archive | Moved to `docs/archive/2026-05/` | Completed-work summary |
| `IMPLEMENTATION_SUMMARY_ORDER_RESTRICTIONS.md` | archive | Moved to `docs/archive/2026-05/` | Completed-work summary |
| `MODERN-PACKAGE-SELECTION.md` | archive | Moved to `docs/archive/2026-05/` | Completed-feature spec |
| `SPLIT-LAYOUT-IMPLEMENTATION.md` | archive | Moved to `docs/archive/2026-05/` | Completed-work summary |
| `TESTING-PACKAGE-SELECTION.md` | archive | Moved to `docs/archive/2026-05/` | Completed-test plan |
| `PHASE3_MANUAL_TESTING.md` | archive | Moved to `docs/archive/2026-05/` | Completed-test plan |
| `PACKAGE_SELECTION_RESPONSIVE_SPEC.md` | archive | Moved to `docs/archive/2026-05/` | Completed spec |
| `REFACTOR_PLAN.md` | archive | Moved to `docs/archive/2026-05/` | Superseded by audit |
| `QUICK_REFERENCE_ORDER_RESTRICTIONS.md` | archive | Moved to `docs/archive/2026-05/` | Snapshot reference |
| `technical-review/CASE_FILE.md` | archive | Moved to `docs/archive/2026-05/technical-review/` | Old technical-review case file |
| `technical-review/ARCHITECTURE.md` | archive | Moved to `docs/archive/2026-05/technical-review/` | Superseded by audit |
| `technical-review/API_AND_EVENT_CONTRACTS.md` | archive | Moved to `docs/archive/2026-05/technical-review/` | Superseded by audit's contracts section |
| `technical-review/HANDOVER_PROTOCOL.md` | archive | Moved to `docs/archive/2026-05/technical-review/` | Superseded by audit |
| `technical-review/PWA_OFFLINE_AND_TESTABILITY.md` | archive | Moved to `docs/archive/2026-05/technical-review/` | Superseded by audit |
| `technical-review/WORKFLOWS.md` | archive | Moved to `docs/archive/2026-05/technical-review/` | Superseded by audit |

## woosoo-print-bridge root (`woosoo-print-bridge/`)

| Path | Classification | Action | Notes |
|---|---|---|---|
| `.agents.md` | canonical | Created 2026-05-14 | Per-app scope rules |
| `README.md` | archive | Moved to `docs/archive/2026-05/` | Audit notes this is Flutter starter boilerplate, not a real readme |
| `CASE_FILE.md` | archive | Moved to `docs/archive/2026-05/` | Old case file, superseded by audit |
| `PHASE2_PRINTER_SSL_RUNBOOK.md` | supporting | Moved to `docs/runbooks/` | Operational runbook, keep accessible |

## woosoo-print-bridge/docs/

| Path | Classification | Action | Notes |
|---|---|---|---|
| `WOOSOO_PRINT_BRIDGE_PRODUCTION_RELIABILITY_AUDIT_2026-05-14.md` | canonical | Restructured + frontmatter | One of the four canonical audits |

## Out of scope

All `*.md` files under `node_modules/`, `vendor/`, `.nuxt/`, `.git/`, `.output/`, `tablet-ordering-pwa/.output/server/node_modules/`, and any other third-party tree are out of scope and untouched.

---

## Summary

- 4 files **created** (root boot layer + this audit doc).
- 5 files **rewritten** to canonical template (the four 2026-05-14 audit docs are restructured in place; `docs/README.md` was created during boot layer).
- ~30 files **archived** (moved with `status: archived` frontmatter and `superseded_by` pointer).
- ~25 files **frontmatter only** (canonical / under-review marker added; body untouched).
- The remaining ~30 in-scope files are **supporting** and unchanged.
- 0 files **deleted**.

The pre-existing `woosoo-nexus/docs/archive/` tree was not consolidated; it already follows archive discipline and its contents are out of scope for this pass.
