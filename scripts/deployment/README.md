# Deployment scripts — migration status

These scripts moved here from `woosoo-nexus/scripts/deployment/` as part of
lifting Docker orchestration to the platform repo root (3-repo sibling model:
`woosoo-platform/` governance + orchestration, `woosoo-nexus/` and
`tablet-ordering-pwa/` are independent app repos).

Run everything from the **platform repo root** (`woosoo-platform/`).

| Script | Status | Notes |
|---|---|---|
| `deploy.sh` | **Migrated** | Platform-root; pulls each app repo in place; `bash -n` clean. Pi runtime verification PENDING. |
| `apply-woosoo-config.sh` | **Migrated** | Adds `WOOSOO_PLATFORM_PATH`; writes `woosoo-nexus/.env`; runs compose from platform root; `bash -n` clean. Pi runtime verification PENDING. |
| `deploy-tablet.sh` | **NOT migrated** | Still assumes `NEXUS_DIR/compose.yaml`. Do not rely on Pi until reworked + Pi-verified. |
| `verify-tablet-deploy-context.sh` | **NOT migrated** | Same compose-path assumption. |
| `update-client.sh` | **NOT migrated** | Own `git pull` + `docker compose` assume single-repo / nexus CWD. |
| `rollback-client.sh` | **NOT migrated** | `git reset --hard` + compose assume single-repo / nexus CWD. |
| `verify-client.sh` | **NOT migrated** | `docker compose` calls assume nexus CWD. |
| `woosoo-backup.sh` | **NOT migrated** | `cd "$WOOSOO_NEXUS_PATH"` + compose default. |
| `woosoo-health.sh` | **NOT migrated** | `cd "$WOOSOO_NEXUS_PATH"` + compose default. |

**Verification gap:** the Pi deploy path (static IP / dnsmasq / systemd /
`/etc/woosoo/woosoo.env` / 3-remote git pull) cannot be exercised on a Windows
dev box. `deploy.sh` and `apply-woosoo-config.sh` are syntax-checked only;
full runtime verification and the rework of the 7 NOT-migrated scripts are a
required follow-up to be done with Pi access.

Old copies remain in `woosoo-nexus/scripts/deployment/` until the platform
deploy path is verified on the Pi, then they are removed in a cleanup commit.
