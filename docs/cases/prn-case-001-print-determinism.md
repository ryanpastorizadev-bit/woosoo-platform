---
status: under-review
last_reviewed: 2026-05-17
scope: woosoo-print-bridge
---

# CASE: prn-case-001-print-determinism

Print job determinism and reliability fixes for woosoo-print-bridge to address critical print reliability issues.

## Run State
- task_slug: prn-case-001-print-determinism
- tier: 2
- branch: agent/prn-case-001-print-determinism
- status: IN_PROGRESS
- last_completed_agent: none
- next_agent: contrarian
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-17 20:53

## Handoff
- Phase in progress:
- Done so far:
- Exact next action:
- Working-tree state:
- Risks / do-not-redo:

## Tier
2

## Branch
agent/prn-case-001-print-determinism

## Problem

Critical print reliability issues identified in the Print Bridge audit that cause jobs to strand and miss events:

1. **ACK backlog stranding** - Jobs park in `printedAwaitingAck` indefinitely
2. **Polling watermark loss** - `_since = now - 10 minutes` loses old events after downtime
3. **Test suite red** - Cannot verify changes with failing baseline
4. **No retention policy** - Storage grows without bounds

## Contrarian Review

This is Tier 2 work because it fixes critical print reliability issues without touching authentication or cross-app contracts. The ACK backlog is the highest risk issue that can cause permanent job loss.

**Risk assessment:**
- **High risk** of permanent job loss in ACK backlog
- **High risk** of missed orders after long downtime
- **Medium risk** of storage exhaustion without retention
- **High risk** of deploying changes without reliable test suite

**Dependencies:**
- Contract references: `../contracts/printer-relay.contract.md`
- Single-app scope (woosoo-print-bridge only)
- Must green test suite before any other changes

## Investigation

Files identified in audit requiring changes:
- `lib/services/polling_service.dart` - Polling watermark logic
- `lib/state/app_controller.dart` - ACK handling, job state machine
- `lib/services/print_job_service.dart` - Print job lifecycle
- `test/` - Entire test suite needs fixing
- Storage layer - Need retention policy implementation

## Root Cause

1. **ACK backlog**: No age/attempt ceilings for `printedAwaitingAck` jobs
2. **Polling watermark**: Fixed 10-minute window drops events during long downtime
3. **Test suite**: Multiple test failures prevent reliable verification
4. **Retention**: No cleanup for successful jobs, dead letters, metrics

## Proposed Fix

### Fix 1: ACK Backlog Terminal Policy
**Files:** `lib/state/app_controller.dart`, `lib/services/print_job_service.dart`
**Change:** Add age + attempt ceilings with terminal path for stranded jobs
**Acceptance:** Jobs don't strand indefinitely, clear terminal conditions
**Rollback:** Remove age/attempt ceiling logic
**Test:** ACK timeout simulation, attempt limit test

**Measurable criteria:**
- Jobs older than 30 minutes in `printedAwaitingAck` marked dead-letter
- Jobs with > 5 retry attempts marked dead-letter
- Dead-letter jobs logged with age and attempt count

### Fix 2: Polling Resume Cursor
**Files:** `lib/services/polling_service.dart`
**Change:** Replace 10-minute synthetic window with persistent cursor
**Acceptance:** No missed events after downtime, proper cursor persistence
**Rollback:** Restore 10-minute window logic
**Test:** Downtime simulation, cursor persistence test

**Measurable criteria:**
- Cursor persisted to local storage after each successful poll
- Resume from exact last processed event timestamp
- No event loss during 2+ hour downtime scenarios

### Fix 3: Green Test Suite
**Files:** `test/unit/polling_service_test.dart`, `test/unit/app_controller_enqueue_test.dart`, entire test suite
**Change:** Fix all failing tests to establish reliable baseline
**Acceptance:** All 102 tests pass consistently
**Rollback:** Keep failing test backups for reference
**Test:** Run full test suite multiple times

**Measurable criteria:**
- `flutter test` shows "All tests passed!" consistently
- No flaky tests (same results across multiple runs)
- Test coverage maintained or improved

### Fix 4: Retention Policy Implementation
**Files:** Storage layer, `lib/services/metrics_service.dart`
**Change:** Implement cleanup for old successful jobs, dead letters, metrics
**Acceptance:** Bounded storage usage, automated cleanup
**Rollback:** Disable cleanup jobs if storage issues occur
**Test:** Storage growth simulation, cleanup verification

**Measurable criteria:**
- Successful jobs retained 7 days, then auto-deleted
- Dead-letter jobs retained 30 days, then auto-deleted
- Metrics data retained 90 days, then auto-deleted
- Storage usage stays under 100MB with normal load

## Files Changed

*To be populated during implementation*

## Verification

### Functional Tests Required
1. **ACK Timeout Test**: Simulate jobs stuck in ACK state
2. **Polling Resume Test**: Test cursor persistence across restarts
3. **Downtime Recovery Test**: Simulate long downtime scenarios
4. **Storage Cleanup Test**: Verify retention policy enforcement
5. **Full Test Suite**: Run all 102 tests consistently

### Acceptance Criteria
- [ ] ACK backlog has terminal policy (30min age or 5 attempts)
- [ ] Polling cursor persists across app restarts
- [ ] No events lost during 2+ hour downtime
- [ ] All 102 tests pass consistently
- [ ] Storage usage stays bounded with retention policy
- [ ] Print reliability > 99.5% in test scenarios

### Performance Requirements
- ACK processing < 100ms per job
- Polling resume < 500ms after restart
- Storage cleanup < 50ms per batch
- Test suite execution < 5 minutes

## Executioner Verdict

*To be completed after verification*

## Remaining Risks

1. **Job loss during ACK policy change** - Risk of marking active jobs as dead-letter
2. **Cursor corruption** - Polling cursor could become invalid
3. **Storage cleanup bugs** - Risk of deleting active jobs
4. **Test suite stability** - Fixed tests may still be flaky in CI

## Contract References

- `../contracts/printer-relay.contract.md` - Print relay contracts
- `woosoo-print-bridge/docs/WOOSOO_PRINT_BRIDGE_PRODUCTION_RELIABILITY_AUDIT_2026-05-14.md` - Audit findings
- Root `AGENTS.md` - Print bridge scope rules
