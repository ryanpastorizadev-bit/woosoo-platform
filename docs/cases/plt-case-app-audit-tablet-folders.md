---
status: canonical
last_reviewed: 2026-05-20
scope: ecosystem
---

# CASE: plt-case-app-audit-tablet-folders

## Run State
- task_slug: plt-case-app-audit-tablet-folders
- tier: 2
- branch: agent/plt-case-app-audit-tablet-folders
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
agent/plt-case-app-audit-tablet-folders

## Problem
Audit `tablet-ordering-pwa/` for docs and folders that appear outdated, unused, orphaned, duplicated, or otherwise no longer relevant. This is a read-only review task; findings should distinguish between intentional archives and true cleanup candidates.

## Contrarian Review
Tier 2. Multi-app user request split into app-scoped audits per AGENTS.md workspace boundary rule. Tablet scope assigned to chuya-frontend. Focus on read-only inventory and relevance review only.

## Investigation
- A large legacy root-doc cluster still sits in `tablet-ordering-pwa/` even though `docs/audits/DOCS_AUDIT_2026-05-14.md` says these files were moved to `docs/archive/2026-05/`: `CASE_FILE.md`, `QUICK_REF_ISSUES.md`, `BLOATING_ANALYSIS*.md`, `COMPREHENSIVE_ISSUE_ANALYSIS.md`, `DEVELOPMENT_SETUP_DIAGNOSIS.md`, `DOCUMENTATION_INDEX.md`, `EXECUTIVE_BRIEF.md`, `PRODUCTION_ARCHITECTURE_GUIDE.md`, `PRODUCTION_DEPLOYMENT_CHECKLIST.md`, `QUICK_REFERENCE.md`, and `SETUP_SUMMARY.md`.
- `docs/technical-review/` duplicates historical pre-audit material that already has archived copies.
- `docs/technical-review/API_AND_EVENT_CONTRACTS.md` conflicts with the current intent-only payload built in `stores/Order.ts`.
- `docs/AGENT_QUALITY_GATE.md` references nonexistent `validate` and `lint:budget` scripts, and lacks the expected frontmatter.
- `docs/AGENT_WORKFLOWS.md`, `docs/WORKFLOW.md`, `docs/OFFLINE_SYNC_RUNBOOK.md`, `docs/browse-menus.md`, and `.ai-context.md` all show drift from the current app structure or behavior.
- Obvious leftovers remain: `public/sw.ts.backup`, `docs/server/DeviceAuthApiController.patch.php`, and `src/ui-ux-pro-max/` (empty placeholder tree).

## Root Cause
- The tablet app completed a doc-archive transition only partially: archive targets exist, but many original root files and pre-audit folders were never retired.
- Several working docs still describe pre-hardening flows (payload shape, offline sync, deployment, agent workflows) and were not updated when the app shifted to stricter intent-only and live-only submission rules.
- A few stray artifacts were committed from experiments or temporary troubleshooting and never cleaned up.

## Proposed Fix
- Move or archive the legacy root-doc cluster and `docs/technical-review/` after fixing any remaining backlinks.
- Rewrite retained docs that still matter (`AGENT_QUALITY_GATE.md`, `AGENT_WORKFLOWS.md`, `OFFLINE_SYNC_RUNBOOK.md`, `SESSION_END_UX_RUNBOOK.md`) so they match the live app and current script set.
- Remove `public/sw.ts.backup`, `docs/server/DeviceAuthApiController.patch.php`, and `src/ui-ux-pro-max/` if no current workflow depends on them.
- Decide whether `.ai-context.md` should be rewritten as a small canonical pointer or removed entirely.

## Files Changed
- `docs/cases/plt-case-app-audit-tablet-folders.md` — specialist audit checkpoint only
- No Tablet PWA app files edited

## Verification
- PASS — The legacy root-doc cluster still exists at `tablet-ordering-pwa/` while archive copies also exist under `tablet-ordering-pwa/docs/archive/2026-05/`, so the docs audit "Moved to archive" claim no longer matches the filesystem.
- PASS — `docs/technical-review/API_AND_EVENT_CONTRACTS.md` still describes a rich order payload with `table_id`, totals, names, prices, and modifiers, while `stores/Order.ts` and `types/index.d.ts` only build the intent-only payload `{ guest_count, package_id, items[] }`.
- PASS — `docs/AGENT_QUALITY_GATE.md` still references missing `validate` and `lint:budget` scripts; `package.json` does not define them.
- PASS — `docs/OFFLINE_SYNC_RUNBOOK.md` still describes queue-and-sync behavior, while `OrderingStep3ReviewSubmit.vue`, `useOrderSubmit.ts`, and `public/sw.ts` all enforce live-only submission and block offline ordering.
- PASS — Confirmed leftovers: `public/sw.ts.backup`, `docs/server/DeviceAuthApiController.patch.php`, and placeholder tree `src/ui-ux-pro-max/`.
- Read-only verifier pass only; no tests or builds were needed because no app files were edited.

## Executioner Verdict
Verdict: APPROVED

Reason:
- Tier 2 read-only audit chain completed with all required checkpoints.
- Verifier independently confirmed the duplicate root-doc cluster, payload-contract drift, bad agent-quality-gate scripts, offline-runbook drift, and leftover artifact findings.
- No Tablet PWA source or docs were edited outside this case file.

Required Next Action:
- None mandatory for this audit case. Execute any cleanup as separate follow-up tasks.

Follow-Ups:
- Retire the duplicate root-doc cluster and `docs/technical-review/` after fixing backlinks.
- Rewrite or archive `docs/AGENT_QUALITY_GATE.md`, `docs/OFFLINE_SYNC_RUNBOOK.md`, and `docs/technical-review/API_AND_EVENT_CONTRACTS.md`.
- Remove `public/sw.ts.backup`, `docs/server/DeviceAuthApiController.patch.php`, and `src/ui-ux-pro-max/` if no workflow depends on them.

## Remaining Risks
- Some legacy tablet docs are still linked from other tablet docs, so cleanup cannot be a blind delete.
- Offline/runbook docs may reflect abandoned work rather than accidental drift; confirm intent before archiving them.
