---
status: canonical
last_reviewed: 2026-05-26
scope: woosoo-nexus
---

# CASE: public-user-manual-screenshots

## Run State
- task_slug: public-user-manual-screenshots
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
- Done so far: Added safe screenshot figures to the public user manual, redacted private dashboard/device values before embedding, and verified the Nexus validation wrapper.
- Exact next action: none
- Working-tree state (list edited files explicitly; cross-check with `git status`): `woosoo-nexus/resources/views/manual/user.blade.php`, `woosoo-nexus/public/docs/user-manual/screenshots/nexus-dashboard-redacted.png`, `woosoo-nexus/public/docs/user-manual/screenshots/nexus-orders-live.png`, `woosoo-nexus/public/docs/user-manual/screenshots/nexus-menus-live.png`, `woosoo-nexus/public/docs/user-manual/screenshots/nexus-packages-live.png`, `woosoo-nexus/public/docs/user-manual/screenshots/nexus-devices-redacted.png`, `docs/cases/public-user-manual-screenshots.md`.
- Risks / do-not-redo: Do not publish unredacted device IPs, POS/database internals, deployment commands, credentials, or operational troubleshooting screenshots.

## Tier
1

## Branch
n/a

## Problem

The public user manual explained Nexus and tablet navigation in text, but it did not yet use the real screenshots supplied for staff-facing visual guidance.

## Contrarian Review

Screenshots improve usability, but the public manual must stay safe. Images that expose private device connection values, POS/database wording, or troubleshooting internals should not be published unredacted.

## Investigation

- The public manual lives in `woosoo-nexus/resources/views/manual/user.blade.php`.
- Public manual screenshots are served from `woosoo-nexus/public/docs/user-manual/screenshots/`.
- The supplied Devices screenshot contained private connection values, so a redacted copy was created before use.
- POS and Monitoring screenshots were not embedded because they include restricted operational/internal details unsuitable for the public guide.

## Root Cause

The manual was accurate but mostly text-only. Staff need screen-level orientation for common pages, while the public asset set must avoid leaking restricted operational details.

## Proposed Fix

Embed safe screenshot figures for Dashboard, Orders, Devices, Menus, and Packages. Use redacted Dashboard and Devices images. Keep captions focused on what staff should click and what each page is for.

## Files Changed

- `woosoo-nexus/resources/views/manual/user.blade.php`
- `woosoo-nexus/public/docs/user-manual/screenshots/nexus-dashboard-redacted.png`
- `woosoo-nexus/public/docs/user-manual/screenshots/nexus-orders-live.png`
- `woosoo-nexus/public/docs/user-manual/screenshots/nexus-menus-live.png`
- `woosoo-nexus/public/docs/user-manual/screenshots/nexus-packages-live.png`
- `woosoo-nexus/public/docs/user-manual/screenshots/nexus-devices-redacted.png`
- `docs/cases/public-user-manual-screenshots.md`

## Verification

- `rg -n "nexus-dashboard-redacted|nexus-orders-live|nexus-devices-redacted|nexus-menus-live|nexus-packages-live" resources\views\manual\user.blade.php` exited 0 and confirmed all five screenshot references.
- `rg -n "192\.168\.|krypton|DB_|password|credential|secret|deploy|deployment|rollback|docker|artisan|ssh|mysql|redis|\.env" resources\views\manual\user.blade.php` exited 1 with no matches.
- `Test-Path public\docs\user-manual\screenshots\nexus-dashboard-redacted.png` exited 0 with `True`.
- `Test-Path public\docs\user-manual\screenshots\nexus-devices-redacted.png` exited 0 with `True`.
- `Test-Path public\docs\user-manual\screenshots\nexus-dashboard-live.png` exited 0 with `False`, confirming the unredacted dashboard metrics copy is not present.
- `Test-Path public\docs\user-manual\screenshots\nexus-pos-live.png` exited 0 with `False`, confirming the unembedded POS/internal copy is not present.
- `Test-Path public\docs\user-manual\screenshots\nexus-monitoring-live.png` exited 0 with `False`, confirming the unembedded monitoring/internal copy is not present.
- `php artisan view:cache` exited 0 with `INFO  Blade templates cached successfully.`
- `php artisan view:clear` exited 0 with `INFO  Compiled views cleared successfully.`
- `.\scripts\pre-merge-check.ps1 -App woosoo-nexus` exited 0 with `pre-merge-check OK (woosoo-nexus)`. The run emitted pre-existing PHPUnit doc-comment metadata deprecation warnings.

## Executioner Verdict

APPROVED

## Remaining Risks

- Existing unrelated Nexus working-tree changes must not be included in this manual follow-up.
