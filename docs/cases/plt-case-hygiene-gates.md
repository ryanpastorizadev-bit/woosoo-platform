---
status: canonical
last_reviewed: 2026-06-08
scope: woosoo-platform
---

# CASE: plt-case-hygiene-gates

Formalise `code-simplifier` as a checkpointed chain phase; `dead-code-cleanup` runs as its internal final sub-step.

## Vault links

- Registry: [[CASE_REGISTRY]] · Contracts: [[CONTRACTS_HUB]] · Home: [[OPERATOR_HOME]]
- Related: [[plt-case-011-specialist-gates]]

## Run State

- task_slug: plt-case-hygiene-gates
- tier: 2
- branch: agent/plt-case-hygiene-gates
- status: IN_PROGRESS
- last_completed_agent: specialist:scribe
- next_agent: verifier
- active_runner: cursor
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-08

## Handoff

- Phase in progress: none — awaiting Verifier.
- Done so far: code-simplifier agent created; chain docs and Specialist handoffs updated.
- Exact next action: Verifier runs governance-doc grep checks; Executioner approves.
- Working-tree state: see ## Files Changed.
- Risks / do-not-redo: `.cursor/rules/woosoo.mdc` hygiene section pending (plan mode blocked `.mdc` edits).

## Tier

2

## Branch

agent/plt-case-hygiene-gates

## Problem

`dead-code-cleanup` was marked mandatory in `AGENTS.md` but had no checkpoint slot; `code-simplifier` was not wired into the Woosoo chain at all.

## Contrarian Review

Tier 2 platform governance. Single-node model: one resumable `code-simplifier` phase; `dead-code-cleanup` is its internal final sub-step. Tier 2–3 in Claude Code; all code tasks in Cursor.

## Success Criterion

Chain docs show `Specialist → code-simplifier (runs dead-code-cleanup internally) → Verifier`; code Specialists checkpoint `next_agent: code-simplifier`; `code-simplifier` checkpoints `next_agent: verifier`; governance grep checks pass.

## Specialist Investigation & Implementation

Inserted `code-simplifier` as step 3 in the agent chain (between Specialist and Verifier). `dead-code-cleanup` remains on Specialist skill lists for incremental hygiene and runs as the simplifier's final internal sub-step — not a separate resumable role.

**Created:**

- `.claude/agents/code-simplifier.md` — per-app standards (no React/ESM defaults); loads `dead-code-cleanup`; checkpoints to Verifier

**Updated:**

- `AGENTS.md` — chain, tiers, skill discovery, model policy, Cursor hybrid note
- `.claude/skills/agent-sequence/SKILL.md` — chain + Agent Chain audit lines
- `.claude/skills/dead-code-cleanup/SKILL.md` — ordering note
- `.claude/agents/{ranpo-backend,chuya-frontend,relay-ops,infra,contrarian,scribe}.md` — handoffs + `next_agent: code-simplifier`
- `docs/RESUME_PROTOCOL.md` — `code-simplifier` in role enums
- `docs/cases/_TEMPLATE.md` — enums + `## Code Simplification` section
- `docs/USAGE_GUIDE.md` — skills §4, Cursor preamble, step-by-step
- `docs/AGENT_USAGE_GUIDE.md` — chain sections, Scenario B flow, skills table
- `.agents/skills/dead-code-cleanup/SKILL.md` — ordering note (mirror)

**Pending (plan mode blocked `.mdc`):**

- `.cursor/rules/woosoo.mdc` — hygiene gates section + checkpoint update (operator or agent-mode follow-up)

## Code Simplification

- Code Simplifier: SKIPPED (governance-only markdown edits; no app code to simplify)
- Hygiene (dead-code-cleanup): PASS (no temp files or debug artifacts introduced)

## Files Changed

- `.claude/agents/code-simplifier.md` (new)
- `AGENTS.md`
- `.claude/skills/agent-sequence/SKILL.md`
- `.claude/skills/dead-code-cleanup/SKILL.md`
- `.claude/agents/ranpo-backend.md`
- `.claude/agents/chuya-frontend.md`
- `.claude/agents/relay-ops.md`
- `.claude/agents/infra.md`
- `.claude/agents/contrarian.md`
- `.claude/agents/scribe.md`
- `docs/RESUME_PROTOCOL.md`
- `docs/cases/_TEMPLATE.md`
- `docs/USAGE_GUIDE.md`
- `docs/AGENT_USAGE_GUIDE.md`
- `docs/cases/plt-case-hygiene-gates.md` (new)
- `.agents/skills/dead-code-cleanup/SKILL.md`

## Verification

```powershell
# Pending full run after woosoo.mdc sync
Select-String -Path ".claude/agents/ranpo-backend.md", ".claude/agents/chuya-frontend.md", ".claude/agents/relay-ops.md", ".claude/agents/infra.md" -Pattern "next_agent"
Select-String -Path ".claude/agents/code-simplifier.md" -Pattern "next_agent"
```

## Remaining Risks

- **Filed-not-blocking:** Executioner should reject when `Code Simplifier` or `Hygiene` audit lines are missing/skipped without documented reason — defer to follow-up PR on `executioner.md`.
- **`.cursor/rules/woosoo.mdc`** not yet synced — Cursor hybrid sessions lack hygiene-gate rules until that file is patched.

## Executioner Verdict

(pending)
