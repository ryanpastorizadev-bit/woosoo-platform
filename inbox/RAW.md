# Raw Intake

Append-only raw issue log. Raw entries are reports, not implementation tasks.

---

## Format

```markdown
### RAW-YYYYMMDD-NNN
Date:        YYYY-MM-DD
Source:      User / Client / Logs / Screenshot / Manual Testing / Production
Urgency:     Low / Medium / High / Critical
App:         Unknown / woosoo-nexus / tablet-ordering-pwa / woosoo-print-bridge / woosoo-platform

Raw report:
<verbatim report>

Notes:
<agent observation>

Status: needs_triage
```

---

### RAW-20260517-001
Date:        2026-05-17
Source:      User
Urgency:     Critical
App:         woosoo-nexus

Raw report:
This paste shows **two real backend issues**:

1. **POS stored procedure missing**
   `get_open_orders_for_session` does not exist on POS DB (`SQLSTATE 1305`) at `19:44:47` (line 70).

2. **Realtime publish failure to Reverb**
   Laravel failed to broadcast with `cURL error 7` to `http://192.168.100.7:8080/apps/woosoo/events` (lines 84, 186), so order creation succeeded but realtime broadcast failed.

Also present:
- `Legacy non-idempotent print event path used` warning (line 81): request lacked `client_submission_id`.
- Repeated relay heartbeat scans are normal info logs (`processed: 0`), not failures.

So root problems in this paste are **POS DB procedure drift** and **Nexus → Reverb internal connectivity on port 8080**.

Notes:
Immediate triage from raw report only: likely Tier 3 backend/platform issue because it touches POS DB behavior, realtime order broadcasts, and print idempotency warning context. Suspected primary app is woosoo-nexus; Reverb connectivity may involve infrastructure but should be confirmed during triage before splitting.

Status: needs_triage

### RAW-20260518-001
Date:        2026-05-18
Source:      User
Urgency:     High
App:         tablet-ordering-pwa

Raw report:
review : I'll start by exploring the project structure and loading the appropriate hook for a review task.

Let me check the state files and explore the PWA structure more deeply.

Let me read the comprehensive analysis documents and explore key source files to identify issues.

Let me explore more source files to identify potential issues - the composables, pages, and stores.

Let me continue examining the stores and more composables for issues.

Let me examine the pages and more composables to complete the review.

Let me continue the review by examining more files - the Device store, Menu store, additional composables, and tests.

Let me check the tests and a few more key files to complete the review.

Let me check a few test files and the utils folder to complete my review.



Based on my comprehensive review of the tablet-ordering-pwa codebase, here is a structured summary of findings:

---

## Review Summary: tablet-ordering-pwa

### 🔴 **Critical Issues**

| Issue | Location | Impact |
|-------|----------|--------|
| **Race Condition in Session End** | `stores/Session.ts:386-400` | The [end()](cci:1://file:///e:/Projects/woosoo-platform/tablet-ordering-pwa/stores/Session.ts:385:4-399:5) method is wrapped in mutex but fire-and-forget calls in other stores (e.g., `Order.ts:630, 646`) don't await it, causing potential state corruption during session cleanup |
| **Missing Await on Critical Cleanup** | `stores/Order.ts:630, 646` | [sessionStore.end()](cci:1://file:///e:/Projects/woosoo-platform/tablet-ordering-pwa/stores/Session.ts:385:4-399:5) called without await after terminal status detection - session may not complete cleanup before new session starts |
| **Direct localStorage Access in Computed** | `composables/useActiveOrderRecovery.ts:35` | [window.localStorage?.getItem()](cci:1://file:///e:/Projects/woosoo-platform/tablet-ordering-pwa/tests/order.submit.spec.ts:14:8-14:102) called without SSR guard in computed context - will crash in SSR/prerender scenarios |
| **Optional Chain on Potentially Undefined Computed** | `composables/useActiveOrderRecovery.ts:33` | `orderStore.getPackage?.value?.id` - `getPackage` is a computed that could be undefined, not a function |

---

### 🟠 **High Priority Issues**

| Issue | Location | Impact |
|-------|----------|--------|
| **Inconsistent Store Patterns** | [stores/](cci:9://file:///e:/Projects/woosoo-platform/tablet-ordering-pwa/stores:0:0-0:0) | Menu store uses Options API (`state/actions/getters`) while Order/Session/Device use Composition API (`reactive/computed`) - increases cognitive load and maintenance burden |
| **Tight Cross-Store Coupling** | `stores/Order.ts:10-12`, `stores/Session.ts:5-7` | Stores import each other creating circular dependency risk and making unit testing difficult |
| **Excessive `any` Types** | `composables/useBroadcasts.ts:138-142`, `stores/Order.ts:90-91` | WebSocket channels and API responses typed as `any` - defeats TypeScript safety for critical real-time features |
| **WebSocket Max Reconnection Too Aggressive** | `composables/useBroadcasts.ts:153` | Max 10 attempts with up to 30s backoff = ~90s total outage before giving up - no persistent queue for missed events during disconnection |
| **Offline Queue Only Handles Orders** | [composables/useOfflineOrderQueue.ts](cci:7://file:///e:/Projects/woosoo-platform/tablet-ordering-pwa/composables/useOfflineOrderQueue.ts:0:0-0:0) | Refill submissions are not queued for offline retry - customers can't add items while offline |
| **PIN Modal Accessibility Gap** | `pages/index.vue:30-95` | No screen reader announcements for digit entry/deletion; readonly input doesn't communicate state changes |

---

### 🟡 **Medium Priority Issues**

| Issue | Location | Impact |
|-------|----------|--------|
| **Unnecessary Prerender Config** | `nuxt.config.ts:113-116` | SPA mode with `prerender.routes: ["/"]` creates unused server output |
| **Memory Leak Risk in Broadcasts** | `composables/useBroadcasts.ts:145, 360-361` | Multiple timer IDs tracked but cleanup could race with new subscriptions |
| **No Deduplication in Offline Queue** | `composables/useOfflineOrderQueue.ts:66-76` | Same order could be queued multiple times if user taps submit repeatedly while offline |
| **Error Messages May Leak Details** | `stores/Order.ts:500-592` | Error classification is good but some paths could expose internal details through logger |
| **Missing Cancellation for Menu Fetch** | `stores/Menu.ts:189-205` | No AbortController for fetch requests - requests may complete after component unmount |
| **PWA Cache Size** | `nuxt.config.ts:170` | 10MB max file size for SW cache may be excessive for tablet storage constraints |

---

### ✅ **Positive Findings**

| Area | Observation |
|------|-------------|
| **Idempotency Implementation** | Well-designed with [useSubmissionIdempotency.ts](cci:7://file:///e:/Projects/woosoo-platform/tablet-ordering-pwa/composables/useSubmissionIdempotency.ts:0:0-0:0) and proper idempotency keys for order/refill submission |
| **Session Boundary Safety** | [Session.ts](cci:7://file:///e:/Projects/woosoo-platform/tablet-ordering-pwa/stores/Session.ts:0:0-0:0) clears offline queue and order state on session end - prevents cross-session data leakage |
| **Network Recovery** | [useNetworkStatus.ts](cci:7://file:///e:/Projects/woosoo-platform/tablet-ordering-pwa/composables/useNetworkStatus.ts:0:0-0:0) properly tracks online/offline with recovery detection |
| **Error Classification** | [useErrorClassifier.ts](cci:7://file:///e:/Projects/woosoo-platform/tablet-ordering-pwa/composables/useErrorClassifier.ts:0:0-0:0) provides customer-safe error messages without technical details |
| **Build Configuration** | Comprehensive Docker setup with production-optimized nginx configuration |
| **Test Coverage** | 52 test files covering order submission, session management, offline sync, and UI contracts |

---

### **Recommended Priority Actions**

1. **Fix race conditions** in session cleanup by ensuring all [sessionStore.end()](cci:1://file:///e:/Projects/woosoo-platform/tablet-ordering-pwa/stores/Session.ts:385:4-399:5) calls are awaited
2. **Add SSR guards** to all localStorage/window accesses in computed/getters
3. **Standardize store pattern** - migrate Menu store to Composition API for consistency
4. **Extend offline queue** to handle refill submissions
5. **Add AbortController** to API requests for proper cancellation
6. **Reduce PWA cache limit** to 5MB for tablet storage constraints

---

### **Edge Cases Identified**

- **Sleep/Wake Recovery**: App handles visibility changes but could lose WebSocket events during extended sleep (>5min threshold)
- **Order Status Sync**: Race between broadcast status update and polling could show stale status briefly
- **Refill Validation**: Only meats/sides allowed in refill but validation happens after API call - should pre-validate
- **Package Restoration**: Menu page watches for cleared package but could restore stale selection after session end

The codebase is generally well-architected with good separation of concerns and comprehensive testing, but has several concurrency and edge-case issues that should be addressed before production deployment.

Notes:
Initial validation found that multiple claimed critical issues are unconfirmed in current code, but several medium/high issues remain valid and need triage into implementation work.

Status: triaged -> TAB-CASE-002

### RAW-20260518-002
Date:        2026-05-18
Source:      User
Urgency:     Critical
App:         woosoo-nexus

Raw report:
woosoo-nexus login returns 500 server error

Notes:
Bug report: POST /api/devices/login endpoint returns HTTP 500. Requires investigation of DeviceAuthApiController@authenticate to identify root cause. Could be device lookup failure, token generation failure, or data validation issue.

Deferred: This is a known Critical intake item. Triaging a live nexus 500 is a standalone Tier-3 task (separate from this reconciliation). See TRIAGED.md for tracking. Do not conflate with NEX-CASE-001 (security hardening, now COMPLETE).

Status: needs_triage
