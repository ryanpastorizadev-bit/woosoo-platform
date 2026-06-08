# Hook: status

**Triggers:** "status" · "what's pending" · "progress" · "state"

Report current orchestration state without loading app source or contracts.

---

## Step 1 — Read Only State Files

Read, in this order:
1. `state/WORK.md`
2. `state/QUEUE.md`
3. `state/DEPS.md` — status rows only unless a dependency is active
4. `state/DONE.md` — recent rows only

**Obsidian map (optional navigation):** `docs/cases/OPERATOR_HOME.md` embeds the same state;
`docs/cases/CASE_REGISTRY.md` lists all cases. Refer operators to OPERATOR_HOME for visual status.

Do not read:
- app source files
- contracts
- all case files
- archive files

---

## Step 2 — Check Case Pointer

If `state/WORK.md` points to an active `case_file`, read only that case file's `## Run State`
and `## Handoff` blocks when the cache is insufficient or contradictory.

If case state conflicts with `state/WORK.md`, report the conflict and trust the case file.

---

## Step 3 — Output

Use this format:

```markdown
# Project Status — YYYY-MM-DD

## Active Task
<case_id> · <app> · <status> · <description>
Case file: <path>
Next agent: <from case Run State, if read>
Agent left off: <Last Agent note from WORK.md>

## Queue
<top 5 rows from state/QUEUE.md>

## Blocked
<blocked rows and required deps, or "none">

## Recently Approved
<recent rows from state/DONE.md, or "none">

## Cross-App Dependencies
<state/DEPS.md rows whose status is not confirmed, or "none">

## Recommended Next Move
<one sentence>
```
