---
status: canonical
last_reviewed: 2026-06-06
scope: woosoo-platform
---

# CASE: plt-case-011-specialist-gates

Add PRE_EDIT_GATE and POST_EDIT_REVIEW as Specialist-phase gates wired into the execute hook.

## Run State

- task_slug: plt-case-011-specialist-gates
- tier: 1
- branch: dev
- status: IN_PROGRESS
- last_completed_agent: specialist:dazai-docs
- next_agent: verifier
- active_runner: cursor
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-06

## Handoff

- Phase in progress:
- Done so far:
- Exact next action:
- Working-tree state (list edited files explicitly; cross-check with `git status`):
- Risks / do-not-redo:

## Tier

1

## Branch

dev (operator: switch to `agent/plt-case-011-specialist-gates` before commit if required by branch policy)

## Problem

Specialist phase (especially Cursor) can edit before planning or hand off to Verifier without an explicit contract/risk review.

## Contrarian Review

Tier 1 platform governance. Extend-not-replace: no `CASE_FILE.md`, no mutable `HANDOVER_PROTOCOL.md`, no `nexus-agent-rules.md`. Phase 2 audit playbooks deferred.

## Success Criterion

`hooks/pre-edit-gate.md` and `hooks/post-edit-review.md` exist; `hooks/execute.md` mandates both in Specialist flow; USAGE_GUIDE + woosoo.mdc reference PRE_EDIT before first edit.

## Specialist Investigation & Implementation

Verified repo had no PRE_EDIT/POST_EDIT before this task. `execute.md` jumped from pre-checklist to execution rules without plan-before-edit.

**Created:**

- `hooks/pre-edit-gate.md` — files table, minimal patch, non-goals, risk review; Tier 3 stop for Cursor
- `hooks/post-edit-review.md` — behavior diff, contract check table, tests, rollback

**Updated:**

- `hooks/execute.md` — Specialist gates section before context loading
- `docs/USAGE_GUIDE.md` — Cursor preamble PRE_EDIT / POST_EDIT lines; step 4 updated
- `.cursor/rules/woosoo.mdc` — Before First Edit section

**Not changed:** AGENTS.md trigger table (audit phrases deferred to Phase 2), `_TEMPLATE.md`, `prompts/`.

## Files Changed

- hooks/pre-edit-gate.md (new)
- hooks/post-edit-review.md (new)
- hooks/execute.md
- docs/USAGE_GUIDE.md
- .cursor/rules/woosoo.mdc
- docs/cases/plt-case-011-specialist-gates.md (new)

## Verification

```text
Test-Path hooks/pre-edit-gate.md, hooks/post-edit-review.md  → True, True
Select-String hooks/execute.md -Pattern 'pre-edit-gate|post-edit-review'  → 4 matches
Select-String docs/USAGE_GUIDE.md -Pattern 'PRE_EDIT|POST_EDIT'  → matches
Select-String .cursor/rules/woosoo.mdc -Pattern 'PRE_EDIT_GATE|POST_EDIT_REVIEW'  → matches
```

Docs-only platform work — app pre-merge gates not required. Verifier: confirm hook chain order in execute.md; no new CASE_FILE.md references.

## Executioner Verdict

(pending)

## Remaining Risks

- Branch is `dev` not `agent/plt-case-011-specialist-gates` — operator confirms branch policy before commit.
- Gates rely on operator/Cursor discipline until used on 2+ real tasks.
