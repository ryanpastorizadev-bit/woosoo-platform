# Woosoo Platform — Session Status Summary

**Date:** 2026-05-21

## Today's Shipped Work

### woosoo-nexus (10 commits)
| Commit | Description |
|---|---|
| `1d6b08a` | Print event items always attached (the blank-receipt root fix) |
| `1aebf41` | `register()`/`refresh()` POS-down hardening; refill legacy-path removal; stuck refill_submission sweeper |
| `d442a45` | Delete dead `processLegacyRefill` (170 lines) |
| `02b6394` | POS sync skips silently when POS unreachable |
| `585cc39` | Admin `/monitoring` print-health dashboard + session reset/force-end controls |
| `2489191` | Monitoring refactor: N+1 fix, useToast, POS lookup cache, abs() clock-skew, hidden-tab polling |
| `7eeb864` | Default placeholder → `2.webp`; document image-resolution chain |
| **`2b83283`** | **P0 — removed phantom `device_orders.print_event_id` writes** (the silent SQL bug that killed broadcasts all day) |

### woosoo-platform (2 commits)
| Commit | Description |
|---|---|
| `1e78a4e` | `REVERB_BROADCAST_HOST=reverb` (server-side publish uses Docker DNS) |
| `f3fcf50` | nginx `:4443` serves `/images`, `/storage`, `/build` from Laravel public |

### tablet-ordering-pwa (2 commits)
| Commit | Description |
|---|---|
| `c7971a0` | NuxtImg `@error` fallback; remove modal `px-3` causing right-edge clip |
| `5fbbda0` | Delete dead `SupportFab`/`InSessionMain`/`QuickButtons` (incl. "blue support hand" + hardcoded "Table 4"); fix MenuHeader duplicate table name; clearer disabled-state labels |

### woosoo-print-bridge (1 commit, **APK not yet rebuilt/installed**)
| Commit | Description |
|---|---|
| `830fdfd` | Polling 30s→5s; HTTP timeouts 10-15s→30s |

---

## End-to-End Status

- ✅ Orders place + print correctly with real item names
- ✅ Broadcast pipeline works (PrintEvent's `broadcast_at` populates after `2b83283`)
- ✅ REVERB_BROADCAST_HOST + queue worker confirmed functional
- ✅ Admin print-health dashboard renders live data
- ✅ Manual Reset / Force-end actions succeed server-side
- ⚠️ Tablets stuck on in-session require **manual refresh** after force-end (WS-zombie state)

---

## Active Architectural Work (in another session)

### POS Outbox Session Reset (case `nex-case-007`, **on testing status**)

**Goal:** Replace minute-level POS polling with POS-local outbox trigger + 5-second consumer. Tablets reset within ~5 s of POS close/void.

**New files (in branch under test):**
- `app/Console/Commands/ConsumePosPaymentStatusEvents.php`
- `app/Services/Pos/PosOrderStatusFinalizer.php`
- `tests/Feature/Console/PosPaymentOutbox{Consumer,Setup}Test.php`

**Modified:** `SetupPosOrderPaymentTrigger.php`, `SyncPosOrderPaymentStatus.php`, `routes/console.php`

**Already partially right:** A *separate* `woosoo_session_status_outbox` + `after_session_close_update` trigger now exists for daily session close, which is the correct architectural split.

---

## 🔴 Open Bugs (paused, waiting for POS Outbox merge)

| # | Sev | What | Location |
|---|---|---|---|
| 1 | Critical | `PosOrderStatusFinalizer::dispatchTerminalEvents` fires `SessionReset` per individual order completion → kicks every tablet in the restaurant to welcome screen each time any table pays | `PosOrderStatusFinalizer.php:85-87` |
| 2 | Critical | Two existing tests assert this wrong behavior (`SessionReset::class` dispatched per-order) — would mask the bug if shipped | `PosPaymentOutboxConsumerTest.php:55, 81` |
| 3 | Medium | Tablet `last_seen_at` only updates on register/refresh/auth — admin Devices panel shows actively-used tablets as offline | `DeviceAuthApiController` only writes; no middleware on regular API calls |
| 4 | Medium | Tablets' Echo WebSocket can enter zombie "connected-but-dead" state silently; SessionReset broadcasts dropped on the floor | `useBroadcasts.ts` — no silent-death detector |
| 5 | Low | Print bridge `830fdfd` (polling 5s, timeouts 30s) committed but APK never rebuilt + installed | Build step pending |

---

## Next Steps (in order, when ready)

1. **Wait for POS Outbox owner to complete + merge** (case `nex-case-007`)
2. **Apply Phase 15 fixes** to nexus once POS Outbox is in main:
   - PR-A: Remove `SessionReset::dispatch` from `PosOrderStatusFinalizer`; update 2 existing test assertions; add 3-table regression test (verifies `SessionReset` is **not** dispatched per-order)
   - PR-B: Add `UpdateDeviceLastSeen` middleware (throttled write of `last_seen_at` on authenticated device API requests)
3. **Add a `pos:consume-session-close-events` consumer** that reads `woosoo_session_status_outbox` and dispatches `SessionReset` (the table + trigger already exist; the consumer is not yet shipped)
4. **Build + install the bridge APK** (`830fdfd`) on the tablet — needed before restaurant deploy for the latency floor improvement
5. **Restaurant deploy:** pull all repos, run `pos:setup-payment-trigger` on Pi (POS local), redeploy, run smoke test (place 3 orders across 3 tables, pay one, verify only that one tablet resets)

---

## What's Working Today vs Tomorrow

| Capability | Today | After POS Outbox merge + Phase 15 |
|---|---|---|
| Order → print latency | 2-10 s (when WS healthy) | Same |
| Cashier closes bill → that table's tablet resets | ~60 s (minute-level poll + per-order `OrderCompleted`) | ~5 s |
| End-of-day session close → all tablets reset | manual force-end | automatic via new session-close outbox + consumer |
| Multi-table safety | manual force-end risks all-tablet reset only if WS healthy on others | safe — per-order events only hit the right tablet |

Plan file with full detail lives in each contributor's local `~/.claude/plans/` directory (Phase 15 plan: `let-s-deploy-on-raspberry-jolly-prism.md`).