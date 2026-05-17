# Hook: unlock

**Triggers:** "blocked" · "unlock" · "dependency" · "can X proceed"

Determine whether a blocked case can proceed.

---

## Step 1 — Read

1. `docs/cases/<task-slug>.md` for the blocked case
2. `state/DEPS.md`
3. `state/QUEUE.md`
4. Relevant contract file only if the dependency is contract-bound

---

## Step 2 — Evaluate Dependency

For each blocking dependency, confirm:
- Dep ID
- provider app
- consumer app
- required output
- status
- verification evidence
- contract file, if applicable

Do not unlock from plans, comments, intent, or unverified code.

---

## Step 3 — If Confirmed

If dependency status is `confirmed` and evidence is sufficient:
- update the case handoff with the unlock evidence
- update `state/QUEUE.md` row status from `blocked` to `queued`
- update `state/WORK.md` only if this is the active case

---

## Step 4 — If Not Confirmed

If evidence is missing or status is not `confirmed`:
- keep the case blocked
- record the missing evidence
- report the provider app and exact required validation

---

## Step 5 — Output

```markdown
## Unlock Result

Case:       <CASE-ID>
Dependency: <DEP-ID>
Status:     unlocked / still blocked
Evidence:   <evidence or missing item>
Next step:  <specific action>
```
