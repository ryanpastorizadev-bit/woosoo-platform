---
status: canonical
last_reviewed: 2026-06-08
scope: ecosystem
---

# Vault Index

**Agents and operators:** start here when navigating the Obsidian vault (platform repo root).
Same files agents read on disk — Obsidian adds graph, search, Kanban, and embeds.

## Daily surfaces

| Note | Who | Purpose |
|------|-----|---------|
| [[cases/OPERATOR_HOME\|OPERATOR_HOME]] | Operator | Pin — embeds `state/WORK`, queue, stability |
| [[cases/OPS_KANBAN]] | Operator | Bucket B Pi ops (Kanban view) |
| `state/WORK.md` | **Agents** | Active task cache (case file wins on conflict) |
| `state/QUEUE.md` | **Agents** | Priority queue |

## Case navigation

| Note | Purpose |
|------|---------|
| [[cases/CASE_REGISTRY]] | **Full wikilink list** — fixes graph orphans for all cases |
| [[cases/CASE_DASHBOARD]] | Dataview dashboards — open / blocked / stale across all cases |
| [[cases/CASES.base\|CASES.base]] | Bases — table + board-by-status + per-app views (auto from projected frontmatter) |
| [[cases/CASE_INDEX]] | Dataview — recently reviewed canonical cases |
| [[cases/CONTRACTS_HUB]] | Cross-app contracts |
| `docs/cases/_TEMPLATE.md` | New case template |

## Visual maps (Canvas)

| Canvas | Purpose |
|--------|---------|
| [[architecture/SYSTEM_MAP.canvas\|SYSTEM_MAP]] | Apps, data flow, and the contract governing each boundary |
| [[cases/DEPLOY_SEQUENCE.canvas\|DEPLOY_SEQUENCE]] | Bucket B deploy-gate ordering (mirrors `OPS_KANBAN`) |

## Canonical docs

| Note | Purpose |
|------|---------|
| [[DOCS_HUB]] | Agent boot docs, deployment, audits |
| [[docs/README\|README]] | Documentation index (this tree) |
| [[LESSONS]] | Recurring-issues ledger — read before work, append after mistakes |
| [[obsidian-setup-guide]] | Vault bootstrap + plugins |
| [[USAGE_GUIDE]] | Operator runbook + Obsidian §6 |
| [[AI_CONTEXT]] | Architecture context for agents |
| [[RESUME_PROTOCOL]] | Case-file resume discipline |

## Agent rules (Obsidian)

1. **Resume** from `docs/cases/<slug>.md` — not from Obsidian UI state.
2. **Cross-reference** related cases with `[[case-slug]]` wikilinks in case bodies.
3. **New case** → add to [[cases/CASE_REGISTRY]] (or run `scripts/obsidian-case-registry.ps1`).
4. **Operator** edits in Obsidian sync via Git; agents trust committed case `## Run State`.
5. **Expected orphans** (intentional): `hooks/`, `state/`, `inbox/`, `Templates/` — linked from this index, not the graph.
6. **Excluded from the vault** (`userIgnoreFilters` in `scripts/obsidian/app.json`): sibling app repos, `node_modules/`, `vendor/`, and `APPLICATION_MATERIALS.md` (personal portfolio, not platform knowledge). Re-run `scripts/obsidian-bootstrap.ps1` after changing exclusions.

Bootstrap: `scripts/obsidian-bootstrap.ps1` · Graph colors: cases / contracts / state / operator
