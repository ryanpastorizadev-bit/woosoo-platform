---
status: canonical
last_reviewed: 2026-06-10
scope: ecosystem
---

# Case Dashboard (live run-state)

Live work-state across 85+ cases. Requires **Dataview** ([activate plugins](../obsidian-setup-guide.md#activate-community-plugins)).
Queries use frontmatter (`run_status`, `app`, `tier`, `updated`, `tags`) projected by
`scripts/obsidian-case-registry.ps1` from each file's `## Run State` body — **re-run the registry
script after run-state edits**. Hub links: [[CASE_INDEX]] · [[CASE_REGISTRY]] · [[OPERATOR_HOME]] ·
[[CASES.base\|CASES.base]] · [[OPS_KANBAN]]

> [!warning] Empty tables?
> If you see raw ` ```dataview ` blocks or zero rows, Dataview is not active. Fix:
> Settings → Community plugins → **ON** → enable **Dataview** → Restricted mode **OFF** → restart
> Obsidian → `Ctrl+P` → **Dataview: Force refresh**. Until then use [[CASE_REGISTRY]] or
> [[CASES.base\|CASES.base]] (Bases core plugin).

> [!tip] Daily progress vs all-case audit
> **Live deploy work** = [[OPERATOR_HOME]] + `state/QUEUE.md` (Bucket B). This dashboard shows
> every non-COMPLETE case file — many are stale/deferred, not active tasks.

## At a glance

Total cases and completion breakdown — auto-updates when `obsidian-case-registry.ps1` is run after any Run State edit.

```dataview
TABLE WITHOUT ID rows.run_status AS Status, length(rows) AS Count
FROM "docs/cases"
WHERE run_status
GROUP BY run_status
SORT run_status ASC
```

```dataview
LIST WITHOUT ID length(rows) + " total cases tracked"
FROM "docs/cases"
WHERE run_status
GROUP BY true
```

---

## Bucket B deploy readiness (Pi ops)

Cases tied to `state/QUEUE.md` Bucket B. For the live queue table see [[OPERATOR_HOME#Deploy queue (Bucket B)]].

```dataview
TABLE WITHOUT ID file.link AS Case, run_status AS Status, app AS App, next_agent AS "Next agent", updated AS Updated
FROM "docs/cases"
WHERE file.name IN (
  "nex-case-011-duplicate-order-printing",
  "nex-case-014-session-domain-login-419",
  "nex-case-007-pos-payment-outbox-session-reset",
  "infra-case-004-script-flow-unification",
  "infra-case-002-deploy-stability-wrappers",
  "infra-case-001-pi-platform-migration",
  "prn-rebuild-apk-scp-pi"
)
SORT updated DESC
```

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

