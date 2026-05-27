---
status: COMPLETE
last_reviewed: 2026-05-25
scope: woosoo-platform
---

# CASE: PLT-CASE-008 — GitHub Issue #9 P1 Remediation

## Run State
- task_slug: plt-case-008-gh-issue-9-p1-remediation
- tier: 3
- branch: claude/review-critic-feedback
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-25

## Handoff
- Phase in progress: complete
- Done so far: All 5 P1 fixes implemented, verified, merged via PR #10, and recorded in `state/DONE.md`.
- Exact next action: none.
- Working-tree state: completed platform-governance case; no app code involved.
- Risks / do-not-redo: P2/P3 follow-ups from Issue #9 remain separate future work; do not reopen this P1 case for them.

## Tier
3 — High-risk (deployment safety, configuration integrity, platform governance)

## Branch
claude/review-critic-feedback

## Problem

GitHub Issue #9 "Review Critic" identified five P1 (critical) remediation items:

1. **Terminology drift:** Documentation uses both "monorepo" and "not a monorepo" inconsistently, creating agent confusion
2. **Case template status:** `docs/cases/_TEMPLATE.md` has `status: under-review` but is used as canonical infrastructure
3. **Deployment safety:** `scripts/deployment/deploy.sh` uses `git reset --hard` without dirty-tree protection
4. **POS config integrity:** `scripts/deployment/apply-woosoo-config.sh` defaults POS host/port to non-production values instead of requiring them
5. **Reverb/API env fail-fast:** Placeholder fallbacks exist for critical runtime/build values instead of hard-failing

These are deployment-safety and governance-integrity issues that can cause data loss or misconfig in production.

## Contrarian Review

**Conducted:** 2026-05-19

1. **Correct app or platform scope?** Yes — `woosoo-platform` governance only (docs, scripts, compose). No app code.
2. **Already exists?** No. These are fixes to identified issues from external review.
3. **Scope exactly as described?** Yes — exactly the 5 P1 items. P2/P3 deferred.
4. **What breaks if wrong?**
   - Terminology: agents may violate workspace boundaries
   - Template status: resume protocol may treat template as unreliable
   - Deploy safety: silent data loss on `git reset --hard` with dirty tree
   - POS config: production connects to wrong POS database
   - Reverb fallback: production uses placeholder secrets
5. **Simpler path?** No simpler path that still addresses all P1 risks.
6. **Touches a contract, auth, state machine, payment, or print flow?** Yes — deployment and configuration, which affects production environment. Tier 3 justified.
7. **Should this be split into separate case files per app?** No. Single platform-governance case.

**Decision:** Proceed as Tier 3. Specialist: infra. Hard constraints: no app code, platform governance only, validate all script syntax.

## Investigation

### Fix 1: Terminology Drift
Files with "monorepo" wording found:
- `AGENTS.md:64` — "**Monorepo boundary:**"
- `AGENTS.md:212` — "## Monorepo Split Rule"
- `docs/AI_CONTEXT.md:62` — "## Monorepo Rule"
- `PROTOCOL.md:131` — "This is a monorepo"
- `docs/AGENT_DEFAULT_INSTRUCTIONS.md:57` — "preserve monorepo boundaries"
- `.gitignore:1` — "woosoo-platform monorepo"
- `.claude/agents/contrarian.md:24` — "monorepo-boundary violations"

### Fix 2: Template Status
`docs/cases/_TEMPLATE.md` frontmatter has `status: under-review` but is referenced as canonical template in `AGENTS.md` and `RESUME_PROTOCOL.md`.

### Fix 3: Deployment Safety
`scripts/deployment/deploy.sh` function `pull_repo()` at line 68-82 runs `git reset --hard` without checking for uncommitted changes. Can silently discard emergency hotfixes or local debugging changes.

### Fix 4: POS Config Integrity
`scripts/deployment/apply-woosoo-config.sh:328-329` defaults:
```bash
set_env "DB_POS_HOST" "${WOOSOO_POS_HOST:-192.168.100.20}"
set_env "DB_POS_PORT" "${WOOSOO_POS_PORT:-3308}"
```
Production truth is `192.168.1.32:3306` per `AGENTS.md:65`.

### Fix 5: Reverb/API Env Fail-Fast
`scripts/deployment/apply-woosoo-config.sh:342-343,348` has placeholder fallbacks:
```bash
set_env "REVERB_APP_KEY" "${WOOSOO_REVERB_APP_KEY:-change_this_reverb_key}"
set_env "REVERB_APP_SECRET" "${WOOSOO_REVERB_APP_SECRET:-change_this_reverb_secret}"
set_env "VITE_REVERB_APP_KEY" "${WOOSOO_REVERB_APP_KEY:-change_this_reverb_key}"
```

## Root Cause

1. Platform repo documentation was bootstrapped with "monorepo" language before the 3-repo sibling model was clarified
2. Template status was marked `under-review` during initial creation and never updated
3. Deploy script was optimized for fast updates without considering dirty-tree safety
4. Config script inherited old development defaults instead of requiring production values
5. Placeholder fallbacks were added for "convenience" without considering production safety

## Proposed Fix

### Fix 1: Terminology Cleanup
Replace in canonical files:
- "monorepo" → "multi-repo sibling workspace"
- "Monorepo boundary" → "Sibling-repo boundary" or "Workspace boundary"
- "Monorepo Split Rule" → "Workspace Split Rule"
- "preserve monorepo boundaries" → "preserve workspace boundaries"

### Fix 2: Template Status
Update `docs/cases/_TEMPLATE.md` frontmatter:
```yaml
status: canonical
last_reviewed: 2026-05-19
```

### Fix 3: Deployment Safety
Add dirty-tree protection to `pull_repo()` in `deploy.sh`:
- Check `git status --porcelain` before `git reset --hard`
- If dirty and `WOOSOO_FORCE_RESET` not true: fail with clear error
- If `WOOSOO_FORCE_RESET=true`: save backup patch first, then reset

### Fix 4: POS Config Integrity
In `apply-woosoo-config.sh`:
- Add `require_var WOOSOO_POS_HOST`
- Add `require_var WOOSOO_POS_PORT`
- Remove fallback defaults: use `"$WOOSOO_POS_HOST"` and `"$WOOSOO_POS_PORT"` directly

### Fix 5: Env Fail-Fast
Create `scripts/deployment/doctor.sh` for pre-flight validation:
- Check all critical vars are set and not placeholders
- Validate `WOOSOO_POS_HOST` not `192.168.100.20`
- Validate `REVERB_APP_KEY` not `change_this_reverb_key`
- Validate `REVERB_APP_SECRET` not `change_this_reverb_secret`
- Exit 1 on any failure with clear operator-facing errors

In `apply-woosoo-config.sh`:
- Add `require_var WOOSOO_REVERB_APP_KEY`
- Add `require_var WOOSOO_REVERB_APP_SECRET`
- Remove placeholder fallbacks from Reverb key assignments

## Files Changed

1. `AGENTS.md` — "Monorepo boundary" → "Sibling-repo boundary", "Monorepo Split Rule" → "Workspace Split Rule"
2. `docs/AI_CONTEXT.md` — "Monorepo Rule" → "Workspace Boundary Rule"
3. `PROTOCOL.md` — "monorepo" → "multi-repo sibling workspace"
4. `docs/AGENT_DEFAULT_INSTRUCTIONS.md` — "monorepo boundaries" → "workspace boundaries"
5. `.gitignore` — comment updated to "multi-repo sibling workspace"
6. `.claude/agents/contrarian.md` — "monorepo-boundary" → "workspace-boundary"
7. `docs/cases/_TEMPLATE.md` — status: canonical, last_reviewed: 2026-05-19
8. `scripts/deployment/deploy.sh` — added dirty-tree guard to `pull_repo()` function (lines 75-96)
9. `scripts/deployment/apply-woosoo-config.sh` — added require_var for POS_HOST, POS_PORT, REVERB_APP_KEY, REVERB_APP_SECRET; removed placeholder fallbacks
10. `scripts/deployment/doctor.sh` — NEW: pre-flight validation script (138 lines)
11. `docs/cases/plt-case-008-gh-issue-9-p1-remediation.md` — NEW: this case file

## Verification

Verifier evidence is recorded in `state/DONE.md`:

- `PROTOCOL.md` and canonical docs multi-repo terminology corrected.
- Deployment scripts hardened with `require_var` guards.
- `REVERB_HOST` corrected to Docker service DNS `reverb`.
- PR #10 merged.

## Executioner Verdict

APPROVED — 2026-05-20

This case is complete. The P1 governance and deployment-safety remediation was merged via PR #10 and logged in `state/DONE.md`.

## Remaining Risks

- P2/P3 items from Issue #9 are deferred (root README, state/ACTIVE.md, queue --tries=3, nginx healthcheck, etc.)
- `compose.yaml` still has some `:-woosoo` fallbacks for PUBLIC_HOST (acceptable for dev, not production — should be caught by doctor.sh if operator forgets to set PUBLIC_HOST)
- doctor.sh validation happens only if explicitly run — deploy.sh does not automatically invoke it yet
