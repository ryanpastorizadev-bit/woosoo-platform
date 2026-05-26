---
status: canonical
last_reviewed: 2026-05-25
scope: ecosystem
---

# CASE: infra-case-002-deploy-stability-wrappers

## Run State
- task_slug: infra-case-002-deploy-stability-wrappers
- tier: 2
- branch: agent/infra-case-002-deploy-stability-wrappers (target PR into `dev` per `feedback-use-dev-branch`; executed in-place on `main` working tree because pre-existing uncommitted case/state changes block a clean checkout — operator must move commits to `dev` at commit time)
- status: IN_PROGRESS (Stage A + R2 re-verification complete on dev; Stage B Pi verification pending)
- last_completed_agent: specialist:infra (R2 review pass)
- next_agent: verifier (Pi runtime — Stage B)
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-25 (session)

## Handoff
- Phase in progress: handing off from specialist to verifier (Pi-side, operator-driven)
- Done so far: all 5 plan changes shipped to working tree; Stage A dev verification PASS (bash -n on 8 scripts, `docker compose config` parses cleanly with all 8 services present)
- Exact next action: operator runs Stage B on the Pi — `sudo bash scripts/deployment/deploy-all.sh`, smoke test, then rollback drill
- Working-tree state: see `git status` — case file + scripts/deployment/* + docs/deployment/examples/woosoo.env.example modifications
- Risks / do-not-redo: do not re-run rollback migration (already done); do not touch `compose.yaml`; do not delete legacy nexus-internal orchestration until Stage B closes

## Tier
2

## Branch
agent/infra-case-002-deploy-stability-wrappers (target: PR into `dev` per `feedback-use-dev-branch`)

## Problem

Deployment from `woosoo-platform/` works but has five stability gaps that will bite under pressure:
1. `rollback-client.sh` is not migrated — hardcoded `cd "$NEXUS_DIR"` then runs `docker compose` from the wrong CWD; a bad deploy cannot be rolled back cleanly.
2. No single wrapper for the canonical sequence (doctor → backup → deploy → health). Operators have to remember and order four commands.
3. `deploy.sh:32-33` defaults to `staging`; stated policy (memory `feedback-use-dev-branch`, 2026-05-25) is `dev`. Silent wrong-branch deploys are easy.
4. Four scripts are copied but not migrated (`deploy-tablet.sh`, `verify-tablet-deploy-context.sh`, `update-client.sh`, `verify-client.sh`) and sit next to working ones — loaded landmines.
5. Pi runtime path never verified end-to-end (only Windows dev box). First real Pi deploy is also the first integration test.

## Contrarian Review

Considered alternatives and rejected:
- **Makefile / justfile / Taskfile**: adds a new dependency on the Pi for one wrapper. Plain bash is enough; operators can `cat` it.
- **Release-tag promotion model** (deploy by tag instead of branch reset): bigger refactor; revisit once Pi runtime is verified.
- **Touch `compose.yaml`**: not needed; all gaps are in the script layer.
- **Auto-rollback in `deploy-all.sh` on failure**: tempting but risky — a half-failed deploy may not be safe to auto-revert without operator eyes. Keep rollback explicit.

## Investigation

Findings from explore agent (full report retained in session transcript):
- 5 of 12 deployment scripts are migrated and working (`deploy.sh`, `apply-woosoo-config.sh`, `doctor.sh`, `woosoo-backup.sh`, `woosoo-health.sh`, `pi-reboot-health.sh`, `switch-network.sh`).
- 5 are unmigrated: `deploy-tablet.sh`, `verify-tablet-deploy-context.sh`, `update-client.sh`, `rollback-client.sh`, `verify-client.sh`.
- `WOOSOO_DOCKER_COMPOSE` env-var pattern is established and consistent across migrated scripts.
- No Makefile / Taskfile / direnv config exists at platform root.
- No existing rollback procedure works end-to-end on the platform-root model.
- `pre-merge-check.sh` does not validate platform-root infra (per-app only).

## Root Cause

Migration from the per-app orchestration model to platform-root was done additively — working subset moved cleanly, but the rollback + tablet-only paths were deferred and never returned to. Without a working rollback in the new model, the migration is unsafe to depend on for production deploys.

## Proposed Fix

5 sequenced changes (see approved plan):
1. Migrate `rollback-client.sh` (`SCRIPT_DIR`/`PLATFORM_ROOT`, `$COMPOSE_CMD` from platform root, preserve backup-dir-arg contract).
2. Quarantine 4 unmigrated scripts under `scripts/deployment/legacy/` with a README warning.
3. Change `deploy.sh:32-33` default branch `staging` → `dev`; document `WOOSOO_DEPLOY_BRANCH=dev` in env example.
4. Add `scripts/deployment/deploy-all.sh` — strict-ordered wrapper (doctor → backup → deploy → health).
5. Prepend operator quick-reference card to `scripts/deployment/README.md`.

## Files Changed

- `scripts/deployment/rollback-client.sh` — full migration to platform-root pattern. New: `SCRIPT_DIR`/`PLATFORM_ROOT` derivation, `$COMPOSE_CMD` from `WOOSOO_DOCKER_COMPOSE`, all `docker compose` calls run from `$PLATFORM_ROOT`, pre-rollback SHA snapshot to `/opt/woosoo/backups/rollback-points/` (forward-roll point). Existing contract preserved (takes a backup directory arg with `*.commit` files + optional `woosoo-nexus.env` snapshot).
- `scripts/deployment/deploy.sh` — three edits:
  - **Branch default** `staging` → `dev` (lines 32-33).
  - **Pre-deploy snapshot block** added before `pull_repo` calls (line ~115). Writes `$WOOSOO_BACKUP_DIR/update-YYYYMMDD-HHMMSS/{woosoo-nexus,tablet-ordering-pwa}.commit` + `woosoo-nexus.env` BEFORE `git reset --hard`. This is the input `rollback-client.sh` consumes — **closes the producer/consumer contract gap** that the review pass discovered.
  - **Inner-variable rename** `BACKUP_DIR`/`BACKUP_FILE` → `DIFF_BACKUP_DIR`/`DIFF_BACKUP_FILE` + `local` declaration inside `pull_repo()`, so the FORCE_RESET diff-backup path does not shadow the script-level snapshot path.
  - **Rollback handle hint** printed at end (line ~207): `sudo bash scripts/deployment/rollback-client.sh $BACKUP_DIR`.
- `scripts/deployment/deploy-all.sh` — **new**. Strict-ordered wrapper around `doctor.sh → woosoo-backup.sh → deploy.sh → woosoo-health.sh` with `set -euo pipefail` and hard-stop error handler. Surfaces latest `update-*` snapshot path in both success and failure output via `latest_snapshot()` helper (`ls -1dt`).
- `scripts/deployment/legacy/` — **new directory**. `git mv` quarantined: `deploy-tablet.sh`, `verify-tablet-deploy-context.sh`, `update-client.sh`, `verify-client.sh`.
- `scripts/deployment/legacy/README.md` — **new**. Explains why these are broken under platform-root and points to the migrated replacements.
- `scripts/deployment/README.md` — prepended operator quick-reference card; updated status table to reflect rollback migration, new `deploy-all.sh`, the new `update-*` snapshot format `deploy.sh` writes, and `legacy/` quarantine. Quick-reference rollback command now uses `$(ls -1dt /opt/woosoo/backups/update-* | head -1)` so the operator doesn't have to type the timestamp.
- `docs/deployment/examples/woosoo.env.example` — added `WOOSOO_DEPLOY_BRANCH=dev` as the supported override; flipped `WOOSOO_NEXUS_BRANCH` / `WOOSOO_TABLET_BRANCH` defaults `staging` → `dev`; updated IPs to real values: `WOOSOO_SERVER_IP=192.168.100.42` (home Pi), `WOOSOO_POS_HOST=192.168.100.7` (POS / krypton_woosoo). Added documentation comment listing both home (`192.168.100.0/24`) and resto (`192.168.1.0/24`) network values.

No change to: `compose.yaml`, any Dockerfile, any application code, `apply-woosoo-config.sh`, `woosoo-backup.sh`, the read-only diagnostic scripts.

## Verification

### Stage A — dev box (Windows + docker) — PASS

Raw output:

```
$ bash -n scripts/deployment/{deploy-all,deploy,rollback-client,doctor,woosoo-backup,woosoo-health,pi-reboot-health,apply-woosoo-config}.sh
OK: scripts/deployment/deploy-all.sh
OK: scripts/deployment/deploy.sh
OK: scripts/deployment/rollback-client.sh
OK: scripts/deployment/doctor.sh
OK: scripts/deployment/woosoo-backup.sh
OK: scripts/deployment/woosoo-health.sh
OK: scripts/deployment/pi-reboot-health.sh
OK: scripts/deployment/apply-woosoo-config.sh

$ docker compose --env-file ./woosoo-nexus/.env -f compose.yaml config --quiet
OK: compose.yaml parses with interpolation

$ docker compose --env-file ./woosoo-nexus/.env -f compose.yaml config --services
mysql
redis
app
reverb
tablet-pwa
nginx
queue
scheduler
```

`docker compose build` and `up -d` were not executed on the dev box in this
pass (heavy, not strictly required since no compose-file/Dockerfile change was
made). Reviewer/operator may run them as a fuller dev gate before Stage B.

### Stage A pass 2 — post-R2 re-verification — PASS

After the review pass surfaced the rollback contract gap, `deploy.sh` gained a
pre-deploy snapshot block, `deploy-all.sh` gained a `latest_snapshot()` helper,
and the example .env was updated with real IPs. Re-ran the cheap gates:

```
$ bash -n scripts/deployment/{deploy-all,deploy,rollback-client}.sh
OK: scripts/deployment/deploy-all.sh
OK: scripts/deployment/deploy.sh
OK: scripts/deployment/rollback-client.sh

$ docker compose --env-file ./woosoo-nexus/.env -f compose.yaml config --quiet
OK: compose.yaml parses

$ grep -n BACKUP_DIR scripts/deployment/deploy.sh
89:        # with the script-level BACKUP_DIR snapshot path created below.
91:        local DIFF_BACKUP_DIR DIFF_BACKUP_FILE
92:        DIFF_BACKUP_DIR="${WOOSOO_BACKUP_DIR:-/opt/woosoo/backups}/git-diffs"
93:        mkdir -p "$DIFF_BACKUP_DIR"
94:        DIFF_BACKUP_FILE="$DIFF_BACKUP_DIR/${name}-$(date +%F_%H%M%S).patch"
114:WOOSOO_BACKUP_DIR="${WOOSOO_BACKUP_DIR:-/opt/woosoo/backups}"
115:BACKUP_DIR="$WOOSOO_BACKUP_DIR/update-$(date +%Y%m%d-%H%M%S)"
116:mkdir -p "$BACKUP_DIR"
121:    git -C "$dir" rev-parse HEAD > "$BACKUP_DIR/${name}.commit"
131:  cp "$NEXUS_DIR/.env" "$BACKUP_DIR/woosoo-nexus.env"
134:  rollback handle: $BACKUP_DIR
207:    sudo bash scripts/deployment/rollback-client.sh $BACKUP_DIR
```

`BACKUP_DIR` is used consistently (lines 115→207). FORCE_RESET diff-backup path
uses `DIFF_BACKUP_DIR` (lines 91-94) and is `local` — no shadow. Producer
(`deploy.sh`) and consumer (`rollback-client.sh`) contracts match.

### Stage B — Pi runtime — PENDING (open follow-up, see Remaining Risks)

Operator gate:

1. Confirm `/etc/woosoo/woosoo.env` contains `WOOSOO_DEPLOY_BRANCH=dev` and IPs match the deployed network (home: `WOOSOO_SERVER_IP=192.168.100.42`, `WOOSOO_POS_HOST=192.168.100.7`; resto: `192.168.1.31` / `192.168.1.32`).
2. `cd /path/to/woosoo-platform && sudo git pull` (orchestration repo only).
3. `sudo bash scripts/deployment/deploy-all.sh` — must complete cleanly. Final output prints both the live-build verify command and the rollback handle (path under `/opt/woosoo/backups/update-*`).
4. Smoke test: `curl -ks https://$WOOSOO_HOST/`, `curl -ks https://$WOOSOO_HOST:4443/build-info.json`, place one real test order.
5. Confirm backups landed:
   - DB: `ls -lah /opt/woosoo/backups/db/` (newest `*.sql.gz` from `woosoo-backup.sh`).
   - Code snapshot: `ls -lah /opt/woosoo/backups/update-*` (newest dir contains `woosoo-nexus.commit`, `tablet-ordering-pwa.commit`, `woosoo-nexus.env`).
6. Rollback drill: `sudo bash scripts/deployment/rollback-client.sh "$(ls -1dt /opt/woosoo/backups/update-* | head -1)"`. Verify forward-roll point landed under `/opt/woosoo/backups/rollback-points/`, then re-deploy forward.

## Executioner Verdict

Pending Stage B (Pi runtime gate). Working tree shipped is Specialist + Stage-A-clean; Executioner approval is held until Pi verification closes the open gap from `infra-case-001`.

## Remaining Risks

- **Stage B (Pi runtime) is not closed by this case.** It remains the open verification gap from `infra-case-001` and must be exercised before relying on this work in production.
- Legacy nexus-internal orchestration files (`woosoo-nexus/compose.yaml`, `woosoo-nexus/docker/{nginx,certs,mysql}`, `woosoo-nexus/scripts/deployment/`) remain as a rollback path until Stage B passes — per the Transition section of `docs/deployment/production-docker.md`.
- The new `deploy-all.sh` does **not** auto-rollback on failure. Operator must read the output and decide. This is intentional.
