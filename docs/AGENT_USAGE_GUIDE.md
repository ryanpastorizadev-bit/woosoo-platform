---
status: canonical
last_reviewed: 2026-05-31
---

# Woosoo Platform — Agent Orchestration Usage Guide

Complete reference for driving the Woosoo 4-agent workflow system. Read this once; use the Hook Trigger Map daily.

---

## System Architecture in One Sentence

Every task flows through a **4-agent chain** (Contrarian → Specialist → Verifier → Executioner), state is checkpointed to a **case file** (`docs/cases/<slug>.md`) after every phase, and any session can resume exactly where a previous one left off.

---

## The 4 Agents

### 1. Contrarian (`haiku`)
**Role:** Challenge the request before any code is touched.

- Classifies the task into Tier 1, 2, or 3
- Challenges assumptions, detects scope creep and cross-app violations
- Routes to the correct Specialist
- Lists candidate skills for the Specialist to load
- Can recommend Proceed / Clarify / Split / Reject

**Tier 1** (trivial — typo, single config line, comment): `Specialist → Executioner` — Contrarian declares Tier and exits immediately; no Verifier needed if no code path changed.

**Tier 2** (standard — bug fix, new endpoint, UI component, doc rewrite): full `Contrarian → Specialist → Verifier → Executioner`.

**Tier 3** (high-risk — auth, POS DB writes, order state machine, payment lifecycle, race conditions, queue/retry, printer duplicate prevention, production deployment, cross-app architecture): full chain + Contrarian must write a *risk analysis*, Specialist must reference `contracts/*.md`, Executioner runs on opus.

---

### 2. Specialist (varies by domain)
**Role:** Implement the smallest safe change within one app.

| Domain | Agent | Allowed path |
|--------|-------|-------------|
| Backend / API / Auth / POS / Reverb / order state | `ranpo-backend` (sonnet) | `woosoo-nexus/**` |
| Frontend / Nuxt / PWA / UI / Pinia / tablet flow | `chuya-frontend` (sonnet) | `tablet-ordering-pwa/**` |
| Printer relay / hardware / heartbeat / station | `relay-ops` (sonnet) | `woosoo-print-bridge/**` |
| Docs / specs / handover / instructions | `scribe` (haiku) | `docs/**`, root `*.md` |
| Docker / Nginx / env / deployment / LAN / Pi | `infra` (sonnet) | `docker/**`, `nginx/**`, `scripts/**`, `compose*.yaml`, `.env.example` |

**Hard limits enforced on every Specialist:**
- Tablet sends intent only: `{ guest_count, package_id, items: [{ menu_id, quantity }] }` — never pricing, tax, modifiers, totals, or POS mapping
- OrderStatus enum is the only valid state machine: `pending → confirmed → in_progress → ready → served → completed | cancelled | voided | archived`
- Customer-facing screens never show raw technical errors (stack traces, SQL, exceptions)
- One app per task — touching a second app returns `SPLIT_REQUIRED`
- POS-first: if a local transaction fails, POS rows are authoritative — no compensating deletes

**Escalate Specialist to opus only for:** security/auth, POS DB writes, payment/order lifecycle, race conditions, queue/retry, printer duplicate prevention, production deployment, cross-app architecture, or unexplained repeated failures. De-escalate once the change is bounded.

---

### 3. Verifier (`haiku`) — Read-only
**Role:** Prove the change works. Never mutates the repo.

Allowed commands only:
```
scripts/pre-merge-check.sh --app <name>   # (or scripts/pre-merge-check.ps1 -App <name>)
php artisan test [--filter=*]
php artisan route:list
npm run test / build / lint / typecheck
docker compose ps / logs
curl -k https://localhost/api/health
git status / diff / log --oneline
```

> **For any app code change the platform-root `scripts/pre-merge-check.sh --app <name>` (PowerShell:
> `scripts/pre-merge-check.ps1 -App <name>`) is the MANDATORY validation gate** (AGENTS.md →
> Validation). It wraps the per-app commands above plus steps not covered by this list; the
> individual commands are for targeted diagnosis, not a substitute for the wrapper.

**Evidence standard (non-negotiable):**
- Quote raw test output verbatim, e.g. `Tests: 33 failed, 372 passed` — no paraphrasing
- Full unfiltered suite proves suite health; `--filter` runs prove only the targeted case
- Functional proof = observed behavior (request/response, UI state, print outcome), NOT "no exception thrown"
- State the known-red baseline and whether this change moved it

---

### 4. Executioner (`opus`) — Read-only
**Role:** Final verdict gate. Returns exactly one of three verdicts.

```
APPROVED          — task is done; may carry a Follow-Ups block
REJECTED          — must be fixed before re-submission
SPLIT_REQUIRED    — task crosses app boundaries; no code modified until explicitly split
```

**Auto-rejects if any of the following:**
- Required agent sequence for the declared tier was skipped
- Tier 3 missing Contrarian written risk analysis
- Specialist modified files outside its allowed path
- Tests not run when code changed; build not run when build-affecting code changed
- Verifier reported FAIL or warnings were ignored
- Functional behavior not proven (no-error ≠ working)
- Multiple apps modified without a SPLIT verdict
- Temporary files or dead code remain in working tree
- Security boundaries uncertain (auth, secrets, Reverb auth, tablet sanitization)
- Uncommitted changes outside declared scope

---

## Triage Tiers

| Tier | Sequence | Token budget | Examples |
|------|----------|--------------|---------|
| 1 — Trivial | `Specialist → Executioner` | ≤ 5 files | typo, single-line config, comment, README link |
| 2 — Standard | `Contrarian → Specialist → Verifier → Executioner` | ≤ 12 files | bug fix, new endpoint, UI component, doc rewrite |
| 3 — High-risk | Full chain + written risk analysis | ≤ 25 files (each beyond 15 justified) | auth, POS DB writes, order state, payment, race conditions, printer dup-prevention, prod deploy |

---

## Resume Protocol — The Durable Checkpoint System

**Why it exists:** The 4-agent chain runs in a single chatbox. If the session is interrupted, work must not be lost or restarted from scratch.

**Solution:** Every case has a durable file at `docs/cases/<task-slug>.md`. Every agent writes its full output AND a refreshed `## Run State` block to that file before handing off. The file, not chat history, is authoritative.

### Mandatory Pre-Task Check (every task, every time)

1. Derive the task slug (kebab-case from request title)
2. Check `docs/cases/<task-slug>.md`
   - **`status: IN_PROGRESS` or `BLOCKED`** → Do NOT restart. Read `## Run State` + `## Handoff`. Adopt `next_agent`. Continue from the exact checkpoint.
   - **`status: COMPLETE`** → Do not reopen. Pull next task from `state/QUEUE.md`.
   - **Absent** → Start fresh as Contrarian. Create case file from `docs/cases/_TEMPLATE.md`.

### Case File `## Run State` Block

```yaml
## Run State
- task_slug: <slug>
- tier: 1 | 2 | 3
- branch: agent/<slug>
- status: IN_PROGRESS | BLOCKED | COMPLETE
- last_completed_agent: none | contrarian | specialist:<name> | verifier | executioner
- next_agent: contrarian | specialist:<name> | verifier | executioner | done
- active_runner: claude-code
- interrupted: false | true
- interrupt_reason: none | rate-limit | context-limit | error | manual-handoff
- updated: <YYYY-MM-DD HH:MM>
```

### Checkpoint Discipline

- Each agent writes its full output + refreshed Run State to the case file **before** handing off
- Chain only advances after checkpoint is written
- On interruption: write `## Handoff` note, set `status: BLOCKED`, `interrupted: true`, `interrupt_reason: <reason>`

---

## State Files at a Glance

| File | Role | Authoritative? |
|------|------|---------------|
| `docs/cases/<slug>.md` | Durable task state, resume point | **YES — always** |
| `state/WORK.md` | Cache of active case's Run State | No — convenience; case file wins on conflict |
| `state/QUEUE.md` | Prioritized task backlog | Yes |
| `state/DEPS.md` | Cross-app dependency status | Yes |
| `state/DONE.md` | Approved, completed tasks | Yes |
| `inbox/RAW.md` | Raw intake entries (untriaged) | Yes |

---

## Hook Trigger Map — What to Type

| Say this | Hook loaded | What it does |
|----------|-------------|--------------|
| `work` / `continue` / `next` / `go` | `hooks/work.md` | Default: resume or pull next task |
| `status` / `progress` / `what's pending` | `hooks/status.md` | Read-only status report; no code touched |
| (raw log/bug/error/complaint) or `intake` | `hooks/intake.md` | Record raw issue to `inbox/RAW.md` |
| `triage <RAW-ID>` | `hooks/triage.md` | Convert raw entry to case file + QUEUE row |
| `execute` / `implement` / `run case <ID>` | `hooks/execute.md` | Pre-execution checklist + context load |
| `verify` / `check if done` / `did it work` | `hooks/verify.md` | Run validation gates; update case |
| `review` / `unfinished` / `partial` | `hooks/review.md` | Audit unfinished work; findings only |
| `blocked` / `unlock` / `dependency` | `hooks/unlock.md` | Check if blocked case can proceed |
| `handover` / `sync` / `after verified` | `hooks/handover.md` | Record approval in DONE.md, unlock deps |

**Default when nothing matches:** `hooks/work.md`

---

## Step-by-Step Usage Guide

### Scenario A: New Bug or Feature Request

1. **Paste or describe the issue** — system matches to `hooks/intake.md`
   - Gets recorded to `inbox/RAW.md` with a `RAW-YYYYMMDD-NNN` ID
2. **Say `triage RAW-YYYYMMDD-NNN`** — converts the raw entry to a case file + QUEUE row
   - Case ID assigned: `nex-case-NNN`, `tab-case-NNN`, `prn-case-NNN`, or `plt-case-NNN`
   - Row added to `state/QUEUE.md`
3. **Say `work`** — system picks up the first unblocked queued task and drives the chain

### Scenario B: Normal "work" Execution Flow

```
work
  └─ Resume check: any IN_PROGRESS case?
      ├─ YES → adopt next_agent role; continue from checkpoint
      └─ NO  → read QUEUE.md; pull first queued row where dep = none or confirmed
                └─ Contrarian phase (new task)
                    └─ Specialist phase (implement change)
                        └─ dead-code-cleanup (hygiene sweep)
                            └─ Verifier phase (prove it works)
                                └─ Executioner phase (verdict)
                                    └─ APPROVED → handover → next task
                                       REJECTED → back to Specialist
                                       SPLIT_REQUIRED → no code modified; task split
```

### Scenario C: Session Was Interrupted Mid-Task

1. Open new session
2. Say `work` or `continue <task-slug>`
3. System checks `docs/cases/<slug>.md`, reads `## Run State`, adopts `next_agent` role, continues from the checkpoint — no re-triage, no repeated work

### Scenario D: Check What's Active

- Say **`status`** — formatted report of active task, top queue rows, blocked items, recommended next move
- Does not load any app source code

### Scenario E: Something Is Blocked

- Say **`blocked`** or **`unlock <CASE-ID>`**
- System reads `state/DEPS.md`, evaluates blocking dependency evidence, either unlocks or reports what's missing

### Scenario F: Approved Work — Clear the Books

- After Executioner returns `APPROVED`, say **`handover`**
- Appends to `state/DONE.md`, clears `state/WORK.md`, updates QUEUE and DEPS, unlocks dependent tasks

---

## Skills — Auto-Loaded Per Scenario

| Skill | When loaded |
|-------|------------|
| `agent-sequence` | **Every task** — mandatory |
| `test-verification` | **Every code task** — mandatory |
| `dead-code-cleanup` | **Every code task** — mandatory pre-completion hygiene |
| `laravel-api-change` | Laravel routes/controllers/FormRequests/jobs/transactions |
| `sanctum-auth-debug` | 419/CSRF, device tokens, Sanctum stateful domains |
| `nuxt-pwa-flow` | Nuxt tablet flow, screen transitions, PWA update |
| `pinia-state-audit` | Pinia store state, session/cart/device leakage |
| `printer-relay-debug` | Printer heartbeat, station routing, duplicate-print prevention |
| `docker-deployment-debug` | Docker/Nginx/compose/health/deployment |
| `documentation-truth-audit` | Any doc/spec/contract change |

---

## Mandatory End-of-Task Output

Every completed task must end with:

```md
## Agent Chain
- Tier: 1 / 2 / 3
- Branch: agent/<slug>
- Contrarian: [checkpoint info]
- Specialist: [checkpoint info]
- Verifier: [checkpoint info]
- Executioner: APPROVED / REJECTED / SPLIT_REQUIRED

## Files Changed
- <path>

## Contract Impact
yes / no — <which contract if yes>

## Validation
<raw output of scripts/pre-merge-check.ps1 -App <name> OR reason it could not run>

## Rollback Plan
<one sentence>
```

---

## Maximizing Full Potential — Key Rules

1. **Trust the hook system** — type short trigger phrases; don't manually invoke agents or skip steps
2. **Use intake → triage → work** for every new issue; don't jump straight to "implement"
3. **Never restart an IN_PROGRESS case** — say `work` and the resume protocol handles it
4. **One app per task is a hard rule** — cross-app changes are caught by the Executioner; split first
5. **"No error" is not "working"** — Verifier must prove functional behavior, not absence of exceptions
6. **Escalate Tier 3 proactively** — auth, POS DB writes, order state, payment, race conditions, prod deploy
7. **Checkpoint before handing off** — every agent writes Run State to case file before control passes
8. **Branch naming:** Tier 2/3 = `agent/<slug>`; never merge until `APPROVED`
9. **Model policy is automatic** — haiku for Contrarian/Verifier/Scribe; sonnet for Specialists; opus for Executioner; escalate Specialist to opus only for security/race/payment
10. **Case file beats everything** — chat history, `state/WORK.md`, memory — all secondary to `docs/cases/<slug>.md`

---

## Critical Files Reference

```
AGENTS.md                           — immutable rules, hook map, 4-agent OS + boot sequence (Claude Code entrypoint)
docs/AI_CONTEXT.md                  — architecture, apps, contracts (load on demand)
docs/AGENT_DEFAULT_INSTRUCTIONS.md  — evidence standards, 15 extended quality rules
docs/RESUME_PROTOCOL.md             — durable checkpointing protocol
docs/cases/_TEMPLATE.md             — case file template for new tasks
docs/cases/<slug>.md                — authoritative durable state per task
state/WORK.md                       — convenience cache of active case (not authoritative)
state/QUEUE.md                      — prioritized task backlog
state/DEPS.md                       — cross-app dependency status
state/DONE.md                       — approved completed tasks
inbox/RAW.md                        — untriaged raw issues
.claude/agents/contrarian.md        — Contrarian agent definition
.claude/agents/ranpo-backend.md     — Backend Specialist definition
.claude/agents/chuya-frontend.md    — Frontend Specialist definition
.claude/agents/relay-ops.md         — Print Bridge Specialist definition
.claude/agents/scribe.md        — Docs Specialist definition
.claude/agents/infra.md             — Infrastructure Specialist definition
.claude/agents/verifier.md          — Verifier agent definition
.claude/agents/executioner.md       — Executioner agent definition
.claude/skills/agent-sequence/      — mandatory sequence + Agent Chain block format
.claude/skills/test-verification/   — evidence standard for proving changes work
.claude/skills/dead-code-cleanup/   — pre-completion hygiene sweep
```
