# Legacy deployment scripts — DO NOT RUN

These scripts assume the **pre-platform-root** single-repo model: they hardcode
`cd "$NEXUS_DIR"` and run `docker compose ...` from inside `woosoo-nexus/`,
where `compose.yaml` no longer lives. Running them in the current topology will
either fail outright or — worse — modify the wrong working tree.

| Script | Why it's broken under platform-root |
|---|---|
| `deploy-tablet.sh` | `cd "$NEXUS_DIR"` before `docker compose build/up`. Compose file is at platform root now. |
| `verify-tablet-deploy-context.sh` | Same compose-path assumption. |
| `update-client.sh` | Own `git pull` + `docker compose` flow assumes single-repo CWD. Superseded by `scripts/deployment/deploy.sh`. |
| `verify-client.sh` | `docker compose` calls assume nexus CWD. Superseded by `scripts/deployment/woosoo-health.sh`. |

**Use these instead** (from the platform repo root, as root):

| Goal | Migrated replacement |
|---|---|
| Full safe deploy | `sudo bash scripts/deployment/deploy-all.sh` |
| Deploy step only | `sudo bash scripts/deployment/deploy.sh` |
| Rollback | `sudo bash scripts/deployment/rollback-client.sh <backup-dir>` |
| Post-deploy verify | `sudo bash scripts/deployment/woosoo-health.sh` |

These files are retained for forensic reference only. They will be removed in
the same cleanup commit that removes the legacy nexus-internal orchestration
files (see Transition section of
[`docs/deployment/production-docker.md`](../../../docs/deployment/production-docker.md)).
