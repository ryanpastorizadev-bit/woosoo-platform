---
status: IN_PROGRESS
last_reviewed: 2026-05-19
scope: woosoo-nexus
---

# CASE: nex-case-005-legacy-print-path

Order submission hitting legacy non-idempotent print event path in production — `client_submission_id` absent from request.

## Run State
- task_slug: nex-case-005-legacy-print-path
- tier: 2
- branch: agent/nex-case-005-legacy-print-path
- status: IN_PROGRESS
- last_completed_agent: none
- next_agent: contrarian
- active_runner: none
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-19

## Handoff
- Phase in progress: none — Contrarian not yet started
- Done so far: Triaged from RAW-20260519-002 (intake 2026-05-19)
- Exact next action: Contrarian to assess scope — determine which submit path omits `client_submission_id` and whether a silent idempotency failure is occurring downstream at the print bridge.
- Working-tree state: no changes
- Risks / do-not-redo: PRN-CASE-001 fixed print determinism on the print-bridge side; this is the upstream Laravel submit path. Do not conflate. Do not modify order submission logic without Contrarian gate.

## Tier
2

## Branch
agent/nex-case-005-legacy-print-path

## Problem

Production log 2026-05-19 18:54:
```
Legacy non-idempotent print event path used
```

A request reached the order/print dispatch without a `client_submission_id`. No confirmed functional order failure at time of observation, but the warning indicates a code path that bypasses idempotency guarantees added by PRN-CASE-001.

Source: RAW-20260519-002.

**Separation from PRN-CASE-001:** that case fixed the print bridge receiver to handle duplicate events. This case is the upstream cause — the Laravel submit path that emits without an idempotency key.

## Contrarian Review

_Pending — Contrarian has not yet run._

## Investigation

## Root Cause

## Proposed Fix

## Files Changed

## Verification

## Executioner Verdict

## Remaining Risks
