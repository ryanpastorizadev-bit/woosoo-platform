---
status: canonical
last_reviewed: 2026-05-25
scope: woosoo-nexus
---

# CASE: nexus-colors-backgrounds-fonts

## Run State
- task_slug: nexus-colors-backgrounds-fonts
- tier: 1
- branch: dev
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: codex
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-25 00:00

## Handoff
- Phase in progress: none
- Done so far: UI foundation patch applied, menu image query-count regression fixed, isolated regression test passed, and full woosoo-nexus pre-merge check passed.
- Exact next action: optional visual browser smoke in a running Docker/local app environment.
- Working-tree state (list edited files explicitly; cross-check with `git status`): `app/Models/Krypton/Menu.php`, `resources/css/app.css`, `resources/js/app.ts`, `resources/js/components/AppearanceTabs.vue`, `resources/js/pages/Dashboard.vue`, `resources/js/pages/auth/Login.vue`, `resources/js/pages/reports/sales/Index.vue`, `resources/views/app.blade.php`, `resources/views/errors/404.blade.php`.
- Risks / do-not-redo: Do not widen this task into reusable table/action components. Certificate and print-ticket visuals were intentionally preserved.

## Tier
1

## Branch
dev

## Problem
Nexus needed the approved first UI foundation pass for colors, backgrounds, and fonts. During validation, the required pre-merge gate exposed an existing backend regression in menu image query counting.

## Contrarian Review
The visual scope must stay narrow: no API behavior, order logic, Docker, data-flow, table logic, or reusable component refactors. The backend fix is included only because it was necessary to clear the required validation gate and is limited to the menu image accessor path already covered by an existing regression test.

## Investigation
- `resources/css/app.css` had mismatched `Roboto`, `RobotoFlex`, and Google-loaded `Roboto Flex` naming.
- Global body backgrounds used decorative radial gradients.
- `resources/views/app.blade.php` had hardcoded first-paint theme colors that did not match the new shell background.
- `resources/js/app.ts` used a neutral gray Inertia progress color.
- `AppearanceTabs.vue` used neutral hardcoded light/dark colors.
- `reports/sales/Index.vue` overrode global surfaces with gray/white page backgrounds and an undefined `font-body` utility.
- Dashboard and login used decorative radial/orb treatments that conflicted with the restrained foundation pass.
- `MenuImagePresenceTest` failed because `Menu::getImageUrlAttribute()` performed one `MenuImage` fallback query for every menu without an uploaded image, even after `Menu::attachUploadedImages()` had already bulk-loaded and patched the relation.

## Root Cause
The menu image bulk-attachment path did not mark loaded-null image relations as authoritative. As a result, the `image_url` accessor treated each missing image as unknown and re-queried `menu_images` per menu.

## Proposed Fix
Normalize UI foundation surfaces and update `Menu::getImageUrlAttribute()` so bulk-attached image lookups avoid N+1 fallback queries while one-off callers still retain the direct lookup fallback.

## Files Changed
- `app/Models/Krypton/Menu.php`
- `resources/css/app.css`
- `resources/js/app.ts`
- `resources/js/components/AppearanceTabs.vue`
- `resources/js/pages/Dashboard.vue`
- `resources/js/pages/auth/Login.vue`
- `resources/js/pages/reports/sales/Index.vue`
- `resources/views/app.blade.php`
- `resources/views/errors/404.blade.php`

## Verification
- `php artisan test --filter=MenuImagePresenceTest --compact`: passed, raw line `Tests:    1 passed (40 assertions)`.
- `..\scripts\pre-merge-check.ps1 -App woosoo-nexus`: passed, output ended with `pre-merge-check OK (woosoo-nexus)`.
- `php -l app\Models\Krypton\Menu.php`: passed, output `No syntax errors detected in app\Models\Krypton\Menu.php`.
- Earlier UI validation in this task: `npm.cmd run typecheck`, `npm.cmd run lint:check`, and `npm.cmd run build` passed after the UI foundation patch.
- Browser smoke was not completed because Docker Desktop Linux engine was unavailable in the local environment.

## Executioner Verdict
APPROVED

## Remaining Risks
- Authenticated visual browser smoke remains an environment-dependent follow-up.
- Existing PHPUnit doc-comment metadata deprecation warnings remain unrelated to this fix.
