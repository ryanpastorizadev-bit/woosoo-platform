---
status: canonical
last_reviewed: 2026-05-17
scope: woosoo-platform
---

# CASE: PLT-CASE-001 — Orchestration System Implementation

## Run State
- task_slug: plt-case-001-orchestration-system
- tier: 2
- branch: main
- status: IN_PROGRESS
- last_completed_agent: specialist:dazai-docs
- next_agent: verifier
- active_runner: codex
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-17

## Handoff
- Phase in progress: verifier
- Done so far: AGENTS.md hook trigger map inserted; CLAUDE.md boot sequence repaired; PROTOCOL.md created; state/WORK.md, state/QUEUE.md, state/DEPS.md, and state/DONE.md created; hooks/work.md and hooks/execute.md created; active case moved to the flat canonical path; flat case paths, app/cross-app terminology, state/WORK.md cache wording, stale print-bridge audit/pre-merge status text, and references to uncreated hook files repaired.
- Exact next action: Verifier should review the diffs and rerun the recorded scans before Executioner verdict.
- Working-tree state:
  - AGENTS.md — updated (hook system section inserted at top, all existing content preserved)
  - CLAUDE.md — updated (boot sequence checks docs/cases before state/WORK.md)
  - PROTOCOL.md — created (new)
  - state/WORK.md — created (new)
  - state/QUEUE.md — created (new)
  - state/DEPS.md — created (new)
  - state/DONE.md — created (new)
  - hooks/work.md — created (new)
  - hooks/execute.md — created (new)
  - woosoo-print-bridge/docs/WOOSOO_PRINT_BRIDGE_PRODUCTION_RELIABILITY_AUDIT_2026-05-14.md — stale red-suite wording aligned with Section 8 evidence
- Risks / do-not-redo:
  - Do NOT overwrite AGENTS.md wholesale — existing 4-agent system, specialist routing, audit checklist, immutable rules must be preserved
  - Do NOT replace docs/cases/<task-slug>.md as authoritative resume point — state/WORK.md is a convenience cache only
  - Do NOT remove Verifier from the agent chain
  - Do NOT change the boot order to read state/WORK.md before docs/cases resume check

---

## Tier
2 — Standard

## Branch
main
<!-- Orchestration/docs work runs on main per team convention. App feature work uses agent/<slug> branches. -->

## Problem

The woosoo-platform orchestration system lacks:
- A single "work" command that routes the agent to the correct next action
- Initial executable hook files for work and execute flows (remaining hooks are follow-up work)
- Machine-readable state files (state/WORK.md, state/QUEUE.md, state/DEPS.md, state/DONE.md)
- Inbox files for raw issue intake
- Standards documents per domain
- Token budget enforcement rules

## Contrarian Review

**Conducted:** 2026-05-17

Challenges considered:

1. **Correct app or platform scope?** Yes — woosoo-platform is the orchestration command center. No app code touched.
2. **Already exists?** Partially. AGENTS.md has 4-agent OS. docs/ has RESUME_PROTOCOL, HANDOVER_PROTOCOL, AI_CONTEXT. Contracts exist. Case template exists. The hook/state system is new.
3. **Scope correct?** Confirmed: docs/orchestration only. No app code. No contract changes.
4. **Blast radius?** Low — adding new files and inserting a section into AGENTS.md. Existing rules are preserved, not replaced.
5. **Simpler path?** Could update only AGENTS.md. But the hook files + state machine provide the actual routing improvement. Both are needed.
6. **Contract/auth/state machine impact?** No. Orchestration docs only.
7. **Split required?** No. Single platform orchestration scope.

**Decision:** Proceed as Tier 2. Specialist: dazai-docs.

**Constraint recorded:** state/WORK.md is a convenience cache that mirrors the active docs/cases/<slug>.md Run State. It does NOT replace it. The docs/cases/<slug>.md file remains the authoritative durable resume point per RESUME_PROTOCOL.md. Boot sequence must check docs/cases first.

## Investigation

Existing system audit:
- AGENTS.md: strong. Has 4-agent OS, tier system, specialist routing, audit checklist, token mitigation policy, completion definition.
- CLAUDE.md: good. References AGENTS.md, has @AGENTS.md include.
- docs/RESUME_PROTOCOL.md: solid. docs/cases/<task-slug>.md is the authoritative resume point.
- docs/cases/_TEMPLATE.md: good template. Run State block is machine-readable.
- contracts/: 5 real contract files (auth-session, order-state, pos-db, printer-relay, tablet-api).
- docs/cases/: flat directory is the canonical case-file location. _TEMPLATE.md exists.
- Gaps: only work/execute hooks exist so far; inbox and standards docs remain follow-up work.

## Proposed Fix

1. Insert hook trigger map into AGENTS.md (done)
2. Update CLAUDE.md boot sequence so docs/cases resume check comes before state/WORK.md (done)
3. Create PROTOCOL.md as concise routing reference (done)
4. Create state/ files: WORK.md, QUEUE.md, DEPS.md, DONE.md (done)
5. Create initial executable hooks: work.md and execute.md (done)
6. Repair flat case paths and app/cross-app terminology across PROTOCOL.md, state, and hooks (done)
7. Clean stale print-bridge red-suite wording while preserving Section 8 raw evidence (done)
8. Leave remaining hooks, inbox files, standards docs, and any contract index as follow-up work in a separate case.

## Files Changed

- AGENTS.md — hook system section inserted
- CLAUDE.md — boot sequence repaired
- PROTOCOL.md — created
- state/WORK.md — created and marked as cache only
- state/QUEUE.md — created
- state/DEPS.md — created
- state/DONE.md — created
- hooks/work.md — created and repaired for flat case paths
- hooks/execute.md — created and repaired for flat case paths
- docs/cases/plt-case-001-orchestration-system.md — active case checkpoint updated
- plan/refactor-woosoo-nexus-n1-query-fixes-1.md — false-positive stale terminology scan wording removed without changing plan meaning
- scripts/pre-merge-check.ps1 — stale Print Bridge suite comment aligned to audit-evidence rule
- scripts/pre-merge-check.sh — stale Print Bridge suite comment aligned to audit-evidence rule
- woosoo-print-bridge/docs/WOOSOO_PRINT_BRIDGE_PRODUCTION_RELIABILITY_AUDIT_2026-05-14.md — stale test-suite wording aligned with Section 8 evidence

## Verification

- [x] Required text scan has zero hits for stale path/order/terminology patterns.
  - Command: forbidden-phrase scan across AGENTS.md, CLAUDE.md, PROTOCOL.md, state files, hook files, this case file, and the print-bridge audit.
  - Output: no matches.
  - Broad repo-style scan excluding dependency, build, storage, and archive directories also returned no matches after updating stale root script comments and one false-positive plan phrase.
- [x] CLAUDE.md boot order: docs/cases resume check comes before state/WORK.md.
- [x] state/WORK.md clearly marked as convenience cache, not authoritative.
- [x] Verifier appears before Executioner in AGENTS.md, CLAUDE.md, PROTOCOL.md, and hooks.
  - Confirmed in AGENTS.md, CLAUDE.md, PROTOCOL.md, and hooks/execute.md.
- [x] Only installed hook files are referenced as loadable files.
  - Output: no paths to uncreated hook files remain; later phases continue from the case file until a follow-up case creates those hooks.
- [x] No application code was touched by this protocol repair.
  - Root status only shows root protocol/case/state/hook/script files.
  - The only nested-app file intentionally touched by this repair is the print-bridge canonical audit doc listed above.
  - Other nested app worktrees have pre-existing dirty files outside this repair; verifier should not treat those as introduced by this case.
- [x] docs/cases/_TEMPLATE.md untouched.

## Specialist Handoff

Task: PLT-CASE-001
App: woosoo-platform
Tier: 2
Files read: AGENTS.md, CLAUDE.md, PROTOCOL.md, state/WORK.md, hooks/work.md, ...6 more
Finding: The interrupted protocol work had been partially corrected, but state/hook files still referenced non-canonical case subpaths and stale app terminology.
Decision: Kept docs/cases/<task-slug>.md authoritative, kept state/WORK.md as a cache, and deferred the remaining hook expansion to a separate follow-up case.
Risks: Nested app worktrees are dirty from other work; this case touched only the print-bridge audit doc in a nested app and did not clean or validate unrelated app changes.
Deps: none
Next action: Verifier reruns the scans in this section and reviews the diff before Executioner verdict.
Validation: Text scans for stale protocol phrases, chain-order check, root/nested git status review.

## Executioner Verdict

PENDING

## Remaining Risks

- Remaining hook files, inbox workflow, and standards docs are follow-up work and should get their own case if still desired.
