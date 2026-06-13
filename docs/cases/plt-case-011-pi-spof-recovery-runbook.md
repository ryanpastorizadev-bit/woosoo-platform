---
status: canonical
last_reviewed: 2026-06-13
scope: ecosystem
---

# CASE: plt-case-011-pi-spof-recovery-runbook

## Run State
- task_slug: plt-case-011-pi-spof-recovery-runbook
- tier: 2
- branch: agent/plt-case-011-pi-spof-recovery-runbook
- status: IN_PROGRESS
- last_completed_agent: contrarian
- next_agent: specialist:infra
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-13

## Handoff
- Phase in progress: none
- Done so far: Contrarian review complete
- Exact next action: Specialist (infra) to draft the staff-facing Pi recovery runbook in docs/deployment/
- Working-tree state: no files edited yet
- Risks / do-not-redo: Runbook must be executable by restaurant staff with no developer access. Do not assume SSH or terminal access unless explicitly confirmed.

## Tier
2

## Branch
agent/plt-case-011-pi-spof-recovery-runbook

## Problem

The Raspberry Pi is the single physical node running Nexus, Reverb, MySQL, Redis, and the
scheduler. The deployment guide covers first-time setup and normal deploys but does not define
recovery procedures for common hardware failure scenarios:

- SD card corruption
- Power loss mid-order
- Disk full (no space left on device)
- Memory exhaustion (OOM)

Without documented recovery steps, a hardware incident during service requires developer
intervention, causing extended restaurant downtime. Restaurant staff should be able to self-recover
from common failures without calling engineering.

## Contrarian Review

**GOAL CHECK:** Continues operating during partial service failures (Pi recovery = operational
continuity). Reduces training requirements (documented steps for staff). — PASS.

**Tier 2.** Documentation-only change. No application code modified.

**Risks:**
- Runbook must not assume developer tools (SSH, Docker CLI, git) are available to the person
  following it during a restaurant emergency.
- Recovery steps must be validated against the actual Pi setup (static IP 192.168.1.31,
  platform-root Docker Compose).
- SD image backup procedure must be costed (time, storage) before recommending it.

**Success Criterion:** Task is done when `docs/deployment/PI_RECOVERY_RUNBOOK.md` exists with
step-by-step recovery instructions for each failure scenario, reviewed and marked canonical.

## Investigation

**Existing documentation:**
- `docs/deployment/DEPLOYMENT_GUIDE.md` (2026-05-27) — Pi setup path; no recovery section
- `docs/deployment/RELEASE_RUNBOOK_order-id-pos-sync.md` — Bucket B rollout; no recovery
- `compose.yaml` — platform-root authority for service definitions
- Pi static IP: `192.168.1.31`; POS static IP: `192.168.1.32`

**Gap confirmed:** No Pi recovery runbook exists anywhere in the repo.

**Failure scenarios to cover:**

| Scenario | Symptom | Staff-observable signal |
|---|---|---|
| SD corruption (read-only FS) | Services fail to start after reboot | Tablets show "Cannot connect" |
| Power loss mid-order | Containers stopped abruptly | Orders in CONFIRMED state, no print |
| Disk full | Scheduler/queue jobs fail | Print jobs queue but never dispatch |
| Memory exhaustion | OOM killer stops containers | Random service unavailability |
| Docker service crash (single container) | One function down | Partial failure: ordering works, print broken |

## Root Cause

Deployment guide was written for the happy path. Recovery scenarios were explicitly noted as a gap
in the Prime Directive review (2026-06-13) and implicitly in the ecosystem engineering review
(2026-05-14 §2.5).

## Proposed Fix

Create `docs/deployment/PI_RECOVERY_RUNBOOK.md` with:

1. **Staff quick-reference card** — visual one-page decision tree: "tablet can't connect →
   Pi power light? → press reset button → wait 90s → if still down → call [engineering contact]"
2. **Scenario A: Power loss mid-order** — safe reboot procedure, how to verify services came
   back, how to check for orders in CONFIRMED state that missed print, how to manually re-trigger
   print (artisan command or admin UI path)
3. **Scenario B: Disk full** — `df -h` to confirm, log rotation command, Docker image prune,
   escalation threshold
4. **Scenario C: Single container crashed** — `docker compose ps` to identify, `docker compose
   restart <service>` recovery, which services are safe to restart solo
5. **Scenario D: SD corruption** — signs (kernel read-only remount messages), staff escalation
   path, engineering steps to restore from backup image
6. **SD image backup procedure** — when to run, where to store, how to restore (engineering task,
   not staff task)
7. **"When to call engineering" threshold** — explicit criteria so staff know when self-recovery
   is appropriate vs. when to stop and call

The runbook must be written in plain language suitable for restaurant staff.
Specialist: `infra` (allowed path: `docs/deployment/**`, `docker/**`, `scripts/**`).

## Files Changed
<!-- Filled by Specialist -->
- `docs/deployment/PI_RECOVERY_RUNBOOK.md` (new)

## Verification

- Dazai-docs reviews for plain-language clarity and staff readability
- All `docker compose` commands cross-checked against `compose.yaml` service names
- All artisan commands verified against `woosoo-nexus` route list (Specialist may not have nexus
  checkout — note this and use only documented commands from existing case files)
- Marked `status: canonical` after Executioner APPROVED

## Executioner Verdict
<!-- Filled by Executioner -->

## Remaining Risks
- Actual SD backup procedure needs to be tested on the physical Pi before marking canonical.
  Executioner may APPROVE the runbook with a Follow-Up to validate Scenario D on device.
- "Engineering contact" placeholder in the quick-reference card must be filled in before going
  live in the restaurant.
