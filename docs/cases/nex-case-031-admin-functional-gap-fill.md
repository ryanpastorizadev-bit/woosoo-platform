---
status: canonical
last_reviewed: 2026-06-13
scope: woosoo-nexus
app: nexus
run_status: IN_PROGRESS
tier: 2
next_agent: verifier
branch: agent/nex-case-031-admin-functional-gap-fill
interrupted: false
updated: 2026-06-13
tags: [app/nexus, status/in-progress, tier/2]
---

# CASE: nex-case-031-admin-functional-gap-fill

> Functional checklist gap-fill for Laravel/Vue admin console. React prototype handoff ignored; real app is target.

## Run State
- task_slug: nex-case-031-admin-functional-gap-fill
- tier: 2
- branch: agent/nex-case-031-admin-functional-gap-fill
- status: IN_PROGRESS
- last_completed_agent: specialist:cursor
- next_agent: verifier
- active_runner: cursor
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-13

## Audit Table (pre-fix expectations → post-fix)

| Area | Pre | Post (expected) |
|------|-----|-----------------|
| Bulk void (history toolbar) | FAIL — wrong payload | PASS — `order_ids` |
| Detail sheet Void/Cancel | FAIL | PASS — destroy + update-status |
| Print toast (detail) | FAIL | PASS — vue-sonner |
| Print retry (Monitoring) | FAIL | PASS — Retry → orders.print |
| Orders kanban filter + refresh | FAIL | PASS |
| Users server search | FAIL | PASS |
| Reports date range + CSV (Daily Sales) | FAIL | PASS |
| Dashboard range toggle | FAIL | PASS — apiStats `range` |
| Global ⌘K search | FAIL | PASS — CommandDialog |
| Monitoring Print Audit link | FAIL | PASS |
| Settings reset defaults | FAIL | PASS |
| Do-not-regress set | PASS | Re-verify in browser |

## Specialist Investigation & Implementation

Implemented functional gaps per [[nex-case-028-admin-ui-handoff-completion]] visual baseline (no restyle):

**HIGH**
- Fixed `DataTableToolbar.handleBulkVoid` to send `{ order_ids }` (external IDs) matching `OrderController::bulkVoid`.
- `OrderDetailSheet`: AlertDialog Void + Cancel with state-machine gating; Void → `orders.destroy`, Cancel → `orders.update-status` cancelled.
- `Orders/Index.vue`: handlers + print toast via `route('orders.print')`.
- `MonitoringController`: `order_id` on failed print events; Retry button posts to existing print route.
- Monitoring header: Print Audit link.

**MED**
- Kanban toolbar: status/table/time filters + Refresh → `reloadOrdersFromServer()`.
- `UserController::index` server search; debounced input on `Users/Index.vue`.
- `ReportDateRangeToolbar` + Daily Sales export route `reports.daily-sales.export`.
- `DashboardController::apiStats` accepts `range=today|week|month`; Dashboard toggle wired.
- `AdminTopbar`: ⌘K/Ctrl+K command palette for navigation.

**LOW**
- `POST admin.settings.reset` + AlertDialog on Settings page.

**Tests:** Extended `OrderActionsTest` — destroy void, cancel via update-status, invalid transition flash. `php artisan test --filter=OrderActionsTest` → 11 passed.

**Packages UI consolidation (canonical `Package` model):**
- Rewrote [`Packages/Index.vue`](woosoo-nexus/resources/js/pages/Packages/Index.vue): hero header, card grid (POS menu name + price + flat "Cuts" list), create/edit dialog (modifier picker + descriptions preserved), removed Dining Tiers tab.
- Enriched [`PackageController::index()`](woosoo-nexus/app/Http/Controllers/Admin/PackageController.php) — `menuOptions` now includes POS `price` for card display.
- Removed entire `TabletPackageConfig` / Dining Tiers stack: controller, models, FormRequest, `PackageUpdated` event, `IndexPackageConfigs.vue`, API `packageConfigs()`, web + API routes.
- Added forward migration `2026_06_13_000001_drop_tablet_package_tables.php` (operator must run `php artisan migrate`).
- Rewired [`admin-shell.ts`](woosoo-nexus/resources/js/config/admin-shell.ts) nav + crumbs to `packages.index`; removed Legacy Packages card from [`Configuration.vue`](woosoo-nexus/resources/js/pages/Configuration.vue).
- Regenerated `ziggy.js` (no `package-configs.*` routes).
- **Tests:** `php artisan test --compact --filter=TabletPackagesApiTest` → 15 passed. `npm run build` → green.

## Code Simplification

**Refinements applied (16 files reviewed):**

| File | Change |
|------|--------|
| `DataTableToolbar.vue` | Removed 4 narrating inline comments (`// Status options for filtering`, `// Device options for filtering (derive from props)`, `// Table options for filtering (derive from props)`, `// Dialog states`); collapsed unnecessary blank lines in `handleExport` |
| `Orders/Index.vue` | Fixed double-quoted import `"@/components/ui/tabs"` → single-quoted to match project style |
| `Users/Index.vue` | Merged two `@inertiajs/vue3` import lines into one; removed stale `/* eslint-disable @typescript-eslint/no-unused-vars */` (no genuine unused vars present) |
| `Dashboard.vue` | Removed stale migration note comment `<!-- WOOSOO STEP 4: icon containers rounded-2xl → rounded-xl … -->` |
| `reports/DailySales.vue` | Eliminated 4 repeated inline `"₱" + new Intl.NumberFormat(…).format(…)` expressions in template; replaced with existing `currencyFormatter` function (DRY) |
| `UserController.php` | Removed commented-out `use AuthorizesRequests` trait and import; removed redundant class-level docblock |
| `DashboardController.php` | Removed stale `@param Request $request` from `index()` docblock (method takes no request parameter) |
| `routes/web.php` | Removed commented-out `Route::get('trashed', …)` dead route |

**No changes needed:** `OrderDetailSheet.vue`, `Monitoring/Index.vue`, `Admin/Settings.vue`, `ReportDateRangeToolbar.vue`, `AdminTopbar.vue`, `MonitoringController.php`, `ReportController.php`, `OrderActionsTest.php` — clean, no dead code or style drift.

**Hygiene (dead-code-cleanup):** PASS — removed commented-out use statement, commented-out route, stale migration comment, and duplicate eslint-disable directive.

---

**Packages UI consolidation pass (6 files reviewed):**

| File | Change |
|------|--------|
| `PackageController.php` | `syncModifiers`: replaced `isset($modifier['sort_order']) ? (int) $modifier['sort_order'] : $index` with `(int) ($modifier['sort_order'] ?? $index)` — idiomatic null coalescing; identical semantics |
| `Packages/Index.vue` | `toggleModifier`: removed redundant `includes()` guard on the remove branch; `Array.filter()` is safe when the value is absent, so the pre-check was dead logic |
| `Configuration.vue` | Removed orphan trailing blank line before `</script>` |
| `admin-shell.ts` | No changes — alignment and structure are clean, consistent with project style |
| `TabletApiController.php` | No changes per minimal-scope instruction; pre-existing orphaned docblock (lines 49–55 for `packages()` method, displaced when cache-key constant was inserted) noted for follow-up; no functional impact |
| `drop_tablet_package_tables.php` | No changes — migration is minimal and correct |

**Hygiene (dead-code-cleanup) — Packages pass:** PASS — no debug logs, commented-out code, unused imports, or orphaned scratch files found in the six reviewed files.

## Handoff
- KDS WIP stashed on `agent/nex-case-030-kds-server-authoritative-time` before branching from `dev`.
- Verifier: run pre-merge-check + browser Verify lines on Orders Echo board after detail sheet changes.
