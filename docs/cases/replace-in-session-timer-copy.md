---
status: canonical
last_reviewed: 2026-05-25
scope: tablet-ordering-pwa
---

# CASE: replace-in-session-timer-copy

## Run State
- task_slug: replace-in-session-timer-copy
- tier: 1
- branch: dev
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: codex
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-25

## Handoff
- Phase in progress: complete
- Done so far: Confirmed the in-session pill used elapsed session time while saying "min remaining"; updated the customer-facing copy to "Active · Session ~N min" and renamed the local computed value to `sessionMinutes`; targeted checks and full tablet pre-merge gate passed; committed and pushed tablet repo `dev` to `origin/dev`.
- Exact next action: none.
- Working-tree state (list edited files explicitly; cross-check with `git status`): `pages/order/in-session.vue`, `docs/cases/replace-in-session-timer-copy.md`
- Risks / do-not-redo: Do not change session timing semantics, API contracts, stores, Docker, or backend code.

## Tier
1

## Branch
dev

## Problem
The customer-facing `/order/in-session` timer pill displayed `Active · ~N min remaining`, but the current tablet code measures elapsed local session age rather than remaining time.

## Contrarian Review
This is a safe tablet-only copy correction. It should not modify API behavior, order state, stores, caching, Docker, or backend code.

## Investigation
- `pages/order/in-session.vue` rendered the pill from `timerPillLabel`.
- `timerPillLabel` used `sessionStore.remainingMs`, which is currently elapsed milliseconds since `sessionStartedAt`.
- The stale phrase was misleading because it implied a countdown.

## Root Cause
The UI copy retained countdown wording after `remainingMs` was repurposed as elapsed session time.

## Proposed Fix
Change the customer-facing label from `Active · ~N min remaining` to `Active · Session ~N min` and rename the local computed value to avoid "remaining" terminology.

## Files Changed
- `pages/order/in-session.vue`
- `docs/cases/replace-in-session-timer-copy.md`

## Verification
- Red/source check before fix: `rg -n "min remaining|remainingMinutes" pages\order\in-session.vue` found the stale copy and variable.
- Source check after fix: `rg -n "min remaining|remainingMinutes" pages\order\in-session.vue` exited 1 with no matches.
- Source check after fix: `rg -n "Session ~|sessionMinutes" pages\order\in-session.vue` found the new `sessionMinutes` computed and `Active · Session ~${mins} min`.
- Targeted lint: `.\node_modules\.bin\eslint.cmd pages\order\in-session.vue` exited 0.
- Full gate: `.\scripts\pre-merge-check.ps1 -App tablet-ordering-pwa` exited 0 and printed `pre-merge-check OK (tablet-ordering-pwa)`.
- Test output inside full gate: `Test Files  71 passed (71)` and `Tests  391 passed | 1 todo (392)`.
- Lint output inside full gate: `60 problems (0 errors, 60 warnings)`, matching existing warning-budget style debt outside this change.
- Commit: `e3d9221 fix(tablet): clarify in-session timer copy`.
- Push: `git push origin dev` updated `dev -> dev` from `66b818f` to `e3d9221`.

## Executioner Verdict
APPROVED

## Remaining Risks
Low. This is a copy-only UI correction. The full gate printed a trailing PowerShell `=true` parse warning after the OK banner and existing Nuxt/dependency warnings, but the process exit code was 0.
