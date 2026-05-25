---
status: canonical
last_reviewed: 2026-05-20
scope: ecosystem
---

# CASE: plt-case-app-audit-nexus-folders

## Run State
- task_slug: plt-case-app-audit-nexus-folders
- tier: 2
- branch: agent/plt-case-app-audit-nexus-folders
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: copilot
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-20 21:30

## Handoff
- Phase in progress:
- Done so far:
- Exact next action:
- Working-tree state (list edited files explicitly; cross-check with `git status`):
- Risks / do-not-redo:

## Tier
2

## Branch
agent/plt-case-app-audit-nexus-folders

## Problem
Audit `woosoo-nexus/` for docs and folders that appear outdated, unused, orphaned, duplicated, or otherwise no longer relevant. This is a read-only review task; findings should distinguish between intentional archives and true cleanup candidates.

## Contrarian Review
Tier 2. Multi-app user request split into app-scoped audits per AGENTS.md workspace boundary rule. Backend scope assigned to ranpo-backend. Focus on read-only inventory and relevance review only.

## Investigation
- `woosoo-nexus/docs/INDEX.md` and `woosoo-nexus/docs/standards/documentation-inventory.md` still route readers to `docs/API_MAP.md` and `docs/print-events-contract-plan.md` as active docs even though archived replacements already exist in `docs/archive/2026-05/`.
- `woosoo-nexus/docs/API_MAP.md` is stale against code. It documents `POST /api/devices/register` as `201`, while `app/Http/Controllers/Api/V1/Auth/DeviceAuthApiController.php` returns `200`.
- `woosoo-nexus/docs/print-events-contract-plan.md` remains in the active docs tree even though it is superseded by `docs/print-events-contract.md` and already archived.
- Non-canonical deployment artifacts remain at app root: `PI5_PRODUCTION_DEPLOYMENT` describes a native no-Docker deployment path, and `PRE_DEPLOYMENT_CHECKLIST.ps1` still hardcodes Laragon-era paths.
- Printer docs are drifted or deprecated in place: `docs/printer_app.md`, `docs/printer_readme.md`, and `docs/printer_manual.md` describe auth or routes that no longer match the live backend.
- Lower-trust API/controller notes in `docs/api/*.md` look stale against current auth boundaries and request contracts.
- Historical artifacts remain in active app folders: `scripts/check_order_19630_full.php`, `scripts/check_order_19630_visibility.php`, `scripts/diagnose_order_19630.php`, and `storage/backups/woosoo_api_pre_b2_backup.sql`.
- `resources/docs/guides/admin/manage-orders.md` still teaches invalid order states compared with the current contract.

## Root Cause
- The 2026-05 archive and audit pass was only partially completed: archived replacements were created, but active indexes and duplicate live copies were not fully retired.
- Nexus keeps several generations of operational guidance side by side, so Docker-era docs, printer-planning docs, and Laragon/native deployment artifacts now compete for authority.
- Historical debug and backup files were left inside active runtime directories instead of being archived or removed after the incident that produced them.

## Proposed Fix
- Archive or delete `docs/API_MAP.md`, `docs/print-events-contract-plan.md`, and `docs/SCRIPTS_REFERENCE.md` after updating any backlinks to their canonical replacements.
- Rewrite or archive `docs/printer_app.md`, `docs/printer_readme.md`, and `docs/printer_manual.md` based on the live `auth:device` printer flow and current print-event endpoints.
- Remove or quarantine app-root deployment leftovers (`PI5_PRODUCTION_DEPLOYMENT`, `PRE_DEPLOYMENT_CHECKLIST.ps1`) if they are no longer part of the supported Docker deployment path.
- Confirm whether `docs/api/` and `resources/docs/guides/` are still consumed; if not, archive them and retain only the canonical audit and supported operational docs.
- Remove one-off incident artifacts from `scripts/` and `storage/backups/` after confirming they are no longer needed for forensics.

## Files Changed
- `docs/cases/plt-case-app-audit-nexus-folders.md` — specialist audit checkpoint only
- No Nexus app files edited

## Verification
- PASS — `woosoo-nexus/docs/INDEX.md` still lists `docs/API_MAP.md` and `docs/print-events-contract-plan.md` as active docs.
- PASS — `woosoo-nexus/docs/API_MAP.md` documents `POST /devices/register` success as `201`, while `app/Http/Controllers/Api/V1/Auth/DeviceAuthApiController.php` returns `200`.
- PASS — `woosoo-nexus/docs/print-events-contract-plan.md` still exists in active docs and an archived replacement exists under `docs/archive/2026-05/`.
- PASS — `PI5_PRODUCTION_DEPLOYMENT` and `PRE_DEPLOYMENT_CHECKLIST.ps1` exist and clearly describe non-canonical native/Laragon deployment flows.
- PASS — Representative printer-doc drift confirmed: `docs/printer_readme.md` still documents nonexistent `/api/orders/unprinted` while routes define `/api/printer/unprinted-orders`.
- PASS — Representative historical artifact confirmed: `scripts/check_order_19630_full.php` is incident-specific and `storage/backups/woosoo_api_pre_b2_backup.sql` is a MySQL dump in the active app tree.
- Read-only verifier pass only; no tests or builds were needed because no app files were edited.

## Executioner Verdict
Verdict: APPROVED

Reason:
- Tier 2 read-only audit chain completed with Contrarian, Specialist, Verifier, and Executioner checkpoints.
- Verifier independently confirmed the main stale-doc, printer-doc drift, and historical-artifact findings against the repository.
- No Nexus app files were modified; this case is an evidence-backed audit only.

Required Next Action:
- None mandatory for this audit case. Execute any cleanup as separate follow-up tasks.

Follow-Ups:
- Archive or remove `woosoo-nexus/docs/API_MAP.md` and `woosoo-nexus/docs/print-events-contract-plan.md` after updating backlinks.
- Rewrite or archive stale printer docs (`docs/printer_readme.md`, `docs/printer_app.md`, `docs/printer_manual.md`) against the live routes/auth model.
- Remove incident-specific scripts and the backup SQL dump after confirming no forensic hold is required.

## Remaining Risks
- Some stale docs are still linked from active files, so cleanup must update backlinks before removal.
- `docs/api/`, `resources/docs/guides/`, and `docs/openapi.json` may still have off-repo consumers that are not visible from repository search alone.
