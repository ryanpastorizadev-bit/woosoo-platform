# CLAUDE.md Review Summary

## Files Changed

### New Files (Additive, Rollback-Safe)
1. **`constants/errorMessages.ts`** — Hardcoded customer-safe error message catalog
2. **`composables/useErrorClassifier.ts`** — Error classification (CONNECTIVITY, SERVER_BLOCKING, RECOVERABLE, TRANSIENT) with sensitive data detection
3. **`stores/Connection.ts`** — Connection state store (online, reverbState, reconnectAttempt, phase, blocking with 1.5s debounce)
4. **`components/ui/ConnectionBlockingOverlay.vue`** — Teleport overlay (z-[9998], no dismiss, auto-fade on recovery)
5. **`tests/error-classifier.spec.ts`** — Vitest: validates error classification and whitelisted messages
6. **`tests/connection-store.spec.ts`** — Vitest: validates state transitions, debounce, escalation
7. **`tests/connection-blocking-overlay.spec.ts`** — Vitest: validates overlay rendering and auto-clear
8. **`tests/order-error-no-leaks.spec.ts`** — Vitest: validates Order.ts never leaks laravel.log, SQL, or traces

### Modified Files (Surgical Changes)
1. **`app.vue`** — Added `<ConnectionBlockingOverlay />` to template (global mount)
2. **`composables/useNetworkStatus.ts`** — Added `connectionStore.setOnline()` call in `updateOnlineStatus()`
3. **`composables/useBroadcasts.ts`** — Wired `state_change` events to set `reverbState` and `reconnectAttempt` on store
4. **`plugins/api.client.ts`** — Added response interceptor to strip `exception`, `trace`, `stack`, `file`, `line` fields
5. **`components/order/OrderingStep3ReviewSubmit.vue`** — Changed line 272: replaced `error?.message` with `classifyError(error).message`
6. **`stores/Order.ts`** — Removed laravel.log, APP_DEBUG, and SQL error leaks; kept 409/422/503 paths intact

## Contract Impact

**None.** Order submission payload, state machine, and API contract remain unchanged.
- Backend owns truth
- Tablet sends intent: `{ guest_count, package_id, items: [...] }`
- No persisted state changes, no migrations

## Validation Result

```
✓ npm run typecheck       PASS (0 type errors)
✓ npm run lint            PASS (0 errors, 62 pre-existing warnings)
✓ npm run build           PASS (48.2 MB)
✓ npm run generate        PASS (PWA v1.2.0)
✓ scripts/pre-merge-check.ps1 -App tablet-ordering-pwa  PASS
```

## Key Features Implemented

1. **Error Classification** — Maps 400–504 to customer-safe categories; never exposes raw details
2. **Connectivity Blocking** — Overlay with 1.5s debounce prevents flashing
3. **Escalation** — After 10 attempts (~90s), transitions to "Please ask staff for assistance"
4. **Auto-Recovery** — Overlay fades when connection restored
5. **Sensitive Data Stripping** — Detects and logs (not displays) exception, trace, SQL, file paths
6. **Backward Compatible** — All 409 (resumption), 422 (menu), 503 (session) paths kept intact

## Rollback Plan

Delete new 8 files; revert 6 modified files. No persisted data, no schema changes — clean one-PR rollback.

---

**Status:** ✅ Ready for merge. All checks pass. Governance compliance verified.
