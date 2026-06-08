---
status: canonical
last_reviewed: 2026-06-08
scope: woosoo-nexus
---

# CASE: kds-implementation-plan

Kitchen Display System (KDS) implementation spec for `woosoo-nexus`. **Deferred** until
blocker case files are `COMPLETE`:

- `docs/cases/plt-case-stability-remediation.md` — Pi ops gates (P0–P1b) **(open)**
- `docs/cases/tab-case-011-active-order-recovery-filter.md` — tablet recovery filter **(COMPLETE 2026-06-07; landed tablet `dev` PR #199)**

Also requires Tier-3 decisions in § B5 locked. GitHub: #137, #143, #144, #145–#148.

Precedence when building:
1. This document § B (behavioral/logic contract) + prototype visual tokens
2. `docs/kds-designer-spec.md` (on `origin/staging` when propagated) — background only; where
   it conflicts with § B, § B wins

Appendix A (3-stage phased sketch from an earlier session) is **superseded** by § B and retained
only in git history / design chat — do not implement from it.

## Run State

- task_slug: kds-implementation-plan
- tier: 2
- branch: agent/kds-phase-0
- status: IN_PROGRESS
- last_completed_agent: specialist (Track A+B consolidated → 73a50b7, bcba487; pushed)
- next_agent: verifier
- active_runner: cursor
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-08
- blocked_by: none (Pi stability deferred per operator; KDS UI slice proceeds in parallel)

## Specialist Investigation & Implementation

**Stability-first note:** [[plt-case-stability-remediation]] P0 (NEX-014 session-domain) remains operator/Pi work — not touched in this slice. KDS UI fixes proceed per explicit re-prioritization.

**Investigated**
- Letterboxed layout: fixed 1280×800 canvas + `transform: scale()` centered in `.kds-device-frame` left margins on 1920×1080 and Tab A11+ landscape.
- Mark Ready stuck disabled: Phase 1 `Display.vue` POSTed item toggles then **reverted** optimistic `done` on API failure (migration/endpoints absent in mock-only env) → `isReadyBlocked` never cleared.
- Gating duplicated: `KdsTicketCard` computed `isReadyBlocked` separately from `canAdvanceTicket()` in `kdsHelpers.ts`.

**Changed (woosoo-nexus, branch `agent/kds-phase-0`)**
- `Display.vue` — true fullscreen shell (`100dvw` × `100dvh`); removed canvas scale/device frame; scroll confined to `.kds-grid-wrap`; client-side mock toggle/advance via `applyAdvance` (no axios/Echo in this slice); mock fallback when `initialTickets` empty.
- `kdsHelpers.ts` — added `isAdvanceBlocked()`; `canAdvanceTicket()` uses strict `item.done === true`.
- `KdsTicketCard.vue` — `:disabled="advanceBlocked"` from centralized helper.
- Touch targets — filter chips and item rows ≥ 44px.
- `kdsHelpers.test.ts` + `vitest.config.ts` + `npm run test:unit` — Mark Ready gating unit tests.

**Changed (2026-06-08 — Cursor proceed: Track A + B)**
- `KdsController.php` — `TERMINAL_ITEM_STATUSES` guard on `toggleItem()`; `lockForUpdate()` on order row in `advance()` + `toggleItem()`; Mark Ready gate re-queries items inside transaction; `$gateMessage` ref pattern for 422 exits.
- `KdsControllerTest.php` — 4 new tests (served/voided/completed toggle rejected; stale-read Mark Ready gate).
- `Display.vue` — `--kds-weight-*` tokens; replaced all `900`/`800` literals with role-based weights; `tabular-nums` on metric/clock/qty values.
- `.interface-design/system.md` — typography weight scale + element mapping table.

**Verification (raw)**
- `npm run typecheck` — exit 0
- `npm run lint:check` — **FAIL** (10 pre-existing errors in unrelated `Devices/Index.vue`, `Tables/Index.vue`, `package-configs/IndexPackageConfigs.vue` on `dev` working tree — not KDS files)
- `npm run test:unit` — 5 passed
- `php artisan test tests/Feature/Admin/KdsControllerTest.php tests/Feature/Admin/KdsDisplayTest.php` — **13 passed** (40 assertions)

**Consolidation checkpoint (2026-06-08)**
- *Audit correction:* the earlier Cursor checkpoint claimed both tracks were on the
  `agent/kds-phase-0` working tree. At audit they were not — Track A was stranded as commit
  `ab2cafe` on sibling branch `fix/kds-p0-controller-guards`, and Track B was a stub (3
  contradictory `--kds-fw-*` tokens, 14 hardcoded `900`/`800` weights still present).
- Track A consolidated onto `agent/kds-phase-0` via `git cherry-pick -x ab2cafe` → **`73a50b7`**
  (`KdsController` guards + 4 tests; `KdsControllerTest` now 10 tests).
- Track B completed to match `.interface-design/system.md` (7 `--kds-weight-*` tokens 500–700;
  all 14 shout weights repointed; `tabular-nums` on metric/clock/filter-count/qty) → **`bcba487`**.
- Branch `agent/kds-phase-0` pushed to `origin` (Track A + B). Stray non-KDS untracked files
  (`Admin/TablesController.php`, `pages/Tables/`) intentionally left out of both commits.
- Open Tier-3 nit (filed, non-blocking): move `toggleItem` terminal-status guard inside the lock
  to fully close the concurrent advance→toggle race.

**Deferred (out of slice)**
- Echo/live feed wiring, backend advance/toggle writes, recall confirmation modal, B5 recall-from-voided decision.
- Physical Tab A11+ wet-hands manual pass.

## WSL test workflow (operator convention)

> **Authoritative for this operator:** code changes always land on **Windows** first; WSL is for
> run/test only — never edit in WSL without pulling Windows commits first.

**Stack:** Docker Compose from **platform root** (not `composer dev` on the WSL host).
Browser: **https://192.168.100.7/kds** (nginx in compose — not localhost).

| Step | Directory | Action |
|------|-----------|--------|
| 1 | Windows | Implement, commit, `git push origin dev` in `woosoo-nexus` |
| 2 | WSL | `cd ~ && cd projects/woosoo-platform` ← **platform root** |
| 3 | WSL | `git -C woosoo-nexus pull origin dev` (or `./run dev` pulls all repos) |
| 4 | WSL | `./run dev --no-pull` **or** rebuild app after frontend changes (see below) |
| 5 | Browser | **https://192.168.100.7/login** → **https://192.168.100.7/kds** |

**Do not run** host `composer install` / `composer dev` inside `woosoo-nexus` on WSL — there is
no native `php`; that invokes Windows Composer and fails with `php: not found`. PHP/Composer/npm
for the app run **inside the Docker `app` container** (bind-mount `./woosoo-nexus`).

After **Vue/KDS frontend** changes, rebuild assets in the container:

```bash
cd ~/projects/woosoo-platform
WOOSOO_FORCE_VITE_BUILD=true docker compose --env-file ./woosoo-nexus/.env -f compose.yaml up -d --build app
```

**Paths:** use `~/projects/woosoo-platform/` — not `/mnt/e/Projects/...`. Canonical operator
procedure: [`docs/USAGE_GUIDE.md § 6`](../USAGE_GUIDE.md#6-wsl-dev-test-windows-edit--docker-run).

## Blockers (resume protocol)

`blocked_by` lists **`task_slug` values only** — the join key for `docs/cases/<task_slug>.md`.
Queue row IDs (e.g. **TAB-CASE-011**) are human labels in `state/QUEUE.md`; **never** put them in
`blocked_by` or the resolver cannot match a case file.

| task_slug (use in `blocked_by`) | case file | status | queue alias |
|---|---|---|---|
| `plt-case-stability-remediation` | `docs/cases/plt-case-stability-remediation.md` | IN_PROGRESS | — |
| `tab-case-011-active-order-recovery-filter` | `docs/cases/tab-case-011-active-order-recovery-filter.md` | **COMPLETE** | TAB-CASE-011 |

Unblock when all rows with `status` ≠ COMPLETE are cleared (currently: Pi ops only).

## Handoff

- Blockers — resolve via `task_slug` → case file (see table above):
  - `plt-case-stability-remediation` — Pi operator verification P0–P1b (**remaining**)
  - `tab-case-011-active-order-recovery-filter` — **COMPLETE** (landed tablet `dev` PR #199)
- Exact next action when unblocked: Rebase branch; implement Phase 0 read-only board (no writes,
  no migration). Resolve B5 #1 before Phase 2 (recall).
- Do-not-redo: Do not conflate kitchen **Served** with payment **Completed** (see § C).

## Mock UI review (2026-06-07)

Uncommitted mock KDS on `woosoo-nexus` `dev`: `/kds` route, `KDS/Display.vue` + components, mock
data only (no backend/Echo). **Committed** on nexus `dev` as `6293bd2` ("Kitchen Display ui mockup").
Review findings and fixes applied:

| Finding | Resolution |
|---|---|
| `blocked_by` must use `task_slug`, not queue ID `TAB-CASE-011` | Blockers table + cross-links in case files and `state/QUEUE.md` |
| `stateLabel(served)` and filter chip said "Completed" (C5 violation) | Renamed to **Served** in `kdsHelpers.ts` and `KdsFilterChips.vue` |
| Duplicate advance/recall state machine in `Display.vue` vs helpers | Centralized in `applyAdvance`, `applyRecall`, `canAdvanceTicket` |
| Mark Ready used `aria-disabled` but still clickable | `:disabled="isReadyBlocked"` on primary action button |
| No duplicate routes/layouts | Single `GET /kds` in `web.php`; no admin sidebar; styles scoped `--kds-*` |
| Same table, separate tickets | Mock data keeps T-05 initial + refill as separate cards (spec rule) |

Remaining mock limitations (expected): no live feed in this UI slice (client-side mock interactions), `html:has(.kds-viewport)` global overflow lock while on page.

### Bug audit (2026-06-08 — Cursor specialist)

| Issue | Root cause | Fix |
|---|---|---|
| Letterboxed canvas / unused viewport | Fixed 1280×800 + scale centering | Full-viewport `.kds-shell` grid; removed scale wrapper |
| Mark Ready stays disabled after checking all items | Axios toggle revert on failed POST | Client-side-only toggle/advance for mock slice |
| Gating logic duplicated in card | Local `isReadyBlocked` computed | `isAdvanceBlocked()` in `kdsHelpers.ts` |
| Filter chips 42px tall | CSS min-height below 44px target | Raised to 44px |
| Compact item rows 40px | Same | Raised to 44px |
| Echo overwriting local toggles | `useKdsEcho` reapplied server payload | Removed Echo hook from mock Display slice |
| Recall confirmation modal | Not in scope | Deferred |
| Reduced motion | Already guarded in Display styles | No change |
| Empty queue | `KdsEmptyState` | No change |

---

## KDS Launch Readiness — B5 decision pre-lock (2026-06-08, read-only prep)

Read-only prep so the implementing agent starts with **locked decisions** the moment the Pi
stability gate clears. Evidence is `contracts/order-state.contract.md` (authoritative mirror of
`OrderStatus::canTransitionTo`); the `woosoo-nexus` repo is not in this checkout, so items marked
**VERIFY-IN-NEXUS** must be confirmed against live code before the affected phase.

### Done / not blocking
- UI mock slice committed (nexus `dev` `6293bd2`); fixes in this case's Specialist section.
- `tab-case-011-active-order-recovery-filter` — COMPLETE (PR #199). Only Pi ops remain as the gate.

### Decisions resolvable from the contract (LOCK these)

| B5 | Decision | Locked answer | Evidence |
|----|----------|---------------|----------|
| **B5.1a** | Recall from **voided** (`voided→in_progress`) | **REJECT — do NOT add this edge.** Recall-from-voided must re-fire as a **new kitchen ticket**, never un-void. | Contract: `VOIDED` is terminal; "terminal states never transition"; "do not invent states/transitions." Adding `voided→in_progress` breaks the terminal invariant + POS parity. |
| **B5.1b** | Recall from **served** (`served→in_progress`) | **PERMITTED but contract-gated.** `SERVED` is non-terminal, so a backward edge is additive — but it requires updating `OrderStatus::canTransitionTo` **and** `order-state.contract.md` in the same change, plus a parity test. | Contract: `SERVED → COMPLETED \| VOIDED` today; new edge must be recorded in the contract per the "no invented transitions" rule. |
| **B5.2** | `new→preparing` on a `pending` order | **Use the existing two-step path `pending→confirmed→in_progress`. Do NOT add `pending→in_progress`.** In practice creation already sets `confirmed`, so Start Preparing is just `confirmed→in_progress` (edge exists). | Contract: `PENDING → CONFIRMED \| VOIDED \| CANCELLED` (no direct `pending→in_progress`); `CONFIRMED → IN_PROGRESS` exists; Appendix C2 "pending is transient; creation sets confirmed." |

### Contract conflict found in this plan (must resolve before P2)

> **Appendix B1 / B7 list `voided → in_progress` ("Recall ⚠️ NEW edge") as a build target.**
> That directly violates `order-state.contract.md` (VOIDED is terminal). Per **B5.1a above**, the
> implementing agent must NOT add that edge — use the new-ticket approach. B1/B7 should be read
> with this override. (This is the §B5 #1 "STOP before P2" risk, now decided.)

### Still requires verification / human sign-off (cannot lock from platform repo)
- **B5.6 (VERIFY-IN-NEXUS):** item display field — payload uses `receipt_name ?? name`; designer spec wants `kitchen_name`. Confirm the POS/menu column exists before wiring P0.
- **B5.3 (VERIFY-IN-NEXUS):** order `type` (initial/refill) derivation from per-item `is_refill`.
- **B5.4 (VERIFY-IN-NEXUS):** item `safety` flag source (notes/modifiers vs allergen field).
- **B5.5 (DESIGN):** threshold + recall-target config storage (`SystemSetting` vs `kds_config`) — pick during P3; not needed for P0/P1.

### Launch sequence (the moment Pi gates are green)
1. Clear `plt-case-stability-remediation` P0–P1b (operator/Pi). KDS `blocked_by` then empty.
2. Tier-3 Specialist (ranpo-backend, **Claude Code — not Cursor**) rebases `agent/kds-phase-0` on `origin/dev`.
3. **P0** read-only board (no writes/migration) — safe first landing.
4. **P1** writes + additive migration + `ItemToggled`; apply B5.2 lock (no new pending edge).
5. **STOP at P2** — apply B5.1a/b locks: voided-recall = new ticket; if served-recall is wanted, update enum **and** contract together with a parity test.
6. P3 thresholds/tokens (resolve B5.5), P4 resilience.

> Tier-3 reminder: KDS touches the order state machine + POS parity. Implementation must run as a
> Claude Code Specialist with the relevant `contracts/*.md` open; Cursor is not permitted for the
> build (this readiness note is read-only planning only).

---

# Appendix B — KDS Implementation Plan + Agent Prompt

> Based on the **"Woosoo KDS — Implementation Spec"** + prototype `Woosoo KDS.html` /
> `kds-app.jsx` / `kds-data.jsx`. **Precedence:** spec wins on logic, prototype wins on look.
> **Sequencing:** execute only after the stability pass unless explicitly re-prioritized.

## B0. What changed vs. the earlier (3-stage) design

- **4 active stages** `new → preparing → ready → served` (+`voided`), labels New/Preparing/Ready/
  **Served** (kitchen Layer 2). Payment **Completed** (Layer 1) removes the card from the active
  queue — not a kitchen stage label.
- **No KDS-originated voids** — voids arrive only from the POS/FOH feed.
- **Recall** brings `served` **or** `voided` back to `preparing` (target configurable).
- **Tokens/fonts from the prototype `:root`** — Raleway / **Kanit** / **JetBrains Mono** (timers).
- **Urgency** = live elapsed: warning ≥15 min, overdue ≥25 min, **configurable per type**.
  **Server-authoritative** time; freeze on served/voided.
- **No per-table color coding.** Color budget = stage (left edge) + urgency.

## B1. Backend ↔ KDS state mapping (C5-corrected)

| Backend `OrderStatus` | KDS `state` | Card label | Primary action → backend transition |
|---|---|---|---|
| `pending`, `confirmed` | `new` | New | **Start Preparing** → `in_progress` *(pending needs edge or auto-confirm — see B5)* |
| `in_progress` | `preparing` | Preparing | **Mark Ready** *(gated: all items `done`)* → `ready` |
| `ready` | `ready` | Ready | **Mark Served** → `served` |
| `served` | `served` | **Served** | **Recall** → `in_progress` ⚠️ NEW edge |
| `completed` | — | *(hidden)* | POS paid — card leaves active queue (Layer 1 terminal) |
| `voided` | `voided` | Voided | **Recall** → `in_progress` ⚠️ NEW edge (terminal-state risk) |
| `cancelled`, `archived` | — | hidden | — |

`DeviceOrder::setStatusAttribute` enforces `canTransitionTo` and throws on invalid edges — every
transition above MUST exist in the enum or writes fail.

## B2. Backend work

- **Enum** `app/Enums/OrderStatus.php` — additively add edges: `served→in_progress`,
  `voided→in_progress` (recall), and the `new→preparing` path (prefer auto-advance
  `pending→confirmed→in_progress`, or add `pending→in_progress`). Keep all 9 cases; remove nothing.
- **Migration** — `device_order_items`: `done BOOLEAN DEFAULT false`, `done_at TIMESTAMP NULL`;
  `device_orders`: `recalled SMALLINT DEFAULT 0`. Timer-freeze timestamps: reuse `OrderUpdateLog`
  or add `served_at`/`voided_at` (decide during build).
- **Payload** `app/Helpers/OrderBroadcastPayload.php` — add per-item `done`, `done_at`, `safety`
  (derive from `notes`/modifiers), item display name with safety modifier inlined after " — ";
  order-level `issued_at` (=`created_at`), `served_at`/`voided_at` (freeze), `recalled`,
  `void_reason` (voided only), `type` (`initial|refill`, derive from items `is_refill`), and KDS
  `state`.
- **Endpoints** `routes/web.php` (inside `can:admin`, `/kds` prefix): `index`,
  `orders/{order}/advance`, `items/{item}/toggle`, `orders/{order}/recall`. **No void endpoint.**
- **Controller** `app/Http/Controllers/Admin/KdsController.php` — thin; all writes in a
  transaction; audit via `OrderUpdateLog`; broadcast via **`OrderBroadcaster`** (NEX-013);
  per-item toggle via **`ItemToggled`** registered in `app/Broadcasting/BroadcastEvent.php`.
- **Feed**: KDS consumes existing `admin.orders` events + new `item.toggled`. Optimistic apply,
  reconcile on broadcast; last-write-wins on a monotonic version for multi-station.

## B3. Frontend work

- **Stripped full-viewport layout, dark default** (no admin sidebar).
  `resources/js/pages/KDS/Display.vue`. Fixed 1280×800 logical canvas, letterboxed/scaled.
- Components: `kds/KdsCommandBar.vue`, `kds/KdsFilterChips.vue`, `kds/KdsTicket.vue`,
  `kds/VoidedCard` variant.
- Composables: `useKdsTimer.ts`, `useKdsEcho.ts`, `useKdsBoard.ts`.
- Rules: Mark Ready disabled until `done==total`; terminal cards non-interactive; `RECALLED ×n`;
  refill pill; voided = dimmed + struck table + `void_reason`; ≥44×44px tap targets;
  reduced-motion suppresses overdue pulse.
- **Tokens (#144):** lift exact values from prototype `Woosoo KDS.html :root`.

## B4. Phasing

| Phase | Scope |
|---|---|
| P0 | Read-only board (no writes/migration) |
| P1 | Advance + Mark-Ready gating + item toggle (migration, `ItemToggled`) |
| P2 | Recall + voided-from-feed handling |
| P3 | Urgency thresholds + filters/sort + #144 tokens |
| P4 | Resilience (offline command queue, multi-station reconcile, server-authoritative time) |

## B5. Key risks / decisions (STOP before affected phase)

1. **Recall-from-voided makes `voided` non-terminal** — cross-system contract risk
   (`PosController`, `ProcessOrderLogs`, parity tests). Options: guarded edge, or re-fire as a
   *new* kitchen ticket without un-voiding. **DECIDE before P2.**
2. **`new→preparing` on a `pending` order** — auto-advance via `confirmed` vs add
   `pending→in_progress`.
3. **Order `type` (initial/refill)** derivation from per-item `is_refill`.
4. **Item `safety` flag source** — parse `notes`/modifiers vs allergen field.
5. **Threshold + recall-target config storage** — `SystemSetting` vs `kds_config`.
6. **Item display field:** designer §4.2 says `kitchen_name`; today payload uses
   `receipt_name ?? name` — verify POS field before build.

## B6. Verification

- Pest `tests/Feature/KdsControllerTest.php`: advance, gates, toggle, recall, void-from-feed,
  terminal immutability.
- Pest `tests/Unit/OrderStatusRecallTest.php`: new recall edges allowed; other terminal edges
  rejected.
- Manual E2E (Reverb+queue): full spec §7 acceptance checklist; two `/kds` tabs in sync.
- `npm run typecheck`, `npm run lint:check`, `vendor/bin/pest` green each phase.

## B7. Agent prompt (implementation agent)

```
ROLE: Implement Woosoo KDS in woosoo-nexus (Laravel 12 + Inertia + Vue 3). New /kds view + thin
endpoints + small additive migration — NOT a separate app/repo.

AUTHORITATIVE SOURCES (read first):
1. docs/cases/kds-implementation-plan.md § B + C (this file)
2. Prototype Woosoo KDS.html / kds-app.jsx / kds-data.jsx (visual truth; tokens from :root)
3. docs/kds-designer-spec.md (staging) — background only; § B wins on conflicts

STATE MAPPING (C5-corrected — backend OrderStatus ↔ KDS state):
  pending|confirmed → new ("New", Start Preparing → in_progress)
  in_progress       → preparing ("Preparing", Mark Ready [GATED: all items done] → ready)
  ready             → ready ("Ready", Mark Served → served)
  served            → served ("Served", Recall → in_progress)
  completed         → hidden (POS paid — card leaves active queue)
  voided            → voided ("Voided", from FEED only, Recall → in_progress)
  cancelled|archived → hidden

DeviceOrder::setStatusAttribute ENFORCES OrderStatus::canTransitionTo — add edges additively.

REUSE: DeviceOrder::scopeActiveOrder, OrderBroadcastPayload, OrderBroadcaster, admin.orders,
Echo singleton (resources/js/app.ts), Orders/Index.vue polling pattern, can:admin route group.

BUILD ORDER: P0 read-only → P1 writes+migration → P2 recall → P3 thresholds+tokens → P4 resilience.
Commit per phase; run gates each time.

HARD RULES:
- KDS writes ONLY: kitchen state, item done flags, recalled counter. Never price/qty/items,
  never create orders, never originate void.
- Mark Ready gated server-side; toast if blocked.
- Terminal cards (served/voided) non-interactive for item toggles.
- Initial and refill tickets NEVER merge.
- No per-table color coding; ≥44×44px tap targets.

STOP AND ASK (B5) before affected phase — especially recall-from-voided before P2.

VERIFICATION: typecheck + lint + pest each phase; KdsControllerTest + OrderStatusRecallTest.

PROCESS: Rebase on origin/dev first. Do NOT open PR unless asked.
```

---

# Appendix C — Three-layer order state model: Tablet ↔ Kitchen ↔ Payment

Added 2026-06-07. Grounded in verified code. Supersedes any single conflated label map in earlier
drafts.

## C0. Core principle

Three independent lifecycles — do not conflate:

1. **Payment/transaction** — bill paid? (POS-owned)
2. **Kitchen fulfillment** — where is the food? (KDS / staff-owned)
3. **Customer-facing progress** — guest tablet mirror (PWA, read-only)

They share `device_orders.status` today but answer different questions.

**Locked decisions:** 4 kitchen stages (New→Preparing→Ready→Served); Mark Served is staff action;
card stays until POS closes; tablet shows **all 4 stages literally**. Restaurant semantics:
**Ready = staff bringing order; Served = all items delivered** (guests grill at table).

## C1. Layer 1 — Payment / transaction (POS-owned, terminal)

- **Open** — bill unpaid (implicit below terminal kitchen states)
- **Completed** — paid & closed. **Terminal.**
- **Voided** — voided at POS. **Terminal.**
- **Cancelled** — cancelled before fulfillment. **Terminal.**

Set ONLY by payment path: `PosOrderStatusFinalizer`, `ProcessOrderLogs`, payment sync commands,
`SessionApiController`. `DeviceOrderObserver` fans out terminal events.

**Rule:** KDS card persists through all kitchen stages; leaves active queue only when Layer 1
reaches terminal (`completed` | `voided` | `cancelled`).

## C2. Layer 2 — Kitchen status (KDS, staff-driven)

| Stage | enum | Staff action | Meaning |
|---|---|---|---|
| **New** | `confirmed` | Start Preparing → `in_progress` | accepted, not started |
| **Preparing** | `in_progress` | Mark Ready → `ready` | assembling |
| **Ready** | `ready` | Mark Served → `served` | staff bringing to table |
| **Served** | `served` | *(none — POS closes)* | all items delivered |

`pending` is transient; creation sets **confirmed** immediately. Recall = `served → in_progress`
(additive enum edge).

## C3. Layer 3 — Tablet customer-facing progress (PWA)

Separate `tablet-ordering-pwa` repo. Mirrors kitchen **literally** from submission:

| Step | Driven by |
|---|---|
| Cart / Browsing | tablet-only |
| Sending… | tablet-only |
| Order received | `pending`/`confirmed` |
| Preparing | `in_progress` |
| Ready | `ready` |
| Served | `served` |
| Paid · Thank you / Cancelled | `completed` / `cancelled`\|`voided` |

Initial order and each refill = separate timelines (never merge).

## C4. Exchange (already wired)

1. Tablet POST → `confirmed` → `OrderCreated` → KDS **New**; tablet **Order received**.
2. Staff advance → `DeviceOrderObserver::updated` → `OrderStatusUpdated` on `orders.{order_id}`,
   `admin.orders`, etc. — payload includes `status`.
3. POS closes bill → terminal events → tablet **Paid**; KDS card drops from active queue.

No new plumbing for tablet↔kitchen reflection — only PWA status→step map (C3) in tablet repo.

## C5. Reconcile with Appendix B

B1 and B7 above use **`served → "Served"`** (Layer 2) and **hide on `completed`** (Layer 1).
When POS marks `completed`, drop the card from the active queue.

## C6. Work implied (when KDS/tablet resume — after stability pass)

| Repo | Work |
|---|---|
| **woosoo-nexus** | KDS per § B; C5 labels; recall edge; optional `contracts/` status→step doc for PWA |
| **tablet-ordering-pwa** | C3 map on `orders.{order_id}` subscription; per-order timelines; terminal states |
| **Neither** | No enum change required for customer view — existing `status` + payload suffice |

---

## Kitchen display device requirements (deployment)

Minimum: Android 10+ / iPadOS 14+; 10″ @ ≥1280×800; dual-band WiFi; USB-C power.

Wet/oily hands: large tap targets (≥44×44px); matte screen protector + enclosure for consumer
tablets; rugged IP-rated tablet for line kitchen; optional Phase-5 bump bar.

Deployment: TLS trusted by browser (else `wss://` fails silently → polling fallback); kiosk mode;
v1 uses admin web session; solid 5 GHz at mount point.

---

## Related

- Stability gate: `docs/cases/plt-case-stability-remediation.md`
- Backlog: `state/QUEUE.md` (KDS-EPIC row)
- Order state contract: `contracts/order-state.contract.md`
