---
status: canonical
last_reviewed: 2026-05-19
scope: tablet-ordering-pwa
---

# CASE: tablet-package-ui-redesign

## Run State
- task_slug: tablet-package-ui-redesign
- tier: 2
- branch: agent/tablet-package-ui-redesign
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: copilot
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-19 19:13

## Handoff
- Phase in progress: —
- Done so far: All phases complete. Contrarian (Tier 2, 6 findings). Specialist (3 files + corrections). Verifier (typecheck/lint/build/382 tests). Executioner APPROVED.
- Exact next action: None — COMPLETE.
- Working-tree state: committed `fbd789f` on staging (primary 3-file specialist commit); follow-up tweaks (PackageCard click→view-modifiers, focus event) in `c371d0f` on staging.
- Risks / do-not-redo: Do not re-run any phase.

## Tier
2

## Branch
agent/tablet-package-ui-redesign

## Problem

Restyle `PackageCard.vue` and `packageSelection.vue` to match reference designs. Add card
selection state (golden glow border) with a slide-up "Continue to Menu" CTA. Fix height-overflow
issues. Fix pre-existing blue text bug.

Plan source: `C:\Users\Pc1\.windsurf\plans\tablet-package-ui-redesign-247b53.md`

## Contrarian Review

**Tier 2 — PROCEED**

Findings to resolve during implementation:

1. **[HIGH] CTA z-index must be `z-20`** — page shell is `z-10`, inspector overlay is `z-30`.
   Without explicit `z-20` the slide-up CTA will be occluded or conflict with the inspector.

2. **[MEDIUM] Subtitle bold guest count requires `<strong>` tag** — cannot use plain
   `{{ guestCount }}` for bold rendering. Must use
   `For <strong>{{ guestCount }}</strong> {{ guestCount === 1 ? 'guest' : 'guests' }} · tap a
   package to preview the meats inside` or equivalent.

3. **[LOW] `focusedPackageId` is dead state** — `handleCardFocus` sets it but the template
   never reads it. Specialist must either wire it to a keyboard-accessibility aria attribute or
   remove it entirely. Do not leave orphaned reactive state.

4. **[LOW] `section` already has `min-h-0`** — PackageCard.vue line 117. Only `overflow-hidden`
   is missing; do not double-add `min-h-0`.

5. **[INFO] `@theme inline` removal is safe** — zero files use Tailwind semantic token classes
   (`bg-background`, `text-foreground`, etc.). All color refs are hardcoded hex or CSS vars.

6. **[INFO] CTA must call `proceedToMenuForPackage(selectedPackage.value)`** — do not inline
   a raw `$router.push`. The existing function handles store persistence.

Candidate skills: `nuxt-pwa-flow`, `nuxt`

## Investigation

Files confirmed read:
- `tablet-ordering-pwa/assets/css/input.css` — lines 1-45: v4 artifacts confirmed present
- `tablet-ordering-pwa/components/PackageCard.vue` — full read
- `tablet-ordering-pwa/pages/order/packageSelection.vue` — full read (29.6 KB)
- `tablet-ordering-pwa/.agents.md` — scope and hard rules confirmed

## Root Cause

Blue text: `<article>` in PackageCard.vue has no `text-white` base class; child text without
an active opacity utility cascades to `body { color: #111827 }` (dark navy, reads blue on dark
backgrounds). Compounded by `@custom-variant dark` and `@theme inline` Tailwind v4 syntax in
`input.css` causing PostCSS partial processing under `@nuxtjs/tailwindcss@6` (v3).

## Proposed Fix

Per plan `tablet-package-ui-redesign-247b53.md`. 3 files:
1. `assets/css/input.css` — remove v4 lines 1-45
2. `components/PackageCard.vue` — `text-white` base, `isSelected` prop, `select` emit, glow classes, `line-clamp-3`
3. `pages/order/packageSelection.vue` — `selectedPackage` ref, `handleCardSelect`, `:is-selected`/`@select` on all card instances, subtitle change, slide-up CTA (z-20), inspector hint

## Files Changed

1. `tablet-ordering-pwa/assets/css/input.css` — removed Tailwind v4 `@custom-variant dark` and `@theme inline` blocks (lines 1-45); replaced with v3-compatible empty base layer.
2. `tablet-ordering-pwa/components/PackageCard.vue` — added `text-white` base class; `isSelected` Boolean prop; `select` emit; golden glow border classes on selected state; `line-clamp-3` on description; removed orphaned `focusedPackageId` dead state; view-modifier + focus event wiring (`c371d0f`).
3. `tablet-ordering-pwa/pages/order/packageSelection.vue` — `selectedPackage` ref; `handleCardSelect` handler; `:is-selected`/`@select` bound on all PackageCard instances; subtitle bold guest count via `<strong>` tag; slide-up "Continue to Menu" CTA (`z-20`); inspector hint text.

Commits: `fbd789f` (primary 3-file specialist commit on `staging`); `c371d0f` (follow-up: PackageCard click→view-modifiers, focus event).

## Verification

```
vue-tsc (typecheck):  PASSED
eslint (lint):        PASSED
vitest (test):        382 / 382 PASSED
nuxt build:           PASSED
nuxt generate:        PASSED
```

Run by Verifier on commit `c371d0f` (staging branch). All Contrarian findings resolved (z-index `z-20`, `<strong>` subtitle, dead state removed, no double `min-h-0`, `proceedToMenuForPackage` called).

## Executioner Verdict

**APPROVED** — 2026-05-19. Tier 2 complete. All 6 Contrarian findings closed. 382/382 tests pass, full build pipeline green. No contract impact. No remaining risks.

## Remaining Risks

- None identified beyond Contrarian findings above.
