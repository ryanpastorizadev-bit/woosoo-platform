---
status: canonical
last_reviewed: 2026-06-05
scope: ecosystem
---

# CASE: pr-40-staging-review-findings

## Run State
- task_slug: pr-40-staging-review-findings
- tier: 2
- branch: dev
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: codex
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-05 00:00

## Handoff
- Phase in progress: none
- Done so far: Reviewed PR #40 staging review findings against current local `origin/main..HEAD` evidence.
- Exact next action: If requested, fix confirmed findings in a separate implementation task.
- Working-tree state (list edited files explicitly; cross-check with `git status`): `docs/cases/pr-40-staging-review-findings.md` created as protocol checkpoint.
- Risks / do-not-redo: Do not treat the pasted PR summary as source of truth; verify against live files before changing deploy behavior.

## Tier
2

## Branch
dev

## Problem
The user requested verification of PR #40 staging review findings before accepting the review.

## Contrarian Review
- The task is a review, not an implementation request. The correct hook is `hooks/review.md`, which requires findings first and no fixes.
- Scope is root infrastructure and documentation. No nested app code should be modified.
- Candidate skills: `agent-sequence`, `documentation-truth-audit`, `docker-deployment-debug`, `test-verification` for evidence discipline. `superpowers:brainstorming` was explicitly invoked but does not open a design flow because no creative or implementation work is requested.

## Success Criterion
Task is done when each pasted finding is checked against the current source tree and any additional material mismatch is reported.

## Investigation
- Current root branch: `dev` at `b0e7104`, clean before this case file.
- Local PR surface checked with `git diff --stat origin/main..HEAD`: 19 files, 878 insertions, 67 deletions.
- Reviewed `scripts/deployment/deploy.sh`, `compose.yaml`, `scripts/deployment/apply-woosoo-config.sh`, `docs/README.md`, `docs/deployment/RELEASE_RUNBOOK_order-id-pos-sync.md`, `state/QUEUE.md`, and `docs/cases/nexus-ui-handoff-visual-implementation.md`.

## Findings
1. ~~High: The pasted "auto-migration before services start" approval is not supported by current code. `deploy.sh` starts services with `docker compose up -d --remove-orphans` before running `php artisan migrate --force` inside the already-running app container.~~
   **RESOLVED 2026-06-05 (INFRA-CASE-002):** `deploy.sh` step 4 runs `php artisan migrate --force` via a one-off container before step 5 (`up -d`). Queue workers and scheduler boot on the updated schema. This finding no longer applies.
2. Medium: The cache-warming concern is partially valid but overstated. There is still a 90x2s app readiness wait before migrations, so slow startup after `up -d` is handled. The real residual issue is that Step 6 silently skips cache warming if the app becomes unavailable after migration.
3. Medium: `docs/cases/nexus-ui-handoff-visual-implementation.md` is an `IN_PROGRESS` case with `next_agent: specialist:ranpo-backend`; promoting it to main would advertise incomplete Nexus work.
4. Medium: `docs/README.md` links to Nexus `dev` docs that the local case itself says are not yet merged to Nexus `dev`; the note is honest, but the index still contains a likely-broken GitHub link.
5. High: The release runbook Step 3 only instructs POS BT-only configuration for NEX-CASE-011, while `state/QUEUE.md` says NEX-CASE-011 requires both open code PR #163 and POS config before deploy.
   **PARTIALLY RESOLVED 2026-06-05:** PR #163 merged to dev 2026-06-04. Runbook updated to note code gate is cleared; operator must confirm dev→staging→main promotion includes PR #163 before Step 1.

## Root Cause
The pasted review mixed accurate line-level findings with at least one stale or inferred deployment claim that does not match the actual script sequence.

## Proposed Fix
No fixes applied in this review task. Recommended follow-up is a root-infra/docs implementation pass to:
- move or gate migration before queue/scheduler/reverb boot, or explicitly stop dependent workers until migration succeeds;
- add a cache-warm skip warning;
- remove or archive incomplete main-bound case state;
- replace the broken Nexus docs index link with a non-clickable pending note or branch-specific link;
- update the runbook to gate Step 1/Step 3 on PR #163 merge status.

## Files Changed
- `docs/cases/pr-40-staging-review-findings.md`

## Verification
- Read-only source verification plus `git diff --stat origin/main..HEAD`.
- No app pre-merge check was run because this was a review-only root documentation/infrastructure assessment and no app code was changed.

## Executioner Verdict
REJECTED (original) — partially superseded 2026-06-05

Finding #1 (migration sequencing) is resolved; it no longer blocks PR #40.
Finding #5 (runbook/queue mismatch) is addressed — runbook updated 2026-06-05; PR #163 code gate cleared.
Findings #2, #3, #4 remain open as low-priority docs cleanup; they do not block the Bucket B deploy sequence.

**Net:** PR #40 is no longer REJECTED on technical grounds. Findings #3 and #4 are documentation debt, not correctness failures.

## Remaining Risks
- The GitHub PR page was not fetched successfully from this environment; findings are based on the current local checkout and remote refs.
