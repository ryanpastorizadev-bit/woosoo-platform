---
status: canonical
last_reviewed: 2026-05-26
scope: woosoo-nexus
---

# CASE: public-user-manual-tablet-screenshots

## Run State
- task_slug: public-user-manual-tablet-screenshots
- tier: 1
- branch: n/a
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: codex
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-26

## Handoff
- Phase in progress: complete
- Done so far: Extracted tablet PWA screens from the supplied PDF, trimmed PDF viewer artifacts, redacted the staff settings connection screenshot, embedded the screens in the public manual, and completed targeted route/view verification.
- Exact next action: none
- Working-tree state (list edited files explicitly; cross-check with `git status`): `woosoo-nexus/resources/views/manual/user.blade.php`, `woosoo-nexus/public/docs/user-manual/screenshots/tablet-*.png`, `docs/cases/public-user-manual-tablet-screenshots.md`; existing Nexus manual screenshot files from the prior pass are still uncommitted and should be included if referenced. The unrelated staged seeder change exists and must not be included.
- Risks / do-not-redo: Do not expose deployment, IP, credential, POS, database, or troubleshooting internals in the public user manual.

## Tier
1

## Branch
n/a

## Problem

The public user manual has Nexus screenshots, but the Tablet Ordering PWA section still needs visual screen guidance from the supplied PDF.

## Contrarian Review

Using the PDF is appropriate if the extracted screens are user-facing and safe. The change should remain Nexus documentation only because the public manual is served from Nexus, and the tablet app behavior itself is not changing.

## Investigation

- The supplied PDF is `C:\Users\Pc1\OneDrive\Desktop\Woosoo-GrillPadd.pdf`.
- Poppler/Ghostscript/MuPDF were not available, so Chrome's PDF viewer was used through Playwright to render the visual pages.
- The PDF contains 12 tablet-oriented screens: welcome, create PIN, enter PIN, device setup, guest count, package selection, menu browse, refill/menu search, review order, placing order, in-session, and session ended.
- The device setup screen includes private connection values, so those values were redacted before the image was embedded.

## Root Cause

The tablet section was text-only. Staff need screen-level visual cues for the guest flow and protected staff settings flow.

## Proposed Fix

Embed tablet screenshots in the public user manual with short captions that explain what each screen is for and what staff or guests do next. Keep the guidance user-facing and redact private setup values.

## Files Changed

- `woosoo-nexus/resources/views/manual/user.blade.php`
- `woosoo-nexus/public/docs/user-manual/screenshots/tablet-welcome.png`
- `woosoo-nexus/public/docs/user-manual/screenshots/tablet-guest-count.png`
- `woosoo-nexus/public/docs/user-manual/screenshots/tablet-package-selection.png`
- `woosoo-nexus/public/docs/user-manual/screenshots/tablet-menu-browse.png`
- `woosoo-nexus/public/docs/user-manual/screenshots/tablet-menu-search.png`
- `woosoo-nexus/public/docs/user-manual/screenshots/tablet-review-order.png`
- `woosoo-nexus/public/docs/user-manual/screenshots/tablet-order-submitted.png`
- `woosoo-nexus/public/docs/user-manual/screenshots/tablet-in-session.png`
- `woosoo-nexus/public/docs/user-manual/screenshots/tablet-session-ended.png`
- `woosoo-nexus/public/docs/user-manual/screenshots/tablet-settings-create-pin.png`
- `woosoo-nexus/public/docs/user-manual/screenshots/tablet-settings-enter-pin.png`
- `woosoo-nexus/public/docs/user-manual/screenshots/tablet-settings-device-setup.png`
- `docs/cases/public-user-manual-tablet-screenshots.md`

## Verification

- Render/extract source: Chrome PDF viewer via Playwright rendered `C:\Users\Pc1\OneDrive\Desktop\Woosoo-GrillPadd.pdf` into public manual PNG assets.
- Visual QA: reviewed a contact sheet of the 12 extracted pages; corrected an initial capture issue where the PDF viewer reused page 1; trimmed PDF viewer white borders from the first and final screenshots; redacted private connection values on `tablet-settings-device-setup.png`.
- Asset existence check exited 0 and returned `True` for all 17 screenshot references in `resources\views\manual\user.blade.php`.
- `rg -n "192\.168\.|172\.18\.|krypton|DB_|password|credential|secret|deploy|deployment|rollback|docker|artisan|ssh|mysql|redis|\.env" resources\views\manual\user.blade.php` exited 1 with no matches.
- `php artisan view:cache` exited 0 with `INFO  Blade templates cached successfully.`
- `php artisan view:clear` exited 0 with `INFO  Compiled views cleared successfully.`
- `php artisan route:list --path=user-manual` exited 0 and showed `GET|HEAD user-manual ... public.user-manual`.
- `.\scripts\pre-merge-check.ps1 -App woosoo-nexus` exited 1 during `composer test` with `Tests:    150 failed, 280 passed (1023 assertions)`. The failure cluster reports `RuntimeException: This database driver does not support dropping foreign keys by name.` in SQLite grammar. The active Nexus working tree also contains unrelated staged app-code changes in `app/Http/Controllers/Admin/PackageController.php`, `database/migrations/2026_05_26_000001_drop_constraints_from_package_modifiers.php`, `database/seeders/PackageSeeder.php`, and `resources/js/pages/Packages/Index.vue`; those files are outside this docs/manual task and were not included.

## Executioner Verdict

APPROVED

## Remaining Risks

- Full Nexus validation is currently blocked by unrelated staged app-code/migration changes in the same working tree. The manual change itself is limited to a Blade documentation page and public PNG assets.
