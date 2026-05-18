---
goal: Remove confirmed N+1 query hotspots in woosoo-nexus
version: 1.0
date_created: 2026-05-16
last_updated: 2026-05-16
owner: Woosoo Nexus
status: 'Planned'
tags: [refactor, performance, laravel, database]
---

# Woosoo Nexus N+1 Query Fixes Implementation Plan

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

This plan removes the confirmed high-impact N+1 query paths in Nexus while preserving response shapes, auth boundaries, and order-state behavior.

## 1. Requirements & Constraints

- **REQ-001**: Preserve the current payload shape for all touched endpoints and views.
- **REQ-002**: Replace row-by-row relation lookups with keyed collections, `whereIn()` batches, or preloaded relations.
- **REQ-003**: Keep the work limited to `woosoo-nexus`; do not modify sibling apps.
- **SEC-001**: Do not weaken branch scoping, session scoping, or existing authorization checks.
- **SEC-002**: Do not expose raw SQL errors or stack traces in any user-facing response.
- **CON-001**: Do not change the bulk action endpoints in this plan.
- **CON-002**: Do not change the order state machine.
- **GUD-001**: Add one regression test per hotspot before changing the implementation.
- **PAT-001**: Prefer `with()`, `load()`, `pluck()`, `groupBy()`, `keyBy()`, and single aggregate queries over per-item queries.

## 2. Implementation Steps

### Implementation Phase 1

- GOAL-001: Remove repeat queries from admin list pages.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Add a dashboard query-budget regression and batch the dashboard rollups in `DashboardController@index`. |  |  |
| TASK-002 | Add a menu-image query-budget regression and remove the per-row `menu_images` lookup in `MenuController@index`. |  |  |

#### TASK-001: Batch dashboard rollups

**Files:**
- Modify: `app/Http/Controllers/Admin/DashboardController.php:67-161`
- Modify: `tests/Feature/DashboardTest.php:1-40`

- [ ] **Step 1: Write the failing test**

Add a Pest test named `test_dashboard_index_keeps_query_count_flat_when_device_count_grows()` that seeds 5 devices and multiple `device_orders`, enables the DB query log, hits `GET /dashboard`, and asserts the query count stays under a fixed ceiling.

```php
use Illuminate\Support\Facades\DB;

test('dashboard index keeps query count flat when device count grows', function () {
    DB::flushQueryLog();
    DB::enableQueryLog();

    $admin = User::factory()->create(['is_admin' => true]);
    $this->actingAs($admin)->get('/dashboard')->assertOk();

    expect(count(DB::getQueryLog()))->toBeLessThanOrEqual(15);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test tests/Feature/DashboardTest.php --filter=test_dashboard_index_keeps_query_count_flat_when_device_count_grows -v`

Expected: FAIL because `DashboardController@index()` currently runs one `Device::where('table_id', ...)` lookup per table order and three `DeviceOrder` queries per device.

- [ ] **Step 3: Write minimal implementation**

Replace the per-row device/table lookup and the per-device order stats with two keyed aggregates:

```php
$tableIds = $tableOrders->pluck('table_id')->filter()->unique()->values()->all();
$devicesByTableId = Device::with('table')
    ->whereIn('table_id', $tableIds)
    ->get()
    ->keyBy('table_id');

$deviceIds = Device::pluck('id')->all();
$deviceStats = DeviceOrder::whereIn('device_id', $deviceIds)
    ->selectRaw('device_id, COUNT(*) as order_count, SUM(CASE WHEN status IN (?, ?) THEN 1 ELSE 0 END) as pending_count, MAX(created_at) as last_order_at', [
        OrderStatus::PENDING->value,
        OrderStatus::CONFIRMED->value,
    ])
    ->groupBy('device_id')
    ->get()
    ->keyBy('device_id');
```

Use the keyed results when building the `tableOrders` and `devices` arrays.

- [ ] **Step 4: Run test to verify it passes**

Run: `php artisan test tests/Feature/DashboardTest.php --filter=test_dashboard_index_keeps_query_count_flat_when_device_count_grows -v`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/Http/Controllers/Admin/DashboardController.php tests/Feature/DashboardTest.php
git commit -m "fix(nexus): batch dashboard rollups"
```

#### TASK-002: Remove per-menu image lookup

**Files:**
- Modify: `app/Http/Controllers/Admin/MenuController.php:17-63`
- Modify: `tests/Feature/Admin/MenuImagePresenceTest.php:114-149`

- [ ] **Step 1: Write the failing test**

Add a Pest test named `test_menus_index_does_not_query_menu_images_per_row()` that seeds several menus with loaded `image` relations, enables the query log, hits `GET /menus`, and asserts the `menu_images` query count does not increase with the number of menus.

```php
use Illuminate\Support\Facades\DB;

test('menus index does not query menu_images per row', function () {
    DB::flushQueryLog();
    DB::enableQueryLog();

    $admin = User::factory()->admin()->create();
    $this->actingAs($admin)->get(route('menus'))->assertOk();

    $imageQueries = collect(DB::getQueryLog())
        ->pluck('query')
        ->filter(fn (string $sql) => str_contains($sql, 'menu_images'))
        ->count();

    expect($imageQueries)->toBeLessThanOrEqual(1);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test tests/Feature/Admin/MenuImagePresenceTest.php --filter=test_menus_index_does_not_query_menu_images_per_row -v`

Expected: FAIL because `MenuController@index()` currently runs `MenuImage::where('menu_id', $menu->id)->value('path')` inside the `map()` loop.

- [ ] **Step 3: Write minimal implementation**

Remove the extra query and use the already eager-loaded relation:

```php
$menus = $menus->map(function ($menu) {
    $imagePath = $menu->image?->path;

    return [
        'id' => $menu->id,
        'name' => $menu->name,
        'img_url' => $menu->image_url,
        'has_uploaded_image' => $imagePath !== null && Storage::disk('public')->exists($imagePath),
        'group' => $menu->group->name ?? null,
        'category' => $menu->category->name ?? null,
        'course' => $menu->course->name ?? null,
    ];
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `php artisan test tests/Feature/Admin/MenuImagePresenceTest.php --filter=test_menus_index_does_not_query_menu_images_per_row -v`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/Http/Controllers/Admin/MenuController.php tests/Feature/Admin/MenuImagePresenceTest.php
git commit -m "fix(nexus): remove menu image n1"
```

### Implementation Phase 2

- GOAL-002: Remove repeat POS lookups from order and browse flows.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-003 | Batch `OrderRepository::getAllOrdersWithDeviceData()` hydration. |  |  |
| TASK-004 | Batch browse-menu modifier assembly in `BrowseMenuApiController` and `MenuRepository`. |  |  |
| TASK-005 | Batch POS menu lookups in `OrderService` and refill fallback lookup in `OrderApiController`. |  |  |
| TASK-006 | Stop `DeviceOrderResource` from calling `checkTableStatus()` per row. |  |  |

#### TASK-003: Batch order repository hydration

**Files:**
- Modify: `app/Repositories/Krypton/OrderRepository.php:25-68`
- Create: `tests/Feature/Repositories/Krypton/OrderRepositoryTest.php`

- [ ] **Step 1: Write the failing test**

Create a feature test that seeds multiple POS `orders`, `order_checks`, and `ordered_menus` rows for one terminal session, enables query logging, calls `OrderRepository::getAllOrdersWithDeviceData()`, and asserts the merge uses a bounded query count.

```php
test('getAllOrdersWithDeviceData hydrates order checks and ordered menus in bulk', function () {
    DB::flushQueryLog();
    DB::enableQueryLog();

    $result = OrderRepository::getAllOrdersWithDeviceData([
        'session' => $session,
        'terminalSession' => $terminalSession,
    ]);

    expect(count(DB::getQueryLog()))->toBeLessThanOrEqual(8);
    expect($result)->not->toBeEmpty();
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test tests/Feature/Repositories/Krypton/OrderRepositoryTest.php -v`

Expected: FAIL because `transform()` currently executes `OrderCheck::where(...)->first()` and `OrderedMenu::where(...)->get()` once per order.

- [ ] **Step 3: Write minimal implementation**

Load the dependent rows once, key them by `order_id`, and reuse them in the transform:

```php
$orderIds = $orders->pluck('id')->all();

$orderChecksByOrderId = OrderCheck::whereIn('order_id', $orderIds)->get()->keyBy('order_id');
$orderedMenusByOrderId = OrderedMenu::whereIn('order_id', $orderIds)->get()->groupBy('order_id');

$mergedOrders = $orders->transform(function ($order) use ($deviceOrders, $orderChecksByOrderId, $orderedMenusByOrderId) {
    $data = $deviceOrders->get($order->id);
    $order->orderCheck = $orderChecksByOrderId->get($order->id);
    $order->orderedMenus = $orderedMenusByOrderId->get($order->id, collect());
    return $order;
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `php artisan test tests/Feature/Repositories/Krypton/OrderRepositoryTest.php -v`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/Repositories/Krypton/OrderRepository.php tests/Feature/Repositories/Krypton/OrderRepositoryTest.php
git commit -m "fix(nexus): batch krypton order hydration"
```

#### TASK-004: Batch browse-menu modifiers

**Files:**
- Modify: `app/Http/Controllers/Api/V1/BrowseMenuApiController.php:29-272, 412-608`
- Modify: `app/Repositories/Krypton/MenuRepository.php:197-265`
- Create: `tests/Feature/Api/V1/BrowseMenuApiTest.php`

- [ ] **Step 1: Write the failing test**

Create a feature test that exercises `getAllModifierGroups`, `getMenusWithModifiers`, and `getMenusByGroupRaw` with multiple package/menu IDs and asserts the query count stays flat.

```php
test('browse menu endpoints batch modifier assembly', function () {
    DB::flushQueryLog();
    DB::enableQueryLog();

    $response = $this->getJson('/api/v1/menus/modifiers-grouped?group=Meat%20Order');

    $response->assertOk();
    expect(count(DB::getQueryLog()))->toBeLessThanOrEqual(10);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test tests/Feature/Api/V1/BrowseMenuApiTest.php -v`

Expected: FAIL because the controller still assembles modifiers with repeated per-menu calls such as `getMenuModifiersByGroup()` and `Menu::getModifiers()`.

- [ ] **Step 3: Write minimal implementation**

Add one data-access method that batches modifier retrieval for a list of IDs and reuse the existing package helper:

```php
public function getMenuModifiersByGroupIds(array $modifierGroupIds): EloquentCollection
{
    return Menu::with(['image', 'group'])
        ->whereIn('menu_group_id', $modifierGroupIds)
        ->where('is_modifier_only', true)
        ->get();
}
```

In the controller, build one keyed lookup from the batched result and reuse `Menu::getPackagesWithModifiers($menuRows)` for package summaries instead of calling `Menu::getModifiers()` inside loops.

- [ ] **Step 4: Run test to verify it passes**

Run: `php artisan test tests/Feature/Api/V1/BrowseMenuApiTest.php -v`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/Http/Controllers/Api/V1/BrowseMenuApiController.php app/Repositories/Krypton/MenuRepository.php tests/Feature/Api/V1/BrowseMenuApiTest.php
git commit -m "fix(nexus): batch browse menu modifiers"
```

#### TASK-005: Batch POS menu lookups in orders and refill paths

**Files:**
- Modify: `app/Services/Krypton/OrderService.php:38-320`
- Modify: `app/Http/Controllers/Api/V1/OrderApiController.php:184-320`
- Modify: `tests/Unit/OrderServiceTest.php:1-60`
- Modify: `tests/Feature/OrderRefillTest.php:59-164`
- Modify: `tests/Feature/OrderCreateAndRefillTest.php:59-179`

- [ ] **Step 1: Write the failing test**

Extend the unit test so `calculateTotalsFromItems()` is exercised with three menu IDs and the test asserts the service resolves prices from one bulk lookup instead of `KryptonMenu::find()` per item. Extend the refill tests so a multi-item refill still succeeds when the controller resolves the menu map once.

```php
test('calculateTotalsFromItems uses one bulk menu lookup', function () {
    $service = app(OrderService::class);
    $method = new ReflectionMethod($service, 'calculateTotalsFromItems');
    $method->setAccessible(true);

    $result = $method->invoke($service, [
        ['menu_id' => 46, 'quantity' => 1],
        ['menu_id' => 47, 'quantity' => 2],
        ['menu_id' => 48, 'quantity' => 1],
    ]);

    expect($result)->toHaveKeys(['subtotal', 'tax', 'total']);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test tests/Unit/OrderServiceTest.php tests/Feature/OrderRefillTest.php tests/Feature/OrderCreateAndRefillTest.php -v`

Expected: FAIL because `calculateTotalsFromItems()` currently calls `KryptonMenu::find()` inside the item loop and the refill controller falls back to name-based lookup per item.

- [ ] **Step 3: Write minimal implementation**

Collect all distinct menu IDs once, load the POS menus once, and reuse keyed maps for both pricing and refill fallback:

```php
$menuIds = collect($items)->pluck('menu_id')->filter()->unique()->values()->all();
$menusById = KryptonMenu::whereIn('id', $menuIds)->get()->keyBy('id');

foreach ($items as $item) {
    $menu = $menusById->get((int) $item['menu_id']);
    $price = (float) ($menu?->price ?? 0);
}
```

For the refill fallback, build the same keyed map once and use `$menusByName = KryptonMenu::whereIn('receipt_name', $names)->get()->keyBy(...)` before the item loop.

- [ ] **Step 4: Run test to verify it passes**

Run: `php artisan test tests/Unit/OrderServiceTest.php tests/Feature/OrderRefillTest.php tests/Feature/OrderCreateAndRefillTest.php -v`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/Services/Krypton/OrderService.php app/Http/Controllers/Api/V1/OrderApiController.php tests/Unit/OrderServiceTest.php tests/Feature/OrderRefillTest.php tests/Feature/OrderCreateAndRefillTest.php
git commit -m "fix(nexus): batch refill menu lookups"
```

#### TASK-006: Remove table-status fan-out from the resource layer

**Files:**
- Modify: `app/Http/Resources/DeviceOrderResource.php:15-105`
- Create: `tests/Unit/Http/Resources/DeviceOrderResourceTest.php`

- [ ] **Step 1: Write the failing test**

Create a unit test that loads a `DeviceOrder` with a mocked `table` relation and asserts the resource does not call `checkTableStatus()` during serialization.

```php
test('device order resource does not call checkTableStatus', function () {
    $table = Mockery::mock(\App\Models\Krypton\Table::class);
    $table->shouldNotReceive('checkTableStatus');

    $order = DeviceOrder::factory()->make();
    $order->setRelation('table', $table);
    $order->setRelation('device', null);
    $order->setRelation('items', collect());

    (new DeviceOrderResource($order))->toArray(request());
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test tests/Unit/Http/Resources/DeviceOrderResourceTest.php -v`

Expected: FAIL because `DeviceOrderResource::toArray()` currently calls `checkTableStatus()` whenever `table` is loaded.

- [ ] **Step 3: Write minimal implementation**

Make the resource serialization-only and keep the loaded relation as the source of truth:

```php
$tableRelation = $this->relationLoaded('table') ? $this->table : null;

return [
    'table' => $tableRelation,
    'tablename' => $tableRelation?->name,
    'items' => collect($items)->map(fn ($it) => [...])->values()->all(),
];
```

Remove the live `checkTableStatus()` call from `toArray()` so a collection response does not fan out into POS queries.

- [ ] **Step 4: Run test to verify it passes**

Run: `php artisan test tests/Unit/Http/Resources/DeviceOrderResourceTest.php -v`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/Http/Resources/DeviceOrderResource.php tests/Unit/Http/Resources/DeviceOrderResourceTest.php
git commit -m "fix(nexus): remove resource table status n1"
```

## 3. Alternatives

- **ALT-001**: Leave the current lazy-loading behavior in place and rely on caching. Rejected because it hides the query explosion instead of removing it.
- **ALT-002**: Move all batching into new service classes. Rejected because the affected code paths are already localized and can be fixed safely in the current controllers/repository/resource files.

## 4. Dependencies

- **DEP-001**: Existing Eloquent relations on `DeviceOrder`, `Menu`, `OrderCheck`, `OrderedMenu`, and `MenuImage`.
- **DEP-002**: Existing test harness helpers such as `RefreshDatabase`, `MocksKryptonSession`, and the current Pest test files.
- **DEP-003**: Existing `Storage::disk('public')` test setup for menu image checks.

## 5. Files

- **FILE-001**: `app/Http/Controllers/Admin/DashboardController.php` — batch admin dashboard rollups.
- **FILE-002**: `app/Http/Controllers/Admin/MenuController.php` — remove the per-menu image lookup.
- **FILE-003**: `app/Repositories/Krypton/OrderRepository.php` — preload POS order children once.
- **FILE-004**: `app/Http/Controllers/Api/V1/BrowseMenuApiController.php` — batch browse-menu modifier assembly.
- **FILE-005**: `app/Repositories/Krypton/MenuRepository.php` — add a batched modifier helper.
- **FILE-006**: `app/Services/Krypton/OrderService.php` — batch POS menu price lookups.
- **FILE-007**: `app/Http/Controllers/Api/V1/OrderApiController.php` — batch refill fallback menu resolution.
- **FILE-008**: `app/Http/Resources/DeviceOrderResource.php` — remove per-row `checkTableStatus()`.
- **FILE-009**: `tests/Feature/DashboardTest.php` — dashboard regression.
- **FILE-010**: `tests/Feature/Admin/MenuImagePresenceTest.php` — menu image regression.
- **FILE-011**: `tests/Feature/Repositories/Krypton/OrderRepositoryTest.php` — repository regression.
- **FILE-012**: `tests/Feature/Api/V1/BrowseMenuApiTest.php` — browse-menu regression.
- **FILE-013**: `tests/Unit/OrderServiceTest.php` — pricing regression.
- **FILE-014**: `tests/Feature/OrderRefillTest.php` — refill regression.
- **FILE-015**: `tests/Feature/OrderCreateAndRefillTest.php` — refill regression.
- **FILE-016**: `tests/Unit/Http/Resources/DeviceOrderResourceTest.php` — resource regression.

## 6. Testing

- **TEST-001**: `php artisan test tests/Feature/DashboardTest.php --filter=test_dashboard_index_keeps_query_count_flat_when_device_count_grows -v`
- **TEST-002**: `php artisan test tests/Feature/Admin/MenuImagePresenceTest.php --filter=test_menus_index_does_not_query_menu_images_per_row -v`
- **TEST-003**: `php artisan test tests/Feature/Repositories/Krypton/OrderRepositoryTest.php -v`
- **TEST-004**: `php artisan test tests/Feature/Api/V1/BrowseMenuApiTest.php -v`
- **TEST-005**: `php artisan test tests/Unit/OrderServiceTest.php tests/Feature/OrderRefillTest.php tests/Feature/OrderCreateAndRefillTest.php -v`
- **TEST-006**: `php artisan test tests/Unit/Http/Resources/DeviceOrderResourceTest.php -v`

## 7. Risks & Assumptions

- **RISK-001**: Query-count assertions can vary if unrelated middleware or test setup adds extra SQL; keep the thresholds intentionally above the known fixed baseline.
- **RISK-002**: `Menu::image` and `Storage::disk('public')` must stay aligned so the image-presence check still reflects actual uploaded files.
- **RISK-003**: The browse-menu refactor depends on preserving the existing package modifier ordering.
- **ASSUMPTION-001**: The current N+1 hotspots are the only ones addressed in this plan; bulk-action loops are intentionally deferred.
- **ASSUMPTION-002**: Existing response shapes and route names remain stable.

## 8. Related Specifications / Further Reading

- `E:\Projects\woosoo-platform\docs\AI_CONTEXT.md`
- `E:\Projects\woosoo-platform\AGENTS.md`
- `E:\Projects\woosoo-platform\woosoo-nexus\.agents.md`
- `E:\Projects\woosoo-platform\docs\superpowers\plans\2026-05-16-woosoo-nexus-n1-query-fixes.md`
