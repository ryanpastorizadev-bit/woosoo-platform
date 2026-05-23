# Confirmed Order Continuity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make a rebooted tablet block on recovery, route to the correct screen, and rehydrate the full confirmed-order item list until the order leaves the active state.

**Architecture:** Keep this implementation inside `tablet-ordering-pwa/`. Nexus already returns the canonical order payload, including `items`, through `GET /api/device-order/by-order-id/{orderId}` via `DeviceOrderResource`, so the missing behavior is tablet-side: the welcome route must wait for recovery before choosing a screen, the order store must hydrate the round ledger from the recovered order payload, and the in-session screen must not render an empty confirmed order while hydration is still in flight.

**Tech Stack:** Nuxt 3, Vue 3, Pinia, TypeScript, Vitest, Element Plus.

---

**Scope note:** This plan stays tablet-only. The current backend endpoint already exposes `order.status`, `order.guest_count`, `order.total`, and `order.items` in `woosoo-nexus/app/Http/Controllers/Api/V1/OrderApiController.php` and `woosoo-nexus/app/Http/Resources/DeviceOrderResource.php`. Do not expand this into a Nexus implementation plan unless the tablet proves unable to hydrate from that existing payload.

## File map

- Modify: `tablet-ordering-pwa/pages/index.vue`  
  Add a blocking recovery state on cold start and route recovered confirmed orders to `/order/in-session` instead of `/menu`.

- Modify: `tablet-ordering-pwa/stores/Order.ts`  
  Hydrate `rounds`, `guestCount`, `serverOrderId`, `serverStatus`, and `serverTotal` from the canonical recovered order payload.

- Modify: `tablet-ordering-pwa/pages/order/in-session.vue`  
  Show a loading state while a recovered confirmed order is still hydrating instead of rendering an empty order stream.

- Create: `tablet-ordering-pwa/tests/index-recovery-contract.spec.ts`  
  Source-level contract test for the welcome-route recovery gate and `/order/in-session` routing.

- Modify: `tablet-ordering-pwa/tests/order.polling.spec.ts`  
  Add a store regression proving `initializeFromSession()` hydrates recovered items into `rounds`.

- Create: `tablet-ordering-pwa/tests/in-session-recovery-loading.spec.ts`  
  Component regression proving the in-session screen stays in a loading state until recovered items exist.

### Task 1: Block the welcome route until recovery resolves

**Files:**
- Create: `tablet-ordering-pwa/tests/index-recovery-contract.spec.ts`
- Modify: `tablet-ordering-pwa/pages/index.vue`

- [ ] **Step 1: Write the failing welcome-route contract test**

```ts
import { readFileSync } from "node:fs"
import { resolve } from "node:path"
import { describe, expect, it } from "vitest"

const PROJECT_ROOT = process.cwd()

function readProjectFile(relativePath: string): string {
    return readFileSync(resolve(PROJECT_ROOT, relativePath), "utf8")
}

describe("welcome recovery routing contract", () => {
    it("keeps a blocking recovery state before showing the start CTA", () => {
        const page = readProjectFile("pages/index.vue")

        expect(page).toContain("const isRecoveringConfirmedOrder = ref(true)")
        expect(page).toContain("v-if=\"isRecoveringConfirmedOrder\"")
        expect(page).toContain("Restoring your order")
    })

    it("routes recovered active orders to /order/in-session instead of /menu", () => {
        const page = readProjectFile("pages/index.vue")

        expect(page).toContain("await router.replace(\"/order/in-session\")")
        expect(page).not.toContain("resumeMenu: \"1\"")
    })
})
```

- [ ] **Step 2: Run the contract test and confirm it fails**

Run: `npm run test:run -- tests/index-recovery-contract.spec.ts`

Expected: FAIL because `pages/index.vue` currently redirects recovered orders to `/menu` and has no dedicated blocking recovery state.

- [ ] **Step 3: Add the blocking recovery gate and route to the in-session screen**

Update `pages/index.vue` so the recovery work finishes before the welcome CTA is shown.

```ts
const isRecoveringConfirmedOrder = ref(true)

onMounted(async () => {
    let redirected = false

    try {
        const recovery = await recoverActiveOrderState("index")
        if (recovery.hasActiveOrder) {
            let canResumeActiveOrder = unref(deviceStore.isAuthenticated)

            if (!canResumeActiveOrder) {
                try {
                    const hasToken = Boolean(deviceStore.token)
                    canResumeActiveOrder = hasToken
                        ? await deviceStore.refresh()
                        : await deviceStore.authenticate()
                } catch {
                    canResumeActiveOrder = false
                }
            }

            if (!canResumeActiveOrder || !unref(deviceStore.isAuthenticated)) {
                return
            }

            redirected = true
            await router.replace("/order/in-session")
            return
        }

        if (route.query.settingsLocked === "1") {
            openSettings("Settings access expired. Please re-enter PIN.")
        }
    } finally {
        if (!redirected) {
            isRecoveringConfirmedOrder.value = false
        }
    }
})
```

Add a blocking recovery panel ahead of the normal CTA block:

```vue
<div v-if="isRecoveringConfirmedOrder" class="space-y-4 animate-fade-in-delayed-2">
    <div class="rounded-2xl bg-surface-20 ring-1 ring-white/10 px-8 py-6 max-w-md text-center">
        <p class="text-sm font-semibold uppercase tracking-[0.2em] text-primary/85">
            Restoring your order
        </p>
        <p class="mt-3 text-sm text-white/65">
            Please wait while we confirm whether this tablet has an active dining session.
        </p>
    </div>
</div>

<div v-else class="space-y-4 animate-fade-in-delayed-2">
    <!-- existing CTA / auth / update blocks stay here -->
</div>
```

- [ ] **Step 4: Re-run the contract test**

Run: `npm run test:run -- tests/index-recovery-contract.spec.ts`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add tests/index-recovery-contract.spec.ts pages/index.vue
git commit -m "fix(tablet): block welcome route on order recovery"
```

### Task 2: Hydrate recovered confirmed items into the order ledger

**Files:**
- Modify: `tablet-ordering-pwa/stores/Order.ts`
- Modify: `tablet-ordering-pwa/tests/order.polling.spec.ts`

- [ ] **Step 1: Add the failing recovery-hydration regression**

Append this test to `tests/order.polling.spec.ts`:

```ts
it("initializeFromSession hydrates confirmed items into rounds from the canonical order payload", async () => {
    const order = useOrderStore()
    const session = useSessionStore()
    const device = useDeviceStore()

    session.setIsActive(true)
    session.setOrderId(19561)
    device.setToken("test-token")

    mockGet.mockResolvedValueOnce({
        data: {
            order: {
                id: 61,
                order_id: 19561,
                status: "confirmed",
                guest_count: 4,
                total: 250,
                created_at: "2026-05-20T12:00:00.000Z",
                items: [
                    { id: 1, menu_id: 10, ordered_menu_id: 501, name: "Beef Brisket", quantity: 2, price: 0, category: "meats" },
                    { id: 2, menu_id: 20, ordered_menu_id: 502, name: "Kimchi Rice", quantity: 1, price: 0, category: "sides" },
                ],
            },
        },
    })

    await order.initializeFromSession()

    expect(order.serverOrderId).toBe(19561)
    expect(order.serverStatus).toBe("confirmed")
    expect(order.guestCount).toBe(4)
    expect((order as any).rounds).toEqual([
        expect.objectContaining({
            kind: "initial",
            number: 1,
            serverOrderId: 19561,
            items: [
                expect.objectContaining({ id: 10, name: "Beef Brisket", quantity: 2 }),
                expect.objectContaining({ id: 20, name: "Kimchi Rice", quantity: 1 }),
            ],
        }),
    ])
})
```

- [ ] **Step 2: Run the store test and confirm it fails**

Run: `npm run test:run -- tests/order.polling.spec.ts`

Expected: FAIL because `initializeFromSession()` currently updates only `serverStatus` and `serverOrderId`; it does not project `order.items` into `rounds`.

- [ ] **Step 3: Add a dedicated recovery hydrator in the order store**

In `stores/Order.ts`, add a helper above `initializeFromSession()` and call it from the `/api/device-order/by-order-id/{orderId}` success path.

```ts
type RecoveredOrderItem = {
    id?: number | null
    menu_id?: number | null
    ordered_menu_id?: number | null
    name?: string | null
    quantity?: number | null
    price?: number | null
    category?: string | null
}

type RecoveredOrderPayload = {
    id?: number | null
    order_id?: number | null
    status?: string | null
    guest_count?: number | null
    total?: number | null
    total_amount?: number | null
    created_at?: string | null
    items?: RecoveredOrderItem[] | null
}

function hydrateRecoveredConfirmedOrder (orderObj: RecoveredOrderPayload): void {
    const recoveredOrderId = Number(orderObj?.order_id ?? orderObj?.id ?? 0) || null
    const recoveredTotal = Number(orderObj?.total ?? orderObj?.total_amount ?? state.serverTotal ?? 0) || 0

    const recoveredItems = Array.isArray(orderObj?.items)
        ? orderObj.items
            .map((item) => {
                const id = Number(item?.menu_id ?? item?.id ?? 0)
                if (!id) { return null }

                return {
                    id,
                    name: String(item?.name ?? "Item"),
                    price: Number(item?.price ?? 0),
                    quantity: Number(item?.quantity ?? 0),
                    isUnlimited: false,
                    ordered_menu_id: Number(item?.ordered_menu_id ?? 0) || undefined,
                    category: item?.category ?? null,
                    img_url: null,
                }
            })
            .filter((item): item is CartItem => item !== null)
        : []

    if (state.rounds.length === 0 && recoveredItems.length > 0) {
        state.rounds = [{
            kind: "initial",
            number: 1,
            submittedAt: String(orderObj?.created_at ?? new Date().toISOString()),
            items: recoveredItems.map(item => ({ ...item })),
            serverOrderId: recoveredOrderId,
            serverTotal: recoveredTotal,
        }]
    }

    state.serverOrderId = recoveredOrderId
    state.serverStatus = String(orderObj?.status ?? state.serverStatus)
    state.serverTotal = recoveredTotal || state.serverTotal

    if (Number(orderObj?.guest_count ?? 0) > 0) {
        state.guestCount = Number(orderObj?.guest_count)
    }
}
```

Then replace the current success block in `initializeFromSession()` with:

```ts
if (orderObj) {
    hydrateRecoveredConfirmedOrder(orderObj)
    logger.debug("Hydrated canonical order payload during initializeFromSession:", {
        orderId: state.serverOrderId,
        roundsCount: state.rounds.length,
        itemCount: state.rounds[0]?.items?.length ?? 0,
    })
} else {
    logger.warn("No order payload returned; initialized minimal order_id:", sessionStore.getOrderId())
}
```

- [ ] **Step 4: Re-run the store regression**

Run: `npm run test:run -- tests/order.polling.spec.ts`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add stores/Order.ts tests/order.polling.spec.ts
git commit -m "fix(tablet): hydrate recovered confirmed order items"
```

### Task 3: Keep the in-session screen loading until recovered items exist

**Files:**
- Create: `tablet-ordering-pwa/tests/in-session-recovery-loading.spec.ts`
- Modify: `tablet-ordering-pwa/pages/order/in-session.vue`

- [ ] **Step 1: Write the failing in-session loading regression**

Create `tests/in-session-recovery-loading.spec.ts`:

```ts
import { describe, expect, it, vi, beforeEach } from "vitest"
import { mount } from "@vue/test-utils"
import { createPinia, setActivePinia } from "pinia"
import { nextTick } from "vue"

import InSession from "~/pages/order/in-session.vue"
import { useOrderStore } from "~/stores/Order"

const g = global as any
g.definePageMeta = vi.fn()
g.navigateTo = vi.fn()

vi.mock("vue-router", () => ({
    useRouter: () => ({
        replace: vi.fn(),
        push: vi.fn(),
    }),
}))

vi.mock("~/stores/Session", () => ({
    useSessionStore: () => ({
        isActive: true,
        orderId: 19561,
        remainingMs: 60_000,
        timerExpired: false,
        getIsActive: () => true,
        getOrderId: () => 19561,
    }),
}))

vi.mock("~/composables/useApi", () => ({
    useApi: () => ({ get: vi.fn(), post: vi.fn() }),
}))

vi.mock("~/composables/useIdleDetector", () => ({
    useIdleDetector: () => ({
        start: vi.fn(),
        stop: vi.fn(),
        isWarning: { value: false },
    }),
}))

vi.mock("~/composables/useSessionEndFlow", () => ({
    useSessionEndFlow: () => ({
        triggerSessionEnd: vi.fn(),
    }),
}))

vi.mock("~/utils/logger", () => ({
    logger: {
        info: vi.fn(),
        debug: vi.fn(),
        warn: vi.fn(),
        error: vi.fn(),
    },
}))

describe("in-session recovery loading", () => {
    beforeEach(() => {
        setActivePinia(createPinia())
        vi.clearAllMocks()
    })

    it("shows a loading state while confirmed-order items are still hydrating", async () => {
        const orderStore = useOrderStore()
        ;(orderStore as any).serverOrderId = 19561
        ;(orderStore as any).serverStatus = "confirmed"
        ;(orderStore as any).rounds = []

        let release!: () => void
        vi.spyOn(orderStore, "initializeFromSession").mockImplementation(() => new Promise<void>((resolve) => {
            release = resolve
        }))

        const wrapper = mount(InSession, {
            global: {
                stubs: {
                    NuxtErrorBoundary: { template: "<div><slot /></div>" },
                },
            },
        })

        await nextTick()

        expect(wrapper.text()).toContain("Restoring your order")
        expect(g.navigateTo).not.toHaveBeenCalledWith("/")

        ;(orderStore as any).rounds = [{
            kind: "initial",
            number: 1,
            submittedAt: "2026-05-20T12:00:00.000Z",
            items: [{ id: 10, name: "Beef Brisket", quantity: 2, price: 0, img_url: null, category: "meats", isUnlimited: false }],
            serverOrderId: 19561,
            serverTotal: 250,
        }]

        release()
        await nextTick()
        await nextTick()

        expect(wrapper.text()).toContain("Beef Brisket")
    })
})
```

- [ ] **Step 2: Run the regression and confirm it fails**

Run: `npm run test:run -- tests/in-session-recovery-loading.spec.ts`

Expected: FAIL because `pages/order/in-session.vue` currently renders the page immediately and has no dedicated recovery-loading state.

- [ ] **Step 3: Add a hydration guard to the in-session page**

In `pages/order/in-session.vue`, add a recovery-loading ref and an `ensureRecoveredItems()` helper before `onMounted()`:

```ts
const isHydratingRecoveredOrder = ref(false)

async function ensureRecoveredItems (): Promise<boolean> {
    const hasRecoveryPointer = orderId.value !== null
    const hasRecoveredItems = displaySubmittedItems.value.length > 0

    if (!hasRecoveryPointer || hasRecoveredItems) {
        return true
    }

    isHydratingRecoveredOrder.value = true

    try {
        await orderStore.initializeFromSession()
        return displaySubmittedItems.value.length > 0
    } finally {
        isHydratingRecoveredOrder.value = false
    }
}
```

Then change the mount guard:

```ts
onMounted(async () => {
    if (!sessionStore.isActive) {
        logger.warn("[in-session] No active session — redirecting to home")
        navigateTo("/")
        return
    }

    const recovered = await ensureRecoveredItems()
    if (!orderStore.hasPlacedOrder || !recovered) {
        logger.warn("[in-session] Confirmed order recovery did not restore items — redirecting to home")
        navigateTo("/")
        return
    }

    updateCurrentTime()
    clockIntervalId = setInterval(updateCurrentTime, 1000)
})
```

Render a blocking loading panel before the order stream:

```vue
<div v-if="isHydratingRecoveredOrder" class="flex flex-1 items-center justify-center px-6 py-8">
    <div class="rounded-2xl border border-white/10 bg-[#141210] px-6 py-5 text-center">
        <p class="text-sm font-semibold uppercase tracking-[0.2em] text-primary/85">
            Restoring your order
        </p>
        <p class="mt-3 text-sm text-white/65">
            Please wait while we reload your confirmed items.
        </p>
    </div>
</div>

<div v-else class="scrollbar-warm flex-1 overflow-y-auto space-y-2 px-6 py-4">
    <!-- existing ordered-items stream -->
</div>
```

- [ ] **Step 4: Re-run the in-session regression**

Run: `npm run test:run -- tests/in-session-recovery-loading.spec.ts`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add tests/in-session-recovery-loading.spec.ts pages/order/in-session.vue
git commit -m "fix(tablet): block in-session until recovery finishes"
```

### Task 4: Validate the full slice and land it cleanly

**Files:**
- Modify: `tablet-ordering-pwa/pages/index.vue`
- Modify: `tablet-ordering-pwa/stores/Order.ts`
- Modify: `tablet-ordering-pwa/pages/order/in-session.vue`
- Create: `tablet-ordering-pwa/tests/index-recovery-contract.spec.ts`
- Modify: `tablet-ordering-pwa/tests/order.polling.spec.ts`
- Create: `tablet-ordering-pwa/tests/in-session-recovery-loading.spec.ts`

- [ ] **Step 1: Run the focused regression suite together**

Run: `npm run test:run -- tests/index-recovery-contract.spec.ts tests/order.polling.spec.ts tests/in-session-recovery-loading.spec.ts`

Expected: PASS.

- [ ] **Step 2: Run the existing related tablet regressions**

Run: `npm run test:run -- tests/order-submit-handoff.spec.ts tests/in-session-ordered-items.spec.ts tests/session.fetch-latest.spec.ts`

Expected: PASS.

- [ ] **Step 3: Run the tablet quality gates**

Run:

```bash
npm run typecheck
npm run lint
npm run test
```

Expected: PASS.

- [ ] **Step 4: Run the repository pre-merge wrapper from the platform root**

Run: `.\scripts\pre-merge-check.ps1 -App tablet-ordering-pwa`

Expected: PASS.

- [ ] **Step 5: Commit the validated slice**

```bash
git add pages/index.vue stores/Order.ts pages/order/in-session.vue tests/index-recovery-contract.spec.ts tests/order.polling.spec.ts tests/in-session-recovery-loading.spec.ts
git commit -m "fix(tablet): restore confirmed orders after reboot"
```

## Self-review

### Spec coverage

- **Live-only submission remains intact:** covered by preserving the existing submit path and validating related behavior with `tests/order-submit-handoff.spec.ts`.
- **Blocking bootstrap before route selection:** covered by Task 1.
- **Confirmed-order recovery with full items/details:** covered by Task 2 and Task 3.
- **No partial confirmed-order rendering:** covered by Task 3.
- **Acceptance criteria and validation scenarios:** covered by Task 4.

### Placeholder scan

- No placeholder markers or “similar to previous task” shortcuts remain.
- Each task names exact files, code snippets, commands, and expected outcomes.

### Type consistency

- The recovered items are mapped into the existing `CartItem`-compatible round ledger shape used by `pages/order/in-session.vue`.
- Route targets remain consistent with the current app: `/order/in-session` for an active confirmed order, `/` for clean start.
