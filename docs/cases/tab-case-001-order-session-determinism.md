---
status: under-review
last_reviewed: 2026-05-17
scope: tablet-ordering-pwa
---

# CASE: tab-case-001-order-session-determinism

Order submission and session consistency fixes for tablet-ordering-pwa to address critical determinism issues.

## Run State
- task_slug: tab-case-001-order-session-determinism
- tier: 2
- branch: agent/tab-case-001-order-session-determinism
- status: IN_PROGRESS
- last_completed_agent: specialist:chuya-frontend (Fix 1 + Fix 2)
- next_agent: specialist:chuya-frontend
- active_runner: copilot
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-18

## Handoff
- Phase in progress: specialist:chuya-frontend — Fix 1+2 of 4 complete; Fix 3–4 remain
- Done so far: Fix 1 (offline contradiction) `ab0dbae`; Fix 2 (dead composables removed, idempotency key centralised) `2111f84`. 369/369 tests pass.
- Exact next action: specialist:chuya-frontend — Fix 3: single persistence owner — remove manual localStorage writes in stores/session.js, use only Pinia with proper hydration. See ## Proposed Fix → Fix 3.
- Working-tree state: clean (commit 2111f84 on staging in tablet-ordering-pwa)
- Risks / do-not-redo: do not re-add BackgroundSyncPlugin; do not re-introduce useOrderSubmission or useOfflineOrderQueue

## Tier
2

## Branch
agent/tab-case-001-order-session-determinism

## Problem

Critical order and session consistency issues identified in the Tablet PWA audit that create race conditions and inconsistent state:

1. **Offline ordering contradiction** - PWA ships offline outbox but blocks submit on offline
2. **Order submission abstraction overlap** - 4 overlapping composables for the same flow
3. **Session persistence conflicts** - localStorage vs Pinia fighting over state
4. **Bootstrap tolerance** - Silent proceed on bootstrap failure

## Contrarian Review

**Conducted:** 2026-05-18 (claude-code)

This is Tier 2 work because it fixes critical correctness issues in the customer-facing ordering flow without touching authentication or cross-app contracts. The offline contradiction is the single biggest correctness risk in the PWA.

### 7 Questions Assessment

| # | Question | Answer |
|---|----------|--------|
| 1 | Correct app scope? | Yes - PWA client-side issues only |
| 2 | Already exists? | No - novel audit findings |
| 3 | Scope as described? | Yes - Tier 2 appropriate |
| 4 | What breaks if wrong? | Customer ordering fails, duplicates, lost sessions |
| 5 | Simpler path? | No - 4 distinct fixes required |
| 6 | Contract/auth/state/payment/print? | No - Tier 2 confirmed |
| 7 | Split per app? | No - single-app scope |

**Verdict:** PROCEED with Tier 2 sequence.

### Risk Assessment
- **High risk** of duplicate orders due to abstraction overlap
- **Medium risk** of stale session state causing ordering errors
- **High risk** of customer frustration from offline inconsistency
- **Medium risk** of session loss during bootstrap failures

### Dependencies
- Contract references: `../contracts/tablet-api.contract.md`
- Single-app scope (tablet-ordering-pwa only)
- Depends on Nexus auth fixes for proper session handling

### Specialist Priority
1. **Fix 1 first** (offline contradiction) - highest customer impact
2. Fix 2 (consolidate composables)
3. Fix 3 (persistence owner)
4. Fix 4 (bootstrap failure)

## Investigation

Files identified in audit requiring changes:
- `components/OrderingStep3ReviewSubmit.vue` - Offline block
- `composables/useOrderSubmit.js` - Order submission
- `composables/useOrderSubmission.js` - Order submission (duplicate)
- `composables/useSubmissionIdempotency.js` - Idempotency
- `composables/useOfflineOrderQueue.js` - Offline queue
- `stores/session.js` - Session persistence
- `pages/bootstrap.vue` - Bootstrap handling

## Root Cause

1. **Offline contradiction**: Service worker enables offline but UI blocks submit
2. **Abstraction overlap**: 4 composables handle similar order submission logic
3. **Persistence conflicts**: Manual localStorage writes conflict with Pinia
4. **Bootstrap tolerance**: No clear failure policy, silent failures allowed

## Proposed Fix

### Fix 1: Resolve Offline Ordering Contradiction
**Files:** `components/OrderingStep3ReviewSubmit.vue`, service worker
**Decision Point:** Choose between live-only vs true-offline model
**Acceptance:** Clear offline behavior contract enforced
**Rollback:** Restore original offline block if live-only breaks workflows
**Test:** Offline scenario test suite (network disable, submit attempts)

### Fix 2: Consolidate Order Submission Abstractions
**Files:** `composables/useOrderSubmit.js`, `composables/useOrderSubmission.js`, `composables/useSubmissionIdempotency.js`, `composables/useOfflineOrderQueue.js`
**Change:** Merge into single composable with clear responsibilities
**Acceptance:** Single source of truth for order submission logic
**Rollback:** Keep original files as backup during consolidation
**Test:** Duplicate submit prevention test, idempotency test

### Fix 3: Single Persistence Owner
**Files:** `stores/session.js`, any manual localStorage usage
**Change:** Remove manual localStorage, use only Pinia with proper hydration
**Acceptance:** No conflicting state sources, clean hydration
**Rollback:** Restore localStorage fallback if Pinia hydration fails
**Test:** State consistency test across page reloads

### Fix 4: Bootstrap Failure Policy
**Files:** `pages/bootstrap.vue`, error handling
**Change:** Implement "no silent proceed" - clear error states on failure
**Acceptance:** Bootstrap failures show clear error, no silent continuation
**Rollback:** Restore tolerant bootstrap if too strict for production
**Test:** Bootstrap failure simulation test

## Files Changed

- `components/order/OrderingStep3ReviewSubmit.vue` — isButtonDisabled now includes `!isOnline.value`; proactive offline warning banner added above CTA; button label shows "No Connection" when offline (`ab0dbae`)
- `public/sw.ts` — BackgroundSyncPlugin removed; create-order route changed to plain NetworkOnly; live-only contract documented in header (`ab0dbae`)
- `tests/sw-precache.spec.ts` — contract test updated to assert no bgSyncPlugin on any order route (`ab0dbae`)
- `composables/useOrderSubmission.ts` — DELETED (dead code: imported but never called in review.vue) (`2111f84`)
- `composables/useSubmissionIdempotency.ts` — DELETED (dead code: only used by deleted composable) (`2111f84`)
- `composables/useOfflineOrderQueue.ts` — DELETED (dead code: never imported anywhere) (`2111f84`)
- `utils/orderHelpers.ts` — added exported `generateIdempotencyKey()` utility (`2111f84`)
- `composables/useOrderSubmit.ts` — import `generateIdempotencyKey` from utils/orderHelpers (`2111f84`)
- `composables/useRefillSubmit.ts` — import `generateIdempotencyKey` from utils/orderHelpers (`2111f84`)
- `pages/order/review.vue` — removed unused `useOrderSubmission` import (`2111f84`)
- `tests/order-submit-source-contract.spec.ts` — 3 new contract tests locking in the cleanup (`2111f84`)

## Verification

### Functional Tests Required
1. **Offline Behavior Test**: Test submit behavior in offline mode
2. **Duplicate Submit Test**: Verify idempotency with rapid submits
3. **State Consistency Test**: Test session state across reloads
4. **Bootstrap Failure Test**: Test error handling on bootstrap failure

### Acceptance Criteria
- [ ] Offline ordering behavior is consistent (chosen model enforced)
- [ ] Single order submission composable with clear responsibilities
- [ ] No localStorage vs Pinia state conflicts
- [ ] Bootstrap failures show clear errors, no silent proceed
- [ ] All existing ordering flows preserved for online users
- [ ] Performance impact < 100ms on order submission

### Performance Requirements
- Order submission latency < 2 seconds
- State hydration < 500ms on page load
- No memory leaks from composable consolidation

## Executioner Verdict

*To be completed after verification*

## Remaining Risks

1. **Breaking existing workflows** - Offline model change may affect restaurant operations
2. **State migration complexity** - Moving from localStorage to Pinia may lose existing sessions
3. **Composable consolidation bugs** - Risk of missing edge cases in merged logic
4. **Bootstrap strictness** - May be too strict for production environments

## Contract References

- `../contracts/tablet-api.contract.md` - Tablet API contracts
- `tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md` - Audit findings
- Root `AGENTS.md` - Frontend scope rules
