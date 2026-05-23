---
status: canonical
last_reviewed: 2026-05-22
scope: ecosystem
---

# CASE: pi-docker-runtime-diagnostics

## Run State
- task_slug: pi-docker-runtime-diagnostics
- tier: 2
- branch: staging
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: codex
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-22 20:00

## Handoff
- Phase in progress: specialist:infra
- Done so far: Runtime evidence reviewed; implementation approved as deployment diagnostics/docs only.
- Exact next action: Patch platform-root deployment diagnostic scripts without changing app behavior, compose routing, nginx routing, or env values.
- Working-tree state (list edited files explicitly; cross-check with `git status`): unrelated dirty files existed before this task; this task should touch only deployment diagnostics/docs and this case file.
- Risks / do-not-redo: Do not publish Reverb port 8080, do not add duplicate nginx websocket blocks, do not modify app code, tablet code, API contracts, order state, or Reverb payloads.

## Tier
2

## Branch
staging

## Problem

The Raspberry Pi deployment needs production-ready diagnostics that enforce the Docker-only runtime model and catch Reverb/runtime drift without changing application behavior.

## Contrarian Review

Approved as root infrastructure diagnostics only. The fix must codify checks for host-native service drift, platform-root compose invocation, Reverb key/origin/runtime wiring, WSS health, and post-reboot evidence.

## Investigation

- `compose.yaml` pins project name `woosoo-nexus`, keeps Reverb internal on Docker network, and configures tablet runtime Reverb settings through `APP_RUNTIME_*`.
- `docker/nginx/default.conf` already proxies `/app/` to `reverb:8080` on both admin `:443` and tablet `:4443`.
- `scripts/deployment/doctor.sh` currently checks only `/etc/woosoo/woosoo.env` variable presence.
- `scripts/deployment/woosoo-health.sh` currently performs broad health output but does not enforce Docker-only ownership, runtime Reverb origin, or sustained websocket checks.

## Root Cause

Deployment verification was still partially manual and legacy-script shaped. It could miss split-brain host services, missing compose interpolation, Reverb origin drift, and post-reboot runtime ownership regressions.

## Proposed Fix

- Harden `scripts/deployment/doctor.sh` as the preflight gate.
- Harden `scripts/deployment/woosoo-health.sh` as the runtime smoke gate.
- Add `scripts/deployment/pi-reboot-health.sh` for reboot-specific checks.
- Update deployment script documentation.

## Files Changed

- `scripts/deployment/doctor.sh` — expanded into a Docker-only runtime preflight gate.
- `scripts/deployment/woosoo-health.sh` — expanded into a post-deploy smoke gate with Reverb/runtime checks.
- `scripts/deployment/pi-reboot-health.sh` — added post-controlled-reboot diagnostic gate.
- `scripts/deployment/README.md` — documented diagnostic order and production volume safety latches.
- `docs/cases/pi-docker-runtime-diagnostics.md` — durable case checkpoint.

## Verification

- `docker compose --env-file ./woosoo-nexus/.env -f compose.yaml config --quiet` — PASS.
- `git diff --check -- scripts/deployment/doctor.sh scripts/deployment/woosoo-health.sh scripts/deployment/README.md` — PASS for tracked edits, with Git line-ending warning for README only.
- `C:\Program Files\Git\bin\bash.exe -n scripts/deployment/doctor.sh` — PASS.
- `C:\Program Files\Git\bin\bash.exe -n scripts/deployment/woosoo-health.sh` — PASS.
- `C:\Program Files\Git\bin\bash.exe -n scripts/deployment/pi-reboot-health.sh` — PASS.
- Root `scripts/pre-merge-check.*` was not run because it supports only `woosoo-nexus`, `tablet-ordering-pwa`, and `woosoo-print-bridge`, not root infrastructure.

## Executioner Verdict

APPROVED

## Remaining Risks

Pi-only runtime checks cannot be fully exercised from the Windows development host. Run `doctor.sh`, `woosoo-health.sh`, and `pi-reboot-health.sh` on the Pi to close the deployment loop.
