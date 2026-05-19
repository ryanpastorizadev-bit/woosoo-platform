# Hook: execute

**Triggers:** "execute" · "implement" · "run case <ID>" · called from hooks/work.md Step 6

---

## Pre-execution checklist

Read `state/WORK.md`. Confirm from the case file (`docs/cases/<slug>.md`):

- [ ] `task_id` is set and matches an existing case file
- [ ] Case `## Run State` status is `IN_PROGRESS`
- [ ] Tier is classified
- [ ] No blocking dependencies — or blocking dep is `confirmed` in `state/DEPS.md`
- [ ] Contrarian phase is recorded in case `## Contrarian Review`
- [ ] `next_agent` in the case file points to a Specialist

If any check fails: stop. Report what is missing. Do not implement.

---

## Context loading by tier

### Tier 1 — Trivial (≤ 5 files)

1. `state/WORK.md`
2. The specific file(s) to change (from case notes or task description)
3. Relevant test file if one exists
4. No more. Do not load: case file, contracts, handover, dep ledger.

### Tier 2 — Standard (≤ 12 files)

1. `state/WORK.md`
2. `docs/cases/<task-slug>.md`
3. `state/DEPS.md` — Status column only (full records only if a dep is active)
4. Source files listed in `## Files to Inspect`
5. Relevant tests
6. `contracts/<relevant>.contract.md` — ONLY if case explicitly confirms contract involvement

### Tier 3 — High-risk (≤ 25 files; each beyond 15 justified in handoff)

1. `state/WORK.md`
2. `docs/cases/<task-slug>.md`
3. `state/DEPS.md` — full records for relevant deps
4. `contracts/<relevant>.contract.md`
5. Source files
6. All relevant tests
7. Related handover file if continuing previous work
8. Additional files: justify each in handoff block before loading

---

## Agent chain by tier

### Tier 1
`Specialist → Executioner`
(Verifier omitted only when no code path changed — document the reason)

### Tier 2
`Contrarian → Specialist → Verifier → Executioner`

### Tier 3
`Contrarian (written risk analysis) → Specialist → Verifier → Executioner`

For Tier 3: Specialist references the relevant `contracts/*.contract.md`. Executioner uses the strongest model.

---

## Execution rules

- Make the smallest correct change.
- Do not modify files outside the stated app.
- Do not add debug logs unless intentionally kept — document them in the case file.
- Do not leave commented-out code.
- Do not change unrelated behavior in files you touch.
- Handle errors clearly. Prevent silent failures.
- If you discover a new risk mid-implementation: pause. Document it in the case file `## Remaining Risks`. Ask user before continuing.
- Failure signals that require stopping: failed tests, build errors, type errors, 4xx/5xx responses, console errors, unexpected file changes.

---

## Handoff block (required between every agent phase)

```
## Handoff
Task:         <case ID>
App:          <woosoo-nexus | tablet-ordering-pwa | woosoo-print-bridge | woosoo-platform>
Tier:         <1 | 2 | 3>
Files read:   <list — max 5 entries, then "...N more">
Finding:      <one sentence — what the investigation revealed>
Decision:     <what was decided and why>
Risks:        <any risks discovered>
Deps:         <dep checks made or "none">
Next action:  <exactly what the next agent phase must do — specific file, function, or behavior>
Validation:   <what must be verified and how>
```

Write this to the case file before handing off to the next phase.

---

## On implementation complete

Update `docs/cases/<slug>.md` `## Run State`:
```
status: IN_PROGRESS
last_completed_agent: specialist:<name>
next_agent: verifier
interrupted: false
updated: <date>
```

Update `state/WORK.md`:
```
status: needs_verification
next_action: VERIFY: <describe what to test — specific behavior or command>
last_agent: specialist:<name> — <date> — Implementation complete. <one-line summary of what changed>.
```

Then hand off to Verifier by updating the case file Run State and `state/WORK.md`.
