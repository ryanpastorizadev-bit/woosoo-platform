# Deployment scripts — operator reference

> **New to deployment?** Start with [`docs/deployment/DEPLOYMENT_GUIDE.md`](../../docs/deployment/DEPLOYMENT_GUIDE.md) — full step-by-step operator guide for both Pi and dev paths.
>
> **Pi/production** → `check.sh` → `init-woosoo-env.sh` (writes `./woosoo.env`, mode 0600) → `deploy-all.sh`. The deploy runs `apply-woosoo-config.sh` for you (installs dnsmasq, sets static IP via nmcli). A root-owned `/etc/woosoo/woosoo.env` is an optional fallback.
> **WSL / Docker Desktop dev** → `dev-docker-bootstrap.sh` then `docker compose build/up` (no system packages, no nmcli, no dnsmasq).
> Running the Pi path on a WSL host will break `systemd-resolved` and host DNS. The script now detects WSL and aborts early.

## Operator quick reference (the only commands you need 99% of the time)

Run from the **platform repo root** (`woosoo-platform/`), as root:

| Goal | Command |
|---|---|
| Full safe deploy (check → doctor → backup → deploy → health) | `sudo bash scripts/deployment/deploy-all.sh` |
| Deploy step only (runs doctor; skips backup + health verify) | `sudo bash scripts/deployment/deploy.sh` |
| Rollback last deploy | see fenced command below the table |
| Post-reboot check only | `sudo bash scripts/deployment/pi-reboot-health.sh` |
| Verify what's live | `curl -ks https://$WOOSOO_HOST:4443/build-info.json` |

Rollback the last deploy (picks the most recent `update-*` snapshot dir):

```bash
sudo bash scripts/deployment/rollback-client.sh "$(ls -1dt /opt/woosoo/backups/update-* | head -1)"
```

Branch deployed is `dev` by default. Override with `WOOSOO_DEPLOY_BRANCH=<branch>`
in `/etc/woosoo/woosoo.env` or as an env var on the command line.

## Migration status

These scripts moved here from `woosoo-nexus/scripts/deployment/` as part of
lifting Docker orchestration to the platform repo root (3-repo sibling model:
`woosoo-platform/` governance + orchestration, `woosoo-nexus/` and
`tablet-ordering-pwa/` are independent app repos).

Run everything from the **platform repo root** (`woosoo-platform/`).

| Script | Status | Notes |
|---|---|---|
| `deploy-all.sh` | **Migrated (new)** | Strict-ordered wrapper: `check` (informational) → `doctor` → `backup` → `deploy` → `health` (with grace + retry). Hard stops on any failure; prints a diagnosis bundle + rollback command on failure. The default operator command for a full deploy. |
| `deploy.sh` | **Migrated** | Platform-root; pulls each app repo in place; `bash -n` clean. Default branch is `dev` (overridable via `WOOSOO_DEPLOY_BRANCH`). **Writes a pre-deploy snapshot** to `$WOOSOO_BACKUP_DIR/update-YYYYMMDD-HHMMSS/` containing `woosoo-nexus.commit`, `tablet-ordering-pwa.commit`, and `woosoo-nexus.env` BEFORE `git reset --hard` — this is the input `rollback-client.sh` consumes. Path is printed at end of deploy. |
| `rollback-client.sh` | **Migrated** | Platform-root; consumes a backup directory (`update-YYYYMMDD-HHMMSS`) produced by `deploy.sh`. Saves a forward-roll snapshot to `/opt/woosoo/backups/rollback-points/` before resetting so you can step forward again if the rollback target was also bad. |
| `apply-woosoo-config.sh` | **Migrated** | Adds `WOOSOO_PLATFORM_PATH`; writes `woosoo-nexus/.env`; runs compose from platform root; `bash -n` clean. Pi runtime verification still required after config changes. |
| `woosoo-backup.sh` | **Migrated** | Uses `WOOSOO_PLATFORM_PATH` for compose execution; flock-protected; 14-day retention. |
| `doctor.sh` | **Migrated** | Preflight gate for Docker-only Pi runtime: required config, compose interpolation, host service drift, port ownership, and Pi resource checks. Diagnostic only. |
| `woosoo-health.sh` | **Migrated** | Runtime smoke gate for Docker MySQL/Redis, tablet runtime config, Reverb origin/WSS, queue logs, and public endpoints. Diagnostic only. |
| `pi-reboot-health.sh` | **Migrated** | Post-controlled-reboot gate: persistent journal, host services, port ownership, Docker stack, and Reverb listener evidence. Diagnostic only. |
| `switch-network.sh` | **Migrated** | Home ↔ resto IP swap via `force-recreate`. |
| `legacy/` | **Quarantined** | `deploy-tablet.sh`, `verify-tablet-deploy-context.sh`, `update-client.sh`, `verify-client.sh` — assume the pre-platform-root single-repo model and will misbehave if run. See `legacy/README.md`. |

## Production diagnostic order

The `deploy-all.sh` wrapper now enforces this order. Run the steps individually
only if you have a specific reason (e.g. running just the preflight without
mutating state).

```bash
# Default: do everything safely, in order
sudo bash scripts/deployment/deploy-all.sh

# Equivalent manual sequence (in case you want to gate between steps)
sudo bash scripts/deployment/doctor.sh         # preflight
sudo bash scripts/deployment/woosoo-backup.sh  # backup before mutation
sudo bash scripts/deployment/deploy.sh         # the deploy
sudo bash scripts/deployment/woosoo-health.sh  # post-deploy verify

# After a controlled maintenance-window reboot
sudo bash scripts/deployment/pi-reboot-health.sh
```

The diagnostic scripts are intentionally read-only. They must not edit compose,
nginx, environment files, Docker resources, or application code.

## Production safety latches

Never use these commands on the production Pi unless there is an explicit,
reviewed data-destruction plan:

```bash
docker compose down --volumes
docker volume prune
docker system prune --volumes
```

Named volumes such as `woosoo-nexus_mysql_data`, `woosoo-nexus_redis_data`, and
`woosoo-nexus_storage_data` are production state. Keep them intact during deploys
and rollbacks.

## Testing deployment on WSL2

The full Pi deploy path (static IP / dnsmasq / systemd / `/etc/woosoo/woosoo.env` /
3-remote git pull / live tablet and Reverb traffic) cannot be exercised on a dev
box. The WSL2 staging-parity path tests the Docker orchestration layer only.

**To enter the test environment (from Windows cmd or PowerShell):**

```cmd
wsl
cd ~/projects/woosoo-platform
```

**Staging-parity deploy test:**

```bash
bash scripts/deployment/init-woosoo-env.sh        # writes ./woosoo.env (first time only)
WOOSOO_ALLOW_NON_PI=true sudo -E bash scripts/deployment/deploy-all.sh
```

`WOOSOO_ALLOW_NON_PI=true` bypasses the Pi-only guard that would otherwise abort.
This exercises: check → doctor → backup → deploy → health — identical to production
minus Pi system mutations (nmcli, dnsmasq, systemd-resolved).

**What this tests:**
- `check.sh` preflight (env vars, Docker, compose config)
- `doctor.sh` preflight gate
- `deploy.sh` git pull + compose orchestration
- `woosoo-health.sh` post-deploy smoke check

**What still requires Pi hardware:**
- Static IP assignment via nmcli
- dnsmasq install and DNS resolution
- systemd service management
- `/etc/woosoo/woosoo.env` fallback path
- Live tablet + Reverb WS traffic

Old copies remain in `woosoo-nexus/scripts/deployment/` until the platform
deploy path is verified on the Pi, then they are removed in a cleanup commit.
