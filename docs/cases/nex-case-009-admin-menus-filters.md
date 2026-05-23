---
status: canonical
last_reviewed: 2026-05-23
scope: woosoo-nexus
---

# CASE: nex-case-009-admin-menus-filters

## Run State
- task_slug: nex-case-009-admin-menus-filters
- tier: 2
- branch: agent/nex-case-009-admin-menus-filters
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-23 11:30

## Handoff
- Phase in progress: n/a
- Done so far: All 4 agents complete. Commit 84193ab on branch agent/nex-case-009-admin-menus-filters.
- Exact next action: Merge to staging.
- Working-tree state: clean (committed)
- Risks / do-not-redo: none

## Tier
2

## Branch
agent/nex-case-009-admin-menus-filters

## Problem

`MenuController@index` returns `course`, `group`, `category`, `is_available`, and `has_uploaded_image` for every menu row, but the Menus DataTable only registers `category` and `is_available` columns in `columns.ts`. Because `DataTableToolbar.vue`'s faceted filters bind to registered columns, the Course, Group, and Uploaded Image filters in the toolbar UI have nothing to attach to and are silently suppressed.

## Contrarian Review

- Scope: `woosoo-nexus` frontend only (Inertia/Vue). No backend change required.
- Tier 2: one app, UI-only, no auth, no state machine, no POS DB writes.
- Risk of modifying shared `DataTableToolbar.vue`: mitigated by column-gating all Menus-only logic via `hasColumn()` — other DataTable instances (Orders, Devices) are unaffected.
- `has_uploaded_image` boolean filter: toolbar sets filterValue to `true`/`false` boolean; TanStack's default `weakEquals` filter handles boolean comparison correctly.
- `course` and `group` faceted filters: follow the same pattern as the existing `category` column (no custom filterFn needed since `useFacetedOptions` generates string options and TanStack auto-selects `includesString`).
- `models.d.ts`: `Menu` already has `group: string`, `category: string`, `course: string`. Only `has_uploaded_image: boolean` needs to be added.
- `DataTableToolbar.vue`: already has `hasColumn()`, `useFacetedOptions` for course/category/group, and is_available toggle. Only `has_uploaded_image` toggle buttons need to be added.
- Verdict: Proceed. Tier 2.

## Investigation

- `columns.ts`: registers `select`, `name`, `category`, `price`, `is_available`, `id`. Missing: `course`, `group`, `has_uploaded_image`.
- `DataTableToolbar.vue`: already has `hasCourseColumn`, `hasCategoryColumn`, `hasGroupColumn` computed from `useFacetedOptions`. Course/Category/Group `DataTableFacetedFilter` components are already in template, gated on their respective `hasColumn` flags. `has_uploaded_image` not yet handled.
- `useFacetedOptions.ts`: returns `{ options: ComputedRef<FacetedFilterOption[]>, hasColumn: boolean }`. Extracts unique string values from column facets.
- `DataTableFacetedFilter.vue`: sets filterValue as `string[]` (array of selected values). Reads facet counts from `getFacetedUniqueValues()`.
- `models.d.ts`: `Menu` already types `course`, `group`, `category` as `string`. Missing `has_uploaded_image: boolean`.

## Root Cause

`course`, `group`, and `has_uploaded_image` are absent from `columns.ts`. Without registered columns, `useFacetedOptions` returns `hasColumn: false` for course and group, so their toolbar filters never render. `has_uploaded_image` has no column or toolbar UI at all.

## Proposed Fix

1. `columns.ts` — add `course`, `group`, `has_uploaded_image` columns.
2. `DataTableToolbar.vue` — add `has_uploaded_image` toggle buttons (Uploaded/Missing), each clearing on re-click.
3. `models.d.ts` — add `has_uploaded_image: boolean` to `Menu`.

## Files Changed

- `woosoo-nexus/resources/js/components/Menus/columns.ts`
- `woosoo-nexus/resources/js/components/ui/DataTableToolbar.vue`
- `woosoo-nexus/resources/js/types/models.d.ts`

## Verification

### Specialist + Verifier (2026-05-23)

**typecheck:** `npm run typecheck` (vue-tsc --noEmit) — exit 0, no errors.

**pre-merge-check:** `.\scripts\pre-merge-check.ps1 -App woosoo-nexus`
```
Tests: 430 passed (1510 assertions)
Duration: 226.95s
pre-merge-check OK (woosoo-nexus)
```
0 failures. No regressions. PHP backend suite unaffected (frontend-only change).

### Commit
Repository: woosoo-nexus
Branch: agent/nex-case-009-admin-menus-filters
Commit: `84193ab` — `feat(menus): restore Course/Group/Image filters in admin Menus DataTable`

## Executioner Verdict

**APPROVED** — 2026-05-23

Frontend-only scope strictly observed. Three columns registered (`course`, `group`, `has_uploaded_image`); toolbar Menus-only controls are column-gated via `hasColumn()` — no other DataTable instances affected. `has_uploaded_image` boolean filter uses TanStack's default `weakEquals`; the two toggle buttons (Uploaded/Missing) independently set `true`/`false`/`undefined`. TypeScript typecheck clean. Backend suite 430/430 green.

## Remaining Risks

- Other DataTable instances (Orders, Devices) must not be affected — column-gating guards this.
- `has_uploaded_image` boolean filter relies on TanStack `weakEquals` — verify rows with `false` are correctly filtered.
