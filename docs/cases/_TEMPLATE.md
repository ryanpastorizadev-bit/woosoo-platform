---
status: under-review
last_reviewed: 2026-05-17
scope: ecosystem
---

# CASE: <slug>

Copy this file to `docs/cases/<task-slug>.md` for each task. Each task gets its own case file —
the shared file is not used (concurrent tasks would collide). This file is the **durable,
runner-agnostic resume point** — see `docs/RESUME_PROTOCOL.md`. Every agent checkpoints here
before handing off; any runner (Claude Code / Codex / Copilot) resumes from here.

## Run State
<!-- Rewritten in full by each agent when it finishes its phase. The resume header. -->
- task_slug: <slug>
- tier: 1 | 2 | 3
- branch: agent/<slug>            <!-- platform governance work uses staging/orchestration-hooks -->
- status: IN_PROGRESS | BLOCKED | COMPLETE
- last_completed_agent: none | contrarian | specialist:<name> | verifier | executioner
- next_agent: contrarian | specialist:<name> | verifier | executioner | done
- active_runner: claude-code | codex | copilot
- interrupted: false | true
- interrupt_reason: none | rate-limit | context-limit | error | manual-handoff
- updated: <YYYY-MM-DD HH:MM>

## Handoff
<!-- Filled when a phase is interrupted (e.g. rate limit). Empty otherwise. -->
- Phase in progress:
- Done so far:
- Exact next action:
- Working-tree state (list edited files explicitly; cross-check with `git status`):
- Risks / do-not-redo:

## Tier
1 / 2 / 3

## Branch
agent/<slug>

## Problem

## Contrarian Review

## Investigation

## Root Cause

## Proposed Fix

## Files Changed

## Verification

## Executioner Verdict

## Remaining Risks
