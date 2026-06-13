---
status: canonical
last_reviewed: 2026-06-10
scope: ecosystem
---

# PLT-CASE: Agent Tooling Health Audit — 2026-06-10

## Run State

```yaml
task_slug:            plt-case-agent-tooling-audit
tier:                 2
status:               complete-read-only
last_completed_agent: investigator (read-only pass)
next_agent:           operator
active_runner:        claude-code
branch:               claude/woosoo-status-audit-gp921y
description:          Full read-only health audit of the platform agent OS, skill layers,
                      Cursor hybrid, Obsidian vault, Superpowers, folder structure, and
                      ultrathink policy. No file changes. Deliverable is this doc only.
updated:              2026-06-10
```

---

## Executive Summary

1. **Agent OS is operationally sound.** The 4-agent chain (Contrarian → Specialist → Verifier → Executioner), triage tiers, model policy, immutable rules, and all 9 hooks are 100% consistent across AGENTS.md, PROTOCOL.md, AGENT_USAGE_GUIDE.md, `.claude/agents/`, `.claude/skills/agent-sequence/SKILL.md`, and every hook file. No drift found.
2. **`.agents/skills/` is a Superpowers skill import — not a native Woosoo layer.** 12 of 22 skills exist only in `.agents/` (brainstorming, executing-plans, writing-plans, etc.). None are loaded by any `.claude/agent` definition. They run as standalone files but are unwired from the 4-agent chain.
3. **Brainstorming gate exists in `.agents/` but is not wired into the lit-agent OS.** `.agents/skills/brainstorming/SKILL.md` defines a hard-gate mandatory for creative work; AGENTS.md, hooks, and `.claude/agents/` contain zero references to it.
4. **No Cursor layer exists.** No `.cursor/` directory, no `.mdc` rules files, no `.code-workspace` file. The audit scope assumed Cursor hybrid mode was set up — it is not.
5. **No Obsidian vault exists.** No `.obsidian/`, no `CASE_REGISTRY`, no `VAULT_INDEX`, no `CONTRACTS_HUB`, no `bases/`, no `canvas/`, no `docs/operator/`, no obsidian-lint script. The repo uses a flat case file system, not an Obsidian vault.
6. **ultrathink / deep-reasoning is undocumented.** Opus is assigned to Executioner and Tier 3 escalation, but there is no explicit policy for when to invoke extended thinking.
7. **One CRITICAL untriaged inbox item.** `RAW-20260523-001` — POST `/api/devices/create-order` returning 500, cross-boundary (tablet + nexus) — has not been triaged into a case file. This is P1 and should be the next triage action.
8. **`ui-ux-pro-max` skill has broken path references.** Two files in `.agents/skills/ui-ux-pro-max/` point to `../../../src/ui-ux-pro-max/` which does not exist anywhere in the repo.
9. **Folder clutter is low but present.** Four `.docx` files at repo root, one stale archive script, one stale plan file, and a pending `DONE.md` backfill — all minor.
10. **Superpowers is not installed.** Referenced in `.agents/skills/executing-plans/SKILL.md` as a recommended cloud-IDE environment, but no local install exists. The `docs/superpowers/` path (used by brainstorming skill for spec output) does not exist.

---

## 1. Agent Chain Verification

### 1a. Chain Consistency

| Source | Documented Chain |
|---|---|
| `AGENTS.md:175–180` | Contrarian → Specialist → Verifier → Executioner |
| `PROTOCOL.md:28–34` | Contrarian → Specialist → Verifier → Executioner |
| `docs/AGENT_USAGE_GUIDE.md:12–64` | Contrarian → Specialist → Verifier → Executioner |
| `.claude/skills/agent-sequence/SKILL.md:6–26` | Contrarian → Specialist → Verifier → Executioner |
| `hooks/execute.md:53–66` | By tier: T1 = Specialist→Executioner; T2/T3 = full chain |
| `hooks/work.md:104–122` | Contrarian performs tier classification on every new task |

**Verdict: 100% consistent. No drift.**

No "code-simplifier," "scribe," or N+1 agent chain exists anywhere in the repo.

### 1b. Triage Tier Routing

| Tier | Conditions | Agent Chain |
|---|---|---|
| **1 — Trivial** | Typo, single-line config, comment, README link | `Specialist → Executioner` |
| **2 — Standard** | Bug fix, new endpoint, UI component, doc rewrite | `Contrarian → Specialist → Verifier → Executioner` |
| **3 — High-risk** | Auth, POS DB, order state, payment, printing, race conditions, cross-app, deployment | `Contrarian (written risk analysis) → Specialist → Verifier → Executioner` |

Consistent across: `AGENTS.md:186–191`, `PROTOCOL.md`, `docs/AGENT_USAGE_GUIDE.md`, `.claude/skills/agent-sequence/SKILL.md:21–26`, `hooks/execute.md`.

### 1c. Model Policy

| Role | Policy (AGENTS.md:244–252) | Agent Frontmatter | Match |
|---|---|---|---|
| Contrarian | haiku | `contrarian.md` line 4 | ✓ |
| Ranpo Backend | sonnet | `ranpo-backend.md` line 4 | ✓ |
| Chuya Frontend | sonnet | `chuya-frontend.md` line 4 | ✓ |
| Relay Ops | sonnet | `relay-ops.md` line 4 | ✓ |
| Dazai Docs | haiku | `dazai-docs.md` line 4 | ✓ |
| Infra | sonnet | `infra.md` line 4 | ✓ |
| Verifier | haiku | `verifier.md` line 4 | ✓ |
| Executioner | opus | `executioner.md` line 4 | ✓ |

**Verdict: 100% match. No drift.**

`docs/AGENT_USAGE_GUIDE.md` line 294 also documents: "escalate Specialist to opus only for security/race/payment."

### 1d. Hook Dispatch Table

| Hook | Trigger Phrases | Dispatches Agent Chain? | Notes |
|---|---|---|---|
| `work.md` | work, continue, next, go | Yes — per tier | Default hook; Contrarian required for new tasks |
| `execute.md` | execute, implement, run case | Yes — per tier | Tier 1 skips Contrarian |
| `verify.md` | verify, check if done, did it work | Verifier only | Correct — Verifier phase only |
| `intake.md` | bug, issue, error, problem, raw log | No — records RAW entry | Explicitly: "does not create case files" |
| `triage.md` | triage \<RAW-ID\>, make a case | No — creates case file | Explicitly: "do not implement fixes" |
| `review.md` | review, unfinished, what was done | No — audit only | Explicitly: "no implementation" |
| `status.md` | status, what's pending, progress | No — read-only | Explicitly: "without loading app source" |
| `unlock.md` | blocked, unlock, dependency | No — evaluates dep | Does not advance agent chain |
| `handover.md` | handover, sync, after verified | No — state update | Requires Executioner pre-approval |

**Verdict: All 9 hooks correctly dispatch or correctly avoid the agent chain.**

---

## 2. Skill Layer Overlap Map

### 2a. Full 22-Skill Inventory

| Skill | `.claude/skills/` | `.agents/skills/` | Origin | Loaded By Agent | Canonical Source |
|---|---|---|---|---|---|
| agent-sequence | ✓ | ✓ | Woosoo native | All agents | `.claude/skills/` |
| dead-code-cleanup | ✓ | ✓ | Woosoo native | All Specialists | `.claude/skills/` |
| docker-deployment-debug | ✓ | ✓ | Woosoo native | infra | `.claude/skills/` |
| documentation-truth-audit | ✓ | ✓ | Woosoo native | dazai-docs | `.claude/skills/` |
| laravel-api-change | ✓ | ✓ | Woosoo native | ranpo-backend | `.claude/skills/` |
| nuxt-pwa-flow | ✓ | ✓ | Woosoo native | chuya-frontend | `.claude/skills/` |
| pinia-state-audit | ✓ | ✓ | Woosoo native | chuya-frontend | `.claude/skills/` |
| printer-relay-debug | ✓ | ✓ | Woosoo native | relay-ops | `.claude/skills/` |
| sanctum-auth-debug | ✓ | ✓ | Woosoo native | ranpo-backend | `.claude/skills/` |
| test-verification | ✓ | ✓ | Woosoo native | Verifier + code tasks | `.claude/skills/` |
| brainstorming | — | ✓ | **Superpowers** | _none_ | `.agents/skills/` (unwired) |
| create-implementation-plan | — | ✓ | **Superpowers** | _none_ | `.agents/skills/` (unwired) |
| devops-rollout-plan | — | ✓ | **Superpowers** | _none_ | `.agents/skills/` (unwired) |
| executing-plans | — | ✓ | **Superpowers** | _none_ | `.agents/skills/` (unwired) |
| find-skills | — | ✓ | **Superpowers** | _none_ | `.agents/skills/` (unwired) |
| frontend-design | — | ✓ | **Superpowers** | _none_ | `.agents/skills/` (unwired) |
| laravel-specialist | — | ✓ | **Superpowers** | _none_ | `.agents/skills/` (superseded by ranpo-backend) |
| nuxt | — | ✓ | **Superpowers** | _none_ | `.agents/skills/` (23 framework ref .md files) |
| nuxt-ui | — | ✓ | **Superpowers** | _none_ | `.agents/skills/` (component library refs) |
| refactor-plan | — | ✓ | **Superpowers** | _none_ | `.agents/skills/` (unwired) |
| ui-ux-pro-max | — | ✓ | **Superpowers** | _none_ | `.agents/skills/` (**BROKEN** — dead paths) |
| writing-plans | — | ✓ | **Superpowers** | _none_ | `.agents/skills/` (terminal output of brainstorming) |

### 2b. Canonical Source Recommendations

| Topic | Recommendation |
|---|---|
| Agent chain sequencing | `.claude/skills/agent-sequence/` — **canonical** |
| Laravel API changes | `.claude/skills/laravel-api-change/` — **canonical**; `.agents/skills/laravel-specialist/` is a Superpowers-originated reference dump, not a workflow skill |
| Nuxt/PWA flow | `.claude/skills/nuxt-pwa-flow/` — **canonical**; `.agents/skills/nuxt/` and `nuxt-ui/` are Superpowers reference material |
| Brainstorming/design | `.agents/skills/brainstorming/` — **only source**, but unwired; needs a decision (see §3) |
| Implementation planning | `.agents/skills/create-implementation-plan/` — only source, Superpowers-originated; no Woosoo equivalent |
| UI/UX design | `.agents/skills/ui-ux-pro-max/` — **BROKEN**; `frontend-design/` is an alternative but also unwired |

### 2c. Orphaned Skills Note

The 12 Superpowers-unique skills in `.agents/skills/` are sourced via `skills-lock.json` from GitHub repos (confirmed by the lock file's `source` + `hash` fields). They were imported but **Superpowers the cloud IDE is not installed**. These skills can be invoked manually via Claude Code's `/skill` syntax, but they are not automatically loaded by any agent definition, and their output paths (e.g., `docs/superpowers/specs/`) do not exist.

---

## 3. Brainstorming Gate

### Current State

- **Defined at:** `.agents/skills/brainstorming/SKILL.md:1–14`
- **Trigger (as documented in skill):** MANDATORY before any "creative work — creating features, building components, adding functionality, or modifying behavior"
- **Hard-gate quote:** "Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it."
- **Output:** Design spec saved to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` (path does not exist)
- **Terminal action:** Calls `writing-plans` skill; prohibits calling any other implementation skill

### Where It Is NOT Referenced

| Location | Contains brainstorming reference? |
|---|---|
| `AGENTS.md` | No |
| `PROTOCOL.md` | No |
| `hooks/intake.md` | No |
| `hooks/execute.md` | No |
| `hooks/work.md` | No |
| All 8 `.claude/agents/` definitions | No |
| `.claude/skills/agent-sequence/SKILL.md` | No |

### Conflict Analysis

The Woosoo lit-agent OS uses **Contrarian** as the design-challenge gate for every Tier 2/3 task. Contrarian challenges scope, risks, and approach before any Specialist begins. This is a lighter-weight design gate than brainstorming (which produces a full spec doc before any implementation action).

**Conflicting triggers:**
- `AGENTS.md:186`: Tier 2/3 tasks → Contrarian first (design challenge)
- `.agents/skills/brainstorming/SKILL.md:3`: Any creative work → brainstorming first (full spec)
- These are **parallel gates** with no documented priority or integration order

### Recommendation

Three options — choose one before wiring anything:

| Option | What it means |
|---|---|
| **A — Keep separate** | Brainstorming is an optional Superpowers-layer skill, invokable manually when a full spec is needed. Contrarian remains the sole mandatory design gate in the lit-agent OS. Document the distinction. |
| **B — Integrate into Tier 3** | Add a brainstorming step to Tier 3 tasks (high-risk feature work). Contrarian classifies; if Tier 3 + creative, brainstorming is required before Specialist runs. Requires AGENTS.md update + `execute.md` + `intake.md` hook changes. |
| **C — Replace with Contrarian** | Deprecate brainstorming as unnecessary given Contrarian's challenge role. Mark `.agents/skills/brainstorming/` as archived. |

**Do not implement in this pass.** Open `plt-case-brainstorm-gate-integration` to decide and wire.

---

## 4. Cursor Hybrid Layer

### What Was Checked

| Item | Result |
|---|---|
| `.cursor/` directory | **NOT FOUND** |
| `.cursor/rules/` | **NOT FOUND** |
| Any `.mdc` files in repo | **NOT FOUND** |
| `woosoo-platform.code-workspace` | **NOT FOUND** |
| Any `.code-workspace` file | **NOT FOUND** |
| Cursor mention in `USAGE_GUIDE.md` | **NOT FOUND** |
| Cursor mention in `AGENT_USAGE_GUIDE.md` | **NOT FOUND** |

### Verdict

**Cursor hybrid mode is not set up.** The audit scope referenced it as if it existed; it does not. All documentation is Claude Code native.

### Failure Modes If Someone Assumes Cursor Rules Are Active

If an operator runs tasks via Cursor IDE assuming `.cursor/rules/*.mdc` govern the session:
- No rules would load — Cursor would operate without project context
- Agent routing (Contrarian first, per-app scope, tier classification) would not be enforced
- Immutable rules (backend owns truth, no hardcoded IPs, single-app boundary) would be silent
- The operator would receive generic Cursor output unconstrained by the Woosoo OS

If Cursor hybrid mode is intended, open `plt-case-cursor-hybrid-setup` to create `.cursor/rules/woosoo.mdc` (and note: AGENTS.md wins over `.cursor/rules/` if they conflict — the `.mdc` file should reference AGENTS.md as authoritative, not duplicate it).

---

## 5. Obsidian Vault Status

### What Was Checked

| Item | Result |
|---|---|
| `.obsidian/` directory | **NOT FOUND** |
| `CASE_REGISTRY.md` (anywhere in repo) | **NOT FOUND** |
| `VAULT_INDEX.md` (anywhere in repo) | **NOT FOUND** |
| `CONTRACTS_HUB.md` (anywhere in repo) | **NOT FOUND** |
| `bases/` directory | **NOT FOUND** |
| `canvas/` directory | **NOT FOUND** |
| `docs/operator/` directory | **NOT FOUND** |
| `scripts/obsidian-lint.ps1` | **NOT FOUND** |
| `scripts/obsidian-bootstrap.sh` | **NOT FOUND** |
| `scripts/obsidian-registry.sh` | **NOT FOUND** |

**obsidian-lint.ps1 run result: N/A — script does not exist. Exit status: cannot run.**

### What Exists Instead

The platform uses a **flat case file system**:
- `docs/cases/<slug>.md` — per-task case files (65+ files)
- `docs/README.md` — documentation index (8 sections)
- `state/QUEUE.md` — machine-readable priority queue
- `state/DONE.md` — append-only verified completion log
- `contracts/*.contract.md` — 6 cross-app data contracts

### Frontmatter Convention (Sampled 3 Case Files)

Consistent pattern across all sampled files (`nex-case-011`, `plt-case-001`, `tab-case-001`):

```yaml
---
status: canonical        # or: archived, under-review
last_reviewed: YYYY-MM-DD
scope: <woosoo-nexus | tablet-ordering-pwa | woosoo-print-bridge | woosoo-platform | ecosystem>
---
```

This frontmatter is **Obsidian-compatible** — if Obsidian were adopted, the vault could be initialized on the existing `docs/` directory without a frontmatter migration. Wikilinks and dataview queries would require a separate setup pass.

### Verdict

The repo is not an Obsidian vault and has no Obsidian infrastructure. The existing case file system is functional and well-structured. If Obsidian adoption is desired, open `plt-case-obsidian-vault-init`.

---

## 6. ultrathink / Deep-Reasoning Policy

### Current State

| Location | ultrathink / extended thinking mentioned? |
|---|---|
| `AGENTS.md` | No |
| `PROTOCOL.md` | No |
| `docs/AGENT_USAGE_GUIDE.md` | No |
| `docs/USAGE_GUIDE.md` | No |
| `hooks/execute.md` | No |
| `hooks/work.md` | No |
| All `.claude/agents/` definitions | No |

### What Does Exist

- `AGENTS.md:244–252`: opus assigned to Executioner; Tier 3 uses opus Executioner
- `docs/AGENT_USAGE_GUIDE.md:294`: "escalate Specialist to opus only for security/race/payment"
- No guidance on **when to request extended thinking** from any model

### Gap

"ultrathink" and extended thinking are user-initiated session behaviors — the operator must know to invoke them. No documented policy exists for:
- Which task types warrant extended thinking
- Whether extended thinking should be the default for Tier 3 Contrarian analysis
- How to signal to the system that a deep-reasoning pass is needed

### Recommendation

Open `plt-case-ultrathink-policy` to add a short policy block to `AGENTS.md` (e.g., "invoke extended thinking when: Tier 3 + auth/payment/race conditions; when Contrarian written risk analysis is required; when Executioner verdict is REJECTED and root cause is unclear"). This is a doc-only change, Tier 1.

---

## 7. Folder Structure Assessment

### Current Layout

```
woosoo-platform/
├── AGENTS.md              ← canonical AI OS entrypoint
├── PROTOCOL.md            ← concise routing reference
├── CLAUDE.local.md        ← personal scratchpad (non-authoritative)
├── APPLICATION_MATERIALS.md ← portfolio document
├── compose.yaml           ← Docker orchestration
├── skills-lock.json       ← Superpowers skill dependency manifest
├── Woosoo_BRD_v1.docx     ← ⚠ binary at root
├── Woosoo_BRD_v2.docx     ← ⚠ binary at root
├── Woosoo_Cost_Estimate.docx ← ⚠ binary at root
├── Woosoo_Technical_Insights.docx ← ⚠ binary at root
├── .claude/               ← Claude Code config (agents + skills + settings)
├── .agents/               ← Extended skill library (Superpowers imports)
├── .codex/                ← Codex TOML agent definitions (mirror of .claude/)
├── contracts/             ← 6 cross-app data contracts
├── docker/                ← Docker infrastructure configs
├── docs/                  ← All documentation (vault root if Obsidian adopted)
│   ├── cases/             ← 65+ case files (canonical task state)
│   ├── business/          ← Business specs (markdown)
│   ├── audits/            ← Audit reports
│   ├── archive/           ← Historical records
│   └── deployment/        ← Deployment guides
├── hooks/                 ← 9 orchestration hooks
├── inbox/                 ← RAW.md + TRIAGED.md (task intake queue)
├── plan/                  ← ⚠ 1 stale plan file
├── scripts/               ← Utility + deployment scripts
│   ├── deployment/        ← Active deployment scripts
│   │   └── legacy/        ← 4 deprecated scripts (correctly isolated)
│   └── _archive-docs-2026-05.ps1 ← ⚠ stale one-shot script
└── state/                 ← Machine-readable orchestration state
```

### Prioritized Issues

| # | Item | Location | Severity | Rationale |
|---|---|---|---|---|
| 1 | Broken path refs | `.agents/skills/ui-ux-pro-max/data`, `scripts` | **Should-Fix** | Files contain `../../../src/ui-ux-pro-max/` which doesn't exist; will confuse any agent loading this skill |
| 2 | Stale archive script | `scripts/_archive-docs-2026-05.ps1` | Nice-to-have | One-shot archive that ran 2026-05-14; operation complete; dead code in active scripts directory |
| 3 | `.docx` files at root | `Woosoo_BRD_v1.docx`, `Woosoo_BRD_v2.docx`, `Woosoo_Cost_Estimate.docx`, `Woosoo_Technical_Insights.docx` | Nice-to-have | Binary business artifacts at repo root; should be in `docs/business-materials/`; no path hardcoded in code |
| 4 | Stale plan file | `plan/refactor-woosoo-nexus-n1-query-fixes-1.md` | Nice-to-have | Status: Planned (2026-05-16); not in QUEUE.md; no active case file; entire `plan/` dir holds only this file |
| 5 | `DONE.md` backfill | `state/DONE.md` | Nice-to-have | QUEUE.md flags: NEX-CASE-001/008/009, TAB-CASE-001..004, PRN-CASE-001/002 have APPROVED verdicts but no DONE.md rows |

**What NOT to touch:**
- `scripts/deployment/legacy/` — correctly isolated; has its own README; not referenced by active scripts
- `.agents/` vs `.claude/` skill overlap — by design; `.agents/` is extended library, `.claude/` is working subset
- `.codex/agents/` — TOML mirror of `.claude/agents/`; serves a different runtime (Codex); leave as-is

---

## 8. Inbox Backlog

Two items in `inbox/RAW.md` are marked `needs_triage` and have not been converted to case files:

### RAW-20260523-001 — CRITICAL (Triage Immediately)

```
severity:   Critical
app:        tablet-ordering-pwa + woosoo-nexus (cross-boundary)
symptom:    POST /api/devices/create-order returning 500 error; browser console error
status:     needs_triage
```

This is a P1 cross-boundary bug. The cross-app nature means it will require a Tier 3 Contrarian pass and likely a SPLIT into at minimum a nexus case + tablet case. **This should be the next triage action** — run `triage RAW-20260523-001`.

### RAW-20260522-001 — Medium

```
severity:   Medium
app:        woosoo-platform
symptom:    Codex MCP GitHub login auth failure
status:     needs_triage
```

Medium priority; platform-only; run `triage RAW-20260522-001` after the critical item.

---

## 9. Prioritized Reorganization Plan

### Phase 1 — Do Now (zero code risk, no approvals needed)

| # | Action | Who | Effort |
|---|---|---|---|
| 1.1 | `triage RAW-20260523-001` — convert POST 500 error to case file | Operator → Contrarian | 30 min |
| 1.2 | `triage RAW-20260522-001` — Codex MCP auth failure | Operator → Contrarian | 15 min |

### Phase 2 — Should-Fix (low risk, documentation + cleanup tasks)

| # | Action | Proposed Case | Effort |
|---|---|---|---|
| 2.1 | Remove `.agents/skills/ui-ux-pro-max/data` and `.agents/skills/ui-ux-pro-max/scripts` (broken path refs) | plt-case-superpowers-skill-cleanup | 5 min |
| 2.2 | Decide brainstorming gate fate (Option A/B/C from §3) and update AGENTS.md accordingly | plt-case-brainstorm-gate-integration | 1–2 hrs |
| 2.3 | Add ultrathink policy block to AGENTS.md (Tier 3 + security/race/payment triggers) | plt-case-ultrathink-policy | 30 min |
| 2.4 | Archive `plan/refactor-woosoo-nexus-n1-query-fixes-1.md` → `docs/archive/` and remove `plan/` dir | plt-case-superpowers-skill-cleanup | 5 min |
| 2.5 | Backfill `state/DONE.md` for NEX-CASE-001/008/009, TAB-CASE-001..004, PRN-CASE-001/002 | plt-case-done-backfill | 20 min |

### Phase 3 — Nice-to-Have (safe, whenever convenient)

| # | Action | Proposed Case | Effort |
|---|---|---|---|
| 3.1 | Move 4 `.docx` files → `docs/business-materials/` | plt-case-folder-cleanup | 5 min |
| 3.2 | Delete `scripts/_archive-docs-2026-05.ps1` | plt-case-folder-cleanup | 2 min |
| 3.3 | Decide Cursor hybrid mode adoption → if yes, open `plt-case-cursor-hybrid-setup` | Operator decision | — |
| 3.4 | Decide Obsidian vault adoption → if yes, open `plt-case-obsidian-vault-init` | Operator decision | — |
| 3.5 | Decide Superpowers skill fate → promote to `.claude/skills/` vs archive vs leave as-is | plt-case-superpowers-skill-cleanup | — |

---

## 10. Follow-up Task Slugs

| Slug | Scope | Tier | Priority | Blocks |
|---|---|---|---|---|
| _(triage RAW-20260523-001)_ | woosoo-nexus + tablet | 3 | **P1 — do first** | opens the actual case |
| _(triage RAW-20260522-001)_ | woosoo-platform | 2 | P2 | opens the actual case |
| `plt-case-brainstorm-gate-integration` | woosoo-platform | 1 | P2 | brainstorming wiring decision |
| `plt-case-ultrathink-policy` | woosoo-platform | 1 | P2 | AGENTS.md doc update only |
| `plt-case-superpowers-skill-cleanup` | woosoo-platform | 1 | P2 | removes broken refs + stale files |
| `plt-case-done-backfill` | woosoo-platform | 1 | P3 | state/DONE.md accuracy |
| `plt-case-folder-cleanup` | woosoo-platform | 1 | P3 | .docx move + archive script delete |
| `plt-case-cursor-hybrid-setup` | woosoo-platform | 2 | Optional | Cursor adoption decision |
| `plt-case-obsidian-vault-init` | woosoo-platform | 2 | Optional | Obsidian adoption decision |

---

## Appendix: Evidence Index

| Finding | File | Lines / Evidence |
|---|---|---|
| 4-agent chain | `AGENTS.md` | 175–180 |
| 4-agent chain (skill) | `.claude/skills/agent-sequence/SKILL.md` | 6–26 |
| Triage tiers | `AGENTS.md` | 186–191 |
| Triage tiers (protocol) | `PROTOCOL.md` | 28–34 |
| Model policy | `AGENTS.md` | 244–252 |
| Model escalation rule | `docs/AGENT_USAGE_GUIDE.md` | 294 |
| Immutable rules | `AGENTS.md` | 59–67 |
| Hook dispatch (execute) | `hooks/execute.md` | 53–66 |
| Hook dispatch (work) | `hooks/work.md` | 104–122 |
| Contrarian definition | `.claude/agents/contrarian.md` | full file (102 lines) |
| Executioner definition | `.claude/agents/executioner.md` | full file (84 lines) |
| Verifier bash allowlist | `.claude/agents/verifier.md` | 20–44 |
| Brainstorming hard-gate | `.agents/skills/brainstorming/SKILL.md` | 1–14 |
| Brainstorming output path | `.agents/skills/brainstorming/SKILL.md` | 29 |
| Superpowers reference | `.agents/skills/executing-plans/SKILL.md` | 14 |
| skills-lock.json | `skills-lock.json` | root (Superpowers skill source hashes) |
| ui-ux-pro-max broken refs | `.agents/skills/ui-ux-pro-max/data`, `scripts` | content: `../../../src/ui-ux-pro-max/...` |
| No Cursor layer | filesystem | `find /home/user/woosoo-platform -type d -name ".cursor"` → no results |
| No Obsidian vault | filesystem | `find /home/user/woosoo-platform -name ".obsidian"` → no results |
| No obsidian-lint.ps1 | `scripts/` | not present |
| Frontmatter convention | `docs/cases/nex-case-011-*.md` | lines 1–3 (status/last_reviewed/scope) |
| Frontmatter convention | `docs/cases/plt-case-001-*.md` | lines 1–3 |
| Frontmatter convention | `docs/cases/tab-case-001-*.md` | lines 1–3 |
| DONE.md backfill note | `state/QUEUE.md` | reconciliation comment block |
| RAW-20260523-001 | `inbox/RAW.md` | Critical, cross-boundary 500 error |
| RAW-20260522-001 | `inbox/RAW.md` | Medium, Codex MCP auth |
| Stale plan file | `plan/refactor-woosoo-nexus-n1-query-fixes-1.md` | frontmatter: status: Planned, 2026-05-16 |
| Archive script | `scripts/_archive-docs-2026-05.ps1` | line 1: "One-shot archive script for the 2026-05-14 documentation audit" |
| .docx files | repo root | `Woosoo_BRD_v1.docx`, `Woosoo_BRD_v2.docx`, `Woosoo_Cost_Estimate.docx`, `Woosoo_Technical_Insights.docx` |
| Definition of Done | `docs/AGENT_DEFAULT_INSTRUCTIONS.md` | 73–84 |
| 15 quality rules | `docs/AGENT_DEFAULT_INSTRUCTIONS.md` | 183–443 |
| Bucket A clear | `state/WORK.md` | lines 74–77 |
| Bucket B in-progress | `state/QUEUE.md` | Bucket B table (6 items) |
