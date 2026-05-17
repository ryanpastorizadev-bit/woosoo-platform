---
status: canonical
scope: ecosystem
---

# Task Queue

<!-- Sorted by priority. Agents pull the first row where status=queued AND dep is none or confirmed. -->
<!-- Add rows when triaged from inbox. Update status as work progresses.                           -->
<!-- Prune completed rows weekly — move summary to docs/archive/.                                  -->
<!-- Last pruned: 2026-05-17                                                                       -->

---

## Pull Rule

Take the **first** row where:
- `status` = `queued`
- `Dep` = `none` **OR** the referenced dep ID is `confirmed` in `state/DEPS.md`

If all queued rows are blocked: report to user, list what must be resolved.

---

## Active Queue

| Priority | Case ID | App | Description | Tier | Dep | Status |
|---|---|---|---|---|---|---|
| P3 | PLT-CASE-002 | woosoo-platform | Complete canonical hook surface | 2 | none | done |

---

## Completed (recent — prune after 7 days)

| Case ID | App | Completed | Evidence |
|---|---|---|---|
| PLT-CASE-002 | woosoo-platform | 2026-05-17 | Hook surface verifier checks passed; Executioner APPROVED |

---
<!--
PRIORITY: P1 (Critical/blocker) | P2 (High) | P3 (Standard) | P4 (Low)
STATUS:   queued | in_progress | blocked | needs_verification | verified | done
TIER:     1 | 2 | 3

PRIORITY GUIDE:
  P1 → Critical severity or production-impacting
  P2 → High severity or dependency-unlocking
  P3 → Standard features and bugs
  P4 → Low severity, nice-to-have

To add a task: run intake → triage → the triage hook appends a row here automatically.
-->
