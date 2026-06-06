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

## Production guardrails (Nexus + Tablet only)

This document is the canonical Docker reference for the platform-root Nexus +
Tablet deployment path. Print Bridge Docker/runtime design is intentionally out
of scope here; `woosoo-print-bridge/` remains the Flutter Android relay and must
be handled in a separate task if its deployment boundary changes.

- Treat built images as the deployable artifact. Runtime `.env` values come from
  `woosoo-nexus/.env` via `--env-file`, not from committed secrets or ad-hoc
  container mutation.
- Keep health checks aligned with the process each container actually runs:
  PHP-FPM checks belong on the `app` service, while queue, scheduler, and Reverb
  workers need process-specific checks before they can be treated as deployment
  gates.
- Smoke checks must hit published endpoints from `compose.yaml`: Nexus through
  ports `80`/`443`, and the Tablet PWA through port `4443`.
- If a future immutable Nginx/PHP-FPM split replaces the current bind-mounted
  staging model, ensure the Nginx container can read the Laravel `public/`
  directory and create `public/storage` before dropping privileges, or grant the
  runtime user ownership required to create the storage link.

## The two `docker/` directories (intentional)

| Path | Role |
|---|---|
| `woosoo-platform/docker/` | **Runtime authority** — what `nginx` mounts: `nginx/default.conf`, `certs/`, `mysql/my.cnf`, `php/local.ini`. Human-edited. |
| `woosoo-nexus/docker/` | **Image build inputs only** — `php/www.conf`, `php/zzz-app.conf`, `docker-entrypoint.sh` are `COPY`ed by `woosoo-nexus/Dockerfile`. |

TLS key material (`docker/certs/*.pem`, `*.key`) is gitignored and
host-provided; only `generate-dev-certs.sh` + `README.md` are tracked.

## Deploy scripts

`scripts/deployment/` (run from platform root):

- `check.sh` — no-sudo pre-deploy readiness check. Reports anything missing
  (tools, certs, config, app repos, built images, not-running containers) with a
  FIX command for each. Run it first on any machine.
- `init-woosoo-env.sh` — seeds `./woosoo.env` from the app `.env` files and
  prompts to confirm each value; re-runnable. Writes the file `chmod 600`. No sudo.
- `deploy-all.sh` — the single full-deploy command: `check → backup → deploy →
  health`. **Use this** instead of calling `deploy.sh` directly. The `deploy` step
  pulls each app repo, applies config, runs the `doctor.sh` gate, hydrates
  dependencies (composer/npm), builds **fresh** images (tablet UI cache-busted by
  build sha), migrates, starts, and warms caches — with retry on the flaky
  network/build steps.
- `deploy.sh` — the workhorse the wrapper calls. It runs the `doctor.sh` gate
  itself, **right after `apply-woosoo-config.sh` writes `woosoo-nexus/.env`** — so
  the gate validates the generated env and is never blocked on a fresh machine.
  Always runs (no skip flag); the placeholder/empty-secret gate cannot be bypassed
  by calling `deploy.sh` directly, and it gates build/migrate/up.
- `apply-woosoo-config.sh` — writes `woosoo-nexus/.env` (`chmod 600`) and runs
  compose from `WOOSOO_PLATFORM_PATH` (default = parent of `WOOSOO_NEXUS_PATH`).

See `scripts/deployment/README.md` for the full per-script reference.

Config contract — secrets live in **one** operator file, resolved in this order:
1. `./woosoo.env` (platform root, user-owned, mode 0600) — **primary**; written by
   `init-woosoo-env.sh`, no sudo required.
2. `/etc/woosoo/woosoo.env` (root-owned, mode 0640) — optional system-path
   alternative for a locked-down production host.

**First-time setup** — generate `./woosoo.env`, confirming each value
(re-runnable; loads existing values as defaults):

```bash
bash scripts/deployment/check.sh          # see what's missing first
bash scripts/deployment/init-woosoo-env.sh
```

Then deploy: `sudo bash scripts/deployment/deploy-all.sh`.

Manual template (if you prefer hand-editing): `docs/deployment/examples/woosoo.env.example`.

## Verification status

- Dev box (Windows): `docker compose config` equivalent to the pre-move
  baseline (only the relocated shared-infra mount sources differ); `docker
  compose build app tablet-pwa` succeeds. **PASS.**
- Pi5 runtime (static IP / dnsmasq / systemd / 3-remote pull / live device /
  printer relay): **NOT yet verified — required follow-up with Pi access.**

## Tablet UI development loop

The production `tablet-pwa` service builds a static `nuxi generate` image with **no
bind-mount** — every UI change otherwise needs a full `docker compose build tablet-pwa`.
For fast iteration use the profile-gated dev service (same single compose file, not an
override, production path untouched):

```bash
# main stack up (for API/Reverb), then:
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml \
  --profile dev up tablet-pwa-dev
# open http://localhost:3000 — edits in ./tablet-ordering-pwa hot-reload
```

`tablet-pwa-dev` runs `Dockerfile.dev` (Nuxt dev server) with `./tablet-ordering-pwa`
bind-mounted and polling watchers (Windows/Docker inotify does not propagate). It is
**absent** from the default/production invocation (`profiles: ["dev"]`).

The prod `tablet-pwa` service no longer has `env_file: ./woosoo-nexus/.env` — it only
needs the `APP_RUNTIME_*` / `NUXT_PUBLIC_*` vars set explicitly in `environment:`
(entrypoint reads only `APP_RUNTIME_*`). This stops Laravel secrets (APP_KEY,
DB_PASSWORD, …) leaking into the tablet nginx container.

## Tablet PWA auto-update (installed kiosk tablets)

Installed tablets now **update themselves** after a deploy — no per-device
action, and a customer mid-order is never interrupted. Implemented in
`tablet-ordering-pwa` (branch `fix/tablet/pwa-auto-update`):

**How it works**

1. **Navigation is network-first** (`public/sw.ts`): a reachable tablet always
   fetches the live `index.html` (falls back to the precached shell only when
   offline). The old precache can no longer pin a stale shell forever.
2. **Order-safe auto-apply** (`composables/useAppUpdate.ts`, wired in
   `app.vue`): the app polls for a new service worker every **60 s** (and on
   wake/visibility, plus a 600 s vite-pwa backup). When a new worker is waiting
   AND there is **no active dining session** (`!sessionStore.isActive`), it
   auto-activates (`SKIP_WAITING` → `controllerchange` → one reload). If a
   customer is mid-order it is **held** and applied the instant the session
   ends — no cart loss, no interruption.
3. **Build-version backstop** (`composables/useBuildVersion.ts`): every 5 min
   the app fetches `/build-info.json` (no-store, prerendered per build). Two
   consecutive sha mismatches → `/recovery` → clean reload. This catches any
   case where path 1–2 failed.
4. `sw.js`, `runtime-config.js`, `/build-info.json` are served `no-store`
   (`tablet-ordering-pwa/docker/nginx/tablet-pwa.conf`); `/build-info.json` is
   prerendered (`nuxt.config.ts` `nitro.prerender.routes`) so it always
   reflects the **deployed** build, not the cached one.

Staff can still force it immediately from **/settings → Apply Update**.

Expected propagation after a prod deploy: idle tablets within ~1 minute;
tablets mid-order at the moment the order completes; worst case (both failed)
within ~5–10 min via the recovery backstop.

## Operational scenarios — exact commands

All commands run from the **platform repo root** (`woosoo-platform/`).

### 1. Deploy a tablet UI change to production

```bash
# 1. land the change on the tablet repo branch the deploy pulls
#    (woosoo-nexus/.env via apply-woosoo-config sets PUBLIC_HOST etc.)
cd tablet-ordering-pwa && git push origin <branch>   # or merge to deploy branch
cd ..

# 2. rebuild + restart ONLY the tablet image (no DB/stack downtime)
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml \
  build --no-cache tablet-pwa
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml \
  up -d tablet-pwa
```
On the Pi the full `scripts/deployment/deploy.sh` does the per-repo pull +
build + up. Tablets then auto-update per the mechanism above — **no tablet
action required**.

### 2. Force one tablet to update now (staff)

On the tablet: **Settings (PIN) → Apply Update**. The button is enabled
whenever an update is waiting (`needRefresh`). The device reloads once onto
the new build. Use this only to skip the wait; it is not required.

### 3. A tablet seems stuck on the old UI — diagnose

```bash
# what build does the SERVER currently serve?
curl -ks https://<PUBLIC_HOST>:4443/build-info.json | tr ',' '\n' | grep -i sha

# is the tablet container actually the new image?
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml \
  exec tablet-pwa sh -c 'ls -1 /usr/share/nginx/html/_nuxt | head'
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml logs --tail=50 tablet-pwa
```
On the device, compare with the running build: open `/settings` (shows build
sha) or DevTools console — `window.__NUXT__.config.public.buildSha`. If the
server sha is new but the device sha is old, the backstop will route it to
`/recovery` within ≤10 min; to force immediately use scenario 2, or as a last
resort power-cycle the tablet (cold start re-fetches the network-first shell).

### 4. Verify which build is live (server side)

```bash
curl -ks https://<PUBLIC_HOST>:4443/build-info.json
# -> { "buildSha": "...", "buildBranch": "...", "buildTime": "..." }
```

### 5. Roll back a bad tablet build

```bash
cd tablet-ordering-pwa && git checkout <previous-good-ref> && cd ..
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml \
  build --no-cache tablet-pwa
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml \
  up -d tablet-pwa
# tablets auto-roll-forward to the rebuilt (older) image the same way
```

### 6. Local UI dev loop (instant, no rebuild)

See **Tablet UI development loop** above — `--profile dev up tablet-pwa-dev`,
edit, browser hot-reloads. No service worker / no rebuild in dev.

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
