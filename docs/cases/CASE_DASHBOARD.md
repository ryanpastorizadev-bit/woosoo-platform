---
status: canonical
last_reviewed: 2026-06-08
scope: ecosystem
---

# Case Dashboard (live run-state)

Live work-state across all cases. Requires the **Dataview** community plugin. Queries read the
derived frontmatter (`run_status`, `app`, `tier`, `updated`, `tags`) that
`scripts/obsidian-case-registry.ps1` projects from each case's `## Run State` body — the body
stays the source of truth, so **re-run the registry script after changing run state** to refresh
these views. Static index: [[CASE_INDEX]] · Full list: [[CASE_REGISTRY]] · Home: [[OPERATOR_HOME]] · Bases: [[CASES.base\|CASES.base]] · Curated Pi-ops: [[OPS_KANBAN]]

> [!info] Why this exists
> 85+ case files carry rich run-state, but it lived in body sections Dataview can't read. The
> registry script now mirrors it into frontmatter, so the queries below actually resolve.

## Blocked / interrupted (look here first)

```dataview
TABLE WITHOUT ID file.link AS Case, app AS App, tier AS Tier, next_agent AS "Next agent", updated AS Updated
FROM "docs/cases"
WHERE run_status = "BLOCKED" OR interrupted = true
SORT updated DESC
```

## Open work by app

```dataview
TABLE WITHOUT ID rows.file.link AS Cases, rows.run_status AS Status, rows.tier AS Tier
FROM "docs/cases"
WHERE run_status AND run_status != "COMPLETE"
GROUP BY app
SORT app ASC
```

## Recently active

```dataview
TABLE WITHOUT ID file.link AS Case, run_status AS Status, app AS App, next_agent AS "Next agent", updated AS Updated
FROM "docs/cases"
WHERE run_status AND run_status != "COMPLETE"
SORT updated DESC
LIMIT 15
```

## Stale reviews (canonical, not reviewed in 30+ days)

```dataview
TABLE WITHOUT ID file.link AS Case, last_reviewed AS "Last reviewed", run_status AS Status, app AS App
FROM "docs/cases"
WHERE status = "canonical" AND last_reviewed AND (date(today) - last_reviewed) > dur(30 days)
SORT last_reviewed ASC
```

## Counts by status

```dataview
TABLE WITHOUT ID rows.run_status AS Status, length(rows) AS Count
FROM "docs/cases"
WHERE run_status
GROUP BY run_status
SORT run_status ASC
```
