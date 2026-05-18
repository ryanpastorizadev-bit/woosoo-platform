---
status: canonical
last_reviewed: 2026-05-18
scope: ecosystem
---

# Production Docker Deployment (Platform-Root Authority)

This is the canonical deployment reference. It supersedes
`woosoo-nexus/docs/deployment/production-docker.md` for **where orchestration
lives and runs**. (The nexus-internal deployment docs are rewritten when the
legacy nexus orchestration files are physically removed — see Transition.)

## Topology — 3 independent git repos (NOT a monorepo)

| Dir | Git remote | Role |
|---|---|---|
| `woosoo-platform/` | `ryanpastorizadev-bit/woosoo-platform` | Governance **and orchestration**: `compose.yaml`, `docker/`, `scripts/deployment/` |
| `woosoo-nexus/` | `tech-artificer/woosoo-nexus` | Laravel app (independent repo) |
| `tablet-ordering-pwa/` | `tech-artificer/tablet-ordering-pwa` | Nuxt PWA (independent repo) |

The app repos are gitignored by the platform repo and versioned independently.
The deploy scripts pull each app repo **in place**.

## Orchestration authority

Run **all** `docker compose` operations from the platform repo root
(`woosoo-platform/`):

```bash
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml up -d --build
```

- `--env-file ./woosoo-nexus/.env` feeds `${PUBLIC_HOST}`, `${REVERB_APP_KEY}`,
  etc. into compose interpolation. Without it those fall back to defaults.
  This is baked into the `WOOSOO_DOCKER_COMPOSE` default in the deploy scripts.
- Compose project name is pinned `name: woosoo-nexus` so container / volume /
  network names (and the Pi's existing `*_mysql_data`, `*_redis_data`,
  `*_storage_data` volumes) are **not** orphaned by the relocation.
- MySQL is not published to the host (internal `woosoo` network only).
- There are no override files; `compose.yaml` is the single source of truth.

## The two `docker/` directories (intentional)

| Path | Role |
|---|---|
| `woosoo-platform/docker/` | **Runtime authority** — what `nginx` mounts: `nginx/default.conf`, `certs/`, `mysql/my.cnf`, `php/local.ini`. Human-edited. |
| `woosoo-nexus/docker/` | **Image build inputs only** — `php/www.conf`, `php/zzz-app.conf`, `docker-entrypoint.sh` are `COPY`ed by `woosoo-nexus/Dockerfile`. |

TLS key material (`docker/certs/*.pem`, `*.key`) is gitignored and
host-provided; only `generate-dev-certs.sh` + `README.md` are tracked.

## Deploy scripts

`scripts/deployment/` (run from platform root):

- `deploy.sh` — pulls each app repo in place (`WOOSOO_NEXUS_BRANCH`,
  `WOOSOO_TABLET_BRANCH`), runs `apply-woosoo-config.sh`, builds, starts,
  warms caches. **Migrated; syntax-checked; Pi runtime verification PENDING.**
- `apply-woosoo-config.sh` — `WOOSOO_PLATFORM_PATH` (default = parent of
  `WOOSOO_NEXUS_PATH`); still writes `woosoo-nexus/.env`; runs compose from the
  platform path. **Migrated; syntax-checked; Pi runtime verification PENDING.**
- The other 7 scripts are copied but **not yet platform-migrated** — see
  `scripts/deployment/README.md` for per-script status.

Config contract: `/etc/woosoo/woosoo.env` (root-owned, mode 0600). Template:
`docs/deployment/examples/woosoo.env.example` (now includes
`WOOSOO_PLATFORM_PATH`, `WOOSOO_NEXUS_BRANCH`, `WOOSOO_TABLET_BRANCH`).

## Verification status

- Dev box (Windows): `docker compose config` equivalent to the pre-move
  baseline (only the relocated shared-infra mount sources differ); `docker
  compose build app tablet-pwa` succeeds. **PASS.**
- Pi5 runtime (static IP / dnsmasq / systemd / 3-remote pull / live device /
  printer relay): **NOT yet verified — required follow-up with Pi access.**

## Transition state (important)

The relocation was done **additively**. The legacy
`woosoo-nexus/compose.yaml`, `woosoo-nexus/compose.local.yaml`,
`woosoo-nexus/docker/{nginx,certs,mysql}`, `woosoo-nexus/docker/php/local.ini`
and `woosoo-nexus/scripts/deployment/` are intentionally **retained** as the
Pi rollback path until the platform deploy path is verified on the Pi.

Deferred follow-up (do with Pi access, then a single cleanup commit per repo):
1. Verify the full Pi deploy cycle on the platform-root stack.
2. Rework the 7 non-core deploy scripts for the platform-root model.
3. Remove the retained legacy nexus orchestration files (Group B).
4. Rewrite the nexus-internal docs (`woosoo-nexus/README.md`,
   `docs/deployment/production-docker.md`, `docs/architecture/ARCHITECTURE.md`,
   `.agents.md`, `docs/INDEX.md`) **in the same commit** the Group B files are
   removed — so no doc asserts a false state at any commit.

The unused BI/ETL stack has been removed from `woosoo-nexus`
(`chore/nexus/remove-bi-stack`); archived BI docs (`status: archived`) remain.
