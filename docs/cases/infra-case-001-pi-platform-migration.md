---
status: canonical
last_reviewed: 2026-05-20
scope: ecosystem
---

# CASE: infra-case-001-pi-platform-migration

## Run State
- task_slug: infra-case-001-pi-platform-migration
- tier: 3
- branch: staging
- status: IN_PROGRESS
- last_completed_agent: contrarian
- next_agent: specialist:infra
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-20 00:00

## Handoff
- Phase in progress:
- Done so far: Contrarian complete. Specialist fixes applied to woosoo-health.sh and woosoo-backup.sh (stale cd path). Ready for Pi-side execution.
- Exact next action: User runs Phase 0 pre-flight on Pi, then proceeds through plan phases.
- Working-tree state: scripts/deployment/woosoo-health.sh, scripts/deployment/woosoo-backup.sh modified (cd WOOSOO_NEXUS_PATH → WOOSOO_PLATFORM_PATH).
- Risks / do-not-redo: Do NOT run docker compose down --volumes. WOOSOO_APPLY_STATIC_IP must be false (SSH only).

## Tier
3 — production migration, data at risk, SSH-only Pi access, first Pi runtime test of platform-root model

## Branch
staging (per user instruction)

## Problem

The Pi currently runs Woosoo from the old single-repo model (`woosoo-nexus/` as compose root).
The platform-root model (`woosoo-platform/` owning `compose.yaml`, `docker/`, `scripts/`) was
built and syntax-checked on the Windows dev box but never tested on Pi hardware.

**Environment:**
- Pi at 192.168.100.42 (home, SSH-only access)
- Restaurant IP: 192.168.1.31; POS: 192.168.1.32
- TLS: mkcert self-signed

## Contrarian Review

**Challenge accepted as valid.** Pi runtime verification is the documented outstanding gap in
`docs/deployment/production-docker.md`. Tier 3 is correct: production data at risk, SSH-only
static-IP danger, first live test of the new orchestration model.

**Candidate skills:** `infra`, `docker-deployment-debug`

**Proceed.** One-app scope (platform infra only — no app code changes).

## Investigation

- `deploy.sh` topology: `NEXUS_DIR="$PLATFORM_ROOT/woosoo-nexus"` — app repos must live
  **inside** `woosoo-platform/`, not as siblings.
- `woosoo-health.sh` and `woosoo-backup.sh` both did `cd "$WOOSOO_NEXUS_PATH"` before running
  compose, which breaks the platform-root model (compose.yaml is one level up).
- `WOOSOO_DOCKER_COMPOSE` env var uses `--env-file ./woosoo-nexus/.env` (relative), which
  requires CWD to be PLATFORM_ROOT.
- MySQL volume name `woosoo-nexus_mysql_data` is preserved because `compose.yaml` pins
  `name: woosoo-nexus`.
- `WOOSOO_APPLY_STATIC_IP=false` is mandatory: SSH access only, IP already static.

## Root Cause

`woosoo-health.sh` and `woosoo-backup.sh` were not updated when orchestration moved to
platform-root. Both scripts `cd` to `WOOSOO_NEXUS_PATH` (the Laravel app dir) before running
`docker compose`, but the platform-root model requires `cd` to `WOOSOO_PLATFORM_PATH` instead.

## Proposed Fix

Update both scripts to derive and `cd` to `WOOSOO_PLATFORM_PATH` (defaulting to
`dirname $WOOSOO_NEXUS_PATH`) before running any compose commands.

## Files Changed

- `scripts/deployment/woosoo-health.sh` — add `WOOSOO_PLATFORM_PATH` var; `cd` to platform path in check [8]
- `scripts/deployment/woosoo-backup.sh` — add `WOOSOO_PLATFORM_PATH` var; `cd` to platform path before dump

## Verification

See plan for full 8-phase Pi runbook. Script-level verification:
```bash
# Dry-run path resolution on Pi (after /etc/woosoo/woosoo.env is in place):
source /etc/woosoo/woosoo.env
echo "Platform: $(dirname $WOOSOO_NEXUS_PATH)"
ls $(dirname $WOOSOO_NEXUS_PATH)/compose.yaml   # must exist
```

Full PASS criteria in plan file.

## Executioner Verdict

(pending — Pi deployment not yet executed)

## Remaining Risks

- Pi runtime test still pending (the purpose of this case)
- 5 other scripts not yet migrated: deploy-tablet.sh, verify-tablet-deploy-context.sh,
  update-client.sh, rollback-client.sh, verify-client.sh
- Restaurant network reconfiguration (update woosoo.env before returning Pi)
- mkcert CA must be installed on each tablet device (one-time, manual)
