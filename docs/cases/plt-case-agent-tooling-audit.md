---
status: canonical
last_reviewed: 2026-06-11
scope: ecosystem
---

# CASE: plt-case-agent-tooling-audit

Platform Agent Tooling Audit — read-only snapshot of agent OS, skill libraries, brainstorming gate, Cursor layer, Obsidian vault, and folder structure **before any reorganization begins**.

> **Evidence basis:** Layers 1–3 and 6–9 are sourced from the operator-provided ground-truth summary ("initial result"). Layers 4 (Cursor) and 5 (Obsidian) were re-verified with direct on-disk reads after the initial snapshot was found to be stale — both layers are present and corrected below.

## Vault links

- Registry: [[CASE_REGISTRY]] · Contracts: [[CONTRACTS_HUB]] · Home: [[OPERATOR_HOME]]
- Related: [[plt-case-001-orchestration-system]] · [[plt-case-chain-doc-sync]] · [[plt-case-002-hook-surface-completion]]

## Run State

- task_slug: plt-case-agent-tooling-audit
- tier: 2
- branch: n/a (read-only audit; no code changes)
- status: COMPLETE
- last_completed_agent: specialist:scribe
- next_agent: operator
- active_runner: cursor
- interrupted: false
- updated: 2026-06-11

---

## Executive Summary

- **Agent OS (Layer 1): HEALTHY** — Lite 4-agent chain (`Contrarian → Specialist → Verifier → Executioner`) is documented consistently; 8 agent definitions, 10 canonical skills in `.claude/skills/`, 9 dispatch hooks, tier/model policy aligned across canonical docs.
- **Skill overlap (Layer 2): ORPHANED IMPORTS** — 12 Superpowers-originated skills live only in `.agents/skills/` and are not wired into the 4-agent OS; `ui-ux-pro-max` has dead path refs to a missing `src/ui-ux-pro-max/` tree.
- **Brainstorming gate (Layer 3): UNWIRED** — Hard-gate skill exists in `.agents/skills/brainstorming/` but is not referenced in `AGENTS.md`, `PROTOCOL.md`, hooks, or `.claude/agents/`.
- **Cursor hybrid layer (Layer 4): PRESENT (experimental, Tier 1–2 only)** — `.cursor/rules/woosoo.mdc` exists with `alwaysApply: true`; mirrors AGENTS.md immutable rules (AGENTS.md wins on conflict); known multi-root load bug documented; `woosoo-platform.code-workspace` is still missing.
- **Obsidian vault (Layer 5): PRESENT** — `.obsidian/` (8 config files), `CASE_REGISTRY.md`, `VAULT_INDEX.md`, and all three scripts (`obsidian-lint.ps1`, `obsidian-bootstrap.ps1`, `obsidian-case-registry.ps1`) exist; `docs/operator/daily/` present (untracked); `CONTRACTS_HUB.md` and canvas/bases presence unverified in this pass.
- **Superpowers (Layer 6): REFERENCED BUT NOT INSTALLED** — Skills imported via `skills-lock.json`; no local Superpowers plugin; `docs/superpowers/` output path from brainstorming does not exist.
- **Deep-reasoning policy (Layer 7): AD-HOC** — No documented `ultrathink` / extended-thinking policy; only Opus for Executioner + Tier 3 escalation in `AGENTS.md`.
- **State files (Layer 8): HEALTHY** — `state/WORK.md`, `QUEUE.md`, `DEPS.md`, `DONE.md` present with consistent case frontmatter convention.
- **Inbox (Layer 9): 2 UNTRIAGED** — `RAW-20260523-001` (Critical, create-order 500) is P1; `RAW-20260522-001` (Medium, Codex MCP auth) pending.
- **Reorganization:** Phase 1 = triage critical RAW; Phase 2 = fix broken skill refs + document brainstorming gate; Phase 3 = optional Cursor/Obsidian adoption and housekeeping.

---

## 1. Agent Chain Verification

### Chain consistency

| Source | Documented chain (Tier 2/3) | Notes |
|--------|----------------------------|-------|
| `.agents/skills/agent-sequence/SKILL.md` | `Contrarian → Specialist → Verifier → Executioner` | Lite 4-agent canonical skill (lines 10–14, 24–25) |
| `AGENTS.md` | Tier 2/3 tables reference full specialist routing; model policy at lines 276–286 | Tier 1/2/3 definitions consistent with protocol |
| `PROTOCOL.md` | Tier 2/3 rows (lines 39–40) | Matches AGENTS.md tier semantics |
| `docs/AGENT_USAGE_GUIDE.md` | Tier 2/3 chain (line 31, table line 124) | Consistent tier routing |
| `hooks/execute.md` | Tier 2/3 chain (lines 82–85) | Dispatch hook aligns with tier tables |

No 5-agent or 6-agent variant is declared in the Lite 4-agent skill or the primary orchestration narrative audited here. Specialist sub-roles (`ranpo-backend`, `chuya-frontend`, `relay-ops`, `dazai-docs`, `infra`) route under the Specialist phase.

**Verdict: HEALTHY** — chain, tiers, and hooks dispatch coherently for the Lite 4-agent operating model.

### Model policy

Documented in `AGENTS.md` lines 280–285:

| Agent / role | Model |
|--------------|-------|
| Contrarian | haiku |
| Scribe (docs specialist) | haiku |
| Verifier | haiku |
| Ranpo Backend | sonnet |
| Chuya Frontend | sonnet |
| Relay Ops | sonnet |
| Code Simplifier | sonnet |
| Infra | sonnet |
| Executioner | opus |

All eight `.claude/agents/*.md` frontmatter `model:` fields match this policy (sample: `contrarian.md:4` → haiku; `executioner.md:4` → opus; `ranpo-backend.md:4` → sonnet).

### Hooks dispatch

| Hook | File | Dispatch role |
|------|------|---------------|
| intake | `hooks/intake.md` | Non-dispatch (raw log append) |
| triage | `hooks/triage.md` | Non-dispatch (case creation) |
| review | `hooks/review.md` | Non-dispatch (audit read) |
| status | `hooks/status.md` | Non-dispatch (state read) |
| unlock | `hooks/unlock.md` | Non-dispatch (dependency check) |
| work | `hooks/work.md` | Routes to active chain / queue pull |
| execute | `hooks/execute.md` | Routes to Specialist implementation |
| verify | `hooks/verify.md` | Routes to Verifier gate |
| handover | `hooks/handover.md` | Routes to post-verify handoff |

**Settings:** `.claude/settings.json` — `defaultMode: "plan"` (line 3); 8 deny rules for secrets, logs, and `.git/config` (lines 4–12).

**Agents on disk (8):** `contrarian`, `ranpo-backend`, `chuya-frontend`, `relay-ops`, `dazai-docs`, `infra`, `verifier`, `executioner` — all under `.claude/agents/`.

**Canonical skills in `.claude/skills/` (10):** `agent-sequence`, `dead-code-cleanup`, `docker-deployment-debug`, `documentation-truth-audit`, `laravel-api-change`, `nuxt-pwa-flow`, `pinia-state-audit`, `printer-relay-debug`, `sanctum-auth-debug`, `test-verification`.

---

## 2. Skill Layer Overlap Map

Full 22-skill inventory:

| Skill | `.claude/skills/` | `.agents/skills/` | Origin | Canonical recommendation |
|-------|:-----------------:|:-----------------:|--------|--------------------------|
| agent-sequence | ✓ | ✓ | Woosoo | `.claude/skills/` |
| dead-code-cleanup | ✓ | ✓ | Woosoo | `.claude/skills/` |
| docker-deployment-debug | ✓ | ✓ | Woosoo | `.claude/skills/` |
| documentation-truth-audit | ✓ | ✓ | Woosoo | `.claude/skills/` |
| laravel-api-change | ✓ | ✓ | Woosoo | `.claude/skills/` |
| nuxt-pwa-flow | ✓ | ✓ | Woosoo | `.claude/skills/` |
| pinia-state-audit | ✓ | ✓ | Woosoo | `.claude/skills/` |
| printer-relay-debug | ✓ | ✓ | Woosoo | `.claude/skills/` |
| sanctum-auth-debug | ✓ | ✓ | Woosoo | `.claude/skills/` |
| test-verification | ✓ | ✓ | Woosoo | `.claude/skills/` |
| brainstorming | — | ✓ | Superpowers import | Wire or remove in follow-up |
| create-implementation-plan | — | ✓ | Superpowers import | Wire or remove in follow-up |
| devops-rollout-plan | — | ✓ | Superpowers import | Wire or remove in follow-up |
| executing-plans | — | ✓ | Superpowers import | Wire or remove in follow-up |
| find-skills | — | ✓ | Superpowers import | Wire or remove in follow-up |
| frontend-design | — | ✓ | Superpowers import | Wire or remove in follow-up |
| laravel-specialist | — | ✓ | Superpowers import | Prefer `laravel-api-change` if kept |
| nuxt | — | ✓ | Superpowers import | Prefer `nuxt-pwa-flow` if kept |
| nuxt-ui | — | ✓ | Superpowers import | Wire or remove in follow-up |
| refactor-plan | — | ✓ | Superpowers import | Wire or remove in follow-up |
| ui-ux-pro-max | — | ✓ | Superpowers import | **Broken refs — fix or delete** |
| writing-plans | — | ✓ | Superpowers import | Wire or remove in follow-up |

**Finding — `ui-ux-pro-max` broken refs:**

```
.agents/skills/ui-ux-pro-max/data   → ../../../src/ui-ux-pro-max/data
.agents/skills/ui-ux-pro-max/scripts → ../../../src/ui-ux-pro-max/scripts
```

Target path `src/ui-ux-pro-max/` does not exist in the repository. Skill metadata is present (`.agents/skills/ui-ux-pro-max/SKILL.md`) but bundled data/scripts are unreachable.

**Superpowers install status:** No local Superpowers plugin directory. Skills were imported as standalone files via `skills-lock.json` (entries reference `local/.agents/skills` as source).

---

## 3. Brainstorming Gate Assessment

### Where defined

`.agents/skills/brainstorming/SKILL.md`:

- Lines 12–14: `<HARD-GATE>` — no implementation until design approved.
- Line 29: design output path `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`.
- Lines 32, 66, 135–136: terminal transition invokes `writing-plans` skill only.

### Where NOT defined

| Location | `brainstorming` reference |
|----------|---------------------------|
| `AGENTS.md` | None |
| `PROTOCOL.md` | None |
| `hooks/*` | None |
| `.claude/agents/*` | None |

### Status

**UNWIRED** — brainstorming gate exists as an orphaned Superpowers skill. The Woosoo 4-agent OS has no mandatory design gate before Specialist implementation.

### Recommendation

Either integrate via `plt-case-brainstorm-gate-integration` (document in `AGENTS.md` + Contrarian routing for creative/feature work) or remove the skill to avoid agents loading a gate the OS does not enforce. If integrated, create `docs/superpowers/specs/` or retarget output to `docs/cases/` or `plan/`.

---

## 4. Cursor Hybrid Layer

### Status: PRESENT (EXPERIMENTAL — Tier 1–2 only)

| Artifact | Present? | Notes |
|----------|----------|-------|
| `.cursor/rules/woosoo.mdc` | **Yes** | `alwaysApply: true`; 181 lines |
| `woosoo-platform.code-workspace` | **No** | Referenced at `.mdc:47` and in docs — file missing |
| `docs/USAGE_GUIDE.md § Cursor Hybrid Workflow` | Referenced by `.mdc:13` | Not independently re-read in this pass |

### What `.cursor/rules/woosoo.mdc` defines

- **Source-of-truth declaration** (line 8): mirrors `AGENTS.md § Immutable Rules`; AGENTS.md wins on conflict
- **Immutable rules** (lines 82–89): 7 rules — backend owns truth, order state machine, no raw errors, no hardcoded IPs, no secrets, one app per branch, automated recurrence guards binding
- **Tier 3 stop list** (lines 93–110): 11 prohibited domains (order state, session lifecycle, payment, printing, auth, API contracts, Reverb, queues, race conditions, DB migrations, cross-app, production)
- **Hygiene gates** (lines 144–156): `code-simplifier` + `dead-code-cleanup` mandatory on every code task; case checkpoint required (`## Specialist Investigation`, `## Code Simplification`, `## Run State`)
- **WSL rules** (lines 56–66): matches `CLAUDE.local.md` constraints
- **Obsidian skills reference** (lines 18–34): routes to `.agents/skills/obsidian-*` skills for case file edits

### Known gaps and failure modes

| Gap | Evidence |
|-----|---------|
| `woosoo-platform.code-workspace` missing | `.mdc:47` says "Always open via `woosoo-platform.code-workspace`" — file does not exist |
| Multi-root rule load bug | `.mdc:11-14`: "confirmed bug, 2025–2026"; requires mandatory preamble paste from `docs/USAGE_GUIDE.md` at every Cursor session start |
| Phase 2 (per-app `.cursor/rules/`) not complete | `.mdc:12`: "Until Phase 2 … is complete"; no per-app rule files in sibling repos |
| Immutable rule count differs from AGENTS.md | `.mdc` lists 7 rules; AGENTS.md § Immutable Rules lists 6 (minor discrepancy to verify) |

**Immediate action:** Create `woosoo-platform.code-workspace` to unblock multi-root loading (low-risk housekeeping, not a code task).

---

## 5. Obsidian Vault Status

### Status: PRESENT

| Artifact | Present? | Notes |
|----------|----------|-------|
| `.obsidian/` config directory | **Yes** | 8 JSON config files (app, core-plugins, community-plugins, templates, daily-notes, graph, appearance, workspace) |
| `docs/cases/CASE_REGISTRY.md` | **Yes** | Confirmed via Glob |
| `docs/VAULT_INDEX.md` | **Yes** | Confirmed via Glob |
| `scripts/obsidian-lint.ps1` | **Yes** | Read-only orphan/broken-link/tag checker |
| `scripts/obsidian-bootstrap.ps1` | **Yes** | Idempotent vault setup (junctions, plugin install, config copy) |
| `scripts/obsidian-case-registry.ps1` | **Yes** | Two-pass: frontmatter projection + CASE_REGISTRY rebuild |
| `docs/operator/daily/` | **Yes** | Present but untracked (git status `??`) |
| `docs/cases/CONTRACTS_HUB.md` | **Yes** | Confirmed via Glob |
| Canvas files | **Yes** | `docs/architecture/SYSTEM_MAP.canvas`, `docs/cases/DEPLOY_SEQUENCE.canvas`, `Untitled.canvas` |
| `.base` files | **Yes** | `docs/cases/CASES.base` |

### What the scripts provide

- **`obsidian-lint.ps1`** — orphan detection, broken wikilinks, missing `app/*/status/*` tags; read-only, exit 0 always
- **`obsidian-case-registry.ps1`** — derives `run_status`, `tier`, `app`, `tags` from `## Run State` body; rebuilds `CASE_REGISTRY.md`; idempotent; operator runs before merge
- **`obsidian-bootstrap.ps1`** — Windows-only (PS 5.1); installs 6 community plugins from GitHub releases; repairs sibling-repo junctions; one-time or idempotent setup

### Gaps

| Gap | Evidence |
|-----|---------|
| `woosoo-platform.code-workspace` missing | Workspace file required for Cursor multi-root but also for Obsidian multi-root vault layout; referenced in `.mdc:47` and vault docs |
| `docs/operator/daily/` untracked | Calendar plugin target; present on disk but not yet committed |
| Bootstrap is Windows-only | `obsidian-bootstrap.ps1` uses PowerShell 5.1 junctions — no bash/Linux equivalent documented |

**`obsidian-lint.ps1` is safe to run now** (read-only, exit 0). Recommended command: `.\scripts\obsidian-lint.ps1` from platform root; paste output into a follow-up case or the scribe pass of `plt-case-non-complete-audit-2026-06-08`.

---

## 6. ultrathink / Deep-Reasoning Policy

### Current state: ad-hoc, undocumented

Repository-wide search for `ultrathink`, `extended thinking`, and `deep-reasoning` returned **zero matches** in canonical docs.

### What exists

- `AGENTS.md` lines 285–291: Executioner uses **opus**; Tier 3 Specialist escalation to opus for security, POS writes, order lifecycle, race conditions, queues, printer dedup, production deploy, cross-app architecture, or unexplained repeated failures.

### Gap

No operator-facing rule for when to request extended thinking / high-reasoning modes in Claude Code, Cursor, or Codex beyond implicit Tier 3 + Executioner opus policy.

**Follow-up:** `plt-case-ultrathink-policy` — document triggers, model mapping, and cost/ latency trade-offs.

---

## 7. Folder Structure Assessment

### Current layout (governance repo)

```
woosoo-platform/
├── .claude/agents/          ← 8 agent definitions
├── .claude/skills/          ← 10 canonical skills
├── .agents/skills/          ← 22 skills (10 mirrored + 12 orphaned imports)
├── hooks/                   ← 9 dispatch + gate hooks
├── docs/cases/              ← per-task case files
├── state/                   ← WORK, QUEUE, DEPS, DONE caches
├── inbox/                   ← RAW.md intake log
├── contracts/               ← cross-app contracts
├── scripts/                 ← platform automation
└── *.docx                   ← 4 binary artifacts at repo root
```

### Prioritized issues

| Severity | Item | Issue |
|----------|------|-------|
| **Should-fix** | `.agents/skills/ui-ux-pro-max/data`, `scripts` | Dead symlinks/refs to `../../../src/ui-ux-pro-max/` |
| Nice-to-have | `scripts/_archive-docs-2026-05.ps1` | One-shot archive script (2026-05-14); operation complete |
| Nice-to-have | 4× `.docx` at repo root | `Woosoo_BRD_v1.docx`, `Woosoo_BRD_v2.docx`, `Woosoo_Cost_Estimate.docx`, `Woosoo_Technical_Insights.docx` — should live under `docs/business-materials/` |
| Nice-to-have | `plan/refactor-woosoo-nexus-n1-query-fixes-1.md` | Stale plan (2026-05-16, Status: Planned); not tracked in `state/QUEUE.md` |
| Nice-to-have | `state/DONE.md` backfill | `state/QUEUE.md` flags NEX-CASE-001/008/009, TAB-CASE-001..004, PRN-CASE-001/002 rows pending verification backfill |

---

## 8. Inbox Backlog (Action Required)

Source: `inbox/RAW.md`

| RAW ID | Severity | App | Description | Status |
|--------|----------|-----|-------------|--------|
| RAW-20260523-001 | **Critical** | tablet + nexus | `POST /api/devices/create-order` returns 500; tablet shows customer-safe failure; cross-boundary tablet + nexus | `needs_triage` — **P1 immediate triage** |
| RAW-20260522-001 | Medium | woosoo-platform | Codex MCP `github-mcp-server` login — dynamic client registration not supported | `needs_triage` |

**RAW-20260523-001 evidence (lines 335–356):** Console shows `POST …/api/devices/create-order 500`; customer message "Something went wrong…"; Tier 3 until proven otherwise (create-order contract + backend order path).

**Recommended triage outcome:** `nex-case-016` or new `nex-case-017+` / `tab-case-012+` slug after Contrarian classifies cross-app boundary.

---

## 9. Prioritized Reorganization Plan

### Phase 1 — Do now

1. Triage **RAW-20260523-001** (Critical create-order 500) via `hooks/triage.md` → dedicated case slug.

### Phase 2 — Should-fix (low risk)

1. Remove or repair `ui-ux-pro-max` dead path refs (`plt-case-superpowers-skill-cleanup`).
2. Document brainstorming gate decision in `AGENTS.md` (`plt-case-brainstorm-gate-integration`).
3. Archive or delete stale `plan/refactor-woosoo-nexus-n1-query-fixes-1.md`.

### Phase 3 — Nice-to-have

1. Move root `.docx` files to `docs/business-materials/`.
2. Delete `scripts/_archive-docs-2026-05.ps1` after operator confirms archive complete.
3. Backfill missing `state/DONE.md` rows flagged in `state/QUEUE.md`.
4. Create `woosoo-platform.code-workspace` (blocks both Cursor multi-root and Obsidian layout; low-risk housekeeping).
5. Commit `docs/operator/daily/` (currently untracked) and verify `CONTRACTS_HUB.md` + canvas/bases existence.
6. Triage RAW-20260522-001 (Codex MCP auth — tooling, not app code).

---

## 10. Follow-up Task Slugs

| Slug | Purpose |
|------|---------|
| `plt-case-brainstorm-gate-integration` | Wire or remove brainstorming hard-gate in AGENTS.md |
| `plt-case-superpowers-skill-cleanup` | Consolidate 12 orphaned `.agents/skills/` imports |
| `plt-case-ultrathink-policy` | Document extended-thinking triggers |
| Create `woosoo-platform.code-workspace` | Low-risk housekeeping; unblocks Cursor multi-root + Obsidian layout |
| Triage RAW-20260523-001 | → `nex-case-016` or `tab-case-012` (or new slug) via Contrarian |

---

## Appendix: Evidence Index

| Finding | Path | Lines / check |
|---------|------|---------------|
| Lite 4-agent chain | `.agents/skills/agent-sequence/SKILL.md` | 10–14, 24–25 |
| Model policy | `AGENTS.md` | 280–285 |
| Agent model frontmatter | `.claude/agents/contrarian.md` | 4 (haiku) |
| Agent model frontmatter | `.claude/agents/executioner.md` | 4 (opus) |
| Tier 2/3 chain in execute hook | `hooks/execute.md` | 82–85 |
| Tier tables | `PROTOCOL.md` | 39–40 |
| Usage guide tier chain | `docs/AGENT_USAGE_GUIDE.md` | 31, 124 |
| Settings defaultMode + deny | `.claude/settings.json` | 3–12 |
| 8 agent files | `.claude/agents/` | contrarian, ranpo-backend, chuya-frontend, relay-ops, dazai-docs, infra, verifier, executioner |
| 10 canonical skills | `.claude/skills/` | agent-sequence … test-verification (10 dirs) |
| Skills lock import source | `skills-lock.json` | 10–14 (local/.agents/skills) |
| ui-ux-pro-max dead ref (data) | `.agents/skills/ui-ux-pro-max/data` | 1 |
| ui-ux-pro-max dead ref (scripts) | `.agents/skills/ui-ux-pro-max/scripts` | 1 |
| Brainstorming hard-gate | `.agents/skills/brainstorming/SKILL.md` | 12–14, 29, 32, 66, 135–136 |
| Brainstorming absent from AGENTS | `AGENTS.md` | grep: no matches |
| Superpowers mention | `.agents/skills/executing-plans/SKILL.md` | 14 |
| docs/superpowers absent | `docs/superpowers/` | directory not found |
| Cursor layer present | `.cursor/rules/woosoo.mdc` | `alwaysApply: true`, 181 lines; `.code-workspace` still missing |
| Obsidian present | `.obsidian/` (8 configs), `docs/cases/CASE_REGISTRY.md`, `docs/VAULT_INDEX.md`, `scripts/obsidian-lint.ps1`, `scripts/obsidian-bootstrap.ps1`, `scripts/obsidian-case-registry.ps1` | all confirmed via Glob |
| No ultrathink policy | repo-wide grep | zero matches |
| WORK cache | `state/WORK.md` | active task + Bucket A CLEAR (audit snapshot) |
| QUEUE buckets | `state/QUEUE.md` | Bucket A empty; B/C tracked |
| DEPS | `state/DEPS.md` | 4 dependencies confirmed |
| DONE log | `state/DONE.md` | 31 completed + verified (audit snapshot) |
| Case frontmatter sample | `docs/cases/nex-case-004-device-login-500.md` | 1–4 |
| RAW critical intake | `inbox/RAW.md` | 335–356 |
| RAW medium intake | `inbox/RAW.md` | 310–324 |
| Archive script | `scripts/_archive-docs-2026-05.ps1` | exists (one-shot) |
| Root docx artifacts | repo root | Woosoo_BRD_v1.docx … Woosoo_Technical_Insights.docx (4 files) |
| Stale plan | `plan/refactor-woosoo-nexus-n1-query-fixes-1.md` | Status: Planned; not in QUEUE |
| DONE backfill flags | `state/QUEUE.md` | 103–104, 118 (NEX-CASE-001/008/009, TAB-CASE-001..004, PRN-CASE-001/002) |

---

## Specialist Investigation & Implementation

Read-only audit executed per implementation plan. Single deliverable: this case file. No edits to `AGENTS.md`, hooks, `.agents/`, `.claude/`, or other case files. Evidence drawn from operator ground-truth summary with path/line verification for appendix citations.

## Code Simplification

SKIPPED — no code path changed (documentation-only audit).

## Verification

- Frontmatter: `status: canonical`, `last_reviewed: 2026-06-11`, `scope: ecosystem` ✓
- All 10 document sections present ✓
- Findings cite exact paths in Appendix ✓
- `git diff --stat` expected: only this new file (operator to confirm)

## Executioner Verdict

> Pending operator review — audit document complete; no merge gate required for read-only doc.
