---
status: canonical
last_reviewed: 2026-05-21
scope: woosoo-print-bridge
---

# PRN-REBUILD-APK-SCP-PI

## Run State
- task_slug: prn-rebuild-apk-scp-pi
- tier: 3
- branch: staging
- status: IN_PROGRESS
- last_completed_agent: specialist:relay-ops
- next_agent: verifier
- active_runner: codex
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-21 18:38

## Handoff
- Phase in progress: verifier
- Done so far: Full print-bridge validation and release build completed from `staging`.
- Exact next action: Verifier should confirm artifact metadata and decide whether to proceed with SCP transfer or close build-only scope.
- Working-tree state (list edited files explicitly; cross-check with `git status`): `## staging...origin/staging`; app code untouched in this run; case file updated.
- Risks / do-not-redo: Do not rerun unrelated cross-app steps; SCP still needs explicit destination/credentials confirmation.

## Tier
3

## Branch
staging

## Problem

Rebuild the Flutter Android release APK for the print bridge from the current repository state and
copy the resulting artifact to the Raspberry Pi over SCP.

## Contrarian Review

### Tier

3

### Assumptions Challenged

- The request does not specify a target SCP destination path or SSH identity, so the deploy step
  can only proceed automatically if an existing documented or configured Pi target is available.
- Building from `staging` is only safe if the current local worktree state is intentional, because
  the artifact will include any uncommitted tracked changes.

### Risks

- Production-adjacent Pi deployment is high-risk operational work; validation and the exact copied
  artifact path must be recorded precisely.
- SCP can fail on host, username, key, or destination-path mismatches even when the APK build
  succeeds.

### Hidden Failure Boundaries

- `flutter analyze` or `flutter test` may fail before the release build, blocking deployment.
- A previously documented Pi LAN IP may be stale; archived docs are hints, not source of truth.
- SCP to the wrong host or path would produce a successful transfer to the wrong destination.

### Assigned Specialist

- relay-ops

### Affected App

- woosoo-print-bridge

### Candidate Skills

- none

### Branch

- staging

### Recommendation

Proceed with validation and rebuild first, then transfer only after the Pi SCP target is confirmed.

## Investigation

- Resumed active case `prn-rebuild-apk-scp-pi` from Specialist phase per Run State.
- Baseline branch/worktree before validation: `## staging...origin/staging`.
- Required quality gates for this app are `flutter analyze` and full `flutter test`.

## Root Cause

Not a defect-fix task; this run was an artifact rebuild/packaging operation.

## Proposed Fix

- Run the required print-bridge validation commands against the current worktree.
- Rebuild the Android release APK with `flutter build apk --release`.
- Confirm release artifact path and metadata for handoff.

## Files Changed

- `../docs/cases/prn-rebuild-apk-scp-pi.md`

## Verification

### Commands Run

- `git --no-pager status --short --branch`
- `flutter --version`
- `flutter analyze`
- `flutter test`
- `flutter build apk --release`
- `Get-Item build\\app\\outputs\\flutter-apk\\app-release.apk | Select-Object FullName,Length,LastWriteTime`

### Results

- Branch/worktree baseline: `## staging...origin/staging`
- Analyze: `No issues found! (ran in 45.8s)`
- Tests: `00:08 +111: All tests passed!`
- Release build: `Built build\\app\\outputs\\flutter-apk\\app-release.apk (51.3MB)`
- Artifact metadata: `E:\\Projects\\woosoo-platform\\woosoo-print-bridge\\build\\app\\outputs\\flutter-apk\\app-release.apk`, `53801156` bytes, timestamp `2026-05-21 18:37` local.

## Executioner Verdict

Pending

## Remaining Risks

- SCP transfer is not executed yet in this run and still requires explicit trusted destination and credentials.
