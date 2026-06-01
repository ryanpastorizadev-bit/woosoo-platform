---
status: canonical
last_reviewed: 2026-06-01
scope: woosoo-nexus
---

# CASE: redesign-woosoo-nexus-login-page

## Run State
- task_slug: redesign-woosoo-nexus-login-page
- tier: 2
- branch: agent/redesign-woosoo-nexus-login-page
- status: BLOCKED
- last_completed_agent: contrarian
- next_agent: specialist:ranpo-backend
- active_runner: codex
- interrupted: false
- interrupt_reason: waiting-user-design-approval
- updated: 2026-06-01 00:00

## Handoff
- Phase in progress: Specialist pending user approval required by requested brainstorming skill.
- Done so far: Booted protocol, created case, inspected AGENTS/docs, app .agents.md, Login.vue, app.css, Dashboard.vue, UI primitives, and package scripts.
- Exact next action: If user approves the design checkpoint, update this case to IN_PROGRESS, implement resources/js/pages/auth/Login.vue only, then validate.
- Working-tree state (list edited files explicitly; cross-check with `git status`): Case file created at docs/cases/redesign-woosoo-nexus-login-page.md. Fresh Nexus app status was clean before commit; platform root had only this untracked case file.
- Risks / do-not-redo: Do not overwrite state/WORK.md while it points to unrelated ecosystem governance work unless the user explicitly asks to switch the active cache.

## Tier
2

## Branch
agent/redesign-woosoo-nexus-login-page

## Problem
The Nexus login page should be redesigned to match the Woosoo Admin dark warm operations look: near-black surfaces, warm borders, amber accent, split desktop layout, operations snapshot, admin-grade form, and responsive single-column behavior with password reveal.

## Contrarian Review
1. Correct app/scope: Yes. The login page is Nexus app UI at `woosoo-nexus/resources/js/pages/auth/Login.vue`; one app only.
2. Existing behavior: Partially exists. Current login already uses AppLogoIcon, warm accent, Inertia form submit, CSRF refresh, and auth status/warning handling, but it still uses a light form card and lacks password reveal.
3. Scope: Narrow UI-only page redesign. No backend auth, routes, contracts, Docker, POS, order state, or API behavior should change.
4. Risk if wrong: Failed login UX, broken password reset link, lost session warning/status messaging, or inaccessible form controls.
5. Simpler path: Replace the page layout and local state in `Login.vue` only, reusing existing form submit, components, and brand tokens.
6. Contract/security/state impact: No API contract or order-state impact. Auth boundary must be preserved by leaving form.post(route('login')) and CSRF refresh intact.
7. Split required: No. Single Nexus file expected.

## Investigation
- Current login file: `resources/js/pages/auth/Login.vue`.
- Existing fonts/tokens: `resources/css/app.css` defines Raleway header, Kanit sans, and Woosoo accent `#f6b56d`; dark theme background is already near black.
- Existing dashboard pattern: `resources/js/pages/Dashboard.vue` uses live operations language and admin stats that can be echoed in static login snapshot copy.
- UI primitives inspected: `Button`, `Input`, `Checkbox`, and `AppLogoIcon` support class overrides needed for the redesign.
- UI/UX skill script note: the installed `ui-ux-pro-max` skill file references a `scripts` path that resolves to a missing local target, so the loaded skill guidance was applied directly instead of the unavailable script output.

## Root Cause
The current login page predates the final dark Woosoo Admin visual direction. It uses the same brand family but presents the sign-in area as a light rounded card, so it does not fully match the admin dashboard/shell aesthetic or the provided mockup.

## Proposed Fix
Implement the approved design in `resources/js/pages/auth/Login.vue` only:
- Add a local `showPassword` ref and wire an accessible reveal/hide icon button.
- Replace the light card layout with a full dark warm split layout at large widths.
- Add a left brand panel with subtle amber glow, brand lockup, headline, and live operations snapshot with mono/tabular numerics.
- Add a compact mobile brand bar below the large breakpoint.
- Style dark inputs with leading lucide icons, warm focus rings, amber checkbox, and amber `Enter workspace` CTA.
- Preserve warning/status messages, reset link, remember checkbox, CSRF refresh, Inertia login route, and validation errors.

## Files Changed
- `../docs/cases/redesign-woosoo-nexus-login-page.md` (case checkpoint)

## Verification
Pending. Required after implementation:
- `npm.cmd run typecheck`
- `npm.cmd run build`
- Platform pre-merge check from root: `scripts/pre-merge-check.ps1 -App woosoo-nexus` if runtime prerequisites are available
- Browser/manual check of `/login` at desktop and mobile widths, including password reveal toggle
- Web design guideline review against the changed login file

## Executioner Verdict
Pending user approval before implementation.

## Remaining Risks
- Static operations snapshot values are decorative and should not imply a live backend data contract.
- Full pre-merge check may require PHP/composer/runtime services that are not guaranteed in this shell.
