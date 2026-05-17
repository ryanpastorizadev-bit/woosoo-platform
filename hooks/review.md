# Hook: review

**Triggers:** "review" · "unfinished" · "what was done" · "partial"

Audit unfinished work. Findings first. Do not implement fixes.

---

## Step 1 — Read

1. `docs/cases/<task-slug>.md` if the task slug is known
2. `state/WORK.md`
3. `git status --short --untracked-files=all`
4. Relevant diffs for files listed in the case or working tree

If no task slug is known, use `state/WORK.md` to identify the active case.

---

## Step 2 — Review Focus

Check:
- whether the current agent phase matches case Run State
- whether completed phases have evidence
- whether files changed match the case scope
- whether app boundaries were respected
- whether validation is missing or insufficient
- whether any stale protocol terms or uncreated-file references remain

---

## Step 3 — Output

Lead with findings:

```markdown
## Findings

- [severity] path:line — issue and impact

## Open Questions

- <question or "none">

## Change Summary

<brief summary of what appears changed>

## Recommended Next Action

<one sentence>
```

If no issues are found, say that clearly and name any remaining validation gaps.
