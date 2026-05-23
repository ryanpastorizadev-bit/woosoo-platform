---
status: canonical
last_reviewed: 2026-05-20
scope: tablet-ordering-pwa
---

# CASE: tablet-screen-ui-ux-review

## Run State
- task_slug: tablet-screen-ui-ux-review
- tier: 2
- branch: agent/tablet-screen-ui-ux-review
- status: BLOCKED
- last_completed_agent: executioner
- next_agent: specialist:chuya-frontend
- active_runner: codex
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-20

## Handoff
- Phase in progress: none; verification-only review completed.
- Done so far: Source audit completed across menu, package selection, cart/review, in-session, and support FAB surfaces. Pre-merge validation was run and failed at npm run test.
- Exact next action: If the user approves fixes, start as specialist:chuya-frontend and address the confirmed UI/UX findings without touching other apps.
- Working-tree state (list edited files explicitly; cross-check with `git status`): App repo clean. Root repo has untracked `docs/cases/tablet-screen-ui-ux-review.md` created for this case plus unrelated pre-existing untracked docs/case files.
- Risks / do-not-redo: User requested validate and verify only; do not implement fixes without explicit approval.

## Tier
2

## Branch
agent/tablet-screen-ui-ux-review

## Problem

Review the tablet-ordering PWA screens for UI/UX inconsistencies and counter-intuitive non-blocking elements, including duplicate table-name display, floating blue support hand affordance, and disabled meat/category/menu-item states that are not visually distinct enough.

## Contrarian Review

- Scope is one app: `tablet-ordering-pwa/**`.
- This is a review/validation pass, not an implementation task.
- Contract risk exists because package-selection tests encode the expected `Preview the meats` flow.
- Customer-facing error-copy risk exists because menu/review error boundaries render raw error messages.

## Investigation

Findings verified from current source:

1. `components/menu/MenuHeader.vue` renders `tableName` as the primary title and again in a right-side table pill.
2. `components/PackageCard.vue` has card-level `emit('select', pkg)` and footer copy `View`, while tests require `Preview the meats` and no direct select emit from the card.
3. `components/menu/MenuItemGrid.vue` package-disallowed meats are marked only by opacity/title and the add button can resolve to `Max`, not a package-specific unavailable reason.
4. `components/menu/SupportFab.vue` is always mounted from `pages/menu.vue`, uses a blue pulsing hand unrelated to the warm menu system, and lacks explicit aria-labels on icon-only buttons.
5. `pages/menu.vue` and `pages/order/review.vue` render raw `error?.message` in customer-facing error boundaries.
6. `pages/order/in-session.vue` renders disabled service/refill-looking buttons that remain visible as inert controls.
7. `components/Ordering/InSessionMain.vue` and `components/Ordering/QuickButtons.vue` still contain hardcoded `Table 4` strings, but these appear to be legacy/unreferenced candidates and need routing verification before deletion.

## Root Cause

UI contract drift: current source keeps older direct-select/inert-control patterns alongside newer modal/package-preview and tablet customer-safety contracts. Disabled and non-blocking affordances often use opacity/title only, which works for code-level blocking but not for tablet users.

## Proposed Fix

Not implemented in this verification-only pass. Recommended next pass:

1. Restore package card contract: clear `Preview the meats` CTA, remove/redirect direct card select, and keep final choice in the meat browser surface.
2. Collapse duplicate menu table display to one clear table identity plus package context.
3. Replace package-disallowed meat state with explicit overlay/badge/copy such as `Not included in this package`; avoid `Max` for package-disabled items.
4. Restyle and gate support FAB by ordering phase, add aria-labels, and reduce the blue pulsing hand visual clash.
5. Replace customer-facing raw error messages with friendly copy and log technical details only.
6. Replace inert visible buttons with explanatory locked states or hide unavailable actions until valid.
7. Verify whether legacy `components/Ordering/*` screens are referenced before cleanup.

## Files Changed

- `docs/cases/tablet-screen-ui-ux-review.md`

## Verification

- `git status --short --untracked-files=all` in `tablet-ordering-pwa`: clean.
- Source inspected with `rg`/`Get-Content` across menu, package selection, package card, cart/sidebar, review, in-session, and support FAB files.
- Root pre-merge validation run: `C:\Users\Pc1\AppData\Local\Microsoft\WindowsApps\pwsh.exe -Command "$env:CI='true'; .\scripts\pre-merge-check.ps1 -App tablet-ordering-pwa"`.
- Validation result: failed at `npm run test`.
- Raw test summary: `Test Files  1 failed | 68 passed (69)` and `Tests  1 failed | 381 passed | 1 todo (383)`.
- Failing test: `tests/package-card-contract.spec.ts > package card interaction contract > opens the meat browser instead of selecting the package directly` because `components/PackageCard.vue` does not contain `Preview the meats`.
- Lint completed with `58 problems (0 errors, 58 warnings)` before the test failure.

## Executioner Verdict

REJECTED

## Remaining Risks

- No app fixes were made because the user requested validate and verify only.
- Runtime browser screenshots were not captured; findings are source and test verified.
- Root repo contains unrelated untracked case/doc files that were not touched.
