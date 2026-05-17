---
status: under-review
last_reviewed: 2026-05-17
scope: woosoo-nexus
---

# CASE: nex-case-001-security-auth-hardening

Tier 3 security and authentication hardening for woosoo-nexus to address critical audit findings before any feature work.

<!-- Status reconciliation (PLT-CASE-004): frontmatter `status: under-review` = triaged but
     NOT started. No phase has run (last_completed_agent: none), so this is NOT a resume —
     a runner picking this up starts fresh as Contrarian per docs/RESUME_PROTOCOL.md §3.4.
     `IN_PROGRESS` here only marks the case as the active queued item (repo convention shared
     with tab/prn/plt-003), not that a phase is mid-flight; `active_runner: none` confirms no
     runner owns it. The QUEUE.md row (status: queued) remains authoritative for scheduling. -->
## Run State
- task_slug: nex-case-001-security-auth-hardening
- tier: 3
- branch: agent/nex-case-001-security-auth-hardening
- status: IN_PROGRESS
- last_completed_agent: none
- next_agent: contrarian
- active_runner: none
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-17

## Handoff
- Phase in progress:
- Done so far:
- Exact next action:
- Working-tree state:
- Risks / do-not-redo:

## Tier
3

## Branch
agent/nex-case-001-security-auth-hardening

## Problem

Critical security vulnerabilities identified in the 2026-05-14 Nexus audit that must be resolved before any public exposure of new features:

1. **Branch scoping weakness** - Cross-branch data visibility in admin/device endpoints
2. **Broadcast channel auth bypass** - `admin.print` and `service-requests.{deviceId}` return `true`
3. **GET credential endpoint** - OWASP-grade vulnerability with credentials in query strings
4. **SessionApiController device guard broken** - `get_class()` string comparison failure

## Contrarian Review

This is Tier 3 work because it touches authentication, authorization, and cross-branch data isolation - all critical security boundaries. The audit findings are concrete and have specific file paths. These fixes must precede any other work as they represent live security vulnerabilities.

**Risk assessment:**
- **High risk** of data leakage between branches
- **Critical risk** of unauthorized broadcast access
- **OWASP violation** with credential exposure
- **Authentication bypass** potential in session management

**Dependencies:**
- Contract references: `../contracts/auth-session.contract.md`
- Must not touch other apps (single-app scope rule)
- Requires careful testing with multi-branch data

## Investigation

Files identified in audit requiring changes:
- `app/Http/Controllers/Admin/DeviceController.php` - Branch scoping
- `app/Http/Controllers/Api/V1/DeviceApiController.php` - Branch scoping  
- `routes/channels.php` - Broadcast authorization
- `app/Http/Controllers/Api/V1/Auth/DeviceAuthApiController.php` - GET credentials
- `app/Http/Controllers/Api/V1/SessionApiController.php` - Device guard

## Root Cause

1. **Branch scoping**: Missing `where('branch_id', auth()->user()->branch_id)` filters
2. **Broadcast auth**: Overly permissive `return true` in channel definitions
3. **GET credentials**: Endpoint exposes credentials in URL/logs
4. **Device guard**: String comparison bug in `get_class()` check

## Proposed Fix

### Fix 1: Branch Scoping (DeviceController & DeviceApiController)
**Files:** `app/Http/Controllers/Admin/DeviceController.php`, `app/Http/Controllers/Api/V1/DeviceApiController.php`
**Change:** Add branch scoping to all queries
**Acceptance:** Admin users only see devices from their branch
**Rollback:** Remove added `where('branch_id', ...)` clauses
**Test:** Multi-branch data isolation test

### Fix 2: Broadcast Channel Auth Hardening
**File:** `routes/channels.php`
**Change:** Implement proper authentication checks for `admin.print` and `service-requests.{deviceId}`
**Acceptance:** Only authorized users can access broadcast channels
**Rollback:** Restore `return true` statements
**Test:** Channel access control test with unauthorized users

### Fix 3: GET Credential Endpoint Retirement
**File:** `app/Http/Controllers/Api/V1/Auth/DeviceAuthApiController.php`
**Change:** Convert GET `/api/token/create` to POST or retire entirely
**Acceptance:** No credentials in query strings or logs
**Rollback:** Restore GET endpoint if conversion breaks clients
**Test:** OWASP security scan passes

### Fix 4: SessionApiController Device Guard Fix
**File:** `app/Http/Controllers/Api/V1/SessionApiController.php`
**Change:** Fix `get_class()` string comparison in `reset()` method
**Acceptance:** Device guard functions correctly with proper class checking
**Rollback:** Restore original `get_class()` logic
**Test:** Device reset integration test with device tokens

## Files Changed

*To be populated during implementation*

## Verification

### Security Tests Required
1. **Branch Isolation Test**: Create users in different branches, verify data isolation
2. **Broadcast Auth Test**: Test channel access with unauthorized users
3. **Credential Exposure Test**: Verify no credentials in URLs/logs
4. **Device Guard Test**: Test device reset with valid/invalid device tokens

### Acceptance Criteria
- [ ] Branch scoping prevents cross-branch data access
- [ ] Broadcast channels require proper authentication
- [ ] No credentials exposed in query strings or logs
- [ ] Device guard correctly validates device class
- [ ] All existing functionality preserved for authorized users
- [ ] Security scan passes (OWASP top 10)

### Performance Requirements
- No measurable impact on query performance (< 5ms overhead)
- No increase in authentication latency

## Executioner Verdict

*To be completed after verification*

## Remaining Risks

1. **Breaking existing integrations** - Changes to auth may affect external systems
2. **Performance impact** - Additional branch filtering queries
3. **Rollback complexity** - Security changes require careful rollback procedures
4. **Test coverage gaps** - May miss edge cases in multi-branch scenarios

## Contract References

- `../contracts/auth-session.contract.md` - Authentication and session contracts
- `woosoo-nexus/docs/WOOSOO_NEXUS_STABILIZATION_AND_HARDENING_AUDIT_2026-05-14.md` - Audit findings
- Root `AGENTS.md` - Security rules and boundaries
