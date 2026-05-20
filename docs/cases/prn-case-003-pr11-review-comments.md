---
status: canonical
last_reviewed: 2026-05-19
scope: woosoo-print-bridge
---

# PRN-CASE-003 — PR #11 Review Comment Remediation

## Run State
- task_slug: prn-case-003-pr11-review-comments
- tier: 3
- branch: agent/prn-case-003-pr11-review-comments
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: codex
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-19

## Handoff
- Phase in progress: Executioner verdict — final approval gate
- Done so far: All four phases complete (Contrarian Tier 3, relay-ops specialist, verifier, executioner). Reservation exception path remediated: typed `HttpStatusException`, transient/non-transient classification, `PrintJob.nextReservationAttemptAt` with 30 s cap, dead-letter routing for HTTP 4xx. Audit doc and `.agents.md` stale-risk wording updated.
- Exact next action: None — task COMPLETE. Commit and push root case file plus print-bridge branch changes when ready.
- Working-tree state: `woosoo-print-bridge/.agents.md`, `woosoo-print-bridge/docs/WOOSOO_PRINT_BRIDGE_PRODUCTION_RELIABILITY_AUDIT_2026-05-14.md`, `woosoo-print-bridge/lib/models/print_job.dart`, `woosoo-print-bridge/lib/services/api_service.dart`, `woosoo-print-bridge/lib/state/app_controller.dart`, `woosoo-print-bridge/test/unit/app_controller_process_queue_test.dart`, `docs/cases/prn-case-003-pr11-review-comments.md`
- Risks / do-not-redo: Do not re-run specialist — changes are verified and approved. Local token/queue payload storage, input rejection visibility, queue-clear safety, and local-only order history are separate audit risks tracked in Remaining Risks.

## Tier
3

## Branch
agent/prn-case-003-pr11-review-comments

## Problem

PR #11 review comments on the print bridge staging branch need source-verified remediation.
The actionable remaining surface is the reservation exception path and stale audit wording
around already-resolved reliability risks.

## Contrarian Review

Tier 3 confirmed because the task touches the core reservation exception path, adds a
persisted `PrintJob` field, and has duplicate-print-prevention implications.

Already-fixed claims verified in current code:
- `.agents.md` frontmatter is `---`.
- The `reserved` to `printing` double write has a crash-recovery comment.
- The stale reserved recovery test uses `copyWith(createdAt: ...)`.
- The stale API base URL probe comment states that only IPv4 hosts are probed.

Mandatory clarifications before code:
- Non-transient reservation failures must not stop at local `failed`; they must route through
  dead-letter visibility with reason `reserve_unexpected_http_status`.
- Transient reservation failures are `SocketException`, `TimeoutException`, and HTTP 5xx;
  HTTP 4xx other than already-handled 404/409 is non-transient.
- `nextReservationAttemptAt` must be capped to a 30 second cooldown so corrupt serialized
  future timestamps cannot strand a job forever.

## Investigation

Specialist: relay-ops.

Files inspected:
- `woosoo-print-bridge/lib/state/app_controller.dart`
- `woosoo-print-bridge/lib/services/api_service.dart`
- `woosoo-print-bridge/lib/models/print_job.dart`
- `woosoo-print-bridge/test/unit/app_controller_process_queue_test.dart`
- `woosoo-print-bridge/docs/WOOSOO_PRINT_BRIDGE_PRODUCTION_RELIABILITY_AUDIT_2026-05-14.md`
- `woosoo-print-bridge/.agents.md`

Findings:
- The existing reservation catch converted all errors into `pending` with `reserve_network_error`,
  so non-transient failures could re-enter the queue without operator dead-letter visibility.
- The queue selector honored `claimedByOtherUntil` but had no persisted cooldown for transient
  reservation transport/backend failures.
- The audit doc and `.agents.md` still described several resolved items as active risks.

## Root Cause

Reservation failures lacked typed HTTP status classification and a distinct local retry deadline.
This made the queue unable to tell genuine transient failures from contract/state failures and
left the retry path vulnerable to reserve hot-loops.

## Proposed Fix

- Add typed `HttpStatusException` for reserve HTTP failures.
- Classify `SocketException`, `TimeoutException`, `HttpException`, and HTTP 5xx as transient.
- Classify HTTP 4xx other than handled 404/409 as non-transient.
- Add persisted `PrintJob.nextReservationAttemptAt` with a 30 second maximum cooldown cap.
- Honor both `claimedByOtherUntil` and `nextReservationAttemptAt` in queue pending selection.
- Move non-transient reservation failures to local `failed` and dead-letter with reason
  `reserve_unexpected_http_status`.
- Update audit and per-app instructions so resolved risks are date-qualified and current
  verification evidence is raw-output backed.

## Files Changed

- `woosoo-print-bridge/.agents.md`
- `woosoo-print-bridge/docs/WOOSOO_PRINT_BRIDGE_PRODUCTION_RELIABILITY_AUDIT_2026-05-14.md`
- `woosoo-print-bridge/lib/models/print_job.dart`
- `woosoo-print-bridge/lib/services/api_service.dart`
- `woosoo-print-bridge/lib/state/app_controller.dart`
- `woosoo-print-bridge/test/unit/app_controller_process_queue_test.dart`
- `docs/cases/prn-case-003-pr11-review-comments.md`

## Verification

### Commands Run

- `dart format lib\services\api_service.dart lib\models\print_job.dart lib\state\app_controller.dart test\unit\app_controller_process_queue_test.dart`
- `flutter test test\unit\app_controller_process_queue_test.dart`
- `.\scripts\pre-merge-check.ps1 -App woosoo-print-bridge`
- `git diff --check`

### Results

- Format: `Formatted 4 files (4 changed) in 0.12 seconds.`
- Targeted test: `00:07 +27: All tests passed!`
- Pre-merge analyze: `No issues found! (ran in 58.2s)`
- Pre-merge full test: `00:09 +111: All tests passed!`
- Pre-merge gate: `pre-merge-check OK (woosoo-print-bridge)`
- Diff check: passed; only line-ending warnings for `.agents.md` and the print-bridge audit doc.

### Functional Proof

- HTTP 5xx reservation failures now remain pending, set `nextReservationAttemptAt`, and skip
  immediate reselection.
- HTTP 4xx reservation failures now become failed/dead-letter with
  `dead_letter_reason = reserve_unexpected_http_status`.
- Persisted future retry timestamps are capped to a 30 second window before being honored.

## Executioner Verdict

Verdict: APPROVED

### Reason

Tier 3 sequence is satisfied in this case file. The change is scoped to the print bridge plus
the root case checkpoint, preserves backend reserve/ack contracts, adds focused tests for the
new reservation behavior, and passes the full required print-bridge pre-merge gate.

### Required Next Action

Review, commit, and push the root case file plus the nested print-bridge branch changes when
ready.

## Remaining Risks

- Root repo has unrelated untracked `docs/cases/plt-case-007-risk-assessment-challenge.md`;
  left untouched.
- Local token/queue payload storage, input rejection visibility, queue-clear operator safety,
  and local-only order history remain separate audit risks.
