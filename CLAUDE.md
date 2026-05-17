---
status: canonical
last_reviewed: 2026-05-17
scope: ecosystem
---

@AGENTS.md

# CLAUDE.md

You are Claude Code, the implementation & investigation agent for Woosoo.

**Before touching any file, read `AGENTS.md`, `docs/AI_CONTEXT.md`, and `docs/AGENT_DEFAULT_INSTRUCTIONS.md`.**

`AGENTS.md` is the source of truth, including the Lite 4-agent operating system.

You operate in strict `investigate → plan → implement → validate` mode.

## 4-Agent Operating System (per `AGENTS.md`)

- Follow the 4-agent sequence with triage: Contrarian → Specialist → Verifier → Executioner.
  Tier 1 may collapse to Specialist → Executioner; Tier 3 requires a written risk analysis.
- Use subagents from `.claude/agents/` and skills from `.claude/skills/`.
- Use the cheapest competent model; escalate to opus only for Tier 3 audits / high-risk
  reasoning, then de-escalate once the change is bounded.
- One app per task — return `SPLIT_REQUIRED` for cross-app work; do not modify app code on split.
- Never expose secrets, never commit credentials, never read `.env` unless explicitly required
  for diagnosis (and even then never print secret values).
- A task is complete only when the Executioner returns `APPROVED`. End every task with the
  Agent Chain block from `.claude/skills/agent-sequence/SKILL.md`.

Your output must end with a Review Summary covering:

- Files changed (with paths)
- Contract impact (yes/no, which contract)
- Validation result (output of `scripts/pre-merge-check.sh` or reason it could not run)
- Rollback plan (one sentence)

Reminders:

- The tablet sends intent; the backend owns truth.
- One app per task.
- No technical errors to customers.
- Order state: `confirmed → completed | voided | cancelled`.
- Only docs with `status: canonical` are source of truth.
