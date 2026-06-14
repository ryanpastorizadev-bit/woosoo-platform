---
status: canonical
last_reviewed: 2026-05-17
scope: ecosystem
---

# AGENTS.md — Woosoo AI Operating Rules

**Prime Directive:** Correctness > speed. This system runs a live restaurant; a bad change can break ordering, printing, and table sessions.

---

## Hook System — Read This First

**Step 1 — Read vault state (mandatory first, before anything else).**
The platform vault already knows what is active. Read these two files; do not search.
- `state/WORK.md` → `task_id`, `status`, `tier`, `case_file`, `next_action`
- `docs/cases/OPERATOR_HOME.md` → P0/P1/P2 gates, deploy queue, priority table

If `task_id` is non-empty and `status` is `in_progress`: use that slug as the resume target.
Do not derive the slug from the user's message — the vault is authoritative.

> **Note:** `state/WORK.md` is injected automatically via `UserPromptSubmit` hook. If already
> present in your context, skip the manual read and proceed directly to Step 1b.

**Step 1b — Resume check (mandatory, per `docs/RESUME_PROTOCOL.md`).**
Using the slug from Step 1, check `docs/cases/<task-slug>.md`.
- Exists with `IN_PROGRESS` or `BLOCKED`: resume from `## Run State → next_agent`. Do not restart.
- Exists with `COMPLETE`: do not reopen. Pull next task from `state/QUEUE.md`.
- Absent: start fresh as Contrarian. Create case file from `docs/cases/_TEMPLATE.md`.

**Step 1c — Vault hub map (navigation when needed).**
The platform repo is an Obsidian vault. Use these hubs when finding related cases or contracts.
Do not duplicate state from these hubs — they are read-only navigation sources.

| Hub | Path | Use when |
|-----|------|----------|
| Vault index | `docs/VAULT_INDEX.md` | First-time navigation; orphan policy |
| Operator home | `docs/cases/OPERATOR_HOME.md` | Active work, priority table, queue (already read in Step 1) |
| Case registry | `docs/cases/CASE_REGISTRY.md` | Full case list + wikilink graph |
| Case index | `docs/cases/CASE_INDEX.md` | Dataview — recently reviewed cases |
| Contracts | `docs/cases/CONTRACTS_HUB.md` | Cross-app contract links |
| Docs hub | `docs/DOCS_HUB.md` | Canonical docs outside cases |

When writing or updating case files: add `[[related-case-slug]]` wikilinks for cross-references.
New cases: ensure slug appears in `CASE_REGISTRY` (run `scripts/obsidian-case-registry.ps1`).
Setup: `docs/obsidian-setup-guide.md` · `docs/USAGE_GUIDE.md § 6`.

**Step 2 — Match the user's phrase to an installed hook. Load that hook and follow it completely.**

| User phrase matches | Load hook |
|---|---|
| "work" · "continue" · "next" · "what's next" · "go" | `hooks/work.md` |
| "status" · "what's pending" · "progress" · "state" | `hooks/status.md` |
| "intake" · "bug" · "issue" · "error" · "problem" · raw log | `hooks/intake.md` |
| "triage" · "convert" · "make a case" | `hooks/triage.md` |
| "execute" · "implement" · "run case" + case ID | `hooks/execute.md` |
| "verify" · "check if done" · "did it work" | `hooks/verify.md` |
| "review" · "unfinished" · "what was done" · "partial" | `hooks/review.md` |
| "blocked" · "unlock" · "dependency" · "can X proceed" | `hooks/unlock.md` |
| "handover" · "sync" · "after verified" | `hooks/handover.md` |

If no phrase matches: load `hooks/work.md` as default.

**Do not load by default:** all case files, all contracts, full repo trees, lock files, archive files, unrelated app directories.

**Token budgets by tier:**
- Tier 1 (Trivial): ≤ 5 files
- Tier 2 (Standard): ≤ 12 files
- Tier 3 (High-risk): ≤ 25 files; each file beyond 15 must be justified in the handoff block

---

## Before ANY action

1. Read `docs/AI_CONTEXT.md` to understand the apps, contracts, and state flow.
2. Identify the **single** target app (`woosoo-nexus/`, `tablet-ordering-pwa/`, `woosoo-print-bridge/`).
3. Read that app's `.agents.md` for its scope-specific hard rules.
4. Do **not** modify more than one app per task unless this is an explicitly approved integration change.
5. Investigate before editing. For non-trivial work, document findings inline in your response or in a case file under the app's `docs/` directory.
6. Skim `docs/LESSONS.md` (Lessons Ledger) for failure modes tagged for the tools/app you will touch. When you hit or spot a mistake, append a ledger entry before you finish — every fix leaves a guard.

## Immutable Rules

- **Backend owns truth.** Tablet may only send `{ guest_count, package_id, items: [ { menu_id, quantity } ] }`. It must never send pricing, tax, modifiers, totals, POS mapping, or state.
- **Order state machine:** the `OrderStatus` enum (`pending, confirmed, in_progress, ready, served, completed, cancelled, voided, archived`); terminal states are `completed | cancelled | voided | archived`. See `contracts/order-state.contract.md`. Do not invent new backend states.
- **Customer-facing UI must never show raw technical errors.** Use friendly messages. Stack traces, SQL errors, and exception dumps belong in logs only.
- **Sibling-repo boundary:** one app per branch/commit unless integration-scoped. Cross-app changes require contract updates first.
- **Config integrity:** production POS uses static IP `192.168.1.32`. Detect mismatches; never write secrets to `.env` without backup and review.
- **No hardcoded LAN IPs or API/Reverb hosts** in tablet or bridge code.
- **Automated recurrence guards are binding.** `scripts/recurrence-check.{ps1,sh}` (wired into `pre-merge-check`) mechanically enforces the LESSONS-derived guards: PowerShell ASCII/parse, anchored case-status classification, no `../` wikilinks, tracked hub canvases, and registry-summary integrity. It must pass before any merge. Never weaken, skip, or comment out a detector to make a change pass; fix the cause.

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
- **woosoo-print-bridge**: `flutter analyze`, `flutter test` *(note: the Print Bridge audit Section 8 resolution log records the suite as green as of 2026-05-17; this is an attributed claim from the sibling repo's audit and is not independently verifiable from this governance repo — the print-bridge app repo is excluded and not present here. Re-verify in that repo before relying on it.)*

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

## Execution model

This operating system runs on **Claude Code** and lives in this file (the source of truth).
Claude Code executes it via `.claude/agents/*` (subagents) and `.claude/skills/*` (skills).
Agent definitions live only in `.claude/agents/`. Per-app rules live in each app's `.agents.md`.

A single chatbox adopts each role in turn (Contrarian → Specialist → code-simplifier → Verifier →
scribe → Executioner) by reading `.claude/agents/<role>.md` as its instruction set for that phase.

## Resume & Handoff (mandatory)

The chain must survive an interruption (rate limit, context limit, crash, manual handoff between
sessions). State is **not** kept only in the chatbox — it is durably checkpointed to the per-task
case file `docs/cases/<task-slug>.md`. Full protocol: `docs/RESUME_PROTOCOL.md`.

**Before ANY task you MUST:**

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

## The Chain

```txt
1. Contrarian      — challenge the request, classify risk, decide path
2. Specialist      — implement (ranpo-backend | chuya-frontend | relay-ops | scribe | infra)
3. code-simplifier — refine recently modified code (runs dead-code-cleanup internally)
4. Verifier        — prove it works by running tests/build/lint/health
5. scribe          — sync affected docs (mandatory when Specialist is a code specialist)
6. Executioner     — final verdict gate
```

First agent is always the Contrarian. Last is always the Executioner. A task is complete only
when the Executioner returns `APPROVED`.

The scribe docs-sync phase (step 4) is **mandatory for code-specialist tasks**
(ranpo-backend, chuya-frontend, relay-ops, infra) after the Verifier PASS. It is **skipped**
when the Specialist is already scribe.

## Triage Tiers

| Tier | Examples | Sequence |
| ---- | -------- | -------- |
| **1 — Trivial** | typo, single-line config, comment, README link | `Specialist → Executioner` (no Verifier if no code path changed) |
| **2 — Standard** (default) | bug fix in one app, new endpoint, UI component, doc rewrite | `Contrarian → Specialist → code-simplifier → Verifier → scribe → Executioner` |
| **3 — High-risk** | auth, POS DB writes, order state machine, payment/order lifecycle, race conditions, queue/retry, printer duplicate prevention, production deployment, cross-app architecture, unexplained repeated failures | `Contrarian (deep, written risk analysis) → Specialist → code-simplifier → Verifier → scribe → Executioner` |

For Tier 3 the Specialist must reference the relevant `contracts/*.md` file and the Executioner
uses the strongest model (opus).

## Specialist Routing Table

| Domain | Specialist | Allowed Path |
| ------ | ---------- | ------------ |
| Backend/API/Auth/POS/Reverb/order state | ranpo-backend | `woosoo-nexus/**` |
| Frontend/Nuxt/PWA/UI/Pinia/tablet flow | chuya-frontend | `tablet-ordering-pwa/**` |
| Printer relay/hardware/heartbeat/station printing | relay-ops | `woosoo-print-bridge/**` |
| Docs/specs/handover/instructions | scribe | `docs/**`, `*.md` (excl. agent/skill defs) |
| Docker/Nginx/env/deployment/LAN/Raspberry Pi | infra | `docker/**`, `nginx/**`, `scripts/**`, `compose*.yaml`, `.env.example` |

## Workspace Split Rule

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

Scenario → skill (the Contrarian selects from these; the Specialist loads only what is listed):

| When the task involves… | Load skill |
| ----------------------- | ---------- |
| Every task (the sequence + the final Agent Chain block) | `agent-sequence` |
| Laravel routes/controllers/FormRequests/resources/jobs/transactions | `laravel-api-change` |
| 419/CSRF, device tokens, Sanctum stateful domains, guard/provider mismatch | `sanctum-auth-debug` |
| Nuxt tablet flow, screen transitions, PWA update behaviour | `nuxt-pwa-flow` |
| Pinia store state, session/cart/device leakage | `pinia-state-audit` |
| Printer heartbeat, station routing, duplicate-print prevention | `printer-relay-debug` |
| Docker/Nginx/compose/health/deployment | `docker-deployment-debug` |
| Any doc/spec/contract change | `documentation-truth-audit` |
| Proving a change works — before claiming "done" (every code task) | `test-verification` |
| After Specialist on Tier 2–3 code tasks — clarity pass before Verifier | `code-simplifier` |
| Pre-completion hygiene sweep — final sub-step of code-simplifier; also incremental during Specialist | `dead-code-cleanup` |
| Writing/editing case files, wikilinks, callouts, embeds, frontmatter | `obsidian-markdown` |
| Vault search, note navigation, case file location | `obsidian-vault` |
| Creating `.base` database view files (OPS_KANBAN, CASE_INDEX, Dataview) | `obsidian-bases` |
| Creating `.canvas` visual diagrams or architecture maps | `json-canvas` |
| Obsidian CLI commands against running vault instance | `obsidian-cli` |
| Vault automation, auto-linking, Dataview query patterns | `obsidian-automation` |
| Knowledge base architecture, LLM wiki structure | `llm-wiki` |

`agent-sequence` is mandatory on every task; `test-verification` is mandatory on every code task;
`code-simplifier` is mandatory on Tier 2–3 code tasks (runs `dead-code-cleanup` internally before
Verifier).

## Model Selection Policy

Use the cheapest competent model.

```txt
Contrarian:     haiku        Ranpo Backend:  sonnet
Scribe:         haiku        Chuya Frontend: sonnet
Verifier:       haiku        Relay Ops:      sonnet
Code Simplifier: sonnet       Infra:          sonnet
Executioner:    opus (final correctness gate; Prime Directive = correctness > speed)
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

## Review Summary (end of every task)

Every task output must end with:

- **Files changed** (with paths)
- **Contract impact** (yes/no, which contract)
- **Validation result** (output of `scripts/pre-merge-check.sh` or reason it could not run)
- **Rollback plan** (one sentence)

## Cursor Specialist Mode (EXPERIMENTAL — Tier 1–2 only)

When `active_runner: cursor` is set in the case file, the Specialist phase is performed in
Cursor IDE rather than as a Claude Code subagent. **Contrarian, Verifier, and Executioner always
run in Claude Code regardless.**

Rules:
- Permitted for **Tier 1 and Tier 2 only.** Tier 3 always uses a Claude Code Specialist — Cursor
  lacks the contract context needed for high-risk flows.
- Tier 1 still requires a minimal Claude Code precheck (slug + case file + Run State checkpoint)
  before Cursor takes over. Slug/case/resume discipline is never skipped.
- Open via **`woosoo-platform.code-workspace`** (multi-root) so `docs/cases/` is in scope.
- Cursor must run the `code-simplifier` phase (invoke subagent on changed files; runs
  `dead-code-cleanup` internally) before the Specialist checkpoint, then write the case file with
  `next_agent: verifier`. Operator confirms the checkpoint landed before typing `verify` in Claude Code.
  This applies to **all code tasks** in Cursor (Tier 1–2), not only Tier 2–3.
- `.cursor/rules/woosoo.mdc` encodes the project rules for Cursor AI. **Rule Sync checklist:**
  when immutable rules change in this file, update `.cursor/rules/woosoo.mdc` to match.
- Known Cursor limitation: `.cursor/rules` may not load reliably in multi-root workspaces.
  The operator paste-preamble (see `docs/USAGE_GUIDE.md § Cursor Hybrid Workflow`) is mandatory
  until Phase 2 (per-app repo `.cursor/rules/` files) is complete and verified.
- See `docs/USAGE_GUIDE.md § Cursor Hybrid Workflow` for the step-by-step handoff protocol.

## Reminders

- The tablet sends intent; the backend owns truth.
- One app per task.
- No technical errors to customers.
- Order state: `OrderStatus` enum; terminal = `completed | cancelled | voided | archived`. See `contracts/order-state.contract.md`.
- Only docs with `status: canonical` are source of truth.
- **Never repeat a known mistake.** Consult `docs/LESSONS.md` before non-trivial work; append a new entry when a failure mode appears. Recurrence promotes the guard to an enforced rule in `docs/AGENT_DEFAULT_INSTRUCTIONS.md § Extended Rules`.
- **Obsidian vault** = platform repo. Agents refer to `docs/VAULT_INDEX.md`, `docs/cases/CASE_REGISTRY.md`, and `docs/cases/CONTRACTS_HUB.md` for navigation; use `[[wikilinks]]` in case files. Operators pin `docs/cases/OPERATOR_HOME.md`. Bootstrap: `scripts/obsidian-bootstrap.ps1`.
