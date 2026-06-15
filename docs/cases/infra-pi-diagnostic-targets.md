---
status: canonical
last_reviewed: 2026-06-14
scope: infra
---

# CASE: infra-pi-diagnostic-targets

## Vault links
- Registry: [[CASE_REGISTRY]] · Contracts: [[CONTRACTS_HUB]] · Home: [[OPERATOR_HOME]]

## Run State
- task_slug: infra-pi-diagnostic-targets
- tier: 1
- branch: dev
- status: IN_PROGRESS
- last_completed_agent: specialist:infra
- next_agent: verifier
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-14 00:00

## Handoff
- Phase in progress: (none — specialist complete, handing to verifier)
- Done so far: All five edits to scripts/pipeline.sh applied; four verification commands passed.
- Exact next action: Verifier runs the four commands listed below and confirms output matches expected.
- Working-tree state: `E:\Projects\woosoo-platform\scripts\pipeline.sh` (only file changed)
- Risks / do-not-redo: Do not modify the two diagnostic scripts (pi-stability-verify.sh, pi-reboot-health.sh); they are out of scope.

## Tier
1

## Branch
dev

## Problem
`pld pi-verify` and `pld pi-health` did not exist. The two Pi diagnostic scripts (`scripts/deployment/pi-stability-verify.sh` and `scripts/deployment/pi-reboot-health.sh`) were only reachable by raw path. Operators had to memorise the script locations rather than using the consistent `pld` CLI surface.

## Contrarian Review
Approved plan from `C:\Users\Pc1\.claude\plans\review-plan-context-the-iridescent-dewdrop.md`. Tier 1 — single-file infra change, no new logic, no security surface, no Docker/Nginx changes. Risk is negligible.

## Success Criterion
`bash -n scripts/pipeline.sh` is clean; `bash scripts/pipeline.sh help` shows both new targets; `pi-verify --dry-run` and `pi-verify --host 192.168.1.31 --dry-run` print the expected sudo commands without "Unknown flag"; `pi-health --dry-run` prints `sudo -E bash ...pi-reboot-health.sh`.

## Investigation
Read `scripts/pipeline.sh` in full. Identified five insertion points:
1. Line 50 — flag var block (add `PI_HOST=""`)
2. Lines 62-63 — while-loop cases (add `--host` / `--host=*`)
3. After `target_pi` at line 727 — add `target_pi_verify` and `target_pi_health`
4. Dispatch case block — add `pi-verify` and `pi-health` arms
5. Header comment and `target_help()` heredoc — add descriptive lines for both targets

## Root Cause
No `pld` dispatch entries existed for the two diagnostic scripts.

## Proposed Fix
Add `PI_HOST` arg, `--host` parser case, `target_pi_verify`, `target_pi_health`, dispatch arms, and help text — all in `scripts/pipeline.sh` only.

## Files Changed
- `E:\Projects\woosoo-platform\scripts\pipeline.sh`

## Verification commands (Verifier — no Pi hardware needed)
```bash
bash -n scripts/pipeline.sh
bash scripts/pipeline.sh help
bash scripts/pipeline.sh pi-verify --dry-run
bash scripts/pipeline.sh pi-verify --host 192.168.1.31 --dry-run
bash scripts/pipeline.sh pi-health --dry-run
```

## Specialist Output

### `bash -n scripts/pipeline.sh`
```text
SYNTAX OK
```

### `bash scripts/pipeline.sh help` (relevant excerpt)
```text
    pi        Production Pi deploy (requires root + woosoo.env)
    pi-verify Post-deploy stability check (session/CSRF, print env, Docker runtime)
    pi-health Post-reboot diagnostic (port ownership, Reverb listener, Pi throttle)
    health    Dev health check
```

### `bash scripts/pipeline.sh pi-verify --dry-run`
```text
══════════════════════════════════════════════
  Woosoo Pipeline  ·  pi-verify  ·  branch: dev
══════════════════════════════════════════════
  (dry-run) sudo bash scripts/deployment/pi-stability-verify.sh 
...
  ✓ complete  ·  0s  (pass:0 skip:0 warn:0)
```

### `bash scripts/pipeline.sh pi-verify --host 192.168.1.31 --dry-run`
```text
══════════════════════════════════════════════
  Woosoo Pipeline  ·  pi-verify  ·  branch: dev
══════════════════════════════════════════════
  (dry-run) sudo bash scripts/deployment/pi-stability-verify.sh --host 192.168.1.31
...
  ✓ complete  ·  0s  (pass:0 skip:0 warn:0)
```

### `bash scripts/pipeline.sh pi-health --dry-run`
```text
══════════════════════════════════════════════
  Woosoo Pipeline  ·  pi-health  ·  branch: dev
══════════════════════════════════════════════
  (dry-run) sudo -E bash scripts/deployment/pi-reboot-health.sh
...
  ✓ complete  ·  0s  (pass:0 skip:0 warn:0)
```
