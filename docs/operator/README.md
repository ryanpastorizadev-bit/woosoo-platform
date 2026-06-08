---
status: canonical
last_reviewed: 2026-06-08
scope: ecosystem
---

# Operator daily logs

`daily/` holds **Calendar plugin** daily notes — Pi ops evidence, agent session notes, smoke-test results.

- Template: `Templates/OPERATOR_LOG.md` (Templater)
- Bootstrap sets folder via `scripts/obsidian/daily-notes.json`
- Link each log to [[OPERATOR_HOME]] and the active case (`[[plt-case-stability-remediation]]`, etc.)

Agents do not read this folder by default; durable state stays in `docs/cases/<slug>.md`.
