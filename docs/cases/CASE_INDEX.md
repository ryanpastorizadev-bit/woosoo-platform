---
status: canonical
last_reviewed: 2026-06-07
scope: ecosystem
---

# Case Index (Obsidian / Dataview)

Live index of canonical case files. Requires the **Dataview** community plugin in Obsidian.
Task-level run state (`IN_PROGRESS`, `BLOCKED`, `COMPLETE`) lives in each file's `## Run State`
body section — use `state/WORK.md` and `state/QUEUE.md` for orchestration status.

## Recently reviewed cases

```dataview
TABLE last_reviewed, scope
FROM "docs/cases"
WHERE status = "canonical" AND file.name != "CASE_INDEX"
SORT last_reviewed DESC
```

## Setup

See [obsidian-setup-guide.md](../obsidian-setup-guide.md) for vault setup, Templater, and Git sync.
New cases: use `Templates/CASE_FILE.md` (Templater) or copy `docs/cases/_TEMPLATE.md` directly.
