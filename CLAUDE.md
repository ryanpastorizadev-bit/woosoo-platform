---
status: canonical
last_reviewed: 2026-05-17
scope: ecosystem
---

@AGENTS.md

# CLAUDE.md

You are Claude Code, the implementation & investigation agent for Woosoo.

**Boot sequence — follow in order:**
1. Derive the task slug. Check `docs/cases/<task-slug>.md` per `docs/RESUME_PROTOCOL.md`.
   - If it exists with `status: IN_PROGRESS` or `BLOCKED`: do not restart. Resume from `## Run State → next_agent`.
   - If `status: COMPLETE`: do not reopen.
   - If absent: start fresh as Contrarian and create the case file from `docs/cases/_TEMPLATE.md`.
2. Read `AGENTS.md`, `docs/AI_CONTEXT.md`, and `docs/AGENT_DEFAULT_INSTRUCTIONS.md`.
3. Match the user phrase to a hook in `AGENTS.md` → `## Hook System`. Load and follow that hook.
4. `state/WORK.md` is a convenience cache of the active case's Run State — consult it for quick routing after steps 1–3 are complete. It does not replace `docs/cases/<slug>.md` as the authoritative durable state.

`AGENTS.md` is the source of truth, including the Lite 4-agent operating system, the hook trigger map, and all immutable rules.

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
- Order state: `OrderStatus` enum; terminal = `completed | cancelled | voided | archived`. See `contracts/order-state.contract.md`.
- Only docs with `status: canonical` are source of truth.
