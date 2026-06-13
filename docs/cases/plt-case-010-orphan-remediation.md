---
status: canonical
last_reviewed: 2026-06-13
scope: ecosystem
---

# CASE: plt-case-010-orphan-remediation

## Run State
- task_slug: plt-case-010-orphan-remediation
- tier: 2
- branch: agent/plt-case-010-orphan-remediation
- status: IN_PROGRESS
- last_completed_agent: contrarian
- next_agent: specialist:ranpo-backend
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-13

## Handoff
- Phase in progress: none
- Done so far: Contrarian review complete
- Exact next action: Specialist (ranpo-backend) to begin Nexus orphan removals; then chuya-frontend for tablet; then relay-ops for bridge. Cross-app — see Workspace Split note.
- Working-tree state: no files edited yet
- Risks / do-not-redo: Do NOT delete any item without verifying no consumer exists. Check git blame and grep before removing.

## Tier
2

## Branch
agent/plt-case-010-orphan-remediation

## Problem

Confirmed orphaned code across all 3 app repos documented in `docs/WOOSOO_ECOSYSTEM_ENGINEERING_REVIEW_2026-05-14.md`
and `contracts/websocket-events.contract.md § Known Issues`. Dead code accumulates as misleading
documentation, increases cognitive load, and creates risk of future confusion (e.g. a developer
wiring up a dead broadcast channel thinking it's active).

This is a pre-release hygiene sprint (Bucket C — non-blocking, but must run before next stable
release). Use the `dead-code-cleanup` skill.

## Contrarian Review

**GOAL CHECK:** Reduces staff workload (simpler codebase = faster fixes = faster response to
restaurant ops issues). Maintainable by a small engineering team. — PASS.

**Tier 2.** No auth changes, no state machine changes, no POS DB writes. Purely removal of unused
code paths.

**Risk:** Deleting something that appears unused but has a hidden consumer (e.g. a channel
subscribed only in a rarely-triggered code path). Mitigation: grep evidence required before
every deletion.

**Cross-app note:** This task touches all 3 repos. The Executioner must approve each repo's
changes separately and the Workspace Split Rule applies — do NOT edit nexus + tablet in the same
commit. Use one branch per repo.

### Success Criterion
Task is done when all items in the confirmed-orphan list below are either removed (with grep
evidence showing zero consumers) or reclassified with a documented reason for keeping them.

## Investigation

Confirmed orphans from ecosystem review (2026-05-14) and websocket contract (2026-06-01):

**woosoo-nexus**
- `app/Http/Controllers/Api/V1/PrintController.php` — orphaned controller (superseded)
- `app/Http/Controllers/Api/EventReplayController.php` — orphaned controller
- `app/Http/Controllers/Api/V1/ServiceMonitorController.php` — orphaned controller
- `resources/js/pages/auth/Register.vue` — unreachable page
- Admin `Orders/Index.vue` — subscribes `admin.print` channel; no producer broadcasts there
- Broadcast events with no consumer: `payment.completed`, `menu.updated`, `package.updated`, `table-service`

**tablet-ordering-pwa**
- `useOfflineOrderQueue.ts` — likely superseded by live-only submit model
- `config/api.ts` — stale `/api/device/login` constant (live code uses `/api/devices/login`)
- 3 competing idempotency helpers: `useOrderSubmit.ts`, `useOrderSubmission.ts`,
  `useSubmissionIdempotency.ts` — merge or pick one canonical implementation
- `pages/auth/register.vue` — potentially redundant

**woosoo-print-bridge**
- `lib/services/performance_monitor.dart` — unused per ecosystem review
- `lib/core/time.dart` — likely unused
- `share_plus` dependency — verify before removing

## Root Cause

Long-running multi-repo project with iterative delivery. Features were partially implemented,
requirements shifted, and alternates were kept "just in case." No anti-orphan sweep has been
run since the ecosystem review (2026-05-14).

## Proposed Fix

For each item:
1. `grep -r <symbol> <repo>` — confirm zero non-self-referencing consumers
2. Delete the file / remove the code / remove the dependency
3. Run pre-merge check for that app
4. Document in Files Changed

**Order of operations:** Nexus first (ranpo-backend), then Tablet (chuya-frontend), then Bridge
(relay-ops). Separate branches per repo. Each gets its own Verifier + Executioner pass.

## Files Changed
<!-- Filled by Specialist -->

## Verification

Per app:
- `bash scripts/pre-merge-check.sh --app woosoo-nexus` — must pass after Nexus changes
- `bash scripts/pre-merge-check.sh --app tablet-ordering-pwa` — must pass after tablet changes
- `bash scripts/pre-merge-check.sh --app woosoo-print-bridge` — must pass after bridge changes
- Grep evidence for each deleted symbol: zero matches outside the deleted file itself

## Executioner Verdict
<!-- Filled by Executioner — one verdict per repo -->

## Remaining Risks
- `order.printed` name collision (3 events → same broadcastAs name) is tracked separately under
  NEX-CASE-011 and must NOT be fixed here.
- The competing idempotency helpers in tablet need a design decision before deletion — confirm
  which is the canonical one before merging/removing the others.
