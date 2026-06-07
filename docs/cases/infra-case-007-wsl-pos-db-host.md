---
status: canonical
last_reviewed: 2026-06-06
scope: ecosystem
---

# CASE: infra-case-007-wsl-pos-db-host

WSL dev admin POS pages fail with `Connection refused` on `pos` DB connection because
`DB_POS_HOST=host.docker.internal` targets the WSL VM, not Windows where Krypton runs.

## Run State

- task_slug: infra-case-007-wsl-pos-db-host
- tier: 2
- branch: dev
- status: IN_PROGRESS
- last_completed_agent: specialist:infra
- next_agent: verifier
- active_runner: cursor
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-06

## Problem

Navigating woosoo-nexus admin (Dashboard, POS, any Krypton-backed page) throws:

```
SQLSTATE[HY000] [2002] Connection refused
(Connection: pos, Host: host.docker.internal, Port: 3308, Database: krypton_woosoo,
 SQL: select * from `sessions` order by `id` desc limit 1)
```

Not related to `db:seed` or containerised `mysql`. Krypton POS/MariaDB runs on **Windows**
port **3308**. With **Docker Engine inside WSL2**, `host.docker.internal` resolves to the
WSL VM — nothing listens on :3308 there.

## Success Criterion

- Fresh `dev-docker-bootstrap.sh` writes `DB_POS_HOST` = detected Windows LAN IP (same as `PUBLIC_HOST`)
- `dev-preflight.sh` auto-fixes legacy `DB_POS_HOST=host.docker.internal` on WSL
- `woosoo health` WARNs when POS TCP probe fails (does not block dev pipeline)
- DEPLOYMENT_GUIDE §4.1.2 documents operator verification steps

## Specialist Investigation & Implementation

### Investigation

- Confirmed error is Laravel `pos` connection (`krypton_woosoo.sessions`), triggered by admin
  navigation not seeder
- [`dev-docker-bootstrap.sh`](../../scripts/deployment/dev-docker-bootstrap.sh) defaulted
  `DEV_POS_HOST=host.docker.internal` with comment "reach Windows host" — incorrect for
  WSL2 Docker Engine (`compose.yaml` `host-gateway` = WSL VM)
- Pi home mode in [`switch-network.sh`](../../scripts/deployment/switch-network.sh) correctly
  uses `DB_POS_HOST=192.168.100.7:3308`
- Operator confirmed Krypton is installed on this Windows dev PC

### Implementation

1. **`dev-docker-bootstrap.sh`** — default `DEV_POS_HOST` to `$DEV_PUBLIC_HOST` (detected LAN IP);
   document `DEV_POS_HOST=host.docker.internal` override for Docker Desktop on Windows
2. **`scripts/lib/host-network.sh`** — added:
   - `woosoo_recommended_pos_db_host`
   - `woosoo_check_pos_db_host` (auto-fix `host.docker.internal` on WSL)
   - `woosoo_check_pos_db_connectivity` (WARN-only TCP probe via `WOOSOO_POS_DC_CMD`)
3. **`dev-preflight.sh`** — section 1c: POS DB host alignment + `DB_POS_PASSWORD` warn
4. **`pipeline.sh` `_dev_health`** — POS TCP probe after HTTP checks (WARN only)
5. **`DEPLOYMENT_GUIDE.md` §4.1.2** — Krypton prerequisite, host mapping, verify commands
6. **`check.sh`** — WSL: missing `woosoo.env` → WARN (not FAIL)

Extended by **infra-case-008** (deployment env audit): recreate+clear messaging, three-surface
docs §4.1.3, `switch-network` config path parity, `init-woosoo-env` network-switch secrets.

### Operator follow-up (manual)

After pulling these changes, on WSL from platform root:

```bash
# 1. Align .env (auto-fixes host.docker.internal → LAN IP)
woosoo check

# 2. Set Krypton readonly password if not already set
#    Edit woosoo-nexus/.env: DB_POS_PASSWORD=<from POS admin>

# 3. Recreate app services so env_file picks up DB_POS_* changes
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml \
  up -d --force-recreate app queue scheduler reverb

# 4. Verify from container
POS_HOST=$(grep -E '^DB_POS_HOST=' woosoo-nexus/.env | head -1 | cut -d= -f2- | tr -d '"')
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml \
  exec -T app sh -c "nc -zv ${POS_HOST} 3308"

# 5. Re-test admin Dashboard / POS pages in browser
```

Windows: confirm Krypton listening — `netstat -an | findstr ":3308"`

## Handoff

- Platform scripts/docs only; no `woosoo-nexus` code change
- Nexus graceful "POS offline" on all admin routes remains out of scope (separate Tier 3 case)

## Run State (checkpoint)

- last_completed_agent: specialist:infra
- next_agent: verifier
- active_runner: cursor
- status: IN_PROGRESS
- updated: 2026-06-06
