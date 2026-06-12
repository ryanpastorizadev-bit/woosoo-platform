# Hook: pre-edit-gate

**Triggers:** "pre-edit" · "pre edit gate" · called from `hooks/execute.md` before first file edit

Do not edit any file until this gate is complete and recorded.

---

## When to run

- Specialist phase, after investigation and before the first file modification.
- Cursor sessions: output in chat even if rules fail to load; optionally enrich case `## Proposed Fix`.
- Tier 3: mandatory. Tier 1–2: mandatory unless the task is a single-line typo with no contract/state impact (document the skip reason in the case file).

---

## Output (required)

Produce all sections below. Stop if you cannot fill `Files Proposed for Modification` or `Minimal Patch Plan`.

### Files Proposed for Modification

| File | Repo / app | Reason | Risk |
| ---- | ---------- | ------ | ---- |
|      |            |        |      |

### Existing Pattern Found

Describe the pattern this change must follow (naming, error handling, state ownership, tests).

### Minimal Patch Plan

Numbered list of the smallest safe changes. One file per step when possible.

### Non-Goals

What you will **not** change in this task.

### Risk Review

| Check | Answer |
| ----- | ------ |
| Race condition risk | |
| State / contract risk | |
| Security / auth risk | |
| Config drift risk | |
| Test impact | |
| Rollback path | |

---

## Gate rule

**Do not edit until this plan is complete.**

If investigation reveals Tier 3 scope (auth, order/session state, payment, printing, broadcasting, queues, migrations, cross-app, production deploy): stop. Tell the operator to use a Claude Code Specialist. Do not proceed in Cursor.

---

## Record

- **Claude Code Specialist:** append summary to case `## Proposed Fix` before editing.
- **Cursor Specialist:** output in chat; include summary in `## Specialist Investigation & Implementation` at checkpoint.
