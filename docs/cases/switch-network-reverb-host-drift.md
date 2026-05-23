---
status: canonical
last_reviewed: 2026-05-22
scope: woosoo-platform
---

# CASE: switch-network-reverb-host-drift

## Run State
- task_slug: switch-network-reverb-host-drift
- tier: 3
- branch: staging
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: codex
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-22 20:30

## Handoff
- Phase in progress: none
- Done so far: Pi runtime evidence showed `PUBLIC_HOST=192.168.100.42` but stale public Reverb/API keys still set to `woosoo.local`; switch script verification was tightened.
- Exact next action: Pull/copy the updated `scripts/deployment/switch-network.sh` to the Pi and run `sudo bash scripts/deployment/switch-network.sh home`.
- Working-tree state (list edited files explicitly; cross-check with `git status`): `scripts/deployment/switch-network.sh` and this case file changed; unrelated dirty files existed before this task.
- Risks / do-not-redo: Do not expose Reverb 8080 publicly, do not use `wss://192.168.100.42:8080`, and do not run `compose down` or remove volumes.

## Tier
3

## Branch
staging

## Problem

The Pi-home switch reported `public_host=192.168.100.42`, but the actual `.env` still contained stale browser-facing values:

```txt
APP_URL="https://woosoo.local"
REVERB_PUBLIC_HOST="woosoo.local"
VITE_REVERB_HOST="woosoo.local"
PUBLIC_HOST="192.168.100.42"
```

This can leave Laravel/Reverb internal publishing correct while browser and tablet runtime configuration still point at the wrong public host.

## Contrarian Review

This is root infrastructure, not app code. The safest change is to fix the switch script and its verification output so Pi-home/Pi-resto flips update and prove the complete public/runtime Reverb map.

## Investigation

- `REVERB_HOST=reverb` and `REVERB_BROADCAST_HOST=reverb` are the correct Docker-internal broadcast path.
- `REVERB_PUBLIC_HOST`, `VITE_REVERB_HOST`, `NUXT_PUBLIC_REVERB_HOST`, and `APP_RUNTIME_REVERB_HOST` are the public/browser-facing values that must follow `PUBLIC_HOST`.
- The previous verification printed `env('PUBLIC_HOST')`, which can pass even when the public Reverb host keys remain stale.

## Root Cause

The switch script's verification label overstated what it proved. It checked `PUBLIC_HOST`, not the full public Reverb/tablet runtime host map.

## Proposed Fix

Expand `switch-network.sh` to:

- write the complete public/runtime Reverb map when switching networks,
- print the full set of changed public and internal keys,
- verify Reverb's runtime host split,
- verify the tablet container's runtime Reverb environment.

## Files Changed

- `scripts/deployment/switch-network.sh`
- `docs/cases/switch-network-reverb-host-drift.md`

## Verification

- `git diff --check -- scripts/deployment/switch-network.sh` — PASS.
- `docker compose --env-file .\woosoo-nexus\.env -f compose.yaml config --quiet` — PASS.
- `C:\Program Files\Git\bin\bash.exe -n scripts/deployment/switch-network.sh` — could not run in the Windows sandbox: `CreateProcessAsUserW failed: 1312`. Run `bash -n scripts/deployment/switch-network.sh` on the Pi.

## Executioner Verdict

APPROVED

## Remaining Risks

The live Pi still needs the updated script run with `home`, then the tablet PWA/site data must be refreshed if it persisted the previous host.
