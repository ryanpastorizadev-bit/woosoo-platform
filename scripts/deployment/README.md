# Deployment scripts — migration status

These scripts moved here from `woosoo-nexus/scripts/deployment/` as part of
lifting Docker orchestration to the platform repo root (3-repo sibling model:
`woosoo-platform/` governance + orchestration, `woosoo-nexus/` and
`tablet-ordering-pwa/` are independent app repos).

Run everything from the **platform repo root** (`woosoo-platform/`).

| Script | Status | Notes |
|---|---|---|
| `deploy.sh` | **Migrated** | Platform-root; pulls each app repo in place; `bash -n` clean. Run `doctor.sh` before it and `woosoo-health.sh` after it on the Pi. |
| `apply-woosoo-config.sh` | **Migrated** | Adds `WOOSOO_PLATFORM_PATH`; writes `woosoo-nexus/.env`; runs compose from platform root; `bash -n` clean. Pi runtime verification still required after config changes. |
| `deploy-tablet.sh` | **NOT migrated** | Still assumes `NEXUS_DIR/compose.yaml`. Do not rely on Pi until reworked + Pi-verified. |
| `verify-tablet-deploy-context.sh` | **NOT migrated** | Same compose-path assumption. |
| `update-client.sh` | **NOT migrated** | Own `git pull` + `docker compose` assume single-repo / nexus CWD. |
| `rollback-client.sh` | **NOT migrated** | `git reset --hard` + compose assume single-repo / nexus CWD. |
| `verify-client.sh` | **NOT migrated** | `docker compose` calls assume nexus CWD. |
| `woosoo-backup.sh` | **Migrated** | Uses `WOOSOO_PLATFORM_PATH` for compose execution; verify on Pi before relying on it as the only backup path. |
| `doctor.sh` | **Migrated** | Preflight gate for Docker-only Pi runtime: required config, compose interpolation, host service drift, port ownership, and Pi resource checks. Diagnostic only. |
| `woosoo-health.sh` | **Migrated** | Runtime smoke gate for Docker MySQL/Redis, tablet runtime config, Reverb origin/WSS, queue logs, and public endpoints. Diagnostic only. |
| `pi-reboot-health.sh` | **Migrated** | Post-controlled-reboot gate: persistent journal, host services, port ownership, Docker stack, and Reverb listener evidence. Diagnostic only. |

## Production diagnostic order

Run these from the platform repo root on the Pi:

```bash
# 1. Before deploy/config changes
sudo bash scripts/deployment/doctor.sh

# 2. Back up before mutating runtime state
sudo bash scripts/deployment/woosoo-backup.sh

# 3. Deploy or apply config using the migrated platform-root scripts
sudo bash scripts/deployment/deploy.sh

# 4. After deploy
sudo bash scripts/deployment/woosoo-health.sh

# 5. After a controlled maintenance-window reboot
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

**Verification gap:** the full Pi deploy path (static IP / dnsmasq / systemd /
`/etc/woosoo/woosoo.env` / 3-remote git pull / live tablet and Reverb traffic)
cannot be fully exercised on a Windows dev box. Syntax checks and compose config
validation are local gates; the diagnostic order above is the required Pi gate.

Old copies remain in `woosoo-nexus/scripts/deployment/` until the platform
deploy path is verified on the Pi, then they are removed in a cleanup commit.
