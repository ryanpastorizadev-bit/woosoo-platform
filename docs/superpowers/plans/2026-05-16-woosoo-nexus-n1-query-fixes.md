# Woosoo Nexus N+1 Query Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans or superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the confirmed high-impact N+1 query paths in Nexus while keeping response shapes, auth checks, and order-state behavior intact.

**Architecture:** Batch relation and lookup work once at the controller/service boundary, keep resources focused on serialization, and avoid per-row POS calls during collection rendering. Preserve existing payload contracts unless a test explicitly requires a scoped change.

**Tech Stack:** Laravel 12, Eloquent, Inertia, Pest/PHPUnit, Sanctum.

---

**Scope note:** This plan covers the confirmed high-impact hotspots from the audit only. It excludes the medium batch-action loops (`bulkComplete`, `bulkVoid`, `markPrintedBulk`) and other lower-priority repeat lookups.

### Task 1: Dashboard rollups

**Files:**
- Modify: `app/Http/Controllers/Admin/DashboardController.php`
- Modify: `tests/Feature/DashboardTest.php`

- [ ] **Step 1: Add the failing query-budget regression**

Add a test named `test_dashboard_index_uses_constant_query_shape_for_devices_and_tables()` that seeds multiple devices and table orders, enables the DB query log, hits `GET /dashboard`, and asserts the query count stays bounded instead of growing with device count.

- [ ] **Step 2: Run the test and confirm it fails**

Run: `php artisan test tests/Feature/DashboardTest.php --filter=test_dashboard_index_uses_constant_query_shape_for_devices_and_tables -v`

Expected: FAIL because the current controller does one lookup per table order and three order queries per device.

- [ ] **Step 3: Replace the per-row lookups**

Change the `foreach ($tableOrders as $tableOrder)` block to resolve devices from one keyed collection, and replace the `->map()` body that does three `DeviceOrder` queries per device with grouped aggregates keyed by `device_id`.

- [ ] **Step 4: Re-run the regression test**

Run: `php artisan test tests/Feature/DashboardTest.php --filter=test_dashboard_index_uses_constant_query_shape_for_devices_and_tables -v`

Expected: PASS with the same dashboard payload shape.

- [ ] **Step 5: Commit**

Commit after the test is green with a message such as `fix(nexus): batch dashboard order rollups`.

### Task 2: Menu index image lookup

**Files:**
- Modify: `app/Http/Controllers/Admin/MenuController.php`
- Modify: `tests/Feature/Admin/MenuImagePresenceTest.php`

- [ ] **Step 1: Add the failing image-query regression**

Extend the existing menu image test with `test_menus_index_does_not_query_menu_images_per_row()` so it seeds several menus, enables the query log, loads the index page, and asserts the `MenuImage` lookup count does not scale with row count.

- [ ] **Step 2: Run the test and confirm it fails**

Run: `php artisan test tests/Feature/Admin/MenuImagePresenceTest.php --filter=test_menus_index_does_not_query_menu_images_per_row -v`

Expected: FAIL because the controller currently runs `MenuImage::where(...)->value(...)` inside the `map()` loop.

- [ ] **Step 3: Remove the per-menu image lookup**

Use the already eager-loaded `image` relation to derive `has_uploaded_image` from the loaded path, and stop querying `menu_images` again for each menu row.

- [ ] **Step 4: Re-run the regression test**

Run: `php artisan test tests/Feature/Admin/MenuImagePresenceTest.php --filter=test_menus_index_does_not_query_menu_images_per_row -v`

Expected: PASS while preserving the existing `Menus/Index` payload.

- [ ] **Step 5: Commit**

Commit after the test is green with a message such as `fix(nexus): remove menu image n1`.

### Task 3: Order repository hydration

**Files:**
- Modify: `app/Repositories/Krypton/OrderRepository.php`
- Create: `tests/Feature/Repositories/Krypton/OrderRepositoryTest.php`

- [ ] **Step 1: Add a repository-level regression**

Create a test that seeds several `Order`, `OrderCheck`, and `OrderedMenu` rows for the same terminal session, calls `OrderRepository::getAllOrdersWithDeviceData()`, and asserts the merged orders still include `orderCheck` and `orderedMenus` without per-order queries.

- [ ] **Step 2: Run the test and confirm it fails**

Run: `php artisan test tests/Feature/Repositories/Krypton/OrderRepositoryTest.php -v`

Expected: FAIL because `OrderCheck::where(...)->first()` and `OrderedMenu::where(...)->get()` currently run inside the `transform()` loop.

- [ ] **Step 3: Preload the dependent rows once**

Fetch all needed `order_id` values first, load `OrderCheck` and `OrderedMenu` collections in bulk, key them by `order_id`, and attach them inside the transform without issuing new queries per order.

- [ ] **Step 4: Re-run the repository test**

Run: `php artisan test tests/Feature/Repositories/Krypton/OrderRepositoryTest.php -v`

Expected: PASS with the same merged order structure.

- [ ] **Step 5: Commit**

Commit after the test is green with a message such as `fix(nexus): batch krypton order hydration`.

### Task 4: Browse-menu modifier fan-out

**Files:**
- Modify: `app/Http/Controllers/Api/V1/BrowseMenuApiController.php`
- Modify: `app/Repositories/Krypton/MenuRepository.php`
- Create: `tests/Feature/Api/V1/BrowseMenuApiTest.php`

- [ ] **Step 1: Add endpoint regressions**

Create tests for `getAllModifierGroups`, `getMenusWithModifiers`, and `getMenusByGroupRaw` that assert the JSON shape stays stable while the query count stays flat when the response contains multiple menus and modifier groups.

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `php artisan test tests/Feature/Api/V1/BrowseMenuApiTest.php -v`

Expected: FAIL because the controller still calls back into `getMenuModifiersByGroup()` from inside per-menu loops.

- [ ] **Step 3: Batch the modifier lookup**

Add a repository helper that accepts the parent/group IDs for the response in one call, return a keyed modifier collection, and make the controller reuse that keyed data instead of fetching modifiers one menu at a time.

- [ ] **Step 4: Re-run the browse-menu tests**

Run: `php artisan test tests/Feature/Api/V1/BrowseMenuApiTest.php -v`

Expected: PASS with the same menu/modifier payloads and preserved ordering.

- [ ] **Step 5: Commit**

Commit after the test is green with a message such as `fix(nexus): batch browse menu modifiers`.

### Task 5: Order service and refill lookup batching

**Files:**
- Modify: `app/Services/Krypton/OrderService.php`
- Modify: `app/Http/Controllers/Api/V1/OrderApiController.php`
- Modify: `tests/Unit/OrderServiceTest.php`
- Modify: `tests/Feature/OrderRefillTest.php`
- Modify: `tests/Feature/OrderCreateAndRefillTest.php`

- [ ] **Step 1: Add the failing lookup-regression tests**

Extend `tests/Unit/OrderServiceTest.php` with a reflection-based test for `calculateTotalsFromItems()` that seeds multiple menu IDs and asserts the method resolves prices from one bulk lookup. Extend the refill feature tests so a multi-item refill still succeeds while the menu lookup count stays bounded.

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `php artisan test tests/Unit/OrderServiceTest.php tests/Feature/OrderRefillTest.php tests/Feature/OrderCreateAndRefillTest.php -v`

Expected: FAIL because the service currently calls `KryptonMenu::find()` inside each item loop and the refill controller falls back to one name lookup per item.

- [ ] **Step 3: Resolve menu data once per request**

Collect distinct `menu_id` values before the loop, load the matching POS menu rows once, build a keyed lookup table, and use that map for both the pricing path and the refill name fallback.

- [ ] **Step 4: Re-run the pricing/refill tests**

Run: `php artisan test tests/Unit/OrderServiceTest.php tests/Feature/OrderRefillTest.php tests/Feature/OrderCreateAndRefillTest.php -v`

Expected: PASS with the same refill behavior and totals.

- [ ] **Step 5: Commit**

Commit after the tests are green with a message such as `fix(nexus): batch refill menu lookups`.

### Task 6: Remove resource-level table-status fan-out

**Files:**
- Modify: `app/Http/Resources/DeviceOrderResource.php`
- Create: `tests/Unit/Http/Resources/DeviceOrderResourceTest.php`

- [ ] **Step 1: Add a mock-based regression**

Create a unit test that builds a `DeviceOrder`, attaches a mocked loaded `table` relation, and asserts `DeviceOrderResource::toArray()` does not call `checkTableStatus()` during collection serialization.

- [ ] **Step 2: Run the test and confirm it fails**

Run: `php artisan test tests/Unit/Http/Resources/DeviceOrderResourceTest.php -v`

Expected: FAIL because the resource currently calls `checkTableStatus()` whenever a table relation is loaded.

- [ ] **Step 3: Make the resource serialization-only**

Remove the live POS status call from `DeviceOrderResource`, keep the loaded `table` relation as the source for `tablename`, and leave any live status enrichment to a single-order controller path if it is still needed later.

- [ ] **Step 4: Re-run the resource test**

Run: `php artisan test tests/Unit/Http/Resources/DeviceOrderResourceTest.php -v`

Expected: PASS with the same serialized order fields and no POS fan-out.

- [ ] **Step 5: Commit**

Commit after the test is green with a message such as `fix(nexus): stop table-status n1 in resources`.

### Notes and considerations

- Keep the order state machine unchanged.
- Do not modify the medium-priority bulk action loops in this plan.
- Preserve response shapes where current tests depend on them.
- Prefer keyed collections and aggregate queries over new helper methods unless the helper removes repeated work across more than one call site.
