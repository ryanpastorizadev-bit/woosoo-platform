---
status: IN_PROGRESS
last_reviewed: 2026-05-19
scope: woosoo-nexus
---

# CASE: nex-case-004-device-login-500

Device login endpoint (`POST /api/devices/login`) returns HTTP 500 in production.

## Run State
- task_slug: nex-case-004-device-login-500
- tier: 3
- branch: agent/nex-case-004-device-login-500
- status: IN_PROGRESS
- last_completed_agent: none
- next_agent: contrarian
- active_runner: none
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-19

## Handoff
- Phase in progress: none — Contrarian not yet started
- Done so far: Triaged from RAW-20260518-002 (intake 2026-05-18; deferred until NEX-CASE-001 COMPLETE — blocker now resolved)
- Exact next action: Contrarian must produce written risk analysis before any fix is proposed. Do not pre-solve.
- Working-tree state: no changes
- Risks / do-not-redo: Tier 3. Authentication endpoint — any change risks locking out all devices. Contrarian gate is mandatory. Separate code path from NEX-CASE-003 (POS stored procedure); do not conflate.

## Tier
3

## Branch
agent/nex-case-004-device-login-500

## Problem

`POST /api/devices/login` (`DeviceAuthApiController@authenticate`) returns HTTP 500 in production.

Source: RAW-20260518-002 (first observed 2026-05-18). Deferred at intake pending NEX-CASE-001 (security hardening) completion — NEX-CASE-001 is now COMPLETE.

Possible failure classes (not yet confirmed — reserved for Contrarian):
- Device lookup failure
- Token generation failure
- Data validation / request shape issue

This is separate from NEX-CASE-003 (`get_open_orders_for_session` stored procedure — POS connection gap).

## Contrarian Review

_Pending — Contrarian has not yet run. Tier 3 mandates a written risk analysis here before any fix is proposed._

## Investigation

_Blank — reserved for Contrarian. Do not pre-fill._

## Root Cause

_Blank — reserved for Contrarian. Do not pre-fill._

## Proposed Fix

## Files Changed

## Verification

## Executioner Verdict

## Remaining Risks
