---
status: canonical
last_reviewed: 2026-05-17
scope: ecosystem
---

# AGENTS.md — Woosoo AI Operating Rules

**Prime Directive:** Correctness > speed. This system runs a live restaurant; a bad change can break ordering, printing, and table sessions.

## Before ANY action

1. Read `docs/AI_CONTEXT.md` to understand the apps, contracts, and state flow.
2. Identify the **single** target app (`woosoo-nexus/`, `tablet-ordering-pwa/`, `woosoo-print-bridge/`).
3. Read that app's `.agents.md` for its scope-specific hard rules.
4. Do **not** modify more than one app per task unless this is an explicitly approved integration change.
5. Investigate before editing. For non-trivial work, document findings inline in your response or in a case file under the app's `docs/` directory.

## Immutable Rules

- **Backend owns truth.** Tablet may only send `{ guest_count, package_id, items: [ { menu_id, quantity } ] }`. It must never send pricing, tax, modifiers, totals, POS mapping, or state.
- **Order state machine:** `confirmed → completed | voided | cancelled`. Do not invent new backend states.
- **Customer-facing UI must never show raw technical errors.** Use friendly messages. Stack traces, SQL errors, and exception dumps belong in logs only.
- **Monorepo boundary:** one app per branch/commit unless integration-scoped. Cross-app changes require contract updates first.
- **Config integrity:** production POS uses static IP `192.168.1.32`. Detect mismatches; never write secrets to `.env` without backup and review.
- **No hardcoded LAN IPs or API/Reverb hosts** in tablet or bridge code.

## Mandatory Workflow

1. **Investigate** — read related files, search for existing patterns, check contracts.
2. **Plan** — smallest safe change; confirm no contract/state/security violation.
3. **Implement** — apply only the approved change.
4. **Validate** — run `scripts/pre-merge-check.sh --app <name>` (or `scripts/pre-merge-check.ps1` on Windows) and report the output. Manual test if applicable.
5. **Review** — check the audit checklist below.
6. **Handover** — update or create the relevant audit doc; cross-reference any contract changes.

## Audit Checklist (every change)

- [ ] Race conditions / duplicate fetches / stale loading
- [ ] State machine integrity (order, session, tablet UI phases, print job phases)
- [ ] API contract unchanged or explicitly updated in the relevant audit doc
- [ ] Security: auth boundaries, secrets, Reverb auth, tablet sanitization
- [ ] Print job idempotency (reserve/ack/failed lifecycle)
- [ ] Reverb listener duplication / reconnect behaviour
- [ ] Technical errors never leak to customer screens
- [ ] Only one app modified

## Validation

Run the pre-merge check script from the platform root:

```bash
bash scripts/pre-merge-check.sh --app woosoo-nexus
bash scripts/pre-merge-check.sh --app tablet-ordering-pwa
bash scripts/pre-merge-check.sh --app woosoo-print-bridge
```

Or on Windows PowerShell:

```powershell
.\scripts\pre-merge-check.ps1 -App woosoo-nexus
```

Per-app commands the script wraps:

- **woosoo-nexus**: `composer test`, `php artisan route:list`, `php artisan config:clear`
- **tablet-ordering-pwa**: `npm run typecheck`, `npm run lint`, `npm run test`, `npm run build`, `npm run generate`
- **woosoo-print-bridge**: `flutter analyze`, `flutter test` *(note: test suite is currently red — see the Print Bridge audit before relying on it)*

If a command cannot be run, explain why. Do not claim success without script output.

## Agent Behavior Standards

See `docs/AGENT_DEFAULT_INSTRUCTIONS.md` for the full ruleset governing agent behavior, evidence standards, test measurement requirements, destructive-git prohibitions, root-cause proof standards, and report-rejection protocol. That document is canonical and must be read alongside this file for any non-trivial task.

## Documentation Truth

- Only docs with `status: canonical` in their YAML frontmatter are current.
- Docs with `status: archived` are historical only — do not treat as source of truth.
- Docs with `status: under-review` are not yet finalized.
- The canonical index is `docs/README.md`. The four 2026-05-14 audit docs (Ecosystem + Nexus + Tablet PWA + Print Bridge) are the authoritative system-state references.
- Per-app rules live in each app's `.agents.md`.

## Branch & Commit

- Branch: `fix/<app>/<short>`, `feature/<app>/<short>`, `chore/<app>/<short>`.
- Commit: conventional commits, e.g. `fix(tablet): stabilise package selection loading`.
- Do not merge dependency PRs into deployment-fix PRs.
- Do not deploy tablet without verifying sibling repo branch/commit.

---

# Lite 4-Agent Operating System

Everything above remains the immutable contract layer. The rules below add **how** work is
executed: a single chatbox behaves like a multi-agent workflow without manual agent switching.

## Runners

This operating system is vendor-neutral and lives in this file (the source of truth):

- **Claude Code** executes it via `.claude/agents/*` (subagents) and `.claude/skills/*` (skills).
- **OpenAI Codex CLI** reads this `AGENTS.md` natively (root + the per-app `AGENTS.md` in each
  app directory). It follows the same sequence narratively in a single chatbox.
- **GitHub Copilot** continues to follow `.github/copilot-instructions.md` (root + per-app).

Agent definitions live only in `.claude/agents/`. Per-app rules live in each app's `.agents.md`
(the per-app `AGENTS.md` files are thin pointers for Codex — do not duplicate rules into them).

Any runner can adopt any role: Codex/Copilot read `.claude/agents/<role>.md` as their
instruction set for that phase and behave as that role in a single chatbox.

## Cross-Runner Resume & Handoff (mandatory)

The chain must survive a runner being interrupted (rate limit, context limit, crash, manual
handoff). State is **not** kept only in the chatbox — it is durably checkpointed to the per-task
case file `docs/cases/<task-slug>.md`. Full protocol: `docs/RESUME_PROTOCOL.md`.

**Before ANY task, every runner (Claude Code, Codex, Copilot) MUST:**

1. Derive the stable task slug and check `docs/cases/<task-slug>.md`.
2. If it exists with `status: IN_PROGRESS` or `BLOCKED`: **do not restart, do not re-run
   completed agents, do not re-triage tier/branch.** Read the `## Run State` + `## Handoff` +
   completed phase sections, adopt the role in `next_agent`, and continue the chain from there.
3. If `status: COMPLETE`: do not reopen. If absent: start fresh as Contrarian and create the
   case file from `docs/cases/_TEMPLATE.md`.

**Checkpoint discipline:** every agent writes its full output **and** an updated `## Run State`
block to the case file the moment it finishes its phase, *before* control passes on. The chain
advances only after the checkpoint is written. No checkpoint = the phase did not happen.

**On interruption:** if able to emit anything, write a `## Handoff` note, set `status: BLOCKED`,
`interrupted: true`, `interrupt_reason: <reason>`. The resuming runner trusts the case file over
any chat history — the case file is authoritative.

Tier, branch, one-app scope, and contract obligations recorded at triage are binding on every
subsequent runner. A resuming runner must not widen scope or skip a gate to "catch up".

## The 4 Agents

```txt
1. Contrarian   — challenge the request, classify risk, decide path
2. Specialist   — implement (ranpo-backend | chuya-frontend | relay-ops | dazai-docs | infra)
3. Verifier     — prove it works by running tests/build/lint/health
4. Executioner  — final verdict gate
```

First agent is always the Contrarian. Last is always the Executioner. A task is complete only
when the Executioner returns `APPROVED`.

## Triage Tiers

| Tier | Examples | Sequence |
| ---- | -------- | -------- |
| **1 — Trivial** | typo, single-line config, comment, README link | `Specialist → Executioner` (no Verifier if no code path changed) |
| **2 — Standard** (default) | bug fix in one app, new endpoint, UI component, doc rewrite | `Contrarian → Specialist → Verifier → Executioner` |
| **3 — High-risk** | auth, POS DB writes, order state machine, payment/order lifecycle, race conditions, queue/retry, printer duplicate prevention, production deployment, cross-app architecture, unexplained repeated failures | `Contrarian (deep, written risk analysis) → Specialist → Verifier → Executioner` |

For Tier 3 the Specialist must reference the relevant `contracts/*.md` file and the Executioner
uses the strongest model (opus).

## Specialist Routing Table

| Domain | Specialist | Allowed Path |
| ------ | ---------- | ------------ |
| Backend/API/Auth/POS/Reverb/order state | ranpo-backend | `woosoo-nexus/**` |
| Frontend/Nuxt/PWA/UI/Pinia/tablet flow | chuya-frontend | `tablet-ordering-pwa/**` |
| Printer relay/hardware/heartbeat/station printing | relay-ops | `woosoo-print-bridge/**` |
| Docs/specs/handover/instructions | dazai-docs | `docs/**`, `*.md` (excl. agent/skill defs) |
| Docker/Nginx/env/deployment/LAN/Raspberry Pi | infra | `docker/**`, `nginx/**`, `scripts/**`, `docker-compose*.yml`, `.env.example` |

## Monorepo Split Rule

One app per task. If a task requires more than one app, the Executioner returns
`SPLIT_REQUIRED` and no app code is modified until the work is explicitly split.

## Branching & Rollback

When the repository is a git repo: Tier 2 / Tier 3 run on a dedicated branch
`agent/<short-task-slug>`; Tier 1 may run on the current working branch. Merge only after
`APPROVED`. On `REJECTED`, restore the Specialist's working tree (`git restore .`) before any
fix-forward; fix-forward only after the Verifier re-runs clean. Branches may be kept for
forensic review. (This repo is not currently a git repo — treat this as documented protocol.)

## Skill Discovery

The Contrarian lists candidate skills (it folds in skill discovery). The Specialist loads only
those skills. Do not load the whole skill library.

## Model Selection Policy

Use the cheapest competent model.

```txt
Contrarian:     haiku        Ranpo Backend:  sonnet
Dazai Docs:     haiku        Chuya Frontend: sonnet
Verifier:       haiku        Relay Ops:      sonnet
Executioner:    opus (final correctness gate; Prime Directive = correctness > speed)
                             Infra:          sonnet
```

Escalate the Specialist to opus only for: security/auth, POS DB writes, payment/order lifecycle,
race conditions/async leaks, queue/retry behaviour, printer duplicate prevention, production
deployment, cross-app architecture, or unexplained repeated failures. De-escalate after opus
planning once files are identified, changes are bounded, contracts are clear, tests are defined,
and rollback is obvious.

## Token Mitigation Policy

Search before reading; read only relevant files. Do not load entire repos or all skills.
Summarize logs but preserve exact errors, commands, and file paths. Split cross-app work instead
of carrying massive context. Reference large docs by path, do not copy them.

## Completion Definition

```txt
No error does not mean working.
Working means verified.
A finished task is a working feature, fully tested, validated, reviewed, and approved.
```

A final answer of "done" is not acceptable. Every task ends with the **Agent Chain** block
defined in `.claude/skills/agent-sequence/SKILL.md`.

Executioner verdicts (only these three):

```txt
APPROVED          # may carry a Follow-Ups: block listing issues to file separately
REJECTED
SPLIT_REQUIRED
```
