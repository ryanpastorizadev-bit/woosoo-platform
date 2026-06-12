# Hook: work

**Triggers:** "work" · "continue" · "next" · "what's next" · "go" · (no specific command given)

This is the default hook. It routes you to the correct action without loading unnecessary context.

---

## Step 0 — Resume check (mandatory before anything else)

Per `docs/RESUME_PROTOCOL.md`:

1. Determine the task slug.
2. Check `docs/cases/<task-slug>.md`.
   - **`IN_PROGRESS` or `BLOCKED`**: do not restart. Read `## Run State` + `## Handoff`. Adopt `next_agent`. Continue from there — skip to Step 3.
   - **`COMPLETE`**: do not reopen. Go to Step 2 (pull next task).
   - **Absent**: go to Step 2 (pull next task — no active case).

---

## Step 0b — Operator Obsidian (human only, optional)

If the operator uses Obsidian: pin `docs/cases/OPERATOR_HOME.md` for the same `state/WORK` and
queue embeds this hook reads from disk. Kanban: `docs/cases/OPS_KANBAN.md`. Agents do not open Obsidian.

## Step 0c — Lessons check

Before implementing, skim `docs/LESSONS.md` for failure modes tagged for the tools/app in scope.
Do not re-make a logged mistake. Append a new entry whenever a fresh failure mode appears.

---

## Step 1 — Consult state/WORK.md (after resume check)

Read `state/WORK.md` now. Parse:
- `task_id` — the active case ID
- `status` — current phase
- `tier` — 1 / 2 / 3
- `app` — target app or platform scope
- `blocking_dependencies` — none or DEP-ID

`state/WORK.md` is a cache of the active case's Run State. If it conflicts with `docs/cases/<slug>.md`, **the case file is authoritative**.

---

## Step 2 — Pull next task (only if no active task or current task is COMPLETE)

1. Read `state/QUEUE.md`
2. Read `state/DEPS.md` — Status column only
3. Select the **first** row where `status = queued` AND dep is `none` or `confirmed` in DEPS.md
4. If no unblocked task exists: report queue state to user. List what is blocking each task. Stop.
5. Create a case file from `docs/cases/_TEMPLATE.md` → `docs/cases/<task-slug>.md`
6. Proceed to Step 3 (Contrarian) with the new task

---

## Step 3 — Branch on status

### status = `in_progress`

You have an active task in an active case file. Continue it.

**Token budget:**
- Tier 1: ≤ 5 files total
- Tier 2: ≤ 12 files total
- Tier 3: ≤ 25 files; each file beyond 15 requires justification in the handoff block

**Read (in this order):**
1. `docs/cases/<task-slug>.md` — full case context
2. `state/DEPS.md` — only if case notes indicate a dependency
3. Source files listed in case `## Files to Inspect`
4. Relevant tests
5. `contracts/<relevant>.contract.md` — only if case notes confirm contract involvement

Execute the `## Next Action` from the case file. When done, update the case file Run State to `needs_verification` and set `next_agent: verifier`.

---

### status = `needs_verification`

Work was done. Not yet verified. Do not mark done yet.

1. Read case `## Verification Plan`
2. Run the specified validation steps:
   - Tier 1: `scripts/pre-merge-check.sh --app <name>` + manual visual check
   - Tier 2: pre-merge check + automated tests + manual walkthrough of affected flow
   - Tier 3: pre-merge check + test coverage + manual walkthrough + state/event trace + cross-app consumer check
3. **If passes:** update case Run State → `verified`. Update `state/WORK.md` status → `verified`. Continue to Executioner from the case file.
4. **If fails:** document failure in case `## Verification` section. Update Run State status → `BLOCKED` with interrupt_reason: `verification-failed`. Report exact failure to user. Do not mark done.

---

### status = `blocked`

1. Read `state/DEPS.md` → find the blocking DEP-ID
2. Report to user:
   - Which case is blocked
   - Which dependency is required
   - Which app must provide it
   - Current dep status
   - Recommended unblock path
3. **Do NOT proceed with the blocked task.**
4. Check `state/QUEUE.md`: is there another unblocked task?
   - Yes → ask user: "Case X is blocked on DEP-NNN. Case Y is unblocked. Work on that instead?"
   - No → report all tasks blocked. List what must be resolved.

---

### status = `done` or task_id empty

No active task → go to Step 2.

---

## Step 4 — Contrarian phase (required for every NEW task, not resumes)

Before starting any new task, challenge it. Answer all seven. Do not skip or summarise away.

```
[ ] 1. Is this in the correct app or platform scope? Could it be misattributed?
[ ] 2. Does this already exist somewhere in the codebase? Check before building.
[ ] 3. Is the scope exactly as described, or narrower/wider than assumed?
[ ] 4. What breaks if this is wrong? Who else consumes this behavior?
[ ] 5. Is there a simpler path to the same outcome?
[ ] 6. Does this touch a contract, auth, state machine, payment, or print flow?
       If yes → escalate to Tier 3 regardless of original tier.
[ ] 7. Should this be split into separate case files per app?
```

If any answer changes the scope → update the case file before proceeding.
If cross-app work is confirmed → return `SPLIT_REQUIRED`. Do not modify app code.

**Record Contrarian output in `docs/cases/<slug>.md` → `## Contrarian Review` before handing off.**

---

## Step 5 — Update state/WORK.md and case file

Before implementation, write:

```
task_id:      <case ID>
status:       in_progress
tier:         <1 | 2 | 3>
app:          <woosoo-nexus | tablet-ordering-pwa | woosoo-print-bridge | woosoo-platform>
specialist:   <ranpo-backend | chuya-frontend | relay-ops | scribe | infra>
description:  <one line>
case_file:    docs/cases/<task-slug>.md
next_action:  <specific first action — file, function, or behavior>
last_agent:   contrarian — <date> — Contrarian complete. <one-line decision>.
```

Also update case file `## Run State`:
```
status: IN_PROGRESS
last_completed_agent: contrarian
next_agent: specialist:<name>
updated: <date>
```

---

## Step 6 — Proceed

Load `hooks/execute.md` for implementation guidance.
