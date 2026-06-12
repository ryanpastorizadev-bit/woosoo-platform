# Hook: handover

**Triggers:** "handover" · "sync" · "after verified"

Handover records approved work and clears the active cache. It runs only after Executioner approval.

---

## Step 1 — Preconditions

Read:
1. `docs/cases/<task-slug>.md`
2. `state/WORK.md`

The case must show:
- `last_completed_agent: executioner`
- `next_agent: done`
- `## Executioner Verdict` = `APPROVED`

If these are missing, stop. Do not write to `state/DONE.md`.

---

## Step 2 — Obsidian hygiene + Lessons capture

Ensure `docs/cases/CASE_REGISTRY.md` lists the case (`scripts/obsidian-case-registry.ps1`).
Operator can track completion on `docs/cases/OPS_KANBAN.md` or `docs/cases/OPERATOR_HOME.md`.

**Lessons capture (mandatory check):** if this task involved a mistake, a wrong assumption, a
repeated failure, or a non-obvious gotcha, append an entry to `docs/LESSONS.md` (symptom → root
cause → guard). If the same root cause has now appeared twice, promote its guard to an enforced
rule in `docs/AGENT_DEFAULT_INSTRUCTIONS.md § Extended Rules` and link it from the ledger.

## Step 3 — Update State Files

Append to `state/DONE.md`:

```markdown
| <CASE-ID> | <app> | <YYYY-MM-DD> | <verification evidence one-line> | APPROVED | <DEP-NNN or none> | <note> |
```

Update `state/QUEUE.md`:
- set the case row status to `done`

Update `state/DEPS.md` if this case provides a dependency:
- set provider dependency to `confirmed`
- record verification evidence
- unblock consumer queue rows only when evidence is sufficient

Update `state/WORK.md`:
- clear active case fields or point to the next queued case
- set status to `done`

---

## Step 4 — Prune If Needed

- Keep the last 30 approved rows in `state/DONE.md`
- Move older approved rows to `docs/archive/DONE_ARCHIVE.md`
- Do not archive active or blocked cases

---

## Step 5 — Output

```markdown
## Handover Complete

Case:          <CASE-ID>
App:           <app>
Verified:      <date>
Evidence:      <validation evidence>

Files updated:
- state/DONE.md
- state/QUEUE.md
- state/DEPS.md, if applicable
- state/WORK.md

Dependencies unlocked: <list or none>
Risks remaining:       <list or none>
Next task:             <next queued case or "none">
```
