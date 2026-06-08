---
status: canonical
last_reviewed: 2026-06-08
scope: ecosystem
---

# PLT-CASE — Obsidian operator wiring

Wire Obsidian into the agent boot layer as the operator UI (same files, richer navigation).

## Specialist Investigation & Implementation

**Investigated:** Obsidian was bootstrapped (plugins, OPERATOR_HOME) but absent from `AGENTS.md`,
`USAGE_GUIDE.md`, `PROTOCOL.md`, hooks, `AI_CONTEXT.md`, and `.cursor/rules`.

**Implemented (phase 1):** OPS_KANBAN, CONTRACTS_HUB, operator daily logs, bootstrap extras, OPERATOR_HOME refresh, boot-layer pointers.

**Implemented (phase 2 — agents refer + orphan fix):**
- `docs/VAULT_INDEX.md`, `docs/DOCS_HUB.md`, `docs/cases/CASE_REGISTRY.md` (84-case wikilink hub)
- `scripts/obsidian-case-registry.ps1`, `scripts/obsidian-lint.ps1`
- AGENTS.md Step 1c (vault map); RESUME_PROTOCOL; AGENT_DEFAULT_INSTRUCTIONS; all key hooks; contrarian + scribe agents
- `_TEMPLATE` + `Templates/CASE_FILE` vault links section; orphan policy in obsidian-setup-guide

**Why:** Same files on disk — agents use vault hubs for navigation; CASE_REGISTRY eliminates case graph orphans.

## Verifier

**Verified 2026-06-08 — all skill wiring checks pass:**

- ✅ 7 symlinks created in `.claude/skills/`: `json-canvas`, `llm-wiki`, `obsidian-automation`, `obsidian-bases`, `obsidian-cli`, `obsidian-markdown`, `obsidian-vault` — all pointing to `.agents/skills/<slug>`; harness now loads them
- ✅ `skills-lock.json` key renamed `"Obsidian Automation"` → `"obsidian-automation"` to match slug convention
- ✅ `AGENTS.md` Skill Discovery table: +7 Obsidian trigger rows (Contrarian now recommends these skills)
- ✅ `.cursor/rules/woosoo.mdc`: added `## Obsidian Skills Reference` section with skill→file routing table and mandatory checkpoint rules for Cursor specialist mode
- ⚠️ `.claude/agents/scribe.md` `skills:` addition blocked by harness classifier — requires manual edit or operator permission grant (see below)

**Pending (manual):** Add to `.claude/agents/scribe.md` `skills:` block:
```yaml
  - obsidian-markdown
  - obsidian-vault
```

## Run State

```
- last_completed_agent: verifier
- next_agent: executioner
- active_runner: cursor
- status: IN_PROGRESS
- updated: 2026-06-08
```
