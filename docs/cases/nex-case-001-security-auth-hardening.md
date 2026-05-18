---
status: in-progress
last_reviewed: 2026-05-17
scope: woosoo-nexus
---

# CASE: nex-case-001-security-auth-hardening

Tier 3 security and authentication hardening for woosoo-nexus to address critical audit findings before any feature work.

<!-- Contrarian phase has now run (2026-05-17, claude-code). The drafted Proposed Fix was
     re-examined against the live woosoo-nexus code: one item (SessionApiController guard) was
     already fixed and is dropped; file/controller/channel references were corrected to verified
     reality. This case is now a genuine IN_PROGRESS resume point: next_agent =
     specialist:ranpo-backend. woosoo-nexus is its own nested git repo (gitignored by the
     platform repo); the agent/<slug> branch is created inside that repo, not the platform repo. -->
## Run State
- task_slug: nex-case-001-security-auth-hardening
- tier: 3
- branch: agent/nex-case-001-security-auth-hardening (inside the woosoo-nexus nested repo)
- status: IN_PROGRESS
- last_completed_agent: specialist:ranpo-backend (Phase 1-nexus correctness batch)
- next_agent: specialist:ranpo-backend (security hardening fixes — branch scoping, broadcast auth, GET credential retirement)
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-18

## Handoff
- Phase completed: specialist:ranpo-backend — Phase 1-nexus correctness batch (2026-05-18)
- Done so far:
  - Contrarian re-examined the drafted plan against live code (2026-05-17). Fix 4
    refuted (already correct) and downgraded to a regression test. Paths/controller/channel
    references corrected.
  - Phase 1-nexus correctness batch applied and verified (2026-05-18):
    1. app/Casts/UtcDateTimeCast.php — set() now parses naive strings as UTC (symmetric with get())
    2. app/Services/PrintEventService.php — ack() now calls ->utc() on $ackAt (symmetric with fail())
    3. app/Services/Pos/PosOrderService.php — voidOrder() adds is_settled=0 to update payload and
       ->where('is_settled', 0) guard to prevent overriding POS-authoritative settled state
    4. app/Services/Pos/TerminalContextResolver.php — both cash_tray_sessions fallbacks now include
       ->where('terminal_id', $terminalId) to prevent cross-terminal tray resolution
    5. config/cors.php — comment updated to accurately state PublicOrigin::corsOrigins() returns
       explicit named origins, never ['*'], so supports_credentials=true is safe
  - Full suite: Tests: 395 passed (1371 assertions); pre-merge-check OK (woosoo-nexus)
- Exact next action: ranpo-backend implements the security hardening fixes (branch scoping on
  Admin/Device controllers, broadcast channel auth hardening in routes/channels.php, GET credential
  endpoint retirement in routes/api.php) + the Fix 4 regression test for SessionApiController.
- Working-tree state: woosoo-nexus repo has the 5 correctness-batch edits applied (uncommitted,
  per task constraints — no git add/commit/push). Security hardening edits not yet started.
- Risks / do-not-redo: Do NOT modify SessionApiController production code (guard already correct).
  Single-app: woosoo-nexus only. Do NOT touch tablet-ordering-pwa or woosoo-print-bridge.

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

**Conducted:** 2026-05-17 (claude-code) — re-examination of the drafted plan against live code.

Tier 3: touches authentication, authorization, and cross-branch data isolation. The original
draft was challenged against the actual woosoo-nexus source. Findings:

| # | Original draft claim | Verdict | Evidence |
|---|---|---|---|
| 1 | `SessionApiController@reset()` `get_class()` bug | **REFUTED — already fixed** | `app/Http/Controllers/Api/V1/SessionApiController.php:96` → `$isDevice = $user instanceof Device;`. Fix 4 dropped; replaced by a regression test only. |
| 2 | Admin controller `Admin/DeviceController.php` | **Path wrong** | Real: `app/Http/Controllers/Admin/Device/DeviceController.php` (nested). `index()` has no `branch_id` scoping; `Api/V1/DeviceApiController.php` `index()` also unscoped. |
| 3 | `service-requests.{deviceId}` returns `true` | **CONFIRMED + mis-keyed** | `routes/channels.php` defines `service-requests.{deviceId}` → `return true;`, but `app/Events/ServiceRequest/ServiceRequestNotification.php:35` broadcasts on `service-requests.<order_id>`. Auth must key off **order ownership**, param `{orderId}`. |
| 4 | `admin.print` returns `true` | **CONFIRMED** | `routes/channels.php` → `Broadcast::channel('admin.print', true);` |
| 5 | GET credential endpoint controller | **Misnamed in draft** | Real: `Api/V1/Auth/AuthApiController@createToken`, `GET /token/create` (`routes/api.php`). |
| 6 | (missed by draft) second GET-credential route | **NEW** | `GET /devices/login` (passcode in query) — same vuln class. |

**Risk assessment:** High (cross-branch data leakage), Critical (unauthorized broadcast +
credential-in-URL exposure across two routes).

**Dependencies / constraints:**
- Contract reference: `contracts/auth-session.contract.md`; audit `woosoo-nexus/docs/WOOSOO_NEXUS_STABILIZATION_AND_HARDENING_AUDIT_2026-05-14.md`.
- Single-app scope: `woosoo-nexus/**` only.
- `woosoo-nexus/` is its own nested git repo, gitignored by the platform repo. The Tier 3
  branch `agent/nex-case-001-security-auth-hardening` is created **inside** that repo.
- Blocker noted at handoff: the nexus repo is on branch `staging` with pre-existing unrelated
  uncommitted changes (5 files) — the Specialist must isolate the branch without absorbing or
  discarding that in-progress work; surfaced to the user before any code edit.

## Investigation

Files verified against live code (2026-05-17), requiring changes:
- `app/Http/Controllers/Admin/Device/DeviceController.php` — `index()` unscoped by branch
- `app/Http/Controllers/Api/V1/DeviceApiController.php` — `index()` unscoped by branch
- `routes/channels.php` — `service-requests.{deviceId}` and `admin.print` return bare `true`;
  `service-requests` is actually broadcast keyed by `order_id` (param name mismatch)
- `routes/api.php` — `GET /token/create` (→ `Api/V1/Auth/AuthApiController@createToken`) and
  `GET /devices/login` expose credentials/passcode in the query string
- `app/Http/Controllers/Api/V1/SessionApiController.php` — `reset()` guard **already correct**
  (`$user instanceof Device`); regression test only, no production change

## Root Cause

1. **Branch scoping**: Missing branch filter on `Device` list queries (admin + API).
2. **Broadcast auth**: Overly permissive bare `true` in `service-requests.*` and `admin.print`;
   `service-requests` channel parameter named `deviceId` while the event broadcasts on
   `order_id`, so any authenticated user can subscribe to any order's service requests.
3. **GET credentials**: Two guest-accessible GET routes accept secrets via query string
   (logged in access logs / browser history / referrers).
4. **Device guard**: No defect — already uses `instanceof`. Risk is regression only.

## Proposed Fix

### Fix 1: Branch Scoping (admin + API device lists)
**Files:** `app/Http/Controllers/Admin/Device/DeviceController.php` (`index()`), `app/Http/Controllers/Api/V1/DeviceApiController.php` (`index()`)
**Change:** Scope `Device` list queries to the authenticated admin's `branch_id`. Confirm the
existing scoping mechanism in the codebase (global scope vs. explicit `where`) before choosing;
do not invent a new pattern.
**Acceptance:** Admin/API callers only see devices from their own branch.
**Rollback:** Remove the added branch filter.
**Test:** Multi-branch isolation — admin of branch A cannot see branch B devices.

### Fix 2: Broadcast Channel Auth Hardening
**File:** `routes/channels.php`
**Change:** (a) Rename `service-requests.{deviceId}` → `service-requests.{orderId}` to match
`ServiceRequestNotification` (`new Channel('service-requests.' . $serviceRequest->order_id)`),
and authorize by **order ownership** (the authenticated device/user must own the order with
that `order_id`). (b) Change `admin.print` from bare `true` to `fn ($user) => $user->is_admin`
(mirrors existing `admin.orders` / `admin.service-requests`).
**Acceptance:** Only the owning principal can subscribe to a `service-requests.<order_id>`
channel; only admins can subscribe to `admin.print`.
**Rollback:** Restore the `return true` bodies and the `{deviceId}` parameter name.
**Test:** Unauthorized user denied; wrong-order owner denied; correct owner allowed; non-admin
denied on `admin.print`.

### Fix 3: GET Credential Endpoint Retirement (BOTH routes)
**File:** `routes/api.php` (and `app/Http/Controllers/Api/V1/Auth/AuthApiController.php` if the
verb change requires request-validation review)
**Change:** Convert `GET /token/create` and `GET /devices/login` to `POST`. Verify the only
callers are the tablet/internal before retiring vs. converting; record client impact in
Remaining Risks.
**Acceptance:** `php artisan route:list` shows both as POST only; no credentials/passcode in
query strings.
**Rollback:** Restore the GET routes.
**Test:** Route-verb test asserting GET returns 405 and POST succeeds.

### Fix 4: SessionApiController Device Guard — regression lock only
**File:** `tests/...` (no production change — `reset()` already uses `$user instanceof Device`)
**Change:** Add a regression test so the correct guard cannot silently regress.
**Acceptance:** Test asserts `reset()` rejects a non-Device/non-admin principal (403) and
accepts a valid `Device` token.
**Rollback:** Remove the test.

## Files Changed

### Phase 1-nexus correctness batch (2026-05-18)
- `woosoo-nexus/app/Casts/UtcDateTimeCast.php` — set() parses naive strings as UTC
- `woosoo-nexus/app/Services/PrintEventService.php` — ack() normalizes printed_at to UTC
- `woosoo-nexus/app/Services/Pos/PosOrderService.php` — voidOrder() guards is_settled reset
- `woosoo-nexus/app/Services/Pos/TerminalContextResolver.php` — both fallbacks add terminal_id constraint
- `woosoo-nexus/config/cors.php` — comment-only: clarifies PublicOrigin never returns ['*']

### Security hardening (pending)
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
