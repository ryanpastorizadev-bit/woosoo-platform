---
status: canonical
last_reviewed: 2026-06-10
scope: ecosystem
---

# Case Index (Obsidian / Dataview)

Canonical case index. Requires **Dataview**; run state lives in each file's `## Run State` body
and is projected to frontmatter by `scripts/obsidian-case-registry.ps1` for [[CASE_DASHBOARD]] and
[[CASES.base|CASES.base]]. Orchestration queue: `state/WORK.md`, `state/QUEUE.md`.

## Recently reviewed cases

```dataview
TABLE last_reviewed, scope
FROM "docs/cases"
WHERE status = "canonical" AND file.name != "CASE_INDEX"
SORT last_reviewed DESC
```

## Hub pages

| Page | Purpose |
|------|---------|
| [[OPERATOR_HOME]] | Daily dashboard — pin this |
| [[CASE_DASHBOARD]] | Dataview — blocked, open-by-app, Bucket B, counts |
| [[CASES.base\|CASES.base]] | Bases — table/board by status (no community plugin) |
| [[CASE_REGISTRY]] | Full case list (wikilink graph hub) |
| [[OPS_KANBAN]] | Bucket B Pi ops (Kanban view) |
| [[CONTRACTS_HUB]] | Cross-app contract links |
| [[VAULT_INDEX]] | Vault navigation + orphan policy |
| [[DOCS_HUB]] | Canonical docs outside cases |

## Setup

See [obsidian-setup-guide.md](../obsidian-setup-guide.md) for vault setup, plugin activation,
Templater, Calendar, and Git sync. New cases: `Templates/CASE_FILE.md` (Templater) or copy [[_TEMPLATE]].
Daily ops: Calendar → `Templates/OPERATOR_LOG.md` → `docs/operator/daily/`.
