---
status: canonical
last_reviewed: 2026-05-20
scope: ecosystem
---

# CASE: plt-case-app-audit-platform-docs

## Run State
- task_slug: plt-case-app-audit-platform-docs
- tier: 2
- branch: agent/plt-case-app-audit-platform-docs
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
agent/plt-case-app-audit-platform-docs

## Problem
Audit platform-level docs and governance folders for docs and folders that appear outdated, unused, orphaned, duplicated, or otherwise no longer relevant. This is a read-only review task; findings should distinguish between intentional archives and true cleanup candidates.

## Contrarian Review
Tier 2. Multi-app user request split into app-scoped audits per AGENTS.md workspace boundary rule. Platform docs scope assigned to dazai-docs. Focus on read-only inventory and relevance review only.

## Investigation
- `AGENTS.md` still states that this repo is not currently a git repo even though the workspace is a git repository.
- `docs/audits/DOCS_AUDIT_2026-05-14.md` is indexed as the full inventory and classification, but several archive/move claims no longer match the actual filesystem in sibling app trees.
- `docs/README.md` omits canonical docs such as `docs/CASE_AUDIT_2026-05-18.md` and `docs/audits/infra-assessment-validated-2026-05-19.md`.
- `docs/CASE_AUDIT_2026-05-18.md` is canonical but stale and uses `date:` instead of the documented `last_reviewed:` frontmatter key.
- `PROTOCOL.md` still references nonexistent per-app `docs/cases/*/TASK_STATUS.md` and `HANDOVER.md` files, and `docs/cases/platform/` is currently an empty leftover directory.
- Several docs point to missing archive or contract paths, including `docs/archive/DONE_ARCHIVE.md` and `../contracts/...` links from case files that should resolve to `../../contracts/...`.
- Likely orphaned platform artifacts remain: `CLAUDE_REVIEW_SUMMARY.md` and `docs/superpowers/plans/2026-05-16-woosoo-nexus-n1-query-fixes.md`.

## Root Cause
- Governance docs changed quickly during the operating-system and documentation-overhaul work, and several canonical indexes/path references were not updated after the structure stabilized.
- Historical audits that were initially accurate are now stale but still marked canonical, so the platform still treats outdated inventories and snapshots as live truth.
- A small number of one-off review or planning artifacts were kept in live docs paths without being indexed or archived.

## Proposed Fix
- Correct `AGENTS.md`, `PROTOCOL.md`, case-file contract links, and archive references so canonical governance docs match the current repo layout.
- Refresh or demote `docs/audits/DOCS_AUDIT_2026-05-14.md` and `docs/CASE_AUDIT_2026-05-18.md` if they are no longer authoritative snapshots.
- Update `docs/README.md` so it fully indexes the canonical docs that remain active.
- Remove or archive orphaned planning/review artifacts and decide whether the empty `docs/cases/platform/` directory still serves any purpose.

## Files Changed
- `docs/cases/plt-case-app-audit-platform-docs.md` — specialist audit checkpoint only
- No platform docs outside the case file edited during the audit

## Verification
- PASS — `AGENTS.md` still states "This repo is not currently a git repo" even though the workspace is a git repository.
- PASS — `docs/audits/DOCS_AUDIT_2026-05-14.md` still claims some tablet docs were moved to archive even though both root and archive copies currently exist.
- PASS — `docs/README.md` omits at least two canonical docs: `docs/CASE_AUDIT_2026-05-18.md` and `docs/audits/infra-assessment-validated-2026-05-19.md`.
- PASS — `docs/CASE_AUDIT_2026-05-18.md` still uses `date:` rather than `last_reviewed:` and its case count snapshot predates the current case inventory.
- PASS — `PROTOCOL.md` still references nonexistent per-app `docs/cases/*/TASK_STATUS.md` and `HANDOVER.md` files.
- PASS — Representative broken contract path confirmed: `docs/cases/nex-case-001-security-auth-hardening.md` links `../contracts/auth-session.contract.md`, but the actual file lives at `contracts/auth-session.contract.md`.
- Read-only verifier pass only; no builds or tests were needed because no repo docs were edited outside the case files.

## Executioner Verdict
Verdict: APPROVED

Reason:
- Tier 2 read-only audit chain completed with all required checkpoints.
- Verifier independently confirmed the stale git-repo claim in `AGENTS.md`, stale/canonical-doc index drift, stale case-audit metadata, broken protocol paths, and broken contract link patterns.
- No platform docs were edited outside this case file during the audit.

Required Next Action:
- None mandatory for this audit case. Execute any cleanup as separate follow-up tasks.

Follow-Ups:
- Correct stale governance docs (`AGENTS.md`, `PROTOCOL.md`, `docs/README.md`, `docs/CASE_AUDIT_2026-05-18.md`, `docs/audits/DOCS_AUDIT_2026-05-14.md`) in a dedicated docs fix task.
- Remove or archive orphaned governance artifacts such as `CLAUDE_REVIEW_SUMMARY.md`, `docs/superpowers/plans/2026-05-16-woosoo-nexus-n1-query-fixes.md`, and the empty `docs/cases/platform/` directory if still unused.

## Remaining Risks
- Some governance files are canonical but stateful, so cleanup must preserve any intentionally live operational surfaces even if they diverge from static frontmatter conventions.
