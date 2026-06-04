---
status: canonical
last_reviewed: 2026-06-02
scope: ecosystem
---

# CASE: workspace-folder-paths

## Run State
- task_slug: workspace-folder-paths
- tier: 1
- branch: current
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: codex
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-02

## Handoff
- Phase in progress: none
- Done so far: Reviewed `woosoo-platform.code-workspace` and root `.gitignore`.
- Exact next action: none
- Working-tree state: `docs/cases/workspace-folder-paths.md` created for protocol checkpoint only.
- Risks / do-not-redo: Do not modify the workspace file unless the user chooses a preferred folder layout.

## Tier
1

## Branch
current

## Problem

User asked whether the VS Code workspace folders in `woosoo-platform.code-workspace` are correct, removable, or should use relative paths.

## Contrarian Review

This is a configuration guidance question, not a code or contract change. The workspace file already uses relative paths.

## Success Criterion

Task is done when the user receives a clear recommendation about the current workspace folder entries and no app code is modified.

## Investigation

- `woosoo-platform.code-workspace` contains root plus explicit child app folders.
- Paths are relative to the `.code-workspace` file location.
- Root `.gitignore` treats app directories as independent sibling repositories managed separately from root governance.

## Root Cause

No defect found. The question is about whether the current multi-root VS Code layout is redundant.

## Proposed Fix

No file change needed. Keep the current folder list if VS Code should treat the root, tablet app, and Nexus app as separate workspace folders.

## Files Changed

- `docs/cases/workspace-folder-paths.md`

## Verification

Read-only inspection of:
- `woosoo-platform.code-workspace`
- `.gitignore`
- `docs/RESUME_PROTOCOL.md`
- `docs/AI_CONTEXT.md`
- `docs/AGENT_DEFAULT_INSTRUCTIONS.md`

No pre-merge check was run because no application code or runtime configuration was changed.

## Executioner Verdict

APPROVED

## Remaining Risks

None for runtime behavior. The only choice is editor ergonomics.
