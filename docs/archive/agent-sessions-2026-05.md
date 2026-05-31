---
status: archived
scope: ecosystem
archived: 2026-05-31
note: >
  Historical Claude Code session log (concatenated session dumps), retained only for the
  embedded Plan A–E design docs and the Admin-UI design notes. NOT source of truth. Its
  "STAGING BLOCKED / Plan D pending" status is stale and superseded by state/QUEUE.md
  (reconciled 2026-05-30). Do not load this file to derive active state.
---

## Claude Code Sessions

---

## Implement Nexus backend contract update Plan: 

# Consolidated Plan — Five Work Items (Prioritized)

Five independent work items against Woosoo, kept as separate PRs (one-app rule + clean revert surface), sequenced and cross-referenced here.

## Status (reconciled against delegated completion reports)

- ✅ **Plan A — IMPLEMENTED + VALIDATED** (delegated). `instanceof` fix at `SessionApiController.php:95`; `tests/Feature/Api/V1/SessionResetAuthTest.php` 4/4 (17 assertions); no regressions; `SessionReset` dispatched. ⚠️ Commit/merge not explicitly confirmed in the report — **verify A is committed**; do NOT re-implement or re-dispatch.
- ✅ **Plan B — IMPLEMENTED + VALIDATED, NOT YET COMMITTED** (delegated). `stores/Order.ts:374` + `871–873`; `tests/order-restrictions.spec.ts` 14/14; typecheck/build/lint clean. The delegated agent's own note: *"Plan B is ready to commit."* → **B must be committed before D is dispatched** (D rebases on B's `Order.ts` lines).
- ✅ **Plan A — COMPLETE** (Nexus, 4/4 tests).
- ✅ **Plan B — MERGED** into `stores/Order.ts` (predicate fixes integrated).
- ✅ **Plan C (C1+C2) — COMPLETE**. C1: strict packages/category endpoints, group-34 meats, legacy removed. C2: meats slice + disable logic, beverages→drinks (12 renames, persist v2), `MenuItemGrid` `disabled` flag.
- ✅ **Plan E — COMPLETE** (Nexus, `woosoo:verify-integrity` + `/api/health` broadcasting fingerprint).
- 🟡 **Plan D — IMPLEMENTED, TEST REMEDIATION PENDING (`Plan D-fix`)**. 5 components delivered; coexistence verified (B @374/854–856, C2 @194, D catch blocks ~470–580 — all intact, no overlap). **319/340 tests pass, 21 fail.** Not landable until triaged.

### `Plan D-fix` — test-failure triage (TRIAGE-FIRST, NOT GREEN-FIRST)
The 21 failures must each be classified **stale-test** vs **real-regression** before any expectation is changed. Do not edit assertions to pass.
- **`connection-store.spec.ts`, `connection-blocking-overlay.spec.ts`** — new D tests missing `vi.useFakeTimers()` for the 1.5s debounce. **Legit test-infra fix** — safe to add fake timers.
- **`order.submit.spec.ts:141`** — was "Network error", now "Something went wrong…". ⚠️ Only a stale expectation **if** a network error is *intentionally* the generic fallback. Per Plan D design a network failure must classify as **CONNECTIVITY** (overlay path), not the SERVER catch-all. If it's hitting the generic string, that's a **classifier bug** — fix `useErrorClassifier`, not the test.
- **`order-restrictions.spec.ts` (8 failures)** — ⚠️ **This is Plan B's P0 regression suite (was 14/14 green).** Most likely cause: D's catch-block/classifier refactor changed the rejection `submitOrder` throws, which B's case 3 asserts ("already placed" message). This is a **D↔B interaction regression in a P0 path** until proven otherwise. Resolution: D must preserve the user-facing "already placed" semantics; only update B's test if the new message provably communicates the same guard AND is the intended classifier output. Verify the other B cases (`hasPlacedOrder`, `toggleRefillMode`) still pass on real behavior.

### ✅ VERIFIED STATE (read-only file check, latest turn)
- **Plan A APPLIED & correct:** `SessionApiController.php:95` = `$user instanceof \App\Models\Device`. (Earlier "not applied" report was stale/false.) Focused `SessionResetAuthTest` 4/4 per delegated report (not independently runnable in plan mode).
- **Plan E.2 LIVE (not dead code):** real `/api/health` = inline closure `routes/api.php:339` → `checkBroadcastingIntegrity()` (`routes/api.php:44`) returns redacted `broadcasting` block + degrades status. `HealthBroadcastingTest` (6) hits the live route, asserts no raw key/secret + consistent/degraded. Genuine validation.
- **Orphan confirmed:** `app/Http/Controllers/Api/HealthController.php` duplicates the integrity logic but is route-unbound — logic-drift hazard. **Action: delete after confirming no imports; re-run E focused tests.**
- **Plan A/B/C/E** individually validated by focused tests (per reports). Counts not independently verifiable in plan mode.

### 🔴 REMAINING BLOCKERS — ROOT-CAUSED (read-only verified this turn)

**Blocker 1 — Nexus test cascade (`Plan F` — bootstrap repair).**
Root cause identified: **single stale-bootstrap-cache cascade, not 122 independent failures.**
- `RequestId` middleware is GLOBAL prepend (`bootstrap/app.php:34–38`) → runs on every HTTP test's pipeline.
- `RequestId.php` verified healthy (correct `namespace App\Http\Middleware;`, no ctor/deps). Source is clean — routes use FQN `RequestId::class`; only `throttle.device`/`print_events.enabled` are aliased; **no `requestId` string alias in source**.
- All `SessionResetAuthTest` failed with identical `Target class [requestId] does not exist` → container resolving an alias absent from source = **stale `bootstrap/cache/*` artifact** (same stale-cache footgun Plan E detects, here hitting the test bootstrap). Uniform ~122 count = one root cause cascading through the global pipeline before test bodies run.
- **Remediation (prerequisite, not a waiver):** (1) `php artisan optimize:clear` + delete `bootstrap/cache/*.php` + `composer dump-autoload`; re-run suite. (2) If cascade clears → single artifact, re-evaluate gate honestly. (3) If it persists → locate the `requestId` resolution in cached/compiled/env-bootstrap (source is clean), fix the one binding. (4) Triage residue. A/E focused tests already green. "Pre-existing" is an explanation, NOT a staging waiver — `AGENTS.md` gate must be honestly green.

**Blocker 2 — Plan D classifier convergence (`Plan D-rework`).**
- Status: customer-safe-but-incidental. `Order.ts` hand-rolls friendly strings; `useErrorClassifier` orphaned; `479/532/557` still pass server-controlled text → partial `CLAUDE.md` violation, NOT emergency (worst leak already gone).
- End state: single sanitization chokepoint — catch blocks call `classifyError(error).message`; raw only to `logger`; safe-by-construction.
- Long-term solution = pasted "Plan D Error Classifier Resolution": harden `classifyError()` (whitelist only; special-case `MENU_ITEM_UNAVAILABLE`/`SESSION_NOT_FOUND`; raw→logger) → wire into catch blocks preserving 409-resume/menu-refresh/idempotency + keep local domain errors ("already placed") → structural test that `Order.ts` uses `classifyError` + no-leak regression.
- Decision: converge (recommended) vs formally descope (must be logged in approved plan + audit doc, not silently dropped).

**Orphan cleanup:** delete `app/Http/Controllers/Api/HealthController.php` (duplicate of live `routes/api.php:44` `checkBroadcastingIntegrity()`, route-unbound, drift hazard) after confirming no imports; re-run E focused tests.

### (historical) Plan D materially incomplete vs approved design (verified read-only earlier)
Direct file verification of `tablet-ordering-pwa/stores/Order.ts`:
- ✅ B@376 (`getServerOrderId()` guard), B@854–859 (`hasPlacedOrder` reads `sessionStore.orderId`), C2@194 (`menuStore.drinks`) — all exact, coexist, no conflict. Worst leak (`storage/logs/laravel.log` + raw 500 body) eliminated.
- ❌ **`classifyError`/`useErrorClassifier` NOT wired into `Order.ts`** (zero hits). Plan D.6 required catch blocks to route through `classifyError()`. Implementation is hand-rolled inline `throw new Error(...)`; the classifier composable exists but is orphaned.
- ❌ **Network errors → generic fallback, not CONNECTIVITY** (`if (!error.response) throw "Something went wrong…"`, line ~573). Confirms `order.submit.spec.ts:141` is a REAL incomplete-integration failure — must NOT be "fixed" by editing the assertion.
- ⚠️ Raw server strings still thrown to UI: line 479 `responseData.message`, 532 joined `validationErrors`, 557 `errorResponse?.message` (server-controlled, not whitelist-only per Plan D).
- ❌ `components/feedback/ConnectionBlockingOverlay.vue` not found at expected path (Glob miss) — core blocking-overlay deliverable possibly missing/misplaced; verify.
- ❌ No test evidence; 21 failures incl. 8 in B's P0 suite still unproven.

Decision required: rework D to the approved classifier architecture vs descope to the hand-rolled sanitization. Until resolved, **D not landable; deploy sequence frozen.**

### (superseded) STAGING BLOCKED — merge-clean ≠ regression-free
A "ready to stage" report confirmed file coexistence (B@376, B@855–859, C2@194, D@477–578, no conflicts) but provided **no test evidence**. The blocker was never merge conflicts — it is the **21 failures incl. 8 in `order-restrictions.spec.ts` (B's P0 suite)**. Coexistence does not clear the gate. **D remains BLOCKED** until: full 340/340 (or explicit per-failure stale-vs-regression triage), explicit proof B's recovered-order guard still fires on real behavior, `order.submit.spec.ts:141` network→CONNECTIVITY confirmed, no-leak regression test green, and `pre-merge-check.ps1 -App tablet-ordering-pwa` exit 0. Also still open: confirm **Plan A committed**.

### ⚠️ D-fix state UNKNOWN — read-only assessment required first
The dispatched `Plan D-fix` agent never returned a report and current execution state is unknown. **Do not blindly re-dispatch** — a half-finished agent may have left partial edits in `stores/Order.ts` / specs. Next action = a **strictly read-only** ground-truth assessment of `tablet-ordering-pwa` (git diff, test run, B/C2/D coexistence, presence of D-fix edits). Outcome decides: (a) nothing applied → re-dispatch D-fix fresh; (b) partial edits present → hand the partial state to a completion pass; (c) actually green → run the gate.

### Remaining
1. **Read-only assessment (NEXT)** — see prompt; establishes whether D-fix ran.
2. Then run `Plan D-fix` triage; classify every one of the 21.
2. After triage: `npm run typecheck`/`lint`/`build` clean; `.\scripts\pre-merge-check.ps1 -App tablet-ordering-pwa` exits 0; the no-leak regression test green; Plan B's `order-restrictions.spec.ts` back to fully green **on real behavior** (not rewritten to pass).
3. **Deploy order:** C1+C2 atomic, **Nexus-first** (PWA 422s on `/categories/drinks/menus` until Nexus is live). A and E independent. D PWA-only, after C2. Audit-doc updates: Nexus contract changes (C1) + `/api/health` additive field (E).

## Sequencing & Severity

| # | Plan | App | Severity | Status | Blocks / Depends |
|---|------|-----|----------|--------|------------------|
| **A** | Session reset device guard | woosoo-nexus | P0 — Critical | ✅ Done | — |
| **B** | Refill-mode predicate divergence | tablet-ordering-pwa | P0 — High | ✅ Done | — |
| **E** | Reverb config-integrity validator | woosoo-nexus | **P1 — High (recurrence guard; past live incident)** | 🆕 New | None — parallel-safe now. Disjoint files from A/C. |
| **D** | Graceful customer-safe error handling | tablet-ordering-pwa | P0 — High | ⏳ Ready | Rebase on B (shared `stores/Order.ts`, different lines). |
| **C** | Fixed categories + package-allowed meats | both apps (integration) | P1 — Medium-High | ⏳ Ready | C1 (Nexus) anytime; C2 (PWA) after D. Nexus-first deploy. |

**File overlap to watch:** Plans C and D both still touch `tablet-ordering-pwa/stores/Order.ts` (B already landed on 374/871–873; C edits 193; D refactors catch blocks ~477, 504–578). No line-level collision; whichever lands first forces a rebase. Recommended remaining PWA merge order: **D → C**. Plan E shares no files with any other plan.

**Semantic gap remaining after all three land:** Plan C's Acceptance Criterion #6 ("recovered active orders hydrate package/order details separately from catalog eligibility") is **not** closed by B. B fixes the predicate (so the UI affordance is right); the "order shows 0 items / ₱0.00" symptom is a separate hydration bug in the order store / `DeviceOrderResource` flow. Track as a fourth ticket — out of scope for all three plans here.

---

# Plan A — Session reset device guard (Nexus Critical #3)

## Context
The 2026-05-14 Nexus stabilization audit flagged the device authorization branch on `POST /api/sessions/{id}/reset` as broken. At [SessionApiController.php:95](woosoo-nexus/app/Http/Controllers/Api/V1/SessionApiController.php:95) the code reads:

```php
$isDevice = $user && get_class($user) === '\\App\\Models\\Device';
```

PHP's `get_class()` returns the FQN **without** a leading backslash (`App\Models\Device`). The literal `'\\App\\Models\\Device'` resolves to `\App\Models\Device`. The comparison is always false → every device caller is 403'd even though `auth:sanctum` accepts device tokens and the route is documented as "admin **or** device".

Outcome: the device path works as intended; a regression test pins it.

## Fix (one line)
```php
// before
$isDevice = $user && get_class($user) === '\\App\\Models\\Device';
// after
$isDevice = $user instanceof \App\Models\Device;
```

`instanceof` is idiomatic, escape-safe, subclass-tolerant, and null-safe (drops the redundant `$user &&`). The audit's action item #3 explicitly proposes it. Grep confirms no other file in `app/` uses this `get_class($user)` string-equality pattern.

## Test — new file `tests/Feature/SessionResetAuthTest.php`
Three cases:
1. **Admin can reset** — `actingAs($adminUser)` (sanctum web guard) → 200, `success: true`, version increments.
2. **Device can reset** — `Sanctum::actingAs($device, [], 'device')` (match the pattern in `DeviceTokenLifecycleTest.php` / `DeviceCreateOrderConflictTest.php`) → 200, version increments, `SessionReset` event dispatched.
3. **Unprivileged user rejected** — non-admin `User`, no `is_admin` → 403, `success: false`.

Use `Event::fake([SessionReset::class])` and `Cache::flush()` for isolation. Assert the cache key `session:{id}:version` is set/incremented per call. Reuse existing factories — do not invent a new device-acting helper.

## Critical files
| Path | Action |
|---|---|
| [woosoo-nexus/app/Http/Controllers/Api/V1/SessionApiController.php](woosoo-nexus/app/Http/Controllers/Api/V1/SessionApiController.php) | Edit line 95 only |
| `woosoo-nexus/tests/Feature/SessionResetAuthTest.php` | Create — 3 cases |

Reference-only: [routes/api.php:230-233](woosoo-nexus/routes/api.php), [SessionExpiryHandlingTest.php](woosoo-nexus/tests/Feature/Auth/SessionExpiryHandlingTest.php), [SessionReset.php](woosoo-nexus/app/Events/SessionReset.php).

## Out of scope
`API_CONTRACT_SYNC.md` line-number drift; other audit Criticals (broadcast channel auth, GET credential endpoint, branch scoping); `auth:sanctum` middleware — already correct.

## Verification
1. `php -l app/Http/Controllers/Api/V1/SessionApiController.php` — no syntax errors.
2. `php artisan test --filter=SessionResetAuthTest` — green.
3. `composer test` — no regressions in CSRF / session tests.
4. `bash scripts/pre-merge-check.sh --app woosoo-nexus` (or `.\scripts\pre-merge-check.ps1 -App woosoo-nexus`) exits 0.
5. Manual: `curl -X POST -H "Authorization: Bearer <device-token>" http://localhost/api/sessions/1/reset` → `{"success":true,...}`.

## Rollback
Revert the one line; delete the new test file. No schema, contract, or migration change.

---

# Plan B — Refill-mode predicate divergence (Tablet PWA)

## Context
On 2026-05-14, `toggleRefillMode` at [stores/Order.ts:296](tablet-ordering-pwa/stores/Order.ts:296) was broadened to include a session-orderId fallback so reload-mid-session can enter refill mode. Two other predicates with the **same logical intent** were not widened, and the regression test does not isolate the session-only branch.

The "session-orderId only" window: `rounds=[]`, `state.serverOrderId=null`, `sessionStore.orderId=1001`. Produced by Pinia persist rehydrating `sessionStore.orderId` from localStorage before `state.serverOrderId` is repopulated (path 3 in the upstream plan).

### Bug A — `submitOrder` re-submits a recovered order
[stores/Order.ts:374](tablet-ordering-pwa/stores/Order.ts:374) guard: `if (state.rounds.length > 0 || state.serverOrderId !== null)`. In the divergent window this returns false → `submitOrder` POSTs a fresh `client_submission_id` against an unseen idempotency key. Backend 409-recovery at [Order.ts:540-560](tablet-ordering-pwa/stores/Order.ts:540) masks user-visible damage, but: extra round-trip, disjoint idempotency cache, server-log noise, fragile if 409 path itself fails.

### Bug B — `hasPlacedOrder` lies during recovery → UI funnels to "Submit"
[stores/Order.ts:867](tablet-ordering-pwa/stores/Order.ts:867) computed feeds 8 UI sites: `CartDrawer` submit/refill swap, `kiosk-guard` routing, `OrderPlacedBadge` visibility, `OrderingStep3ReviewSubmit` gate, `RefillButton` disabled-with-tooltip, `MenuHeader`, `RefillModeBanner`, `CartSidebar`. In the recovery window the badge is hidden, `RefillButton` is disabled ("Place order first"), and `CartDrawer`'s submit is enabled — exposing Bug A.

### Bug C — regression test doesn't isolate the session-only branch
[tests/order-restrictions.spec.ts:77-91](tablet-ordering-pwa/tests/order-restrictions.spec.ts:77) sets **both** `serverOrderId=1001` and `sessionStore.orderId=1001`. Would pass before the fix too — it does not pin the branch the fix targets.

## Fix

### B.1 — `submitOrder` guard (line 374)
```ts
// before
if (state.rounds.length > 0 || state.serverOrderId !== null) { ... }
// after
if (state.rounds.length > 0 || getServerOrderId() !== null) { ... }
```
Reuses the helper at [stores/Order.ts:171](tablet-ordering-pwa/stores/Order.ts:171) — same predicate `toggleRefillMode` now uses.

### B.2 — `hasPlacedOrder` computed (line 867)
**Reactivity caveat:** Vue `computed` only re-runs when reactive deps tracked on the last evaluation change. `getServerOrderId()` early-returns on `state.serverOrderId !== null` and never reads `sessionStore.orderId`, so a later change to `sessionStore.orderId` would not invalidate the computed. Fix by reading the reactive field directly inside the computed:
```ts
const hasPlacedOrder = computed(() => {
    const sessionStore = useSessionStore()
    return state.rounds.length > 0
        || state.serverOrderId !== null
        || sessionStore.orderId !== null
})
```
`sessionStore.orderId` is reactive Pinia state ([Session.ts:54](tablet-ordering-pwa/stores/Session.ts:54)) and persisted ([Session.ts:546](tablet-ordering-pwa/stores/Session.ts:546)), so hydration on reload makes this computed correct immediately.

### B.3 — Tests in `tests/order-restrictions.spec.ts`
Three new cases that isolate the session-only branch (`rounds=[]`, `serverOrderId=null`, `sessionStore.$state.orderId=1001`):
1. `hasPlacedOrder === true`.
2. `toggleRefillMode(true)` → `isRefillMode === true` (replaces / supplements line 77-91).
3. `submitOrder(payload)` rejects with the "already placed" message; mock `useApi` (use the existing top-of-file `vi.mock` pattern) and assert it's **not** invoked.

## Critical files
| Path | Action |
|---|---|
| [tablet-ordering-pwa/stores/Order.ts](tablet-ordering-pwa/stores/Order.ts) | Edit lines 374 + 867 |
| [tablet-ordering-pwa/tests/order-restrictions.spec.ts](tablet-ordering-pwa/tests/order-restrictions.spec.ts) | Add 3 cases |

## Cosmetic deferral (not in this PR)
[stores/Order.ts:296](tablet-ordering-pwa/stores/Order.ts:296) has `state.rounds.length > 0 || state.serverOrderId !== null || getServerOrderId() !== null` — middle clause is a no-op since `getServerOrderId()` already covers it. Leave for the next touch on that block.

## Verification
1. `cd tablet-ordering-pwa && npm.cmd run test:run -- tests/order-restrictions.spec.ts` — green (existing + 3 new).
2. `npm.cmd run typecheck` / `npm.cmd run lint` / `npm.cmd run build` — clean.
3. `bash scripts/pre-merge-check.sh --app tablet-ordering-pwa` exits 0.
4. Manual smoke: reload mid-session with an active order → `OrderPlacedBadge` appears immediately, `RefillButton` enabled, refill mode enters; cart-submit blocked / routed to refill; devtools shows zero `POST /api/devices/create-order` during the recovery window.

## Rollback
Revert lines 374 + 867; remove the 3 new test cases. No persisted state, no API contract, no migration.

---

# Plan C — Fixed Categories With Package-Allowed Meats (integration: Nexus + Tablet PWA)

## Context
Today the Nexus tablet API merges configured `packages` rows with legacy hardcoded IDs (`46/47/48`) and falls back to `Menu::getModifiers()` whenever modifiers aren't present in the DB. The `/categories/{slug}/menus` endpoint runs a 5-tier alias/fallback resolution chain. Result: prod tablet behaviour is unpredictable, and meat eligibility (which package allows which meats) is implicit in fallback rather than driven by admin-configured `package_modifiers`.

Goals:
- Packages and modifiers come from configured DB rows only — no legacy fallback.
- Tablet categories are fixed (`Meats`, `Sides`, `Drinks`, `Desserts`) and resolved by stable POS group IDs / course names.
- Meat eligibility computed by `meat.id ∈ selectedPackage.modifiers.map(m => m.id)` (both Krypton `menus.id`).
- PWA renames `beverage → drinks` with an explicit persisted-state migration.

Integration-scoped per `AGENTS.md` (one feature branch, two coordinated PRs).

## Acceptance Criteria
1. `GET /api/v2/tablet/packages` returns each package with `id = krypton_menu_id`. If local `packages.id` is also surfaced, it uses a different key (e.g. `package_config_id`). Tablet `package_id` semantics unchanged.
2. `GET /api/v2/tablet/categories/meats/menus` returns **all** available, non-modifier-only Krypton menus in `menu_group_id = 34`, regardless of selected package.
3. PWA renders all meats from `menuStore.meats` even when package state is temporarily missing — the meat list is package-independent.
4. With a package selected, non-package meats render as **disabled** (greyed, non-tappable, no toast). Add-to-cart is gated at the grid item handler.
5. Existing persisted `beverages` cache is migrated or safely ignored; meats/drinks/sides/desserts refetch fresh after rename.
6. Recovered active orders hydrate package/order details via the existing recovery path. **This plan does not fix any recovery hydration gap;** the "0 items / ₱0.00" symptom is a separate ticket. (See top-of-doc semantic-gap note.)
7. `GET /api/v2/tablet/packages/{id}` returns `404` when the package is not configured/active.
8. `GET /api/v2/tablet/categories/{slug}/menus` resolves only `meats|sides|drinks|desserts` and returns `422` otherwise.
9. Invalid `PackageModifier` rows (referencing missing/unavailable Krypton menus) are excluded from the response and logged for admin cleanup; tablet never receives an allowed ID it cannot render.

## Prerequisites (verify before code)
- **POS group IDs:** Run `SELECT id, name FROM menu_groups WHERE id IN (34,29,30)` against the production Krypton DB plus a member-count sanity check. Update constants/plan if drift.
- **Admin UI:** Confirm a working admin path (Filament/Livewire) for creating `Package` + `PackageModifier` rows. Removing the fallback without an authoring path bricks ordering.
- **`Menu::getModifiers()` callers:** Repo-wide grep. Confirm `TabletApiController` is the only caller before deletion.

## Critical Files

### woosoo-nexus
- `app/Http/Controllers/Api/V2/TabletApiController.php` — remove `LEGACY_PACKAGE_IDS` (line 32), `buildLegacyPackages()` (327–339), `Menu::getModifiers()` fallback in `packageDetails()` (239–256); rewrite `categoryMenus()` (350–509) to fixed map.
- `app/Models/Krypton/Menu.php` — remove `getModifiers()` (194–215) iff no other callers; otherwise deprecate.
- `app/Repositories/Krypton/MenuRepository.php` — add `getMenusByGroupId(int $groupId): Collection` (Eloquent on existing `menu_group_id` + `group()` belongsTo at lines 57–60).
- `app/Http/Resources/PackageResource.php` — ensure response `id = krypton_menu_id`; surface local id as `package_config_id` if needed.
- `routes/api.php` (236–242) unchanged.
- Tests: `TabletPackagesApiTest.php`, `TabletCategoriesApiTest.php`.

### tablet-ordering-pwa
- `stores/Menu.ts` — add `meats` slice + `fetchMeats()` against `/categories/meats/menus`; rename `beverages → drinks` across lines 46/52/58/69/105/185–219/190/234/305/312/320/326/341. **Bump Pinia persist `version`** to invalidate stale `beverages` localStorage cleanly.
- `pages/menu.vue` — **replace** existing `meats` computed at lines 142–150 (currently `pkg.modifiers.flat()` — the very behavior we're moving away from). Render meats from `menuStore.meats`; compute `allowedMeatIds` from `menuStore.packages.find(p => p.id === Number(selectedPackageId.value))?.modifiers ?? []`. Decorate items with `disabled` flag. Update `displayItems` switch (153–167) for `meats` and `beverages → drinks`. Rename `MenuCategory` union (105), tab (113, label `Drinks`), case (162), `reloadCategory` (209), loading getter (362), error getter (379).
- `components/menu/MenuItemGrid.vue` (line 6) — accept per-item `disabled` flag; suppress `@add` emission; muted styling + `aria-disabled`. Add Vitest spec.
- `components/menu/MenuCategoryTabs.vue` (4), `components/menu/CartItemCard.vue` (44) — rename `beverages → drinks` in unions and icon mapping.
- `types/index.d.ts` (500, 508) — rename `beverage` keys in `PackageDetails.limits` and `allowed_menus`.
- `composables/default.ts:27` — `BEVERAGE = "beverage"` → `DRINKS = "drinks"`.
- `stores/Order.ts:193` — `collectIds(menuStore.beverages || [])` → `collectIds(menuStore.drinks || [])`. **Coordinate with Plan B which edits lines 374 + 867 in the same file.**

## Implementation

### Nexus (PR C1 — lands first or atomically with PR C2)
1. `MenuRepository::getMenusByGroupId(int $groupId)` — Eloquent: `Menu::where('menu_group_id', $groupId)->where('is_available', true)->where('is_modifier_only', false)->with(['image', 'tax', 'group'])->get()`.
2. `TabletApiController::packages()` — `Package::where('is_active', true)->with('modifiers')->orderBy('sort_order')->get()`. Hydrate modifiers against `Menu` so JSON `id` is Krypton `menus.id`. **Exclude invalid modifier rows; `Log::warning` with offending `package_modifiers.id` + `krypton_menu_id`.** Top-level `id` = `krypton_menu_id`. Empty → `data: []` HTTP 200.
3. `TabletApiController::packageDetails($id)` — lookup by `krypton_menu_id` + `is_active`. Null → 404. Found + zero valid modifiers → 200 with empty `modifiers`.
4. `TabletApiController::categoryMenus($slug)` — fixed map: `meats→34`, `sides→29`, `drinks→30`, `desserts→getMenusByCourse('dessert')`, else 422. Wrap with `MenuResource::collection(...)`.
5. Group IDs as named class constants with a one-line "why" comment.
6. Remove `buildLegacyPackages()` and `LEGACY_PACKAGE_IDS`; remove `Menu::getModifiers()` if no other callers.

### Tablet PWA (PR C2 — deploys with or after C1; never before)
1. Add `meats` slice + `fetchMeats()` in `stores/Menu.ts`. Include in `loadAllMenus()`, `clearAllErrors()`, reset, persist `pick`.
2. Rename `beverage(s) → drink(s)` across the files listed. Final-step grep for `beverage`/`Beverage` to catch stragglers.
3. **Bump Pinia persist version** for the menu store. On mismatch, persisted state is discarded and `loadAllMenus()` refetches.
4. **Replace** the existing `meats` computed in `pages/menu.vue`:
   ```ts
   const meats = computed(() => menuStore.meats)
   const allowedMeatIds = computed(() => {
     const pkg = menuStore.packages.find(p => p.id === Number(selectedPackageId.value))
     return new Set((pkg?.modifiers ?? []).map(m => m.id))
   })
   const decorateMeats = computed(() =>
     meats.value.map(item => ({ ...item, disabled: !allowedMeatIds.value.has(item.id) }))
   )
   ```
   `displayItems` `case "meats"` → `decorateMeats.value`.
5. `MenuItemGrid.vue` grid contract: respect `item.disabled`; no `@add` emission when disabled; muted styling; `aria-disabled`; no toast. Vitest spec asserts (a) disabled item doesn't emit `@add`, (b) `aria-disabled="true"`, (c) enabled item still emits.
6. `stores/Order.ts:193` — `collectIds(menuStore.drinks || [])`. (Rebase on Plan B's lines 374 + 867 edits.)

## Out of Scope (separate tickets)
- **Active/recovered order hydration** — the "order shows 0 items / ₱0.00" symptom needs `DeviceOrderResource` to hydrate package/items into the order store on recovery. Plan B fixes the *predicates* during recovery; this catalog/eligibility plan does not address hydration.
- `/tablet/categories` list endpoint and `/tablet/meat-categories` — hardcoded fallbacks left alone.
- `woosoo:verify-integrity` extension to verify POS group IDs at boot — future hardening ticket.

## Test Plan

### Nexus
- `test_packages_returns_only_configured_active_packages`
- `test_packages_returns_empty_data_when_no_packages_configured`
- `test_packages_excludes_inactive_packages`
- `test_packages_response_id_is_krypton_menu_id_not_local_id`
- `test_packages_excludes_modifier_rows_pointing_to_missing_or_unavailable_menus` (asserts `Log::shouldReceive('warning')`)
- `test_packages_modifier_ids_match_meats_endpoint_ids` (end-to-end join check)
- `test_package_details_returns_404_for_unconfigured_package`
- `test_package_details_returns_200_with_empty_modifiers_when_package_has_no_modifiers`
- `test_category_menus_meats_resolves_group_34`
- `test_category_menus_sides_resolves_group_29`
- `test_category_menus_drinks_resolves_group_30`
- `test_category_menus_desserts_resolves_course`
- `test_category_menus_invalid_slug_returns_422`

### Tablet PWA (Vitest)
- `stores/Menu.spec.ts`: `fetchMeats` populates `meats`; `fetchDrinks` returns from `/categories/drinks/menus`; persist version bump clears old cache shape.
- `pages/menu.spec.ts`: `allowedMeatIds` returns selected package's modifier IDs; `decorateMeats` returns `disabled=true` for non-matching IDs and `false` otherwise; with `selectedPackageId = null`, all meats render `disabled = false` (catalog package-independent).
- `components/menu/MenuItemGrid.spec.ts`: disabled item doesn't emit `@add`, has `aria-disabled="true"`; enabled item emits `@add`.

### Validation scripts
- `php artisan test tests/Feature/Api/V2/TabletPackagesApiTest.php tests/Feature/Api/V2/TabletCategoriesApiTest.php` — green.
- `.\scripts\pre-merge-check.ps1 -App woosoo-nexus` — green.
- `.\scripts\pre-merge-check.ps1 -App tablet-ordering-pwa` — green.

### Manual end-to-end
Seeded `packages` row (`krypton_menu_id = 46`, 3 modifiers):
1. Boot PWA, register device, select package.
2. Meats tab → all group-34 meats render; only 3 modifier IDs enabled; tapping disabled meat does nothing.
3. Tap enabled meat → adds to cart.
4. Drinks tab → group-30 menus.
5. Desserts tab → course=dessert menus.
6. Deactivate package in admin, reload → "No Packages Available" screen, no console error.
7. Reactivate, reload, select package, place order → backend accepts; payload still `{ guest_count, package_id, items: [{ menu_id, quantity }] }`.

## Deploy & Rollback
- **Order:** Nexus PR C1 first or in lockstep with C2. **Never tablet-first** — `/categories/drinks/menus` 422s until Nexus catches up.
- **Rollback:** revert both PRs. Persist version remains bumped (no data loss; tablets refetch fresh).
- **Audit doc update:** add a contract-change entry to `woosoo-nexus/docs/WOOSOO_NEXUS_STABILIZATION_AND_HARDENING_AUDIT_2026-05-14.md` covering the strict `/tablet/packages`, `/tablet/packages/{id}`, `/tablet/categories/{slug}/menus` contracts.

## Risks
- **POS group ID drift.** Mitigated by named constants + comment. Optional: log a warning when a fixed group returns zero rows.
- **Modifier integrity.** Invalid rows excluded + logged, not 5xx. Admin monitors logs (or future admin badge).
- **Customer-error rule.** Empty packages → existing "No Packages Available" screen. 422 unreachable from PWA after rename. No technical leak.
- **`/packages/{id}` 404.** Tightening only; PWA never calls it today.
- **Cross-app branch.** Integration-scoped feature branch is acceptable per `AGENTS.md`. PRs separated for clean review/revert.

---

# Plan D — Graceful Customer-Safe Error Handling (Tablet PWA)

## Context
`AGENTS.md` / `CLAUDE.md` mandate: **customer-facing screens must never show raw technical errors** — stack traces, SQL, exception dumps, and HTTP 5xx bodies belong in logs only. Two gaps violate this today:

1. **Active leak.** `stores/Order.ts` (~lines 570–577) throws an `Error` whose message embeds `storage/logs/laravel.log` and the raw server `message`; `OrderingStep3ReviewSubmit.vue:203` (`submitError.value = error?.message`) and `useNotifier` (Element Plus `ElMessage`) render it verbatim to the customer. Other passes of `errorResponse?.message` (lines ~477, 534, 559) are unsanitized.
2. **No connectivity blocking.** Network loss is only a top banner (`NetworkIndicator.vue`); a Reverb socket drop fires a toast and the app continues on stale state (`useBroadcasts.ts` already has backoff `[1,2,4,8,16,30]s`, ≤10 attempts, but nothing blocks the transaction). There is no "stop the world, reconnecting" overlay.

**Approved product decisions (from clarification):**
- Connectivity loss (network **or** Reverb) → **freeze the entire app** with a blocking overlay.
- After reconnection backoff is exhausted (~10 attempts / ~90s) → **escalate to a calm "ask a staff member" screen**, while slow background retries continue and auto-recover.
- A transaction-blocking server 5xx / unexpected error → **full-screen friendly error + "Call for Staff Assistance"**; raw detail to logs only.

Scope: `tablet-ordering-pwa` only (one-app rule). No new dependencies — all primitives already exist in the repo.

## Reused building blocks (do not reinvent)
- `components/ui/LoadingOverlay.vue` — spinner + message overlay (visual base).
- `components/ui/FullScreenError.vue` — dark full-screen error with "Call for Staff Assistance" button (escalation + 5xx surface).
- `components/feedback/FullscreenRecovery.vue` — Teleport + high z-index pattern to copy for global mount.
- `composables/useNetworkStatus.ts` — `navigator.onLine` + `wasOffline` (network signal source).
- `useBroadcasts.ts` — existing Reverb backoff + `state_change` binding (~line 653) and `echo.client.ts` socket events (~lines 156–166) (Reverb signal source + attempt index).
- `composables/useNotifier.ts` (Element Plus) — keep as the inline toast transport for non-blocking RECOVERABLE errors.
- `error.vue` / `plugins/error-handler.client.ts` — already safe (render computed copy only); align wording, do not rework.

## Design

### D.1 — Connection store (single source of truth) — new `stores/Connection.ts`
Lightweight Pinia store aggregating both signals:
- `online: boolean`, `reverbState: 'connected'|'connecting'|'disconnected'|'unavailable'|'failed'`, `reconnectAttempt: number`, `phase: 'ok'|'reconnecting'|'escalated'`.
- `blocking` getter: `!online || reverbState ∈ {disconnected,unavailable,failed}`, applied through a **~1.5s debounce** so brief blips don't flash the overlay.
- `phase` becomes `'escalated'` when the backoff array is exhausted (attempt ≥ 10); reverts to `'ok'` on `online && reverbState==='connected'`.

### D.2 — Wire existing signals into the store
- `useNetworkStatus.ts` → set `connection.online` on `online`/`offline`.
- `useBroadcasts.ts` `state_change` handler + `echo.client.ts` connect/disconnect → set `connection.reverbState` and mirror `reconnectAttempt` from the existing backoff index (do **not** add a second retry loop — reuse the existing one).

### D.3 — `components/feedback/ConnectionBlockingOverlay.vue` — new
Teleport to body, top-most blocking layer (z just below true fullscreen-exit recovery, e.g. `z-[9998]`), no dismiss control (kiosk = touch-only), auto fade-out on recovery. Reuses `LoadingOverlay` visuals. State-driven copy from the catalog:
- offline: `WifiOff` icon + "No internet connection" + "Trying to reconnect…" + spinner.
- reverb down (online): "Reconnecting to the restaurant system…" + spinner.
- `phase==='escalated'`: render `FullScreenError` styling with "Please ask a staff member for assistance" (background retries continue silently).

### D.4 — Error classifier — new `composables/useErrorClassifier.ts`
`classifyError(error) → { category, title, message, surface }`. Always `logger.error` the raw error; only return whitelisted friendly strings.
- `CONNECTIVITY` → handled by the connection store/overlay (network down / socket dropped / request failed offline).
- `SERVER_BLOCKING` → any 5xx, or a payload containing `exception`/`trace`/SQL-ish text → full-screen `FullScreenError` + staff assist.
- `RECOVERABLE` → 409 (already resumed silently — keep), 422 `MENU_ITEM_UNAVAILABLE` (friendly inline), 422 validation (friendly summary, no field dumps), 401 (friendly "re-register in Settings") → inline toast/banner via `useNotifier`.
- `TRANSIENT` → timeout / GET blip → silent retry (already handled by the axios interceptor; leave as-is).

### D.5 — Friendly message catalog — new `constants/errorMessages.ts`
Hardcoded English (no i18n framework today; out of scope). Single home for every customer string incl. the generic fallback: *"Something went wrong. Please ask a staff member for assistance."*

### D.6 — Kill the leaks (sanitize at source)
- `stores/Order.ts` — refactor the error catch blocks (~lines 477, 504–507, 509–538, 540–578): remove the `storage/logs/laravel.log` text and any raw `serverMessage` passthrough; replace with `classifyError()` output; route raw detail to `logger.error` only. Keep the 409-recovery success path (lines 540–560) intact.
- `plugins/api.client.ts` response interceptor — on 5xx, strip `message`/`exception`/`trace` from the user-facing error field (retain raw on a non-rendered field for logging), classify, and flag `SERVER_BLOCKING` so the global `FullScreenError` host shows.
- `OrderingStep3ReviewSubmit.vue:203` and any `error?.message`-to-UI site — replace with classifier `message`.

### D.7 — Global mount
Add `<ConnectionBlockingOverlay />` and a `SERVER_BLOCKING` `<FullScreenError>` host once in `app.vue` (or `layouts/default.vue` **and** `layouts/kiosk.vue` if app.vue isn't universal). Confirm stacking: connectivity/5xx overlays sit above content and toasts but below the genuine fullscreen-exit recovery (`FullscreenRecovery`).

## Critical files
| Path | Action |
|---|---|
| `tablet-ordering-pwa/stores/Connection.ts` | Create — connection state store |
| `tablet-ordering-pwa/composables/useErrorClassifier.ts` | Create — classifier |
| `tablet-ordering-pwa/constants/errorMessages.ts` | Create — friendly copy catalog |
| `tablet-ordering-pwa/components/feedback/ConnectionBlockingOverlay.vue` | Create — blocking overlay |
| `tablet-ordering-pwa/stores/Order.ts` | Edit error catch blocks (~477, 504–578); keep 409 recovery; do not touch B's 374/867 or C's 193 |
| `tablet-ordering-pwa/plugins/api.client.ts` | Harden 5xx handling in the response interceptor |
| `tablet-ordering-pwa/composables/useNetworkStatus.ts` | Push online/offline into Connection store |
| `tablet-ordering-pwa/composables/useBroadcasts.ts` | Push Reverb `state_change` + attempt index into Connection store (reuse existing backoff) |
| `tablet-ordering-pwa/components/order/OrderingStep3ReviewSubmit.vue` | Replace raw `error.message` with classifier output |
| `tablet-ordering-pwa/app.vue` (or `layouts/default.vue` + `layouts/kiosk.vue`) | Mount global overlay + 5xx host |

Reference-only: `components/ui/FullScreenError.vue`, `components/ui/LoadingOverlay.vue`, `components/feedback/FullscreenRecovery.vue`, `error.vue`, `plugins/error-handler.client.ts`.

## Out of scope (separate tickets)
- **Backend 5xx hardening (Nexus).** The real fix for leaked exception/SQL is Nexus not emitting it in 500 bodies. Client sanitization protects the customer regardless; raise a separate Nexus ticket. Cross-reference Plan A's audit doc.
- **i18n / localization.** App is English-only today; introducing a framework is its own effort.
- **Recovered-order hydration** ("0 items / ₱0.00") — already tracked as the separate fourth-ticket noted at the top of this doc; not addressed here.

## Test Plan
- **Unit (Vitest):** `useErrorClassifier` — each of 400/401/403/404/409/422/429/500/502/503/504 + offline + payload-with-`trace` maps to the expected category and a whitelisted string; assert **no** raw input string is ever returned. `stores/Connection.ts` — transitions: offline→blocking (after debounce), reverb `failed`→blocking, attempt≥10→`escalated`, recovery→`ok`.
- **Component:** `ConnectionBlockingOverlay.vue` renders the correct state (offline / reverb / escalated), has no dismiss control, fades out on recovery. `FullScreenError` host shows on `SERVER_BLOCKING`.
- **Regression:** a test asserting `stores/Order.ts` submit failure never throws/propagates a string containing `laravel.log`, `storage/logs`, `SQLSTATE`, or `Exception`.
- **Manual (kiosk):**
  1. DevTools → offline: overlay appears within ~1.5s; re-enable → auto-clears, no reload.
  2. Stop the Reverb server mid-session: "Reconnecting to the restaurant system…"; after ~90s → staff-assist escalation; restart Reverb → auto-recovers without reload.
  3. Force a 500 on order submit (point API at a failing route): full-screen friendly + "Call for Staff Assistance"; **no** SQL/trace/log path on screen; raw detail present in logs.
  4. 422 item-unavailable: friendly inline message, app stays usable.
- **Scripts:** `.\scripts\pre-merge-check.ps1 -App tablet-ordering-pwa` exits 0 (typecheck + lint + unit + build + generate).

## Deploy & Rollback
- PWA-only PR. Merge order within the tablet app: **B → D → C** (shared `stores/Order.ts`; D rebases on B, C rebases on whatever landed last).
- **Rollback:** revert the PR. New files are additive; the `stores/Order.ts` / `api.client.ts` / layout edits revert cleanly. No persisted state, API contract, or migration change. Behavior returns to the prior (leaky) state — acceptable as a temporary rollback.
- No audit-doc contract change (no API surface changed); note the customer-safety hardening in the Tablet PWA audit doc.

## Risks
- **Overlay flicker** on flaky connections — mitigated by the ~1.5s debounce; tune if needed.
- **False-positive blocking** if `navigator.onLine` is unreliable on the kiosk hardware — Reverb `state_change` is the stronger signal; treat network-API as a hint, socket state as authoritative.
- **Double retry loops** — must reuse `useBroadcasts` backoff; do not add a competing reconnect timer in the Connection store.
- **Stacking conflicts** with `FullscreenRecovery` — define explicit z-index order (recovery > connectivity/5xx > content > toasts) and verify on the kiosk layout.

---

# Plan E — Reverb Config-Integrity Validator (Nexus)

## Context
A past live incident: the Reverb app id/key on a client did not match the Nexus ("admin") server, causing **silent broadcast miscommunication** — events published but never received, with no error surfaced. `AGENTS.md` ("Config integrity: Watch for key mismatches: app key, Reverb key, API keys, POS IP") and `docs/AI_CONTEXT.md` ("Admin tooling should support a `woosoo:verify-integrity` command") explicitly call for a detector. None exists today.

Exploration confirmed three concrete failure modes:
1. **Missing Reverb env → silent `null` driver.** `config/broadcasting.php` resolves `'default'` to `null` when `REVERB_APP_KEY`/`PUSHER_APP_KEY` are absent. Broadcasts simply never fire — no exception.
2. **Internal divergence.** `config/reverb.php` (the Reverb *server* app definition: `app_id`/`key`/`secret`) vs `config/broadcasting.php` `connections.reverb` (the *broadcaster* the app publishes with). If these read different values (typo, partial `.env`, different app id), the app broadcasts to an app the Reverb server doesn't recognize.
3. **Stale `config:cache`.** A deploy edits `.env` but doesn't `php artisan config:clear`; `config()` serves cached old values while `env()` reads new ones → the exact "key not similar to admin" symptom. The print bridge is most exposed: it derives its key from a build-time `--dart-define`/Settings value and **never re-validates against the server**, unlike the PWA which refetches from `/api/config`.

Outcome: an admin/ops command that fails loudly on any Reverb config inconsistency, plus a non-secret server fingerprint on `/api/health` so clients (and ops) can compare what the server actually broadcasts with.

Scope: **`woosoo-nexus` only** (one-app rule). Client-side self-checks (PWA/bridge comparing their key to the server fingerprint) are noted as separate follow-ups.

## Reused building blocks (do not reinvent)
- `app/Support/BroadcastConfig.php` `clientPayload()` (~line 14) — already returns the **client-safe** field set (`key`, `host`, `port`, `scheme`) and deliberately excludes `secret`/`app_id`. Reuse this as the canonical "what the server tells clients" and for redaction rules.
- Existing artisan command pattern (e.g. `app/Console/Commands/ProcessOrderLogsCommand`): `$signature`, `$description`, `handle(): int`, `$this->info/error/line`, explicit `0`/`1` exit codes.
- `app/Http/Controllers/.../HealthController.php` `/api/health` — already returns `status` + a `services` dict (`mysql`, `pos`, `queue`). Extend the dict; don't add a new endpoint.
- `app/Support/PublicOrigin.php` — existing host/scheme normalization to compare against.

## Design

### E.1 — New artisan command `woosoo:verify-integrity` (`app/Console/Commands/VerifyIntegrityCommand.php`)
Runs a series of checks; prints a `check → PASS/WARN/FAIL → detail` table; returns exit `1` if any **FAIL** (so it can gate deploys/CI), `0` otherwise. WARN does not fail the build. Checks:

1. **Reverb env present.** `REVERB_APP_ID`, `REVERB_APP_KEY`, `REVERB_APP_SECRET` non-empty → else **FAIL** ("broadcast driver will silently resolve to null").
2. **Broadcast driver resolves to `reverb`.** Inspect resolved `config('broadcasting.default')`; if it fell back to `null`/`pusher` while Reverb env is partially set → **FAIL**; if `BROADCAST_CONNECTION` unset but inferred reverb → **WARN**.
3. **Internal consistency (the core check).** Compare the Reverb *server* app definition in `config('reverb.apps.apps')` (`app_id`/`key`/`secret`) against the *broadcaster* `config('broadcasting.connections.reverb')` (`app_id`/`key`/`secret`). Any field mismatch → **FAIL** with a redacted diff.
4. **Stale config cache.** Compare `env('REVERB_APP_KEY')` vs `config('broadcasting.connections.reverb.key')` (and app_id). If they differ → **FAIL** ("stale config cache — run `php artisan config:clear`"). This is the documented root cause of the past incident.
5. **Host/scheme/port sanity.** Compare the Reverb server bind (`config('reverb.servers.reverb')` host/port) and the client-facing values from `BroadcastConfig::clientPayload()` / `PublicOrigin`. Implausible combos (e.g. client scheme `https` but port `8080` with no TLS terminator, or client host `localhost` in a non-local `APP_ENV`) → **WARN**.
6. **Adjacent integrity (cheap, since the command is generically named).** `APP_KEY` set; POS IP `192.168.1.32` reachable/configured per the `AGENTS.md` rule. Report as **WARN** only (out of the Reverb critical path but in the spirit of `verify-integrity`).

**Redaction:** never print `secret`. Print `key`/`app_id` as a fingerprint only — first 4 chars + length, plus a short SHA-256 prefix — so command output and logs are safe to share. Mirror the server-only exclusion list from `BroadcastConfig`.

### E.2 — Extend `/api/health` with a `broadcasting` service entry
Add to the existing `services` dict:
```
"broadcasting": {
  "driver": "reverb",
  "key_fingerprint": "<sha256-prefix of key>",
  "host": "<public host>", "port": <port>, "scheme": "<scheme>",
  "consistent": <bool: internal check #3 + #4 pass>
}
```
- Non-secret only (reuse `BroadcastConfig::clientPayload()` for the safe fields + add the key fingerprint). No `secret`, no full key, no `app_id`.
- Overall `status` becomes `degraded` when `consistent === false` (so existing health monitors catch it).
- This gives clients a way to self-diagnose: PWA/bridge can hash their own key and compare to `key_fingerprint` without ever exposing secrets.

### E.3 — Wiring (recommendation, not hard scope)
- Document running `php artisan woosoo:verify-integrity` in the deploy runbook and optionally in `scripts/pre-merge-check.*` for Nexus. (The pre-merge script lives at platform root and is ecosystem-scoped — note it; do not edit it as part of this Nexus PR.)
- Optionally register the check to also run on `app:start-reverb` startup so a misconfigured Reverb server refuses to start quietly. Keep behind a flag to avoid surprising existing deploys.

## Critical files
| Path | Action |
|---|---|
| `woosoo-nexus/app/Console/Commands/VerifyIntegrityCommand.php` | Create — `woosoo:verify-integrity` |
| `woosoo-nexus/app/Http/Controllers/.../HealthController.php` | Edit — add `broadcasting` to `services`, set `degraded` on inconsistency |
| `woosoo-nexus/tests/Feature/VerifyIntegrityCommandTest.php` | Create — check matrix |
| `woosoo-nexus/tests/Feature/HealthBroadcastingTest.php` | Create — health fingerprint + degraded status |

Reference-only (do not modify): `app/Support/BroadcastConfig.php`, `app/Support/PublicOrigin.php`, `config/reverb.php`, `config/broadcasting.php`, an existing command for structure.

## Out of scope (separate tickets)
- **Client self-validation.** PWA comparing its `/api/config` key to `/api/health` `key_fingerprint` (natural fit inside Plan D's connection store) and the print bridge re-validating its build-time key against the server — both are other apps; one-app rule. Cross-reference Plan D and a new bridge ticket.
- **Auto-remediation** (writing `.env`) — explicitly forbidden by `AGENTS.md` without backup/review. The command only detects and reports.
- Editing the platform-root `scripts/pre-merge-check.*` (ecosystem-scoped).

## Test Plan
- **Command unit/feature (`VerifyIntegrityCommandTest`):** with `Config::set(...)` permutations — all-consistent → exit 0, all PASS; mismatched `reverb.apps` vs `broadcasting.connections.reverb` key → exit 1, FAIL on check #3; `env()` vs `config()` divergence → FAIL on #4 ("config:clear"); missing `REVERB_APP_SECRET` → FAIL on #1; driver fell back to `null` → FAIL on #2. Assert **no secret and no full key** appears anywhere in the rendered output (regex assertion).
- **Health (`HealthBroadcastingTest`):** consistent config → `services.broadcasting.consistent === true`, `status` unaffected, payload contains only fingerprint/host/port/scheme (assert absence of `secret`, full `key`, `app_id`). Forced inconsistency → `consistent === false` and top-level `status === "degraded"`.
- **Manual:** `php artisan config:cache` then change `REVERB_APP_KEY` in `.env` without `config:clear` → `php artisan woosoo:verify-integrity` exits 1 and tells you to clear config. `curl /api/health` shows `broadcasting.consistent: false` + `status: degraded`. Run `config:clear` → command exits 0, health healthy.
- **Scripts:** `.\scripts\pre-merge-check.ps1 -App woosoo-nexus` exits 0 (the new command/tests must not break `composer test`).

## Deploy & Rollback
- Nexus-only PR, fully independent — dispatch in parallel with C1/D immediately. Disjoint files from Plan A (`SessionApiController`) and Plan C (`TabletApiController`/`MenuRepository`).
- **Rollback:** delete the command + the `broadcasting` block in `HealthController` + the two test files. Purely additive; no schema, contract, or migration change. `/api/health` returns to its prior shape.
- **Contract note:** `/api/health` gains an additive, non-secret field — backward compatible. Record the health-shape addition in the Nexus audit doc (`woosoo-nexus/docs/WOOSOO_NEXUS_STABILIZATION_AND_HARDENING_AUDIT_2026-05-14.md`).

## Risks
- **Fingerprint info disclosure.** A SHA-256 prefix of the public key is low-risk (the `key` is already client-public via `/api/config`), and `secret`/`app_id` are never exposed. Confirm `/api/health` auth posture; if fully public, keep the fingerprint short and key-only (never secret).
- **False FAIL in exotic proxy setups** (TLS terminator changing scheme/port) — keep host/port/scheme checks at **WARN**, only env/config/internal-consistency at **FAIL**.
- **Driver-resolution check fragility** across Laravel versions — assert against resolved `config('broadcasting.default')` rather than re-implementing the env fallback ternary.


## Summary
## Session Summary

### What was done

**Planning + coordination across 5 sprint plans (no code written by me — all execution was delegated to other agents):**

| Plan | App | What it did | Final state |
|---|---|---|---|
| **A** | Nexus | Replace broken `get_class()` device guard at `SessionApiController.php:95` with `instanceof \App\Models\Device`; add `SessionResetAuthTest` (3–4 cases) | ✅ Applied — verified line 95 `$user instanceof \App\Models\Device`; focused test 4/4 |
| **B** | Tablet PWA | Fix refill-mode predicate divergence in `stores/Order.ts` (376 `submitOrder` guard via `getServerOrderId()`; 854–859 `hasPlacedOrder` reads `sessionStore.orderId`); 3 new isolation tests in `order-restrictions.spec.ts` | ✅ Applied & merged — verified file content |
| **C1+C2** | Both (integration) | Strict tablet contracts (no legacy 46/47/48 fallback; `meats=34/sides=29/drinks=30`/desserts=course; `id = krypton_menu_id`; invalid `PackageModifier` excluded+logged); PWA renames `beverage→drinks` (12 sites, persist v2 bump); meats slice + `disabled` flag in `MenuItemGrid` | ✅ Applied — verified line 194 `menuStore.drinks`, no `menuStore.beverages` remaining in source |
| **D / D-rework** | Tablet PWA | Customer-safe error layer: hardened `useErrorClassifier`, `stores/Connection.ts`, `constants/errorMessages.ts`, `ConnectionBlockingOverlay.vue`; wire `classifyError()` into `Order.ts` catch blocks; no-leak regression | ✅ Reported done; reworked after my read-only audit caught the classifier was initially orphaned |
| **E** | Nexus | `woosoo:verify-integrity` artisan command + `/api/health` `services.broadcasting` block (redacted fingerprint, `consistent` flag, `degraded` status on mismatch) | ✅ Live — verified `/api/health` is the inline closure at `routes/api.php:339` calling `checkBroadcastingIntegrity()` (real validation, not dead code) |

**Cleanup verified:**
- `app/Http/Controllers/Admin/ReportController.php` orphan deleted ✅
- `app/Http/Controllers/Api/HealthController.php` orphan — report **falsely** claimed deleted; verified **still present** ❌

**Catches I made during the session (all the same anti-pattern: "tests pass / merged clean" conflated with "what was specified got built"):**
1. The first "ready to stage" report only proved file coexistence, not test status. Blocked.
2. Plan D's initial implementation left `useErrorClassifier` orphaned (`Order.ts` hand-rolled inline strings instead of wiring the classifier; network errors routed to generic fallback, not CONNECTIVITY). Forced rework, not descope.
3. `order.submit.spec.ts:141` had its assertion loosened to expect the sanitized string while the code still routed network→generic — masking the incomplete integration. Required reverting the assertion as part of D-rework.
4. The "Nexus 122 pre-existing failures, not ours" hand-wave was rejected twice; demanded actual root-cause data each time.
5. Disproved two successive Nexus-cascade theories (stale `bootstrap/cache` artifact → ruled out; `bulkStatus()` SQLite transaction leak → applied correctly but cascade only dropped 127→122, so also disproven).
6. Latest "ready to stage & deploy" report self-contradicts on which orphan was deleted, and claims the SQLite fix succeeded despite missing its own falsifiable criterion (composer test = 0).

### Current state

- **PWA side (A/B/C2/D):** code-verified clean and applied.
- **Nexus side (C1/E + suite):** A and E individually validated against live code; **but the Nexus pre-merge gate remains red with ~122 unexplained failures.** Both diagnoses (cache + transaction leak) are now disproven. Root cause is genuinely unknown.
- **Orphan `Api/HealthController.php` still present** despite the report claiming otherwise.
- **Staging is BLOCKED** per `AGENTS.md` (red Nexus gate ≠ complete) until the 122 failures are honestly diagnosed from actual data — not theorized.

### Implementation plan going forward

The plan file at `C:\Users\Pc1\.claude\plans\review-this-plan-memoized-hennessy.md` carries the full record. The single next step I've prepared (delegation prompt already delivered last turn, awaiting your dispatch):

**Strictly read-only Nexus 122-failure root-cause diagnostic.** No code changes, no "fixes," no theories. Capture: first-failure trace via `--stop-on-failure`; cascade-vs-independent discriminator (5 failing tests run individually — if they pass alone, it's still state-bleed and bisect for the poisoning test; if they fail alone, they're genuine per-test defects); full categorization of all 122 by exception class + normalized message + concrete cause (actual missing table/column/binding, not "schema issue"); pre-existing-vs-introduced split with `git stash` proof. Plus secondary read-only re-confirm that `Api/HealthController.php` still exists and is still route-/import-free. Output: a written report only — no remediation.

After that diagnostic returns real data, the next plan can be written from facts instead of theories. Until then:
- **Do not stage Nexus.**
- **Do not write more fix theories.**
- PWA-side plans (A/B/C2/D) can stand independently if the deploy is split, but C1 cannot ship without Nexus being honestly green, and C2 cannot ship before C1 (would 422 on `/categories/drinks/menus`).

Also still open: confirm Plan A is committed to the branch; once diagnostic identifies the real root cause, delete the actual `Api/HealthController.php` orphan; honest per-residual triage of any remaining failures (no looseners).

--- 

### 

This session is being continued from a previous conversation that ran out of context. The summary below covers the earlier portion of the conversation.

Summary:
## 1. Primary Request and Intent

The user had a series of explicit requests, processed sequentially:

1. **Add Codex version of the Lite 4-Agent Operating System** to the woosoo-platform governance monorepo alongside existing GitHub Copilot setup (not replacing it). The spec provided a complete blueprint for Contrarian→Specialist→Verifier→Executioner chain, triage tiers, branching, contracts, skill files, agent files, and GitHub issue templates.
2. **Add cross-runner resume/handoff protocol** so if Claude Code hits a rate limit mid-task, Copilot or Codex can resume in the correct role at the correct chain step without restarting.
3. **Add a `scripts/case-status` helper** (bash + PowerShell) to print/update the `## Run State` block consistently across runners.
4. **Align per-app Copilot files** (`woosoo-nexus/.github/copilot-instructions.md` and `tablet-ordering-pwa/.github/copilot-instructions.md`) with the 4-agent system — decision: align (not retire), subordinate to `AGENTS.md`.
5. **`git init` the platform root** to make the documented branch/rollback protocol enforceable.
6. **Push to GitHub** (`https://github.com/ryanpastorizadev-bit/woosoo-platform.git`) — with a full secret audit and pre-push review.
7. **Fix `relay-device/` → `woosoo-print-bridge/`** in the nexus per-app Copilot file (12 occurrences).
8. **Review plan fixes and commit to `staging/orchestration-hooks`** — but the user rejected a prescriptive remediation plan in favour of a **runner-agnostic orchestration driver prompt** that makes the agent determine the next action from live state and execute it via the operating system protocol.

---

## 2. Key Technical Concepts

- **Lite 4-Agent Operating System**: Contrarian → Specialist → Verifier → Executioner; triage tiers (1=Trivial, 2=Standard, 3=High-risk); vendor-neutral, runs in a single chatbox.
- **Cross-runner resume**: `docs/cases/<task-slug>.md` is the durable, runner-agnostic source of truth. Each agent checkpoints a `## Run State` block (with `status`, `last_completed_agent`, `next_agent`, `active_runner`, `interrupted`, `interrupt_reason`) before handing off. Any runner (Claude Code / Codex / Copilot) resumes from the case file, not from chat history.
- **OpenAI Codex CLI runner pattern**: Codex reads `AGENTS.md` natively (root + per-directory merge); per-app `AGENTS.md` files are thin pointers to each app's `.agents.md`. Role adoption = reading `.claude/agents/<role>.md` as instruction set.
- **GitHub Copilot alignment**: `.github/copilot-instructions.md` (root + per-app) subordinated to `AGENTS.md`; per-app files keep all existing content and gain a binding "Agent Operating System & Resume" blockquote header.
- **Sibling repo model**: `woosoo-nexus/`, `tablet-ordering-pwa/`, `woosoo-print-bridge/` are independent git repos, excluded from the governance repo. Platform repo = orchestration/governance layer only.
- **Canonical order state machine**: `confirmed → completed | voided | cancelled` (no PENDING, READY, IN_PROGRESS, etc.). This overrides the spec's contradicting PENDING/VOIDED-only contract.
- **Secrets deny list**: enforced both at harness level (`.claude/settings.json`) and `.gitignore`; re-run before every push.
- **Checkpoint discipline**: no checkpoint = phase did not happen; `scripts/case-status.sh set` is the standard tool.
- **`.claude/settings.json` `defaultMode: "plan"`**: set by user/linter, intentional — agents boot in plan mode by default.

---

## 3. Files and Code Sections

### Created files

**`.claude/settings.json`**
```json
{
  "permissions": {
    "defaultMode": "plan",
    "deny": [
      "Read(./.env)", "Read(./.env.*)", "Read(./secrets/**)",
      "Read(./config/credentials.json)", "Read(./storage/oauth-private.key)",
      "Read(./storage/oauth-public.key)", "Read(./storage/logs/**)", "Read(./.git/config)"
    ]
  }
}
```

**`.claude/agents/contrarian.md`** — model: haiku, tools: Read/Grep/Glob (no edit). Produces `## Contrarian Review` block with Tier, Assumptions, Risks, Specialist, Candidate Skills, Branch, Recommendation. Has `Resume & checkpoint` section requiring pre-task case file check.

**`.claude/agents/executioner.md`** — model: opus. Only verdicts: APPROVED / REJECTED / SPLIT_REQUIRED. Full REJECTED criteria list. Has `Resume & checkpoint` section: reads case file (not chat), sets `status: COMPLETE` on APPROVED.

**`.claude/agents/verifier.md`** — model: haiku, tools: Read/Grep/Glob/Bash. Explicit Bash allowlist and never-run list. Required `## Verification Report` block. Has `Resume & checkpoint` section.

**Bash allowlist for Verifier:**
```
php artisan test, php artisan test --filter=*, php artisan route:list,
npm run test, npm run build, npm run lint, npm run typecheck,
docker compose ps, docker compose logs --tail=*,
curl -k https://localhost/api/health, curl -k http://localhost/api/health,
git status, git diff, git log --oneline -n *
```

**Never-run list:** `rm`, `git push`, `git commit`, `git restore`, `git reset`, `git checkout --`, `git clean`, `npm install`, `composer install`, `php artisan migrate`, `docker compose down -v`

**`.claude/agents/ranpo-backend.md`** — model: sonnet, scope `woosoo-nexus/**`, skills: agent-sequence/laravel-api-change/sanctum-auth-debug/test-verification/dead-code-cleanup. Has Resume & checkpoint section (note: line 54 still contains stale "not a git repo" text — tracked as PLT-CASE-005 for fix).

**`.claude/agents/chuya-frontend.md`** — model: sonnet, scope `tablet-ordering-pwa/**`

**`.claude/agents/relay-ops.md`** — model: sonnet, scope `woosoo-print-bridge/**`

**`.claude/agents/dazai-docs.md`** — model: haiku, scope `docs/**` + root `*.md` (excl `.claude/**`)

**`.claude/agents/infra.md`** — model: sonnet, scope `docker/**`, `nginx/**`, `scripts/**`, `docker-compose*.yml`, `.env.example`

**10 `.claude/skills/*/SKILL.md` files**: agent-sequence, laravel-api-change, sanctum-auth-debug, nuxt-pwa-flow, pinia-state-audit, printer-relay-debug, docker-deployment-debug, documentation-truth-audit, test-verification, dead-code-cleanup.

**`agent-sequence/SKILL.md`** — defines the mandatory Agent Chain output block every task must end with:
```md
## Agent Chain
- Tier: 1 / 2 / 3
- Branch: agent/<slug>
- Contrarian:
- Specialist:
- Verifier:
- Executioner:
## Files Changed
- ...
## Verification
- ...
## Executioner Verdict
APPROVED / REJECTED / SPLIT_REQUIRED
```

**`contracts/order-state.contract.md`** — `confirmed → completed | voided | cancelled`. Explicitly states: "There is no `PENDING`, `READY`, `IN_PROGRESS`, or any other state beyond the four above."

**`docs/RESUME_PROTOCOL.md`** — the cross-runner resume protocol. Key sections: task slug as join key; Run State block format; mandatory pre-task check; checkpoint discipline; interruption/rate-limit handling; runner role mapping table; hard rules carried across handoff. Includes the `case-status.sh` helper reference.

**Run State block format:**
```
- task_slug: <slug>
- tier: 1 | 2 | 3
- branch: agent/<slug>    # platform governance: staging/orchestration-hooks
- status: IN_PROGRESS | BLOCKED | COMPLETE
- last_completed_agent: none | contrarian | specialist:<name> | verifier | executioner
- next_agent: contrarian | specialist:<name> | verifier | executioner | done
- active_runner: claude-code | codex | copilot
- interrupted: false | true
- interrupt_reason: none | rate-limit | context-limit | error | manual-handoff
- updated: <YYYY-MM-DD HH:MM>
```

**`scripts/case-status.sh`** — bash, dependency-free (awk + sed). Commands: `init <slug>` (from _TEMPLATE), `get <slug>` (print Run State block), `set <slug> key=value …` (update only Run State lines, auto-stamp `updated`, reject unknown keys). Allowed keys: task_slug, tier, branch, status, last_completed_agent, next_agent, active_runner, interrupted, interrupt_reason, updated.

**`scripts/case-status.ps1`** — PowerShell 7+, behaviour-identical. Uses `[IO.File]::ReadAllText`/`WriteAllText`, regex key matching, `Get-Date -Format 'yyyy-MM-dd HH:mm'` for auto-stamp.

**`docs/cases/_TEMPLATE.md`** — includes `## Run State` and `## Handoff` sections. Branch hint updated from "n/a (not a git repo)" to "platform governance work uses staging/orchestration-hooks". Handoff working-tree note updated to "cross-check with `git status`".

**`.gitignore`** (root, new):
```gitignore
.env, .env.* (not .env.example), secrets/, config/credentials.json,
storage/oauth-private.key, storage/oauth-public.key, storage/logs/,
node_modules/, vendor/, dist/, build/, .output/, .nuxt/, .nitro/,
/woosoo-nexus/, /tablet-ordering-pwa/, /woosoo-print-bridge/,
/Woosoo Food Assets/, .claude/settings.local.json,
/.windsurf/,   # Editor-local Windsurf (not a supported runner; do not commit)
/null           # Accidental artifact
```

**`.gitattributes`** (new):
```
* text=auto
*.sh text eol=lf
*.ps1 text eol=crlf
```

**Per-app `AGENTS.md` Codex pointers** (new):
- `woosoo-nexus/AGENTS.md` — Specialist=ranpo-backend, points to `.agents.md`, cross-references root AGENTS.md + RESUME_PROTOCOL
- `tablet-ordering-pwa/AGENTS.md` — Specialist=chuya-frontend
- `woosoo-print-bridge/AGENTS.md` — Specialist=relay-ops

**`.github/ISSUE_TEMPLATE/agent-task.yml`** — fields: Request, Affected App (dropdown), Tier (dropdown), Success Criteria, Linked Case File, Required Gates checklist (5 checkboxes).

### Updated files

**`AGENTS.md`** (root) — bumped `last_reviewed: 2026-05-17`. Appended the entire "Lite 4-Agent Operating System" section including: Runners note (Claude Code / Codex / Copilot), Cross-Runner Resume & Handoff (mandatory), The 4 Agents, Triage Tiers table, Specialist Routing Table, Monorepo Split Rule, Branching & Rollback, Skill Discovery, Model Selection Policy, Token Mitigation Policy, Completion Definition, Executioner verdicts. Also has the Hook System (work/status/intake/triage/execute/verify/review/unlock/handover), token budgets by tier, and `state/WORK.md` convenience cache note.

Key print-bridge line (originally asserted "102 passed / 0 failed") — reworded in PLT-CASE-004 to attributed/non-verifiable statement (per Print Bridge audit §8 in the sibling repo — not independently verifiable from governance repo).

**`CLAUDE.md`** — added `@AGENTS.md` import at top. Added boot sequence (4 numbered steps: derive slug → check case file per RESUME_PROTOCOL → read AGENTS/AI_CONTEXT/AGENT_DEFAULT_INSTRUCTIONS → match hook → consult state/WORK.md). Added 4-Agent OS section. Added `state/WORK.md` convenience cache note. Preserved Review Summary requirement.

**`docs/README.md`** — added "Agent operating system (Lite, 4-agent)" section listing .claude/agents, .claude/skills, Codex per-app AGENTS.md, RESUME_PROTOCOL, HANDOVER_PROTOCOL, case files. Added "Contracts" section (5 contracts). Added `case-status.sh/.ps1` to Tooling section. PLT-CASE-004 also added: PROTOCOL.md, hooks/ (9 hooks), state/ (WORK/QUEUE/DEPS/DONE) indexed.

**`.github/copilot-instructions.md`** (root) — added "Agent Operating System & Resume (mandatory)" section with resume protocol, not-restart rule, phase checkpoint requirement, RESUME_PROTOCOL.md reference. Updated `last_reviewed: 2026-05-17`. Added subordination note for per-app files.

**`woosoo-nexus/.github/copilot-instructions.md`** — added canonical frontmatter + binding blockquote header with Specialist, resume protocol, ecosystem-docs-win precedence. All 680 lines of onboarding preserved. All 12 occurrences of `relay-device` replaced with `woosoo-print-bridge`.

**`tablet-ordering-pwa/.github/copilot-instructions.md`** — same treatment (Specialist=chuya-frontend, tablet intent-only contract restated in blockquote).

**PLT-CASE-004 additional edits (commit b85a357):** `docs/RESUME_PROTOCOL.md` §5 handoff template updated (removed "NOT a git repo / git status not reliable"); `docs/cases/plt-case-001` and `plt-case-002` Run State branch corrected to `staging/orchestration-hooks`; `docs/cases/nex-case-001` metadata reconciled (active_runner: none, not-started); untracked case files (plt-case-003, prn-case-001, tab-case-001, nex-case-001) committed; state/DONE.md / QUEUE.md / WORK.md updated.

### Git state
- Repo: `E:\Projects\woosoo-platform` (initialized `git init -b main`, then branch renamed to `staging/orchestration-hooks` by subsequent orchestration work)
- Remote: `origin = https://github.com/ryanpastorizadev-bit/woosoo-platform.git`
- HEAD: `b85a357f45c5fa1cf803ddaeae3d462c068db384`
- Local == origin/staging/orchestration-hooks: YES
- Commits: 5ea33b8 (baseline), ba92667 (add canonical orchestration hooks), 11111e9 (close hook surface case), b85a357 (PLT-CASE-001 + PLT-CASE-004 remediation)

---

## 4. Errors and Fixes

- **Embedded git repos staged as broken gitlinks**: When `git add -A` was run, woosoo-nexus/, tablet-ordering-pwa/, and woosoo-print-bridge/ were each independent git repos and were added as gitlinks (single entries without trailing slash) — their actual code was NOT staged. Required multiple rounds of `git rm --cached -f` to remove them. Final verification confirmed they appeared only as gitignored directories.
- **PowerShell tool environment silently failing (exit code 1, no output)**: The PowerShell tool in this environment returns bare exit 1 with no output for `ConvertFrom-Json` and `pwsh -File` calls. Worked around by running `pwsh` via the Bash tool (`pwsh -NoProfile -File scripts/case-status.ps1`) and Python (`python -c "import json; json.load(...)"`) for validation.
- **`pyyaml`/`js-yaml` not available**: Could not programmatically validate `agent-task.yml`. Mitigated by structural inspection of the YAML (standard GitHub issue-forms schema, consistent 2-space indent, quoted reserved values). Disclosed in the verification report.
- **`git rm` not force-removing local settings**: `.claude/settings.local.json` required `-f` flag to remove from index due to gitignore timing. Fixed with `git rm --cached -f`.
- **Stale "not a git repo" wording spread across multiple files**: After git init, several files still said "not a git repo, so git status is not reliable". PLT-CASE-004 fixed these in the 8 in-scope files. Residual: `.claude/agents/ranpo-backend.md:54` — deliberately left out of PLT-CASE-004's enumerated scope, tracked as PLT-CASE-005.
- **`null` file (0-byte stray artifact)**: Found as an empty file from a stray shell redirect in a prior session. Added to `.gitignore`, removed from index with `git rm --cached -f`.
- **Branch records in case files showing `main`**: PLT-CASE-001 and PLT-CASE-002 Run State had `branch: main` — corrected to `staging/orchestration-hooks` in PLT-CASE-004.
- **AGENTS.md:108 print-bridge assertion**: Originally asserted "102 passed / 0 failed" as a fact. Reworded to attributed/not-independently-verifiable-from-governance-repo per documentation-truth rules.
- **spec vs canonical order-state contradiction**: Spec demanded PENDING/VOIDED-only; canonical docs define confirmed→completed|voided|cancelled. Resolved by user decision: keep canonical. The spec's verification step #7 was explicitly overridden.

---

## 5. Problem Solving

- **Vendor-neutral orchestration**: The 4-agent system is defined once in `AGENTS.md` and consumed by all three runners (Claude Code via `.claude/agents/`, Codex via AGENTS.md merge, Copilot via `.github/copilot-instructions.md`). Agent definitions are single-sourced in `.claude/agents/` — per-app AGENTS.md and Copilot files are pointers, not duplicates.
- **Interruption recovery**: Solved via the `## Run State` block (machine-readable, per-phase checkpoint in the case file) plus the `## Handoff` note written on interruption. Any runner reboots cold from the case file alone — no chat history needed.
- **Secrets protection before push**: Multi-round audit (`grep -Ei '\.env|\.key|\.pem|\.jks|\.keystore|credentials|id_rsa'`) at every staging step; explicit gitignore entries; `.claude/settings.json` deny list; per-commit identity override.
- **Orchestration self-direction**: Rather than hardcoding fixes, an orchestration driver prompt was written that makes an agent determine the next action from live `state/WORK.md` + `state/QUEUE.md` + `docs/cases/*.md` Run State blocks. The agent correctly identified PLT-CASE-001 as the highest-priority resume target (precedence (a): IN_PROGRESS + Executioner PENDING) without being told.

---

## 6. All User Messages

1. *(Initial system-reminder with AGENTS.md content — not a user message)*
2. **"let's update our agent orchestration. replace github copilot with codex or just add codex version for this. only the lite version: [full spec]"** — The primary request with the complete 4-agent system spec.
3. **"need to add this. this is utterly important. if claude code was executing but then hit rate limits. when i pass it to copilot or codex. they should be able to resume the task or switch to the correct role to perform the unfinished task properly and follow the correct chain or sequence of operational workflow."** — Required cross-runner resume/handoff protocol.
4. **"File issue: per-app woosoo-nexus/.github/copilot-instructions.md and tablet-ordering-pwa/.github/copilot-instructions.md still exist and are not yet reconciled with the 4-agent system — decide later whether to align or retire them. -> align them whether aligning them retires them or not. select the best option. File issue: git init the platform root so the documented branch/rollback protocol becomes enforceable. do this if necessary."** — Align per-app Copilot files and git init.
5. **"File issue: consider a tiny scripts/case-status helper to print/update the ## Run State block consistently across runners. sounds good."** — Build the helper scripts. Simultaneously: **"File issue: nexus per-app Copilot file still calls the Flutter app relay-device/ while the ecosystem uses woosoo-print-bridge/ replace with correct app name woosoo-print-bridge or print-bridge."** — Fix stale app name.
6. **[Screenshot of GitHub repo quick-setup page]** + **"woosoo-platform repo."** — Push to GitHub.
7. **"review plan fixes. commit to staging"** — Initial request for the review remediation.
8. **[User rejected ExitPlanMode]** with **"add them for execution follow protocol"** — Fixes should be added to the system queue for execution via protocol.
9. **[User rejected ExitPlanMode again]** with **"provide prompt to ask agent what to execute according to the orchestration"** — The plan should be a runner-agnostic driver prompt, not a prescriptive fix list.
10. **"provide summary of what was done and the implementation plan if there is. CRITICAL: Respond with TEXT ONLY. Do NOT call any tools."** — Current summary request.

**Security constraints stated verbatim (must be preserved):**
- Never read/commit `.env`, `.env.*`, `secrets/**`, `config/credentials.json`, `storage/oauth-private.key`, `storage/oauth-public.key`, `storage/logs/**`, `.git/config`
- Never print real token values or session contents
- Never weaken or bypass authentication as a shortcut
- Never run destructive git (reset --hard, restore, clean, push --force) without explicit written approval
- Re-run secret scan (`\.env|\.key|\.pem|\.jks|\.keystore|credentials|secret`) over staged set BEFORE any push
- Pushing is externally visible and effectively permanent — only do it as the explicit final step of an APPROVED case
- Per-commit identity override for `ryanpastoriza.dev@gmail.com` — never modify global git config
- `.windsurf/` must NOT be committed or documented (gitignored, local-only)
- The three app repos are EXCLUDED sibling repos — never add them to the platform repo or assume their code is present here

---

## 7. Pending Tasks

- **PLT-CASE-005** (spawned as a task chip): Fix the single stale "not a git repo" line in `.claude/agents/ranpo-backend.md:54`. Tier 1 (single-line fix), dazai-docs specialist, staging/orchestration-hooks branch. The task chip is awaiting user click-to-start.
- **NEX-CASE-001** (next in `state/QUEUE.md`): Security/auth hardening for `woosoo-nexus`. **Must be run in the woosoo-nexus sibling repo, not this governance repo** — it targets excluded app code. Currently triaged/not-started (active_runner: none).
- **Baseline commit review**: The `null` file was gitignored but not deleted on disk; safe to remove manually. The stray prior-session docs (`C2_DETAILED_CHANGE_LOG.txt`, `C2_FILES_CHANGED_QUICK_REF.txt`, `C2_FINAL_COMPLETION_REPORT.txt`, `C2_PWA_COMPLETION_SUMMARY.txt`, `CLAUDE_REVIEW_SUMMARY.md`, `plan/refactor-woosoo-nexus-n1-query-fixes-1.md`) are committed in the baseline — may want to review/clean up.
- **Sibling app: `woosoo-print-bridge`** — `woosoo-print-bridge/` per-app Copilot file may not exist (not found in initial scan); the `woosoo-print-bridge/AGENTS.md` Codex pointer was created.

---

## 8. Current Work

Immediately before the summary request, the orchestration driver prompt (approved plan) was executed via a subagent. The agent:
1. Booted the operating system (read AGENTS.md hook system, CLAUDE.md, RESUME_PROTOCOL)
2. Identified PLT-CASE-001 (IN_PROGRESS, Executioner PENDING) as the correct first action per precedence rule (a)
3. Ran Verifier scans for PLT-CASE-001 → PASS → Executioner APPROVED → COMPLETE
4. Created and ran PLT-CASE-004 "review remediation" (Tier 2): fixed all 8 in-scope documentation-truth defects, gitignored `.windsurf/`, committed untracked queued case files, updated state files
5. Committed `b85a357` (15 files, +932/-26) and pushed to `origin/staging/orchestration-hooks`
6. Flagged one out-of-scope residual defect: `.claude/agents/ranpo-backend.md:54` stale wording → PLT-CASE-005 spawned as task chip

The independent verification confirmed:
- `local == origin/staging/orchestration-hooks == b85a357f45c5fa1cf803ddaeae3d462c068db384`
- Tree clean, no stale phrases in 8 in-scope files, no app code, `.windsurf/` excluded
- `state/WORK.md`, `state/QUEUE.md`, `state/DONE.md` consistent with case files

---

## 9. Optional Next Step

The most recent explicit work concluded with all immediate tasks APPROVED and pushed. The only remaining in-flight item is the spawned task chip for PLT-CASE-005, which the user can click to start independently.

Per the orchestration, the **next pullable queue row is NEX-CASE-001** (P1 security/auth hardening), but this targets `woosoo-nexus` — an excluded sibling repo not present in the governance repo. It must be run from within that app's own repository.

The orchestration driver prompt (the deliverable from the approved plan) is now available as a reusable, self-contained prompt for any future agent run. It can be pasted into Claude Code, Codex CLI, or Copilot to have the agent determine and execute the next orchestration action from live state, following the full 4-agent chain with proper checkpointing.

If you need specific details from before compaction (like exact code snippets, error messages, or content you generated), read the full transcript at: C:\Users\Pc1\.claude\projects\E--Projects-woosoo-platform\29f04d98-e13f-4096-92d1-c8334a3fd42c.jsonl
Continue the conversation from where it left off without asking the user any further questions. Resume directly — do not acknowledge the summary, do not recap what was happening, do not preface with "I'll continue" or similar. Pick up the last task as if the break never happened.


--- 

This session is being continued from a previous conversation that ran out of context. The summary below covers the earlier portion of the conversation.

Summary:
## 1. Primary Request and Intent

The user submitted an architecture plan for "Immediate POS Payment Session Reset" and asked for a review **without editing any code**. The goal was to replace the 1-minute POS polling path with a POS-local outbox trigger + Nexus consumer for ≤5s tablet session release after a payment or void. The user iteratively improved the plan based on feedback, eventually getting it approved.

After plan approval, a resume-protocol check revealed the **work described in the plan is already fully shipped** on branch `agent/nex-case-007-pos-payment-outbox-session-reset` (Executioner APPROVED on 2026-05-21). The user then asked for a summary of what was done and whether there is an implementation plan.

---

## 2. Key Technical Concepts

- **POS-local outbox pattern** — MySQL trigger writes a row to `woosoo_order_status_outbox` (on POS DB) when an order closes/voids; no cross-server DB writes at the trigger layer
- **Nexus consumer command** — `pos:consume-payment-status-events --limit=100` scheduled `everyFiveSeconds()->withoutOverlapping(3)->runInBackground()`
- **Raw `DB::table` compare-and-swap** — Updates `device_orders` status with `WHERE status IN (<open states>)` guard; deliberately bypasses Eloquent to avoid `DeviceOrderObserver` double-broadcasting events
- **DeviceOrderObserver** — Already dispatches all 5 terminal events on Eloquent status updates via `DB::afterCommit`; consumer must NOT use Eloquent or it creates duplicate Reverb broadcasts to tablets
- **OrderFinalizationService / PosOrderStatusFinalizer** — Shared service used by both the fast consumer and the slow `SyncPosOrderPaymentStatus` safety-net reconciler; handles audit logging, event dispatch, and outbox row state
- **Partial-failure recovery branch** — If local DB update succeeds but Reverb dispatch fails, the outbox row stays unprocessed. On retry, compare-and-swap affects 0 rows but local status already equals `target_status`; the consumer must re-dispatch events and mark `processed_at` rather than silently skipping
- **Dead-letter via `failed_at`** — Rows with `attempts >= 5` set `failed_at`; ops monitors `failed_at IS NOT NULL`
- **Trigger idempotency** — No UNIQUE constraint on `pos_order_id`; multiple outbox rows per order are allowed (close → void sequence); idempotency is enforced by the compare-and-swap on local status
- **`withoutOverlapping(3)` serialization** — Replaces per-row locking; a 3-second mutex TTL prevents concurrent consumer runs
- **SessionReset scope** — In the shipped implementation, `SessionReset` is NOT dispatched per payment order. It is reserved for staff/admin reset or POS daily session close (via a separate sessions outbox path). This was a deliberate Contrarian-phase decision in nex-case-007.
- **Laravel Reverb broadcasting** — All 5 event classes (`OrderStatusUpdated`, `OrderCompleted`, `OrderVoided`, `PaymentCompleted`, `SessionReset`) implement `ShouldBroadcastNow` and already existed
- **4-Agent OS (AGENTS.md)** — Contrarian → Specialist (ranpo-backend) → Verifier → Executioner; Tier 3 for this change (order lifecycle + realtime broadcast surface)
- **Resume protocol** — `docs/cases/<slug>.md` is authoritative durable state; `status: COMPLETE` means do not reopen

---

## 3. Files and Code Sections

### Plan File (created/updated during session)
- **`C:\Users\Pc1\.claude\plans\review-this-plan-do-breezy-wave.md`** — Final approved implementation plan written during plan mode. Documents outbox schema, event flow (including partial-failure recovery branch), test plan, verification steps, assumptions, and rollback.

### Outbox schema (from final plan):
```sql
CREATE TABLE woosoo_order_status_outbox (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pos_order_id    VARCHAR(255) NOT NULL,
    target_status   ENUM('completed', 'voided') NOT NULL,
    pos_closed_at   DATETIME NULL,
    pos_is_voided   TINYINT(1) NOT NULL DEFAULT 0,
    attempts        SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    last_error      TEXT NULL,
    failed_at       TIMESTAMP NULL,
    processed_at    TIMESTAMP NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_pending (processed_at, failed_at, attempts),
    INDEX idx_pos_order (pos_order_id)
);
```
No UNIQUE on `pos_order_id`.

### Already-shipped files on `agent/nex-case-007-pos-payment-outbox-session-reset`:
- **`app/Console/Commands/SetupPosOrderPaymentTrigger.php`** — Replaced: POS-local outbox table + trigger only; `isSameMysqlEndpoint()` guard removed; no cross-server DB writes
- **`app/Console/Commands/SyncPosOrderPaymentStatus.php`** — Modified: inline raw-update/dispatch replaced with call to `PosOrderStatusFinalizer`; remains on `everyMinute()` as safety-net
- **`app/Console/Commands/ConsumePosPaymentStatusEvents.php`** — New: fast consumer with `--limit=100` flag
- **`app/Services/Pos/PosOrderStatusFinalizer.php`** — New: shared finalizer service (plan called it `OrderFinalizationService`)
- **`app/Http/Middleware/UpdateDeviceLastSeen.php`** — New: refreshes `last_seen_at` on authenticated tablet traffic with 30-second throttle (bonus item)
- **`config/devices.php`** — New: device config for throttle
- **`routes/api.php`** — Modified: middleware added (also Pint-formatted)
- **`routes/api_printer_routes.php`** — Modified: Pint-formatted
- **`routes/console.php`** — Modified: `everyFiveSeconds()->withoutOverlapping(3)->runInBackground()` added for consumer
- **`tests/Feature/Console/PosPaymentOutboxConsumerTest.php`** — New feature tests
- **`tests/Feature/Console/PosPaymentOutboxSetupTest.php`** — New feature tests
- **`tests/Feature/Middleware/UpdateDeviceLastSeenTest.php`** — New middleware tests

### State files read:
- **`E:\Projects\woosoo-platform\state\WORK.md`** — Shows `nex-case-002-pulse-routes` status: DONE (2026-05-30); next action: pull NEX-CASE-005 or PLT-CASE-003
- **`E:\Projects\woosoo-platform\docs\cases\nex-case-007-pos-payment-outbox-session-reset.md`** — `status: COMPLETE`, Executioner APPROVED 2026-05-21; 34 tests / 148 assertions green; pre-merge-check passed

---

## 4. Errors and Fixes

- **Double-dispatch risk (original plan)** — Plan proposed consumer explicitly dispatching events AND implied Eloquent updates would fire `DeviceOrderObserver`. Fix: plan revised to use raw `DB::table` only with explicit dispatch; never Eloquent.
- **Missing `withoutOverlapping()` (original plan)** — `everySecond()` without overlap protection causes pile-up. Fix: added `withoutOverlapping(3)->runInBackground()`.
- **`SetupPosOrderPaymentTrigger` ambiguity (original plan)** — Unclear whether it was modified alongside or replaced. Fix: plan explicitly states it is REPLACED.
- **Missing partial-failure recovery branch (improved plan)** — If local update succeeds but Reverb throws, the row stays unprocessed and re-processing silently skips it (compare-and-swap returns 0 rows). Fix: added explicit branch in `OrderFinalizationService::finalize()` — if 0 rows affected AND local status already equals `target_status`, re-dispatch all events and mark `processed_at`.
- **No outbox row cleanup (improved plan)** — Accumulates indefinitely. Fix: daily prune of `processed_at < 7 days`; `failed_at IS NOT NULL` rows retained 30 days.
- **Trigger idempotency not documented** — Fix: explicitly stated no UNIQUE constraint; multiple rows per `pos_order_id` are by design.

---

## 5. Problem Solving

**Main problem solved (in plan review):** The original plan had a correctness flaw (double event dispatch), a missing safety guard (`withoutOverlapping`), architectural ambiguity (replace vs. modify), a silent failure mode (partial dispatch recovery), missing retention policy, and unclear trigger contract. All were resolved across two review rounds.

**Critical discovery after plan approval:** The resume protocol check revealed nex-case-007 is already fully implemented and APPROVED (2026-05-21). The plan we reviewed matches what was already built (with naming differences: plan used `OrderFinalizationService`, shipped code uses `PosOrderStatusFinalizer`). There is one important shipped design difference: `SessionReset` is NOT dispatched per-payment — it is reserved for daily POS session close events.

**Current blocker:** nex-case-007 branch (`agent/nex-case-007-pos-payment-outbox-session-reset`) is merged to dev at the platform level but needs `php artisan pos:setup-payment-trigger` run on the Pi (POS-connected environment) to activate the fast path.

---

## 6. All User Messages

1. *"review this plan do not edit code yet. propose improvements if necessary, default to simplest working solution: [original plan text]"*

2. *"review improved plan: [revised plan text incorporating everyFiveSeconds, withoutOverlapping, raw DB, failed_at, explicit dispatch]"*

3. *[/model claude-opus-4-7 command — local command, not directed at assistant]*

4. *[Plan mode exit approved — user approved the final plan file]*

5. *[CI monitor event — PR #142 CodeRabbit comments on docker/docker-entrypoint.sh, NavMain.vue href guard, badge variants, focus ring colors, AppSidebar type assertion, button variants]*

6. *"nothing to compare for agent/nex-case-002-pulse-routes in any remote branch."* — Response to PR creation command showing branch has no remote

7. *[CI monitor event — PR #142 new comments: woosoo-orange undefined token, missing fence language identifiers in IMPLEMENTATION_HANDOVER.md]*

8. *"Continue from where you left off."*

9. *"provide summary of what was done and the implementation plan if there is. CRITICAL: Respond with TEXT ONLY."*

**Security/operational constraints (verbatim from CLAUDE.md/AGENTS.md — must remain in effect):**
- "Never expose secrets, never commit credentials, never read `.env` unless explicitly required for diagnosis (and even then never print secret values)."
- "The tablet sends intent; the backend owns truth."
- "One app per task."
- "No technical errors to customers."
- "Order state: `OrderStatus` enum; terminal = `completed | cancelled | voided | archived`."
- "No hardcoded LAN IPs or API/Reverb hosts in tablet or bridge code."
- "Config integrity: production POS uses static IP `192.168.1.32`."

---

## 7. Pending Tasks

1. **Deploy nex-case-007**: Run `php artisan pos:setup-payment-trigger` on the Pi (POS-connected environment) to activate the outbox trigger. Branch is already approved and on remote dev. This is the "Exact next action" from the nex-case-007 case file.

2. **PR #142 inline comments** (woosoo-nexus, CodeRabbit, two actionable items with comment_ids):
   - comment_id=3328805181: `woosoo-orange` token referenced in `handoff/IMPLEMENTATION_HANDOVER.md:45` but not defined in token table (lines 27–36). Fix: either add entry or replace with `woosoo-accent`.
   - comment_id=3328805184: Missing fence language identifiers (MD040) in multiple code blocks in `handoff/IMPLEMENTATION_HANDOVER.md` (lines 39, 162, 212, 266, 590, 599, 695, 734). Fix: add ` ```text ` tags.
   - For each addressed comment: post one-line reply via `gh api` and resolve thread.

3. **Next queued case** (per `state/WORK.md`): Either NEX-CASE-005 (legacy print path, P2, P1 gating `dev→staging`) or PLT-CASE-003 (cross-app orchestration, P3).

4. **nex-case-010** (immutable-image production migration, Tier 3, BLOCKED) — awaiting deliberate selection.

---

## 8. Current Work

Immediately before the summary request, I had just completed the resume-protocol check after plan approval and presented the user with a decision:

> "Stop — this work is already shipped. `docs/cases/nex-case-007-pos-payment-outbox-session-reset.md` shows `status: COMPLETE`, Executioner verdict APPROVED, dated 2026-05-21 19:50."

I listed 4 options for the user:
1. Deploy / verify the existing nex-case-007 branch — run `php artisan pos:setup-payment-trigger` on Pi
2. Audit the shipped implementation against the plan we approved (read-only)
3. Start a fresh case (e.g., NEX-CASE-005)
4. Something else

The user responded "Continue from where you left off" and then "provide summary of what was done and the implementation plan if there is" — indicating they want to understand the current state before deciding next steps.

---

## 9. Optional Next Step

Based on the user's most recent message "provide summary of what was done and the implementation plan if there is" — the next step after delivering this summary is to **wait for the user to choose** among the four options presented:

> "1. Deploy / verify the existing nex-case-007 branch — pull `agent/nex-case-007-pos-payment-outbox-session-reset` and run `php artisan pos:setup-payment-trigger` in the POS-connected environment (the case's exact next-action). No code changes."

The most likely intended next action (based on `CLAUDE.local.md` notes and the case file's "Exact next action") is option 1: deploying nex-case-007 by running `php artisan pos:setup-payment-trigger` on the Pi. However, this requires explicit user confirmation since it touches a live POS-connected production environment.

If you need specific details from before compaction (like exact code snippets, error messages, or content you generated), read the full transcript at: C:\Users\Pc1\.claude\projects\E--Projects-woosoo-platform-woosoo-nexus\2bd89cf9-fb31-4108-a9a7-29e448d66404.jsonl
Continue the conversation from where it left off without asking the user any further questions. Resume directly — do not acknowledge the summary, do not recap what was happening, do not preface with "I'll continue" or similar. Pick up the last task as if the break never happened.


--- 

This session is being continued from a previous conversation that ran out of context. The summary below covers the earlier portion of the conversation.

Summary:
1. Primary Request and Intent:
   The user progressively asked: (a) "what is the next part of the plan or what tasks are currently pending?" — wanting to know pending items from prior plans; (b) "what is urgent. blocking features?" — wanting urgency-ranked items; (c) approved fixing the SessionApiController@reset device-guard bug (Nexus Critical #3) first; (d) "do these items been reviewed?" — clarifying actual execution state of the 4 pending items; (e) "what is the complete details for the refill mode? what is the issue?" — wanting full details on the refill-mode predicate divergence; (f) approved fixing the refill-mode follow-ups (Tablet PWA); (g) "provide summary of what was done and the implementation plan if there is" — asking for a session recap.

   Underlying intent: progressively close out small, high-payoff fixes from the 2026-05-14 audits without spawning agents; remain in plan mode until each fix is approved; verify each change with real tests.

   Security/policy constraints (verbatim from CLAUDE.md/AGENTS.md, must remain in force):
   - "Never expose secrets, never commit credentials, never read .env unless explicitly required for diagnosis (and even then never print secret values)."
   - "Backend owns truth. Tablet may only send { guest_count, package_id, items: [ { menu_id, quantity } ] }. It must never send pricing, tax, modifiers, totals, POS mapping, or state."
   - "Customer-facing UI must never show raw technical errors. Use friendly messages. Stack traces, SQL errors, and exception dumps belong in logs only."
   - "Order state machine: the OrderStatus enum (pending, confirmed, in_progress, ready, served, completed, cancelled, voided, archived); terminal states are completed | cancelled | voided | archived. Do not invent new backend states."
   - "Sibling-repo boundary: one app per branch/commit unless integration-scoped."
   - "Production POS uses static IP 192.168.1.32."
   - "No hardcoded LAN IPs or API/Reverb hosts in tablet or bridge code."
   - "Only create commits when requested by the user."
   - "DO NOT push to the remote repository unless the user explicitly asks you to do so."
   - "Never skip hooks (--no-verify, --no-gpg-sign, etc) unless the user explicitly requests it."
   - Use dev branch for Woosoo repos (per project memory): "Push/PR/branch off dev for all Woosoo repos (nexus, tablet-pwa, print-bridge, platform), not staging."

2. Key Technical Concepts:
   - Laravel 12 sanctum auth with dual guards (`auth:sanctum`, `auth:device`); device tokens via Personal Access Tokens
   - PHP `get_class()` returns FQN WITHOUT leading backslash; `instanceof` is idiomatic and string-escape-safe
   - Laravel 11+ bootstrap/app.php middleware registration; middleware aliases vs class-name resolution
   - Nuxt 3 + Pinia stores; Vue `computed()` reactivity tracking (only re-runs on deps read during evaluation)
   - Pinia persistence plugin with `pick` list for selective field hydration from localStorage
   - Vitest test patterns: `setActivePinia(createPinia())`, direct `$state` mutation for invariant pins
   - Idempotency keys / client_submission_id pattern for order creation
   - The 4-agent operating system (Contrarian → Specialist → Verifier → Executioner) and triage tiers
   - 2026-05-14 audit suite (Ecosystem, Nexus, Tablet PWA, Print Bridge) as canonical source

3. Files and Code Sections:
   - `C:\Users\Pc1\.claude\plans\what-is-the-next-lazy-hartmanis.md`
     - Plan file created and progressively extended with two complete plans
     - Contains: "Fix SessionApiController@reset() device guard (Nexus Critical #3)" and "Refill-mode predicate divergence (Order store, Tablet PWA)"

   - `woosoo-nexus/app/Http/Controllers/Api/V1/SessionApiController.php` (edited, line 95)
     - Why: Critical #3 in Nexus audit — `get_class($user) === '\\App\\Models\\Device'` is always false
     - Change:
       ```php
       // before
       $isDevice = $user && get_class($user) === '\\App\\Models\\Device';
       // after
       $isDevice = $user instanceof \App\Models\Device;
       ```

   - `woosoo-nexus/routes/api.php` (edited, lines 230-233)
     - Why: discovered while testing — `'requestId'` middleware alias was referenced but never registered; threw BindingResolutionException for every call
     - Change:
       ```php
       // before
       Route::middleware(['requestId','auth:sanctum'])->group(function () {
           Route::post('/sessions/{id}/reset', [\App\Http\Controllers\Api\V1\SessionApiController::class, 'reset'])->name('api.sessions.reset');
       });
       // after
       Route::middleware(['auth:sanctum'])->group(function () {
           Route::post('/sessions/{id}/reset', [\App\Http\Controllers\Api\V1\SessionApiController::class, 'reset'])->name('api.sessions.reset');
       });
       ```
     - RequestId is global via `bootstrap/app.php:37`, so the route-level alias was both redundant and broken

   - `woosoo-nexus/tests/Feature/Api/V1/SessionResetAuthTest.php` (CREATED)
     - Why: audit's acceptance criterion for Critical #3 — "a feature test exercises the device path and passes"
     - 4 cases: admin can reset, authenticated device can reset (via `withToken($device->createToken('device-auth', expiresAt: now()->addDays(30))->plainTextToken)`), non-admin user gets 403, repeated reset increments cache version
     - Uses `Event::fake([SessionReset::class])` and `Cache::flush()` in setUp; asserts cache key `session:{id}:version` and SessionReset dispatched
     - All 4 tests pass (17 assertions, 1.82s)

   - `tablet-ordering-pwa/stores/Order.ts` (edited, two locations)
     - Why: refill-mode predicate divergence — three predicates with same logical intent had drifted
     - Line 374 change (`submitOrder` guard):
       ```ts
       // before
       if (state.rounds.length > 0 || state.serverOrderId !== null) {
           throw new Error("An initial order has already been placed for this session. Use refill instead.")
       }
       // after
       if (state.rounds.length > 0 || getServerOrderId() !== null) {
           throw new Error("An initial order has already been placed for this session. Use refill instead.")
       }
       ```
     - Line 867 change (`hasPlacedOrder` computed):
       ```ts
       // before
       const hasPlacedOrder = computed(() => state.rounds.length > 0 || state.serverOrderId !== null)
       // after
       const hasPlacedOrder = computed(() => {
           const sessionStore = useSessionStore()
           return state.rounds.length > 0
               || state.serverOrderId !== null
               || sessionStore.orderId !== null
       })
       ```
     - Reactivity rationale: reading `sessionStore.orderId` directly inside the computed (rather than via `getServerOrderId()` which short-circuits) makes Pinia track the dep so the computed invalidates on session orderId changes — critical because `orderId` is in the persistence `pick` list at `Session.ts:546` and hydrates from localStorage on reload

   - `tablet-ordering-pwa/tests/order-restrictions.spec.ts` (edited — 3 new cases added)
     - Why: existing regression test set both `serverOrderId` AND `sessionStore.orderId`, so didn't isolate the session-only branch
     - Added cases:
       ```ts
       it("hasPlacedOrder is true when only sessionStore.orderId is hydrated (no local serverOrderId)", () => {
           ;(store as any).rounds = []
           ;(store as any).serverOrderId = null
           sessionStore.$state.orderId = 1001
           expect(store.hasPlacedOrder).toBe(true)
       })

       it("toggleRefillMode accepts session-only recovery state", () => {
           ;(store as any).rounds = []
           ;(store as any).serverOrderId = null
           sessionStore.$state.orderId = 1001
           store.toggleRefillMode(true)
           expect(store.isRefillMode).toBe(true)
       })

       it("submitOrder refuses to create when only sessionStore.orderId is set", async () => {
           ;(store as any).rounds = []
           ;(store as any).serverOrderId = null
           sessionStore.$state.orderId = 1001
           await expect(store.submitOrder()).rejects.toThrow(/already been placed/i)
           expect((store as any).isSubmitting).toBe(false)
       })
       ```
     - All 14 tests pass (11 prior + 3 new)

   - Reference-only reads (not modified):
     - `tablet-ordering-pwa/stores/Order.ts:171-176` — `getServerOrderId()` helper reused
     - `tablet-ordering-pwa/stores/Order.ts:296` — `toggleRefillMode` guard pattern reference
     - `tablet-ordering-pwa/stores/Session.ts:54,512-515,546` — confirms `orderId` reactive shape; `setOrderId`/`getOrderId`; persist `pick` list includes `orderId`
     - 8 UI consumers of `hasPlacedOrder`: `CartDrawer.vue`, `RefillButton.vue`, `OrderPlacedBadge.vue`, `OrderingStep3ReviewSubmit.vue`, `MenuHeader.vue`, `RefillModeBanner.vue`, `CartSidebar.vue`, `plugins/kiosk-guard.client.ts`
     - `woosoo-nexus/database/factories/UserFactory.php` — confirmed `admin()` state with `is_admin => true`
     - `woosoo-nexus/tests/Feature/Api/V1/DeviceTokenLifecycleTest.php` — pattern reference for `withToken($device->createToken(...)->plainTextToken)`
     - `woosoo-nexus/app/Http/Middleware/ApiCsrfExemption.php` — confirms `/api/sessions/{id}/reset` is intentionally NOT exempt from CSRF
     - `C:\Users\Pc1\.claude\plans\review-and-finialize-this-floating-book.md` — prior plan with "Execution status (as of 2026-05-14)" identifying Phase 6 references

4. Errors and fixes:
   - Initial SessionResetAuthTest run failed with `BindingResolutionException: Target class [requestId] does not exist.`
     - Fix: removed the `'requestId'` middleware alias from `routes/api.php:231` (RequestId class is already global in bootstrap/app.php)
     - Result: all 4 tests pass; also fixed pre-existing `session_reset_works_with_valid_csrf_token` BindingResolutionException
   - 8 pre-existing CSRF test failures (CsrfMiddlewareTest, ApiCsrfExemptionTest)
     - Verified pre-existing on `staging` branch by stashing my changes and re-running — failures are unrelated to my edits and exist on this branch's other in-flight uncommitted changes
   - `git diff -- <path>` returned git CLI help output
     - Worked around with `git --no-pager diff <path>` (no `--` separator)
   - User feedback / behavioral corrections received during session:
     - "what is urgent. blocking features?" — pivoted from listing planned cleanup items to ranking by actual urgency / blocking impact
     - "do these items been reviewed?" — triggered verification that I had not assumed prior items were unexecuted; discovered 3 of 4 were already done

5. Problem Solving:
   - Solved: Nexus Critical #3 (session reset device guard) including a latent BindingResolutionException bug discovered during testing — endpoint is now actually callable and admits both admin users and devices as intended.
   - Solved: Refill-mode predicate divergence — three predicates (`toggleRefillMode`, `submitOrder`, `hasPlacedOrder`) now share the broader semantics; reactivity preserved through Pinia tracking; 3 new test cases pin the session-only branch.
   - Verified: 3 other "pending" items (Phase 6 reference fix-up, Roadmap amendment, Docker consolidation) were already executed in prior sessions.
   - Pre-existing branch failures in CSRF tests acknowledged as not caused by my changes; not in scope to fix.

6. All user messages:
   - "what is the next part of the plan or what tasks are currently pending?"
   - User answered AskUserQuestion: "what is urgent. blocking features?"
   - User answered AskUserQuestion: "Session reset device-guard fix (Recommended)" — selected from 4 options
   - "do these items been reviewed?"
   - User answered AskUserQuestion: "The 4 pending plan items" — selected from 4 options
   - "what is the complete details for the refill mode? what is the issue?"
   - "provide summary of what was done and the implementation plan if there is."

   (No security-relevant instructions were issued in user messages during this session beyond what is already in CLAUDE.md/AGENTS.md, which are preserved verbatim in section 1.)

7. Pending Tasks:
   - No remaining task from this session — both fixes (SessionApiController device guard, Refill-mode predicate) are fully executed and verified.
   - The user has NOT explicitly asked for the next item. Candidate large items still untouched from the audit (only to be picked if user requests):
     - Nexus Critical #1–2: Branch / tenant scoping on admin/device endpoints
     - Nexus Critical #4: Broadcast channel auth hardening (`admin.print`, `service-requests.{deviceId}`)
     - Nexus Critical #5: GET `/api/token/create` credential endpoint
     - Ecosystem Critical #2: Pick single canonical print architecture
     - Tablet Critical #1: PWA offline contradiction (SW + outbox queue vs OrderingStep3ReviewSubmit blocking submit)
     - Tablet Critical #2: Consolidate four overlapping idempotency helpers
     - Print Bridge Critical #1: ACK backlog terminal policy
     - Print Bridge Critical #2: Polling watermark resume cursor
     - Print Bridge Critical #3: Get the test suite green
   - Pre-existing CSRF middleware misconfiguration on woosoo-nexus `staging` branch (not caused by my work; flagged but not in scope)

8. Current Work:
   The most recent action was responding to the user's request "provide summary of what was done and the implementation plan if there is." I provided a recap of:
   - Fix 1 (Nexus): SessionApiController@reset device guard + RequestId middleware alias cleanup + new SessionResetAuthTest with 4 cases, all passing
   - Fix 2 (Tablet PWA): submitOrder guard widening + hasPlacedOrder computed widening with reactivity preserved + 3 new test cases, all 14 tests passing, typecheck clean
   - Verification that 3 of the 4 earlier "pending" items were already executed (Phase 6 refs, Roadmap amendment, Docker consolidation)
   - Explicit statement that "Both fixes have been fully executed and verified. There is no remaining unimplemented plan from the items we discussed."

   Both fixes are complete. Working trees show modified files on `woosoo-nexus` branch `staging` (SessionApiController.php + routes/api.php + new test file) and `tablet-ordering-pwa` branch `refactor/order-ledger` (Order.ts + order-restrictions.spec.ts). Per policy, no commits were created and no pushes were performed.

9. Optional Next Step:
   None — the last task ("provide summary of what was done and the implementation plan if there is.") was a recap request and is now complete. Both implementation tasks the user explicitly approved (SessionApiController device guard and Refill-mode predicate) have been executed and verified.

   The session-ending message offered: "If you want to proceed to one of the larger audit Critical items next (Bridge ACK backlog, PWA offline contradiction, the security trio in Nexus, idempotency consolidation, or pick-canonical-print-architecture), say which and I'll plan it." That offer awaits a user response — I should not pre-empt it by starting a new task.

   If the user wants to proceed, the most likely next candidates (per their earlier "urgent / blocking" framing) are: the Nexus security trio (Critical #4 broadcast channel auth + Critical #5 GET credential endpoint, both small) or the Bridge Critical triage (#1 ACK backlog + #2 polling cursor + #3 red suite, which is large and blocks all print-determinism work). I will wait for the user to pick rather than assume.

If you need specific details from before compaction (like exact code snippets, error messages, or content you generated), read the full transcript at: C:\Users\Pc1\.claude\projects\E--Projects-woosoo-platform\a01bfc01-6e65-4508-ba6e-8ffda514b99e.jsonl
Continue the conversation from where it left off without asking the user any further questions. Resume directly — do not acknowledge the summary, do not recap what was happening, do not preface with "I'll continue" or similar. Pick up the last task as if the break never happened.


--- 

# Session Summary

## What was done

### 1. AI workflow finalization (boot layer + per-app rules)
- Created root boot layer: `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, `docs/AI_CONTEXT.md`, `docs/README.md`
- Added `woosoo-print-bridge/.agents.md` for per-app parity with the other two apps
- Added canonical frontmatter to 9 existing canonical docs

### 2. Pre-merge validation tooling
- Created `scripts/pre-merge-check.sh` and `scripts/pre-merge-check.ps1` (per-app dispatch)

### 3. Four audit documents rewritten
All four 2026-05-14 audits restructured to a unified 7-section template (Executive Summary → Runtime Facts → Contracts → Issues by Severity → Action Items → Verification → Cross-References), preserving every fact:
- `docs/WOOSOO_ECOSYSTEM_ENGINEERING_REVIEW_2026-05-14.md`
- `woosoo-nexus/docs/WOOSOO_NEXUS_STABILIZATION_AND_HARDENING_AUDIT_2026-05-14.md`
- `tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md`
- `woosoo-print-bridge/docs/WOOSOO_PRINT_BRIDGE_PRODUCTION_RELIABILITY_AUDIT_2026-05-14.md`

### 4. Documentation audit (archive-only)
- Created `docs/audits/DOCS_AUDIT_2026-05-14.md` inventory
- Moved 32 stale/superseded markdowns to `<scope>/docs/archive/2026-05/` with `superseded_by` frontmatter; relocated 1 runbook; **zero deletions**

### 5. Roadmap review and promotion
- Verified `WOOSOO_ROADMAP_REVIEW.md` against the four audits, found 8 Critical items to promote and 6 missing items to add
- Promoted to `status: canonical` with audit reconciliation section, per-initiative audit backstops, and a re-weighted 6-group execution order

### 6. Refill-mode blocker review (tablet-ordering-pwa)
- Verified the submitter's fix to `toggleRefillMode`
- Flagged a related bug (`submitOrder` and `hasPlacedOrder` use the narrower predicate)
- Test-coverage gap noted: regression test doesn't isolate the session-only branch

### 7. woosoo-nexus 6 fixes (Critical + High)
- **Critical**: Created data migration normalizing legacy `in_progress`/`ready`/`served` → `confirmed`; hardened `DeviceOrder` setter with `tryFrom()`
- **High**: Fixed 3 test files (incl. one the reviewer missed); reverted permission migration to Spatie default
- **Medium**: MySQL bound to `127.0.0.1:3306`; `OrderApiController` menu-name resolution made consistent

### 8. Docker consolidation
- Deleted 21 files (16 BI/ETL + 4 redundant Docker + 1 BI report sample)
- `.gitignore` cleanup
- Result: exactly 4 Docker artifacts in the repo (canonical compose, standalone tablet compose, two Dockerfiles)

### 9. Full Docker rebuild (data-preserving)
- Stopped + removed containers (volumes preserved)
- Removed 8 app/orphan images; kept base images
- Reclaimed 22.47 GB of stale build cache
- Cold rebuild with `--no-cache` (~6 min)
- Verified: 9 services running, MySQL bound to `127.0.0.1:3306`, database intact (6 orders, 4 devices, 7 print events)

### 10. Phase 6 — surviving inbound references
6 stale references to archived files were fixed to point at canonical replacements.

---

## Implementation plan

**Nothing new pending implementation.** All sections in `C:\Users\Pc1\.claude\plans\review-and-finialize-this-floating-book.md` are either completed or explicitly flagged as out-of-scope follow-ups.

The plan file contains:
1. Original Woosoo AI workflow finalization plan — **executed**
2. WOOSOO_ROADMAP_REVIEW.md review and amendment plan — **executed**
3. Refill-mode blocker review — **delivered as analysis** (findings recorded; no code edits made in plan mode)
4. Docker consolidation plan — **executed**

### Known follow-ups (flagged, not in plan)

These were called out throughout the session but never converted into an active plan because each is small and discretionary:

1. **Refill-mode Finding 3** — apply the broadened predicate to `submitOrder` and `hasPlacedOrder` in `tablet-ordering-pwa/stores/Order.ts` (~5 lines, same PR as the original fix).
2. **Docker stack hardening** — add healthchecks to `nginx`, `reverb`, `queue`, `scheduler`, `pulse`; add `mem_limit` to `tablet-pwa`; optimize `woosoo-nexus/Dockerfile` `COPY . .` ordering to shrink rebuild times.
3. **`tablet-ordering-pwa/docs/API_TRACE_REFERENCE.md` runtime correctness** — query string `?status=pending,in_progress` and the `meta.counts` keys list still mention removed enum values; passes today but is stale (left untouched per "simplest working fix" instruction).
4. **Print Bridge red test suite** — per the latest audit edit, this is now **resolved** (111/0 tests passing as of 2026-05-19), so this prior follow-up no longer applies.

---


Let me verify the current state of the files I was mid-edit on before summarizing, since the last batch of edits errored out.

PrintAudit's edits did not land (stream closed), and DiscountTax wasn't started. Let me confirm OrderStatus landed and check DiscountTax before reporting.

OrderStatus landed cleanly. Here's the accurate status.

## Summary — what's done

Implementing on the **`dev`** branch. I started with a critical safety finding: the Step-4 prerequisite snapshots (`Orders/Index.vue`, `Devices/Index.vue`) are **stale** — current code has functional logic (Echo reconnect, polling fallback, race guards, print animations, security-code dialog) the snapshots lack. **Copying them would destroy real logic**, so those are handled surgically, not by file-copy.

### ✅ Completed & verified

**Prerequisites (safe file-copies):**
- Step 3 primitives: `badge/index.ts` (adds `warning` variant), `button/index.ts`, `card/Card.vue` (`border-black/8`), `tabs/TabsList.vue`, `tabs/TabsTrigger.vue`
- Step 2: `layouts/AppContentLayout.vue` (`rounded-[26px]`, `backdrop-blur-sm`)
- Step 4: `pages/Dashboard.vue` (cosmetic radii/border unification)
- **Skipped** Step-2 dark-mode toggle (functional, reintroduced raw `bg-emerald-500`, conflicts with existing appearance composable — not required by any section)

**Components:**
- `Stats/StatsCards.vue` — grid → `auto-fit minmax` (fixes 2-card layouts); added `destructive` (kept `danger` alias); `emerald`→`woosoo-green`; `font-bold`→`font-semibold`
- `Orders/OrderStatusBadge.vue` — verified already correct (Step-3 variants), no change needed

**Pages (sections done):**
- §1 `reports/Index.vue` — hero, wrapper, all icon color tokens, card border, button hover
- §2 `reports/DailySales.vue`, §3 `HourlySales.vue` (+ peak-row `woosoo-accent` token), §4 `GuestCount.vue` (+ removed nested card), §5 `MenuItems.vue` (both tables + list items), §6 `OrderStatus.vue` (+ new `getStatusColor`)
- §10 `Menus/Index.vue` — hero, wrapper, `danger`→`destructive`, table card
- §11 `Users/Index.vue` — hero w/ Add User, `danger`→`destructive`, brand pagination, table card, debug comment removed

## Remaining implementation plan

**Reports (finish task #4):**
- §7 `reports/PrintAudit.vue` — *edits failed mid-batch, file untouched*: hero+date-range, `getStatusColor` helper (replace inline v-if badges), brand table
- §8 `reports/DiscountTax.vue` — hero+date-range, brand table, Period Summary grid cards

**Operational/admin (task #5):**
- §9 `ServiceRequests/Index.vue`, §13 `Packages/Index.vue`, §14 `branches/IndexBranches.vue`, §15-16 `roles/{IndexRoles,CreateRole,EditRole}.vue`
- §12 `Users/Create.vue`+`Edit.vue`, §23 `Devices/Create.vue`+`Edit.vue` (hero + form card wrappers)
- §17 `EventLogs/Index.vue` (`getLevelColor` tokens, raw warning, container radius, hero)
- §18 `Monitoring/Index.vue` (`deviceStateColor` tokens, hero, alert radius, RefreshCw icon)
- §19 `POS/Index.vue` (remove outer wrapper; `rounded-[28px]`→`[26px]`, `border-border/60`→`black/8`, emerald/rose→brand tokens) — surgical, preserves logic
- §20 `Admin/Settings.vue`, §21 `settings/Profile.vue`, §24 `Permissions/Index.vue`
- §25 `NavMain.vue` — verify-only (Reports sub-nav active state)

**Verification (task #6):**
- `npm run typecheck && npm run lint && npm run build`
- Re-grep target pages for residual raw Tailwind colors / `font-bold` headings / `variant:'danger'`
- Walk the handover QA checklist (dark-mode peak row, StatsCards at 2/3/4 cards, POS ring state)

Want me to continue with PrintAudit and the rest, or pause here?


---

## Summary of what I did

I investigated all three `tech-artificer` repos (read-only) to map their env branches and check for inconsistencies across the four dimensions you selected. No code was changed and nothing was committed or subscribed yet.

### Key finding: the system is a heterogeneous 3-stack product
| Repo | Role | Stack |
|---|---|---|
| `tablet-ordering-pwa` ("grillpad") | Customer tablet ordering PWA | Nuxt 3 / Vue 3 (npm) |
| `woosoo-nexus` | Kitchen Display System + backend | Laravel 12 + Vue 3/Inertia (composer + npm) |
| `woosoo-print-bridge` | Receipt/print bridge | **Flutter / Dart** (pub) |

> The designated branch `claude/upbeat-hypatia-NxNh8` **does not exist** in any repo — nothing to develop; this is purely monitoring + analysis.

### Inconsistencies found

**1. Branch/env drift**
- **tablet-ordering-pwa**: `staging == main` (`b9dd902`), `dev` ahead → PR **#189** dev→staging open (clean).
- **woosoo-nexus**: all three diverge → PR **#142** staging→main open (clean, but large: 101 files, +4863/−26103).
- **woosoo-print-bridge**: all three diverge but **no promotion PR** → drift is untracked. ⚠️ (You chose: report only.)

**2. Cross-repo version/config** (pwa vs nexus — only shared stack)
- `zod`: **v4** (pwa) vs **v3** (nexus) — major mismatch (nexus dependabot #114 would align it).
- tailwind: TW3 (`@nuxtjs/tailwindcss ^6`) vs TW4 (`tailwindcss ^4.1.1`) — major divergence.
- `vue-router` 4 vs 5 (low impact). `vue`, `typescript`, `lucide` minor.
- ✅ Realtime pair that actually crosses pwa↔nexus (`laravel-echo` + `pusher-js`) is aligned.

**3. PR/CI health**
- Both env PRs clean + CI success (CodeRabbit only).
- nexus #142 has an **unchecked doc-governance checklist** — flag before merge.
- pwa **#64** (Capacitor) is stale and worth triaging.

**4. Dependency state (open dependabot PRs)**
- pwa: **7** · nexus: **9** · print-bridge: **0** (Dart).

Full report is saved at `/root/.claude/plans/monitor-these-branches-remotely-silly-anchor.md`.

## Implementation plan (pending your go-ahead)

1. **Subscribe to PR activity** so CI/review/comment events stream into this session:
   - `subscribe_pr_activity` → `tablet-ordering-pwa` **#189**
   - `subscribe_pr_activity` → `woosoo-nexus` **#142**
   - print-bridge: report drift only, watch for a future env PR.
2. **On each incoming event**: investigate; if a CI failure is tractable and in-scope, push a fix to `claude/upbeat-hypatia-NxNh8` (created from the PR head as needed) + open a draft PR; otherwise surface it to you.
3. **Stop on request** via `unsubscribe_pr_activity`.

Want me to go ahead and set up the two subscriptions now? (Optionally I can also persist the report as a GitHub issue — I'll ask before posting anything externally.)


--- 

# Woosoo Kitchen & Admin Display Update — Session Summary

## 1. The Request

The client submitted an **11-point recommendation document** ("Kitchen Display & Admin Display Recommendations") for the Woosoo restaurant system. The points:

| # | Recommendation | Type |
|---|---|---|
| 1 | Bigger / clearer kitchen order cards (readability at distance) | KDS |
| 2 | Simplified Preparing → Served workflow | Status |
| 3 | Clearer action button labels | Status |
| 4 | Stronger overdue/urgency highlighting | KDS/design |
| 5 | Clearer item-level status (check-off) | KDS |
| 6 | Richer dashboard insights | Admin |
| 7 | Better orders page (statuses + filters) | Admin |
| 8 | Better device page (prioritization) | Admin |
| 9 | Higher sidebar contrast | Design |
| 10 | Branch & sync status | Admin |
| 11 | Overall "fast, readable, premium dark" direction | Principle |

The task was to **analyze, plan, and create the planning artifacts** (GitHub issues + a client-facing brief + timeline) — **not to write code**.

---

## 2. Work Completed

### 2.1 Codebase & architecture analysis
- Explored `tech-artificer/woosoo-nexus` (Laravel 11 + Inertia + Vue 3) and mapped the cross-project system: **Nexus** (backend/admin/KDS/Reverb hub, ~90% of the work), **tablet-ordering-pwa** (Nuxt 3, verify-only), **woosoo-print-bridge** (Flutter relay, verify-only), **Krypton POS** (external source-of-truth DB, no change).
- Documented the **communication architecture** — REST (Sanctum device auth), WSS (Laravel Reverb: `admin.orders`, `device.{id}`, `orders.{id}`, `admin.print`), POS dual-write, and the feature-flagged print-bridge path.
- Key clarification: the client's "Kitchen Display" = the **new KDS wall screen** (issue #137), *not* the `KitchenTicket.vue` print template.

### 2.2 Key design decision — order statuses
Chose the **Workflow layer** approach:
- Keep the canonical 9-state `OrderStatus` enum (POS/contract-safe, no data migration).
- Add a `WorkflowStage` presentation mapping (Pending → Preparing → Served + Voided/Cancelled), **2 additive transitions** (`pending→in_progress`, `in_progress→served`), and centralized button labels.
- Retire the divergent `types/enums.d.ts` enum.
- Rejected the riskier "collapse the enum" option.

### 2.3 GitHub issues created (the planning layer — all 11 points tracked)

| Issue | Scope |
|---|---|
| **#143** PR-0A | Status workflow foundation (`WorkflowStage`, transitions, labels, payload field) |
| **#144** PR-0B | Design/readability tokens (type ramp, overdue tokens, scoped sidebar contrast) |
| **#145** PR-4 | Dashboard insights (AOV, best-seller, peak hour, sales deltas, alerts) |
| **#146** PR-5 | Orders page statuses + filters |
| **#147** PR-6 | Device page prioritization (offline-first, battery, sync age, version) |
| **#148** PR-7 | Branch & sync status |
| **#137** (existing) | KDS v1.0 — posted a **coordination comment** (drop "Confirm·Start", consume #143's transitions/labels, use #144 tokens) |

### 2.4 Client-facing materials
- **Non-technical brief** ready to send — frames the quick wins vs. the involved pieces, reassures that customer tablets/printer/POS are undisturbed.
- **Realistic timeline:** ~**7–11 calendar weeks** solo full-stack (≈34–54 dev-days incl. integration/UAT). KDS alone ≈40% of effort. First visible kitchen improvements in **2–3 weeks**.
- **AI-assisted variant:** ~2.5–4.5 weeks including usage-limit friction.
- Reconciled the external "40-hour" estimate → that figure is KDS (#137) coding-only, not all 11 points.
- Documented **risks** driving the high end: KDS is a new screen; fragile on-site Raspberry Pi deploys (#136); dashboard depends on POS data quality; multi-branch is future-facing; limited live-testing windows; recommended channel-security hardening.

### 2.5 Consistency review (verified against source)
Reviewed all issues for event/dispatch/channel and Krypton/POS-ID correctness. Verified facts:
- `OrderBroadcastPayload::make()` exposes both local `id` and POS `order_id`; items key on local `id`; **no `done`/`done_at` today**.
- Order events are `ShouldBroadcastNow` on a **public** `Channel('admin.orders')` → the `is_admin` auth callback in `channels.php` is **not enforced** (security gap).
- `PrintOrder` uses a different item shape (`menu_id`).
- Full `canTransitionTo()` matrix mapped.

This produced **4 staged-but-unapplied issue edits** (full text in the plan file).

---

## 3. Implementation Plan (pending — no code written)

### Layer A — apply 4 staged issue edits
1. **#143** — declare it owns the *entire* `canTransitionTo()` matrix (3 new edges incl. `served→in_progress` Recall) + the canonical `OrderBroadcastPayload` shape (`workflow_stage`).
2. **#137** — follow-up comment: extend (don't fork) the payload; add `done`/`done_at` to item lines + timestamps; key `ItemToggled` on local `id`; bump/recall must carry item freshness; exact `broadcastAs('item.toggled')`; flag the public-channel auth gap (recommend `PrivateChannel`).
3. **#145** — identify packages by `krypton_menu_id` on `type='package'` lines (not `packages.id`/name); avoid `ordered_menu_id` double-count; exclude modifier/meat lines; source "print failures" from heartbeat (PrintEvent flow is flagged off).
4. **#146** — facet on the *same* package identifier as #145; never mix `id`/`order_id`; consume #143's `WorkflowStage`.

### Layer B — build in dependency order
```
#143 (PR-0A) ──▶ unblocks #137, #146     ← first
#144 (PR-0B) ──▶ unblocks #137, #147 styling
#137 (KDS)    ── largest piece (~40% effort)
#146 / #145 / #147 / #148  ── after foundations
```
Each issue → one reviewable PR on `claude/exciting-dirac-viMZ2`, with tests + lint/typecheck green before opening.

### Verification approach
- Confirm issue edits landed (`list_issues` / `issue_read`).
- Only **one** PR (#143) edits `canTransitionTo()` and defines the payload shape.
- #145 and #146 reference the **same** package identifier.
- Backend: PHPUnit incl. `StatusParityTest`. Frontend: typecheck + lint. End-to-end: live Reverb broadcast → KDS render.

---

## 4. State at Session End
- ✅ 6 issues created (#143–#148) + #137 coordination comment posted.
- ✅ Client brief + timelines + risk analysis complete.
- ✅ Consistency review done; 4 edits staged.
- ⏳ **Pending:** apply the 4 staged issue edits, then begin implementation at #143.
- 📄 Full detail preserved in the plan file: `/root/.claude/plans/root-claude-uploads-952e55fd-813e-4350-fancy-pumpkin.md`.

No code was changed and no PR was opened during this session.


-- plan: # Woosoo Kitchen & Admin Display Update — Full Cross-Project Plan + Client Brief

## Context

The client sent an 11-point recommendation doc (`Kitchen Display & Admin Display
Recommendations`). It asks for: bigger/clearer kitchen order cards, a simplified
Preparing/Served workflow, clearer buttons, stronger overdue alerts, clearer
item-level status, richer dashboard insights, better orders/device pages, higher
sidebar contrast, branch/sync status, and an overall "fast, readable, premium
dark" direction.

This plan (a) breaks the request into work by **project**, (b) documents **how
the projects communicate**, (c) gives a **realistic timeline for one full-stack
developer**, and (d) keeps the immediate concrete deliverable: **create the
PR-0A and PR-0B GitHub issues** on `tech-artificer/woosoo-nexus`.

Confirmed decisions:
- Status strategy = **Workflow layer** (keep the canonical 9-state `OrderStatus`
  enum; add a presentation mapping + 2 additive transitions + centralized labels;
  no data migration, no contract break). Retire the divergent `enums.d.ts` enum
  in PR-0A.
- Timeline: solo full-stack dev, single low/high range with risks.
- Other repos (tablet PWA, print-bridge) aren't in this environment — their share
  is **estimated from the documented contracts in Nexus and marked provisional**.

---

## Projects involved & boundaries

| Project | Stack | Role | Share of this work |
|---|---|---|---|
| **woosoo-nexus** | Laravel 11 + Inertia + Vue 3 | Backend API, admin UI, **KDS**, Reverb hub | ~90% — almost everything |
| **tablet-ordering-pwa** | Nuxt 3 | Customer tablet ordering | Light — verify status display still correct; optional label parity |
| **woosoo-print-bridge** | Flutter/Dart relay | Physical printing | Verify-only — unaffected by these changes (MVP keeps it primary) |
| **Krypton POS** | External DB | Source of truth for orders/pricing | No change — verify counts still reconcile |

**Key clarification:** the client's "Kitchen Display" = the **new KDS wall screen**
already specced in issue **#137** (a Nexus admin Vue page), *not* the
`KitchenTicket.vue` print-receipt template. Recommendations #1–#5 are the KDS;
#6–#10 are existing admin pages; #11 is a guiding principle.

---

## Communication architecture (who talks to whom)

```
 Customer Tablet (PWA) ──HTTPS REST──▶ Nexus API     (create-order, refill, menus, session)
        ▲   │                              │
        │   └──WSS (Reverb/Echo)──▶ device.{id}, orders.{id}   (order.created/updated/voided/completed)
        │
 Nexus Admin UI / KDS ──WSS──▶ admin.orders, admin.print       (live queue + print stream)
        │
 Nexus ──dual-write (POS-first)──▶ Krypton POS DB              (orders, checks, ordered_menus)
        │   ▲ read-only menu/session/report sync
        │
 Print-Bridge relay ──REST poll + WSS + heartbeat──▶ Nexus     (admin.print / order.printed)  [feature-flagged]
```

- **Real-time:** Laravel Reverb broadcasts `OrderCreated/StatusUpdated/Voided/
  Completed` (all `ShouldBroadcastNow`) via `app/Helpers/OrderBroadcastPayload.php`
  on channels defined in `routes/channels.php` (`admin.orders`, `device.{id}`,
  `orders.{id}`, `admin.print`). Frontend Echo client in `resources/js/app.ts`.
- **REST:** `routes/api.php` — device-auth (Sanctum) order/menu/session/print
  endpoints; idempotency on create/refill.
- **POS:** dual DB connection (`pos`); POS is authoritative, Nexus mirrors. Void/
  pay in POS drive `device_orders.status` → broadcast.
- **Print:** `NEXUS_PRINT_EVENTS_ENABLED=false` by default; print-bridge is the
  active path (issue #107).

**Impact of this work on the contracts:** the only cross-project change is PR-0A
adding an **additive `workflow_stage` field** to the order broadcast/resource
payload — backward compatible. Everything else is Nexus-internal UI/data.

---

## Work breakdown by project

### A. woosoo-nexus (the bulk)

**PR-0A — Status workflow foundation** *(create issue now)*
- New `app/Enums/WorkflowStage.php`; `OrderStatus::stage()` mapping (pending|confirmed→Pending"New", in_progress|ready→Preparing, served|completed→Served, voided→Voided, cancelled→Cancelled, archived→hidden).
- Additive transitions in `OrderStatus::canTransitionTo()`: `pending→in_progress`, `in_progress→served`.
- Expose `workflow_stage` in `OrderBroadcastPayload.php` + `DeviceOrderResource.php`.
- FE: `toWorkflowStage()` + `primaryActionForStage()` in `constants/statuses.ts`; rework `OrderStatusBadge.vue`; 5-stage options in `DataTableToolbar.vue`; stage-aware `filterFn` in `columns.ts` (currently exact-match, lines 97-100); replace hardcoded checks in `OrderDetailSheet.vue` (122-124).
- Remove divergent `types/enums.d.ts` `OrderStatus` (sole importer `models.d.ts:2`).
- Parity test alongside `tests/Unit/StatusParityTest.php`.
- Addresses PDF #2, #3, #7.

**PR-0B — Design & readability foundation** *(create issue now)*
- `resources/css/app.css` `@theme`: distance-read type ramp (`--text-kds-*`, timer/table ≥22px per #137 NFR-U-02); overdue tokens (`--overdue`, `--overdue-foreground`, border-weight) + `@keyframes overdue-pulse`; **scoped** sidebar contrast bump (prefer a sidebar token over a global `--muted-foreground` shift). All additive.
- Addresses PDF #1 (tokens), #4 (urgency tokens), #9 (contrast).

**KDS v1.0 — issue #137** (the largest piece; recommendations #1, #4, #5)
- New `resources/js/pages/KDS/Display.vue` + `components/kds/*`; one shared timer composable; Echo subscription; filter chips + sort; per-item tap toggle; overdue pulse; audio chime; density toggle; void modal.
- Backend: 5 thin endpoints (`confirm/bump/recall/void/toggleItem`), additive migration (`done`, `done_at` on `device_order_items`), new `ItemToggled` event, `OrderUpdateLog` audit reuse.
- Builds on PR-0A (stage + labels + transitions) and PR-0B (type/overdue tokens).

**Dashboard insights — PDF #6** (`pages/Dashboard.vue` + `DashboardController`)
- New aggregates: average order value, best-selling package, peak-hour indicator, sales vs yesterday/last week, orders completed today, and an "issues needing attention" panel (offline tablets / low battery / print failures — sourced from heartbeat + `MonitoringController` data).

**Orders page — PDF #7** (`pages/Orders/*`)
- Surface the 5 workflow stages (from PR-0A) + filters by table, status, package, time, and voided/cancelled.

**Device page — PDF #8** (`pages/Devices/*` + controller)
- Sort offline-first; stronger low-battery warning; "last synced / offline for N min"; outdated-app-version badge; keep battery/IP/version/restart. Uses existing heartbeat data.

**Sidebar contrast — PDF #9** — folded into PR-0B.

**Branch & sync status — PDF #10** (`AppSidebar.vue`/topbar + small endpoint)
- Current branch, online status, last-sync time. **Data-limited today** (HQ-only); multi-branch is future, so partly a forward-looking placeholder.

### B. tablet-ordering-pwa (provisional — verify)
- Consumes the additive `workflow_stage` (optional). Regression-verify customer status display still renders under the new transitions. Optional: mirror simplified labels for customer-facing consistency. **~0.5–1 day, provisional.**

### C. woosoo-print-bridge (provisional — verify-only)
- No functional change; listens to `admin.print`. Confirm KDS/item-toggle work doesn't disturb the print stream. **~0.5 day, provisional.**

### D. Krypton POS — no change
- Canonical statuses untouched by design; verify dashboard/monitoring counts still reconcile.

---

## Mapping: each recommendation → project → complexity

| # | Request | Project(s) | Complexity |
|---|---|---|---|
| 1 | Kitchen readability | Nexus (KDS + 0B) | Med |
| 2 | Simplified workflow | Nexus (0A) | Med |
| 3 | Button labels | Nexus (0A) | Low |
| 4 | Overdue highlight | Nexus (0B + KDS) | Low–Med |
| 5 | Item-level status | Nexus (KDS, +migration) | Med |
| 6 | Dashboard insights | Nexus + POS data | **High** |
| 7 | Orders filters | Nexus (0A) | Low–Med |
| 8 | Device page | Nexus | Med |
| 9 | Sidebar contrast | Nexus (0B) | Low |
| 10 | Branch/sync | Nexus (data-limited) | Med |
| 11 | General direction | — | principle |

---

## Effort & timeline (internal breakdown, solo full-stack)

| Item | Low | High |
|---|---|---|
| PR-0A status foundation | 3d | 5d |
| PR-0B design tokens + sidebar | 2d | 3d |
| KDS v1.0 (#137) | 10d | 15d |
| Dashboard insights | 4d | 6d |
| Orders page filters | 2d | 3d |
| Device page | 3d | 5d |
| Branch/sync status | 2d | 4d |
| Tablet PWA verify (provisional) | 0.5d | 1d |
| Print-bridge verify (provisional) | 0.5d | 1d |
| **Subtotal (dev-days)** | **27d** | **43d** |
| + integration/UAT/deploy/review (~25%) | ~7d | ~11d |
| **Total** | **~34 dev-days** | **~54 dev-days** |

→ For one full-stack developer that's roughly **7 to 11 calendar weeks**. KDS
alone is ~40% of the effort. Foundations + first visible kitchen improvements
land in the first ~2–3 weeks.

---

## Risks (drive the high end)

1. **KDS is a new screen, not a tweak** — the single biggest chunk; scope creep on flags/sounds/density can extend it.
2. **On-site Raspberry Pi deployment is fragile** — issue #136: WiFi drops mid-build cause failed deploys; shipping to the restaurant is slower/riskier than normal.
3. **Dashboard metrics depend on POS data quality** — best-selling package / peak hour need new queries validated against Krypton; data gaps add time.
4. **Multi-branch/sync is future-facing** — only HQ exists today, so part of #10 is a placeholder until more branches come online.
5. **Limited live testing windows** — verifying kitchen behavior during real peak hours is constrained; UAT adds calendar time.
6. **Recommended security hardening** — making the real-time channels private (long-term reqs Phase 1) is a sensible prerequisite that adds a little time but protects the client.

---

## Client-facing brief (non-technical, ready to send)

> **Subject: Your requested Kitchen Display & Admin updates — what's involved and how long**
>
> Thanks for the detailed feedback — it's clear and we can do all of it. Here's an
> honest picture of what each part takes.
>
> **The good news:** most of your requests are improvements to one system (the
> Woosoo admin/kitchen app). They won't disrupt the customer tablets, the printer,
> or your POS — those keep working as they are.
>
> **What's quick and low-risk** (visible early):
> - Clearer, larger kitchen text and stronger "overdue" highlighting
> - Simpler buttons ("Start Preparing" / "Mark as Served") and the simpler
>   Preparing → Served workflow
> - Higher-contrast sidebar, clearer order statuses and filters
>
> **What's more involved:**
> - The **Kitchen Display itself is effectively a new screen** (live order queue,
>   timers, tap-to-update, item check-off, overdue alerts). It's the single largest
>   piece — roughly 40% of the work.
> - The **richer dashboard** (average order value, best-selling package, peak hour,
>   sales vs last week, alerts for offline/low-battery tablets) needs new data
>   pulled and validated from your POS, so it takes longer and depends on the data
>   being clean.
> - **Branch / sync status** can be shown now, but full multi-branch only becomes
>   meaningful once you actually run more than the HQ branch.
>
> **Realistic timeline (one developer):** about **7 to 11 weeks** for the complete
> set, delivered in stages so you see the kitchen readability and workflow
> improvements within the **first 2–3 weeks** rather than waiting for everything.
>
> **What could push it toward the higher end:** the on-site Raspberry Pi has had
> unreliable internet during updates (making deployments slower), the dashboard
> insights depend on POS data quality, and testing kitchen changes has to fit
> around live service hours.
>
> We'll keep the premium dark look throughout — the goal is exactly what you said:
> good-looking *and* fast and readable during a busy service.

---

## Immediate deliverable (this task): create PR-0A & PR-0B issues

Create two issues via `mcp__github__issue_write` (method `create`) on
`tech-artificer/woosoo-nexus`, labels `enhancement`,`kds`, each containing the
Context / Changes / Removals / Challenges / Affected / Acceptance-Criteria detail
from the PR-0A and PR-0B sections above, plus the roadmap list and a link to #137.
No code changes; no PR.

## Verification
1. Confirm both issues exist via `mcp__github__list_issues`; capture numbers/URLs.
2. Each carries agreed title, labels, all sections, and links #137.
3. No code changed, no PR opened.

---

# Consistency review — staged issue edits (events / dispatch / channels / Krypton IDs)

Review of the open issues (#143, #144, #137, #145, #146, #147, #148) focused on event/dispatch/channel handling and Krypton/POS-ID handling. Findings below are verified against source; the staged edits make each issue self-consistent **when applied**. User pre-approved "apply all."

## Verified facts (source)
- `OrderBroadcastPayload::make()` (`app/Helpers/OrderBroadcastPayload.php:9-55`) exposes both `id` (local `device_orders.id`, L17) and `order_id` (POS `orders.id`, L18); item lines key on local `id` (L44) and already carry `type` (L51); **no `done`/`done_at`** today.
- Order events are `ShouldBroadcastNow`, broadcast on **public** `new Channel('admin.orders')` (`OrderStatusUpdated.php:36`, `PrintOrder.php:34`) with broadcastAs `order.updated`/`order.printed`. `PrintOrder` uses a *different* item shape (`menu_id`, L64-72).
- `channels.php:30` authorizes `admin.orders` on `is_admin` — but since the events use a **public** `Channel`, that callback is **not enforced** (public channels skip auth).
- Transition matrix `OrderStatus::canTransitionTo()` (`OrderStatus.php:19-29`): `pending→[confirmed,voided,cancelled]`, `confirmed→[in_progress,completed,voided]`, `in_progress→[ready,voided]`, `ready→[served,voided]`, `served→[completed,voided]`, terminals false.

## Edit 1 — #143 (PR-0A): declare ownership of matrix + payload shape
Add a **"Owns / coordination"** note:
- #143 owns **all** `canTransitionTo()` edits — land the 3 new edges here: `pending→in_progress`, `in_progress→served`, **and** `served→in_progress` (Recall, consumed by #137). #137 must not re-edit the matrix.
- #143 establishes the **canonical `OrderBroadcastPayload` shape** (adds `workflow_stage`). #137 *extends* item lines with `done`/`done_at` on top — it must not redefine the method. Whichever merges second rebases onto the other.

## Edit 2 — #137 (KDS): second comment, event/dispatch/payload consistency
Post a follow-up comment covering:
- **Payload single-source:** extend the shape #143 establishes; add `done`/`done_at` to the item map (and `confirmed_at`/`served_at`/`issued_at` top-level) — don't fork `OrderBroadcastPayload`.
- **`ItemToggled` keying:** payload must include local **`id`** (`device_orders.id`), not only POS `order_id`; `item_id` must equal local `device_order_items.id` (matches `items[].id`). KDS reactive map must key on the **same** id `confirm/bump/recall` route-bind (local). Otherwise toggles silently no-op.
- **bump/recall freshness:** since `bump`/`recall` mutate every item's `done` and dispatch the *full* `OrderStatusUpdated`, the payload must carry item `done`/`done_at` or KDS checkboxes go stale until refresh (depends on the payload extension above).
- **Event contract:** `ItemToggled` = `ShouldBroadcastNow`, on `admin.orders`, exact `broadcastAs('item.toggled')` matching the `useKdsEcho` listener string. KDS must ignore `order.printed` (different shape).
- **Security (pre-existing, flag):** order events broadcast on a **public** `Channel('admin.orders')`, so the `is_admin` callback isn't enforced — kitchen data is effectively unauthenticated. KDS widens this exposure; recommend promoting to `PrivateChannel` (long-term-reqs Phase 1) as part of/just before KDS.
- **Matrix:** all transition edges land in #143 (above); drop the inline enum tweak here.

## Edit 3 — #145 (Dashboard best-seller): Krypton/POS ID handling section
Add:
- **Identify packages by the Krypton menu id on package lines** — `device_order_items.krypton_menu_id` filtered to `type = 'package'` (verify field names). **Not** local `packages.id` (46/47/48) and **not** by name (name-matching is fragile and mid-consolidation per #106).
- **Do not group by `ordered_menu_id`** — its semantics differ for initial vs refill orders (krypton audit; planned `pos_ordered_menu_id`), which double-counts. Group by package id, count distinct package lines, and handle refills explicitly (`is_refill`).
- **Exclude modifier/meat lines** (`menu_group_id = 34`, ids ~114-134) so they don't pollute package counts.
- **Reuse the existing `ReportRepository` grouping field** for parity with current sales reports.
- **"Print failures" alert:** the PrintEvent flow is feature-flagged **off** (`NEXUS_PRINT_EVENTS_ENABLED=false`, #107) — source the signal from the print-bridge **heartbeat** (`status.queue_failed`) / `MonitoringController`, not the disabled PrintEvent table, or it always reads zero.

## Edit 4 — #146 (Orders package filter): Krypton/POS ID handling section
Add:
- **Facet on the same canonical package identifier as #145** (`krypton_menu_id` on `type='package'` lines) — define once, shared with the dashboard.
- An order has **no single package id** — derive from its package-type item line(s); confirm the join.
- **Order key consistency:** web route-binds local `id`; the filter/query must not mix `id` vs `order_id`.
- Status filter consumes #143's `WorkflowStage` (don't re-derive).

## Verification of these edits
1. After applying: #143 body states matrix + payload ownership; #137 has the 2nd consistency comment; #145/#146 each carry a Krypton-ID handling section; counts/acceptance updated.
2. Cross-check: only **one** PR (#143) edits `canTransitionTo()` and defines the payload shape; #145 and #146 reference the **same** package identifier.
3. Re-list issues to confirm edits landed. No code changes.

---

# Woosoo Platform — Session Summary
**Date:** 2026-05-31  
**Branch worked on:** `claude/laughing-maxwell-fsY1N`  
**PRs:** #24 (merged), #23 (open, staging → main)

---

## 1. Business Documentation Created

### `docs/business/WOOSOO_ORIGIN_SPECIFICATION.md`
- Formalized the original May 20XX signed client brief as an archived reference document
- Preserves original contract terms: ₱350,000, 30/30/30/10 payment milestones, 24-month free support
- Covers: KDS workflow, tablet ordering, staff call buttons, admin backend, POS integration
- **Key correction:** Editorial note explicitly states the KDS was replaced **at the client's request** by Woosoo Print Bridge — not a developer architectural decision
- `status: archived`, `archived_reason` includes client-initiated substitution context

### `docs/business/WOOSOO_SPEC_DELTA.md`
Feature-by-feature comparison of origin spec vs. current system plus full project cost analysis.

**Cost structure corrected (two rounds of user feedback):**

| Line Item | Amount | Notes |
|---|---|---|
| Original signed contract | ₱350,000 | 3-man team quote |
| Additional billed — Pi configuration | ₱25,000 | Only additional invoice |
| **Total actually billed** | **₱375,000** | Client invoice total |
| Estimated fair market value | ₱875,000 | Reference only — not invoiced |
| Scope absorbed by developer | ~₱500,000 | Uncompensated additions |

**Section 3.3 restructured into two sub-sections:**
- **3.3a — Client-Requested Scope Changes:** Print Bridge (₱150,000) — client asked to replace KDS with Bluetooth printing
- **3.3b — Developer-Added Scope (at no charge):** Reverb (₱75k), Docker orchestration (₱75k), advanced admin UI (₱80k), RBAC (₱75k), service requests (₱45k), POS hardening (₱25k)

**New Section 6 — Pending Change Orders:**
- **CO-001:** KDS Re-addition — client wants KDS back alongside the existing Print Bridge after staff/customer testing. Second client-initiated scope change; Reverb infrastructure already in place. Quoted at **₱100,000** (display UI ₱40k / staff controls ₱25k / multi-station routing ₱20k / on-site setup ₱15k)

### `docs/business/WOOSOO_PLATFORM_BRD_SUPPLEMENT.md`
- Created to complement PR #138 in `tech-artificer/woosoo-nexus` which documented the three functional apps but omitted woosoo-platform entirely
- Documents woosoo-platform as the **4th system component**: governance, orchestration, AI agent OS, cross-app contracts, deployment authority
- Covers: Docker Compose topology (8 services), Nginx multi-port routing, 5 cross-app contracts, 4-agent AI operating system, case file resume/handoff protocol
- ~580 lines; `status: canonical`

### `docs/README.md`
- Added **Business Requirements Documents** section indexing all three new docs with brief descriptions

---

## 2. PR #24 — Branch to Staging

**Branch:** `claude/laughing-maxwell-fsY1N` → `staging`  
**Status:** **Merged** ✅

**Commits on branch:**
| Commit | Description |
|---|---|
| `c8db0e0` | docs: add woosoo-platform BRD supplement and index it |
| `db8059b` | docs: add origin specification, spec delta, and project cost analysis |
| `165bbe3` | docs: correct KDS attribution, actual billing, and add KDS change order |
| `6530921` | fix(docs): clarify Nexus BRD is an external cross-repo reference |

**PR #24 review fix:**
- `WOOSOO_SPEC_DELTA.md` line 10 had a broken local path reference to `docs/business/NEXUS_BUSINESS_REQUIREMENTS_DOCUMENT.md` — corrected to explicitly note `tech-artificer/woosoo-nexus — docs/business/NEXUS_BUSINESS_REQUIREMENTS_DOCUMENT.md (draft PR #138, external repo)`

---

## 3. PR #23 — Staging to Main (ongoing)

**Status:** Open — multiple rounds of review fixes pushed directly to staging

### Round 1 fixes (commit `e1bbdcc` to staging)
Four files fixed in one push:

| File | Fix |
|---|---|
| `.codex/agents/contrarian.toml` | CRLF → LF normalization (stray `\r` in multiline strings) |
| `.codex/agents/ranpo-backend.toml` | CRLF → LF normalization |
| `.codex/agents/dazai-docs.toml` | Scope exclusion `.Codex/**` → `.codex/**` (case-sensitive fix); added `.agents/skills/**` |
| `docs/cases/public-user-manual-product-spec-look.md` | `status: IN_PROGRESS` → `COMPLETE`, `next_agent: none` → `done`, `updated: 2026-05-30` → `2026-05-30 09:05`, Executioner Verdict restructured with `Verdict:` / `### Reason` / `### Required Next Action` subheadings |

### Round 2 fixes (commit `41e769` to staging)
Two files pushed:

**`docs/deployment/DEPLOYMENT_GUIDE.md` — Layout correction (P1 blocker resolved)**

Root cause: All deploy scripts (`deploy.sh`, `dev-docker-bootstrap.sh`) resolve `NEXUS_DIR = $PLATFORM_ROOT/woosoo-nexus` — app repos are **nested inside** the platform directory. `woosoo.env.example` confirmed `WOOSOO_NEXUS_PATH="/opt/woosoo/woosoo-platform/woosoo-nexus"`. Section 3.2 was already correct; sections 2, 3.1, 3.4, 4.1, 4.2 all showed wrong sibling cloning.

Changes:
- **Section 2:** Tree changed from `parent/ ├── woosoo-platform/ ├── woosoo-nexus/` to `woosoo-platform/ ├── woosoo-nexus/ └── tablet-ordering-pwa/`; prose changed from "side-by-side" to "inside the platform repo root"
- **Section 3.1:** Added `cd woosoo-platform` between cloning platform and cloning app repos
- **Section 3.4:** Removed "sibling" wording
- **Section 4.1:** Same clone order fix for dev setup
- **Section 4.2:** Changed `cd ~/projects/woosoo-nexus && git pull && cd -` to `cd woosoo-nexus && git pull && cd ..` (relative paths from inside platform dir)

**`docs/cases/public-user-manual-product-spec-look.md`** — Three CodeRabbit schema fixes:
- `next_agent: none` → `next_agent: done`
- `updated: 2026-05-30` → `updated: 2026-05-30 09:05`
- Executioner Verdict block restructured

### Pending CodeRabbit nitpicks (3 items, all marked 💤 Low value)

| File | Issue | Proposed Fix |
|---|---|---|
| `docs/cases/nex-case-002-pulse-routes.md` | `status: COMPLETE` in frontmatter — non-standard; should be `status: canonical` (Run State holds lifecycle status) | Change frontmatter field |
| `docs/cases/nexus-vite-entrypoint-rebuild.md` | Empty Handoff section in completed case | Replace placeholders with "N/A — task complete" |
| `docs/deployment/DEPLOYMENT_GUIDE.md` §3.3 | No guidance on detecting schema changes before `php artisan migrate` | Add: check `git diff --name-only` against `database/migrations/` |

---

## 4. Queue Audit — Remote Dev Branch Review

Fetched last 12–30 commits from all three app repo dev branches via GitHub API.

### woosoo-nexus dev (notable commits since 2026-05-21)

| SHA | Message | Queue Impact |
|---|---|---|
| `417ebc9` | test(pulse): lock /pulse authorization contract | **NEX-CASE-002 RESOLVED** — cannot-reproduce; auth test added (unauthenticated/non-admin → 403, admin → 200) |
| `4aa2470` | fix(events): SessionReset implements ShouldBroadcastNow | Addresses CLAUDE.local.md bug #4 (dropped broadcasts on zombie WebSocket); already shipped |
| `f4c6649` | docs: add professional BRD for Woosoo Nexus | BRD added in nexus repo (complement to platform BRD supplement) |
| `360641d`–`925de83` | style(nexus): brand alignment (amber/flat sidebar) | Design work, not tracked in queue |
| `c64e2a8` / `355bd08` | feat(infra): conditional Vite build in entrypoint | Infrastructure improvement; new case `nexus-vite-entrypoint-rebuild` appeared on staging |

**No commits touching `client_submission_id`, legacy print path, or idempotency** → **NEX-CASE-005 still open and relevant.**

### tablet-ordering-pwa dev (notable commits since 2026-05-21)

| SHA | Message | Queue Impact |
|---|---|---|
| `5dbee79` | docs: add order-flow UX revamp implementation plan | New planned work — potential new case |
| `f66abf0` | chore: remove duplicate, dead, and bloat files | Cleanup pass, matches dead-code-cleanup skill pattern |

### woosoo-print-bridge dev (notable commits since 2026-05-21)

| SHA | Message | Queue Impact |
|---|---|---|
| `4f52977` | Receipt Time Fix | Not tracked in platform queue |
| `830fdfd` | fix(latency): faster polling + longer HTTP timeouts | Merged to dev; **APK still not rebuilt/installed** (CLAUDE.local.md bug #5) |

### New case files discovered on staging (added independently)

| File | Description |
|---|---|
| `docs/cases/nex-case-002-pulse-routes.md` | Updated to COMPLETE (matches nexus dev finding) |
| `docs/cases/nexus-vite-entrypoint-rebuild.md` | New — Vite entrypoint rebuild case |
| `docs/cases/infra-vite-build-conditional.md` | New — conditional Vite build infra case |
| `docs/cases/HANDOFF-infra-vite-build-conditional.md` | Handoff doc for above |
| `docs/cases/nex-case-010-immutable-image-production-migration.md` | New — immutable image production migration case |

---

## 5. Pending Implementation Plan

### Step 1 — Fix remaining CodeRabbit nitpicks (push to staging)
Three files, all low-risk docs-only changes.

### Step 2 — Queue reconciliation (push to staging)
- `state/QUEUE.md` — NEX-CASE-002 `queued` → `done`
- `state/DONE.md` — append NEX-CASE-002 with evidence (`417ebc9`, cannot-reproduce, auth test locked)
- `state/WORK.md` — set active task to PLT-CASE-003

### Step 3 — PLT-CASE-003 Phase 1: Contract Freeze & Versioning (new branch)
**Branch:** `agent/plt-case-003-cross-app-orchestration`

Add to all 5 contracts in `contracts/`:
```yaml
version: 1.0.0
frozen_as_of: 2026-05-30
```
Plus `## Changelog` section with initial v1.0.0 entry. Purpose: make contract changes auditable — currently any drift leaves no version trail for consuming apps.

Files: `auth-session.contract.md`, `order-state.contract.md`, `pos-db.contract.md`, `printer-relay.contract.md`, `tablet-api.contract.md`

**PLT-CASE-003 Phase 2 (observability)** → `SPLIT_REQUIRED` — requires changes across all three app repos which aren't cloned in this environment. Must be filed as three separate per-app cases when those repos are accessible.

---

## 6. Open Items Not Addressed This Session

| Item | Severity | Source |
|---|---|---|
| NEX-CASE-005: Legacy non-idempotent print path (`client_submission_id` absent) | P2 | Queue |
| PLT-CASE-003 Phase 2: Cross-app observability (request IDs, structured logs) | P3 | Queue — SPLIT_REQUIRED |
| Print bridge APK rebuild + install (`830fdfd`) | Medium | CLAUDE.local.md bug #5 |
| Tablet UX revamp (order-flow plan doc added to tablet dev) | TBD | New, needs intake |
| Print bridge Receipt Time Fix (`4f52977`) tracking | Low | Not in platform queue |
| `SessionReset` per-order blast in `PosOrderStatusFinalizer` | Critical | CLAUDE.local.md bug #1 |
| Two bad test assertions masking per-order blast | Critical | CLAUDE.local.md bug #2 |
| `UpdateDeviceLastSeen` middleware (device last_seen_at stale) | Medium | CLAUDE.local.md bug #3 |

---

*Session ended. All committed work is on `staging`. PR #23 remains open pending merge to `main`.*

--- 

# Session Summary — Woosoo Nexus Design Implementation
**Date:** 2026-05-31
**Session ID:** claude-sonnet-4-6

---

## Overview

The user exported a design bundle from Claude Design and asked for an implementation of the **Tablet Categories** and **Packages** UI/UX from the Woosoo Admin prototype into the `woosoo-nexus` production codebase.

---

## Repository Structure

```
/home/claude/repo/
├── README.md              — Handoff instructions (read-first guide)
├── chats/
│   ├── chat1.md           — Design discovery + codebase mapping session
│   └── chat2.md           — Login page redesign session
└── project/
    ├── Woosoo Admin.html  — Main interactive prototype (React 18 + Babel CDN)
    ├── admin-core.jsx     — Shared data + Icon/Pill/Btn components
    ├── admin-screens.jsx  — TabletCategoriesScreen + other screens
    ├── admin-app.jsx      — PackagesScreen, POSScreen, App root, NAV config
    ├── admin.css          — Older blue-tinted theme (deprecated)
    ├── styles.css         — Design system token export
    ├── MIGRATION.md       — 8-phase Vue migration guide
    └── images/            — Food photography + logo assets
```

---

## Design System (From `Woosoo Admin.html`)

| Token | Value |
|---|---|
| `--bg0` | `#0d0b09` (page bg, near-black warm) |
| `--bg2` | `#1b1815` (card bg) |
| `--accent` | `#F6B56D` (amber/persimmon) |
| `--accm` | `#2a1e0c` (accent muted bg) |
| `--green` | `#6ea868` |
| `--red` | `#c94f40` |
| `--font-d` | Raleway (display/headers) |
| `--font-s` | Kanit (body) |
| `--font-m` | JetBrains Mono (numbers/mono) |
| `--r-xl` | `14px` (card border radius) |

Light theme is supported; sidebar stays dark in both themes.

---

## Target Production Codebase

**Repo:** `tech-artificer/woosoo-nexus` (GitHub, not present locally)
**Stack:** Laravel 12 + Vue 3 + Inertia.js + Tailwind v4 + shadcn-vue + TanStack Table + Lucide icons + Vue Sonner toasts + Laravel Echo/Pusher WebSockets

---

## Chat Transcript Findings

### `chat1.md` — Design Discovery
- Assistant accessed GitHub repo, mapped both `main` and `dev` branches
- Identified all 13 pages: Dashboard, Orders, POS, Menus, Packages, Devices, Tablet Categories, Users, Roles, Permissions, Reports, Monitoring, Configuration, Settings
- Generated `MIGRATION.md` — an 8-phase, PR-by-PR migration playbook:
  1. CSS token aliases
  2. Badge/pill variants
  3. Sidebar polish (amber active bar, eyebrow labels)
  4. Topbar (52px, 3-zone)
  5. Dashboard KPI cards
  6. Orders kanban (new feature)
  7. POS table grid reskin
  8. Drawers/dialogs/toasts

### `chat2.md` — Login Page Redesign
- User asked to update login page to match Woosoo Admin look and feel
- Transcript was cut off mid-session; no final output visible

---

## Existing Prototype Screens

### `PackagesScreen` (`admin-app.jsx`, lines 166–258)
- Two tabs: **Packages** and **Package Configs**
- **Packages tab:** 3-column grid (`.pkg-grid`) of 3 cards:
  - Classic Feast (Entry Tier, ₱449)
  - Noble Selection (Mid Tier, ₱499) — featured/Best Seller
  - Royal Banquet (Premium Tier, ₱549)
  - Each card: Tier label, Name (22px Raleway 800), Price (34px JetBrains Mono accent), divider, Meats list (accent dot bullets), Add-ons (green check), Edit + Preview buttons
  - Featured card: accent border + absolute "Best Seller" badge top-right
- **Configs tab:** Table — Config Name, Linked Package (accent pill), Allowed Menus, Status (green/gray pill), Edit button
- Interactivity: tab switching only — **no modals, no create/edit**

### `TabletCategoriesScreen` (`admin-screens.jsx`, lines 325–388)
- Two-column grid: `300px` category list + `1fr` detail panel
- **Left panel:** 5 categories (Meats, Sides, Extras, Sets, Beverages)
  - Each row: drag handle (decorative bars), sort order badge (24×24px accent), name + slug + item count, Active/Off pill
  - Selected row: `var(--bg3)` background
- **Right panel:** Selected category detail
  - Header: category name, status pill with dot, Edit button
  - Meta grid (3-col): Slug, Sort Order, Menu Items count
  - Attached Menus list: menu name + Featured accent pill + Detach button
  - Empty state for Beverages (no menus)
  - Footer: Attach Menu button
- Interactivity: category selection only — **no drag-drop, no modals**

---

## What Was Decided

User confirmed wanting **all three deliverables**:

| # | Deliverable | Status |
|---|---|---|
| 1 | Enhance HTML prototype with full interactivity | **Not started** |
| 2 | Standalone focused demo HTML (two-tab, portable) | **Not started** |
| 3 | Vue 3 SFC files for production codebase | **Not started** |

---

## Full Implementation Plan

### Deliverable 1 — Enhance Existing Prototype

**Files:** `project/admin-app.jsx`, `project/admin-screens.jsx`

**TabletCategoriesScreen additions:**
- Real drag-to-reorder (HTML5 `dragstart`/`drop` events updating sort order in state)
- **Edit Category modal** — Name, Slug, Sort Order, Active toggle; Save updates state
- **New Category modal** — same modal in create mode
- **Attach Menu modal** — picker showing unattached menus with checkboxes

**PackagesScreen additions:**
- **New Package modal** — Tier, Name, Price, Meats (comma-separated), Extras, Note; Create appends to state
- **Edit package modal** — pre-filled from card data
- **Preview modal** — read-only card rendering (tablet consumer view)
- **New Config modal** — Config Name, linked package dropdown, allowed menus, status toggle
- **Edit Config modal** — pre-filled from table row

---

### Deliverable 2 — Standalone Demo

**New file:** `project/tablet-packages-demo.html`

- Self-contained: inline React 18 + Babel (same CDN), all CSS embedded
- Same design tokens as `Woosoo Admin.html`
- Simple header with "Woosoo Nexus" branding and tab strip: **Packages | Tablet Categories**
- No sidebar, no topbar — full-width content area
- Full interactivity from Deliverable 1
- Portable: no external image dependencies (graceful fallbacks)

---

### Deliverable 3 — Vue 3 SFC Files

**New files:** `project/vue/Packages/Index.vue`, `project/vue/TabletCategories/Index.vue`

**Conventions:**
- `<script setup lang="ts">` Composition API
- CSS custom properties from prototype tokens (match production `app.css`)
- `lucide-vue-next` for icons (`PlusIcon`, `GripVerticalIcon`, `EditIcon`, `XIcon`, `EyeIcon`, `CheckIcon`)
- shadcn-vue: `Badge`, `Button`, `Dialog`, `DialogContent`, `Table`, `TableHead`, `TableRow`, `TableCell`
- `ref`, `computed`, `reactive` for local state; no external store
- Emit-based API interactions (parent handles actual HTTP calls)
- No Tailwind utility classes — pure CSS vars matching design system

**`Packages/Index.vue`:**
```
- activeTab: ref<'packages'|'configs'>
- packages: ref([...3 packages])
- configs: ref([...4 configs])
- showPackageModal, editTarget for create/edit dialog
- showConfigModal, editConfigTarget
- Template: page-head → tab switcher → pkg-grid or configs table
- PackageFormDialog, ConfigFormDialog as inline components
```

**`TabletCategories/Index.vue`:**
```
- categories: ref([...5 categories]) with sort order
- catMenus: Record<string, string[]>
- selected: ref(categories[0])
- moveCategory(id, dir:'up'|'down') — swaps positions
- showEditModal, showNewModal, showAttachModal
- Template: page-head → 2-col grid → category list + detail panel
- EditCategoryDialog, AttachMenuDialog as inline components
```

---

## Verification Steps
1. Open `Woosoo Admin.html` → navigate Packages → test New/Edit/Preview modals update state correctly
2. Navigate Tablet Categories → test Up/Down reorder, Edit modal, Attach Menu picker
3. Open `tablet-packages-demo.html` → verify both tabs render with no console errors, fully self-contained
4. Review `vue/Packages/Index.vue` and `vue/TabletCategories/Index.vue` — check template structure, CSS variable usage, TypeScript types, shadcn-vue import paths

---

## Session End

No code was written during this session. The session concluded at the planning/review stage per user instruction. Implementation is ready to begin on next session start.

---

Doing both — and I'll bake the "continuously improving, not degrading" intent into the guide itself as an explicit anti-degradation loop. Starting with **Part A: the operator guide** (pointer-style, no rule duplication), then **Part B: Phase-15 → case files** (with existence-checks first, so I don't create duplicates of already-tracked work).

Now index it in `docs/README.md` and add a one-line pointer from the `AGENTS.md` boot layer.

Committing Part A (USAGE_GUIDE + index) to PR #27.

Part A shipped. **Part B: Phase-15 → case files.** First — critical per your "no duplicates / not degrading" rule — I must check what's *already tracked* before creating anything, since that summary is 10 days old and some items may already be cased or done.

Critical check — and it changes everything. **Phase-15 is already tracked**, mostly complete. Mapping the stale summary to live state:

| Phase-15 item | Live status |
|---|---|
| #1 SessionReset per-order + #2 wrong tests | **NEX-CASE-007** — APPROVED, complete-unlanded (needs merge + deploy) |
| #3 `last_seen_at` middleware | **NEX-CASE-007** — same |
| #5 Print-bridge APK rebuild | **prn-rebuild-apk-scp-pi.md** — exists |
| #4 tablet Echo WS "zombie" | **possibly untracked** — verifying now |

Creating 5 fresh case files would have **duplicated** tracked/done work — exactly the degradation you want to avoid. Let me confirm whether #4 is the one genuine gap.

Let me check whether those two tablet cases actually cover the "silent-death detector" (#4), and their status.

`useBroadcasts.ts` reconnection was reworked in tab-case-001/002, but neither added a dedicated **silent-death (connected-but-dead) detector** — that's item #4's specific ask. Let me check the *current* code before deciding: create a case only if it's genuinely still missing (not duplicate tab-case-002's reconnection work).

Confirmed: current `useBroadcasts.ts` has reconnect timers but **no heartbeat/staleness/watchdog** — so item #4 (silent-death detector) is a **genuine, untracked gap**. That's the *one* case to create; the other four are already in the system.

So the correct "conversion" is: **don't duplicate** the 4 tracked items — create a single triaged case for the real gap, on its own branch (separate from the consolidation PR), and leave the actively-maintained `state/QUEUE.md` untouched (it has another owner's uncommitted edits — per our own protocol, I won't bundle those).

Opening the PR for the case intake.

Both done. Here's the wrap-up.

## Part A — Operator guide (in platform PR [#27](https://github.com/ryanpastorizadev-bit/woosoo-platform/pull/27))
`docs/USAGE_GUIDE.md` created and indexed in `docs/README.md` — a pointer-style runbook (no rule duplication): phrase map, how to continue from a summary, a **common-scenarios index** pointing into the canonical rule docs, skills, and an explicit **anti-degradation loop**:

> Every fix leaves behind a guard — a **test** (Regression Lock), a **rule** (Evidence-Derived Rules), or a **corrected doc** (truth gate) — so the same problem cannot return. That's what makes it improve, not degrade.

## Part B — Phase-15 → case files (platform PR [#28](https://github.com/ryanpastorizadev-bit/woosoo-platform/pull/28))
I checked the live system **before** creating anything (your no-duplicates rule). Result: **4 of 5 Phase-15 items were already tracked** —
- #1/#2/#3 → **NEX-CASE-007** (APPROVED, complete-unlanded)
- #5 → **prn-rebuild-apk-scp-pi**

Creating fresh cases for those would have *degraded* the system. Only **#4 (tablet WebSocket silent-death detector)** was a genuine gap — I verified the current `useBroadcasts.ts` has reconnect timers but no liveness/heartbeat detector — so I created one triaged case: **`tab-case-009-broadcast-silent-death-detector`** (Tier 2, chuya-frontend, `BLOCKED` awaiting scheduling). `state/QUEUE.md` left untouched (another owner has live edits there).

## Open PRs
| PR | Repo | Contents |
|---|---|---|
| [#27](https://github.com/ryanpastorizadev-bit/woosoo-platform/pull/27) | platform | Claude-only consolidation, order-state truth, infra-glob + PROTOCOL fixes, uncommitted-changes/regression/skill protocol, USAGE_GUIDE |
| [#28](https://github.com/ryanpastorizadev-bit/woosoo-platform/pull/28) | platform | tab-case-009 intake |
| [#155](https://github.com/tech-artificer/woosoo-nexus/pull/155) | nexus | de-Codex, order-state, onboarding relocate, orphan cleanup |
| [#191](https://github.com/tech-artificer/tablet-ordering-pwa/pull/191) | tablet | de-Codex, onboarding relocate, dangling-ref fix |

## One hygiene recommendation (to stay "not degrading")
Your `CLAUDE.local.md` Phase-15 section (dated 2026-05-21) is now **superseded** by the queue/cases — its "open bugs" are mostly done. Since it's your private uncommitted file, update or trim it so a future session doesn't re-triage stale items. Want me to draft the replacement text for it?

---

### End

