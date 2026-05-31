# Hook: triage

**Triggers:** "triage <RAW-ID>" · "convert this to a case" · "make a case"

Convert a raw intake entry into a flat case file. Do not implement fixes.

---

## Step 1 — Read

1. `inbox/RAW.md` — the specified RAW entry
2. `state/DEPS.md` — status column only
3. Existing `docs/cases/*.md` filenames — to avoid duplicate IDs and duplicate cases

Do not read app source files unless the user explicitly asks for investigation instead of triage.
Do not load contracts unless contract impact is already confirmed by the raw report.

---

## Step 2 — Assign Case ID And Slug

Use these prefixes:
- `nex-case-NNN-*` for `woosoo-nexus`
- `tab-case-NNN-*` for `tablet-ordering-pwa`
- `prn-case-NNN-*` for `woosoo-print-bridge`
- `plt-case-NNN-*` for `woosoo-platform`

Check existing flat case files in `docs/cases/` and choose the next available number for that prefix.

---

## Step 3 — Create Case File

Create:

```text
docs/cases/<task-slug>.md
```

Required sections:
- YAML frontmatter with `status: canonical`, `last_reviewed`, and `scope`
- `## Run State`
- `## Handoff`
- `## Tier`
- `## Branch`
- `## Problem`
- `## Contrarian Review`
- `## Investigation`
- `## Proposed Fix`
- `## Files Changed`
- `## Verification`
- `## Specialist Handoff`
- `## Executioner Verdict`
- `## Remaining Risks`

Initial Run State:

```markdown
- task_slug: <task-slug>
- tier: <1 | 2 | 3>
- branch: <current git branch or explicit user override>
- status: IN_PROGRESS
- last_completed_agent: contrarian
- next_agent: specialist:<name>
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: YYYY-MM-DD
```

---

## Step 4 — Update Queue

Append or update one row in `state/QUEUE.md`:

```markdown
| <priority> | <CASE-ID> | <app> | <description> | <tier> | <dep or none> | queued |
```

Priority guide:
- P1: critical or production-impacting
- P2: high severity or dependency-unlocking
- P3: standard work
- P4: low severity

---

## Step 5 — Update Intake Index

In `inbox/RAW.md`, change the RAW entry status to:

```text
triaged -> <CASE-ID>
```

Append one row to `inbox/TRIAGED.md`.

---

## Step 6 — Output

```markdown
## Triage Complete

Case ID:  <CASE-ID>
File:     docs/cases/<task-slug>.md
Priority: <P1/P2/P3/P4>
Queue:    Added to state/QUEUE.md

To execute: say `work`.
To execute immediately: say `execute <CASE-ID>`.
```
