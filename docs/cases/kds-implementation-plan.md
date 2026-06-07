---
status: canonical
last_reviewed: 2026-06-07
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
- tier: 3
- branch: claude/happy-cannon-2nR48 (rebase on origin/dev before work)
- status: BLOCKED
- last_completed_agent: contrarian (spec consolidation + C5 label reconciliation)
- next_agent: specialist:ranpo-backend | specialist:chuya-frontend (Phase 0 split by layer)
- active_runner: none
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-07
- blocked_by: plt-case-stability-remediation

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

Remaining mock limitations (expected): no live feed, client-side-only transitions, `html:has(.kds-viewport)` global overflow lock while on page.

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
