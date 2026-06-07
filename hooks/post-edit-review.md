# Hook: post-edit-review

**Triggers:** "post-edit" · "post edit review" · called from `hooks/execute.md` after Specialist edits, before Verifier

Review changes just made. Do not start Verifier handoff until this output is complete.

---

## Output (required)

### Changed Files

| File | Purpose | Risk |
| ---- | ------- | ---- |
|      |         |      |

### Behavior Changed

Before → after in plain language (runtime / user-visible behavior).

### Contract Check

Confirm whether any of these changed. Mark each: **unchanged** | **changed (documented in case)** | **N/A**.

- API response shape
- Request payload shape
- Broadcast event payload
- Database schema
- Env key (`.env.example` / template only — never live `.env`)
- Queue / job behavior
- Device / session / order state
- Print payload format

If any item is **changed** without case or contract documentation: stop. Document in case `## Remaining Risks` before handoff.

### Regression Risks

List plausible regressions (including race / stale state / duplicate handling).

### Tests

| Category | Detail |
| -------- | ------ |
| Tests added | |
| Tests updated | |
| Tests recommended | |
| Manual verification steps | |

### Rollback

One concrete sentence: how to revert safely (e.g. `git restore <paths>`).

---

## Record

Append summary to case `## Specialist Investigation & Implementation`, then update `## Run State` per `hooks/execute.md` → On implementation complete.

Hand off to Verifier only after this review and the case checkpoint are written.
