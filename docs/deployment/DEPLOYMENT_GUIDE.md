---
status: canonical
last_reviewed: 2026-05-27
scope: ecosystem
---

# Woosoo Deployment Guide

Step-by-step operator guide for deploying and updating the Woosoo stack.
For architectural detail and the compose/docker authority model, see
[`production-docker.md`](./production-docker.md). For per-script reference,
see [`../../scripts/deployment/README.md`](../../scripts/deployment/README.md).

---

## 1. Which path are you on? (read this first)

There are **two** deployment paths. Picking the wrong one will damage your
host (the Pi path installs `dnsmasq`, disables `systemd-resolved`, and tries
to set a static IP via `nmcli` — all destructive on a dev workstation).

| Host                                | Path     | Entry script                                  |
| ----------------------------------- | -------- | --------------------------------------------- |
| Raspberry Pi 5 in production/staging | **Pi**   | `scripts/deployment/deploy-all.sh`            |
| WSL2, Docker Desktop, dev Linux box | **Dev**  | `scripts/deployment/dev-docker-bootstrap.sh`  |

`apply-woosoo-config.sh` now refuses to run on WSL / Docker Desktop hosts.
If you see `ERROR: apply-woosoo-config.sh is a Pi provisioning script.`,
you are on the wrong path — switch to **Path B** below.

The rest of this guide is organised as: prerequisites → Path A (Pi) →
Path B (dev) → common operations → recovery → rollback → troubleshooting.

---

## 2. Prerequisites (both paths)

Both paths need the two app repos cloned **inside** the platform repo root:

```
woosoo-platform/              # governance + orchestration (this repo)
├── woosoo-nexus/             # Laravel API (nested, independent git repo)
└── tablet-ordering-pwa/      # Nuxt PWA (nested, independent git repo)
```

Both paths run `docker compose` **from the platform repo root**, never
from inside a sub-repo. The compose file is `woosoo-platform/compose.yaml`.

Both paths require Docker Engine ≥ 24 with the compose v2 plugin.

---

## 3. Path A — Production deploy on the Raspberry Pi

### 3.1 First-time Pi setup (one-off)

```bash
# 1. Clone the repos (app repos go inside the platform directory)
sudo mkdir -p /opt/woosoo && sudo chown $USER:$USER /opt/woosoo
cd /opt/woosoo
git clone https://github.com/ryanpastorizadev-bit/woosoo-platform.git
cd woosoo-platform
git clone https://github.com/tech-artificer/woosoo-nexus.git
git clone https://github.com/tech-artificer/tablet-ordering-pwa.git

# 2. See what's still missing (no sudo; prints a FIX line for each item)
bash scripts/deployment/check.sh

# 3. Generate the operator config ./woosoo.env (no sudo; written chmod 600).
#    Re-runnable — confirm or edit each value. See §3.2 for required values.
bash scripts/deployment/init-woosoo-env.sh

# 4. Full deploy. deploy-all.sh runs check -> backup -> deploy -> health
#    (the doctor.sh gate runs inside deploy, right after config is written).
#    The deploy step runs apply-woosoo-config.sh (installs dnsmasq, sets the
#    static IP, writes woosoo-nexus/.env), hydrates deps, builds fresh, migrates,
#    and starts the stack.
sudo bash scripts/deployment/deploy-all.sh
```

> Prefer a root-owned system-path config instead of `./woosoo.env`? Copy the
> template to `/etc/woosoo/woosoo.env` (mode 0640, root:root) — every script
> checks `./woosoo.env` first, then falls back to `/etc/woosoo/woosoo.env`.

### 3.2 Required values in `woosoo.env`

These map to what `doctor.sh` validates (it rejects placeholder/empty secrets, so
a deploy cannot proceed on default credentials). See the example file for the full
list with comments.

| Variable                    | Production value         | Notes                                  |
| --------------------------- | ------------------------ | -------------------------------------- |
| `WOOSOO_HOST`               | `woosoo.local`           | Hostname tablets resolve via dnsmasq   |
| `WOOSOO_SERVER_IP`          | `192.168.1.31`           | Pi's static IP on the restaurant LAN   |
| `WOOSOO_GATEWAY`            | `192.168.1.1`            | Restaurant router                      |
| `WOOSOO_CIDR`               | `24`                     |                                        |
| `WOOSOO_SCHEME`             | `https`                  |                                        |
| `WOOSOO_PLATFORM_PATH`      | `/opt/woosoo/woosoo-platform` |                                  |
| `WOOSOO_NEXUS_PATH`         | `/opt/woosoo/woosoo-platform/woosoo-nexus` |                     |
| `WOOSOO_POS_HOST`           | `192.168.1.32`           | **Static IP per AGENTS.md**            |
| `WOOSOO_POS_PORT`           | `3308`                   |                                        |
| `WOOSOO_POS_DATABASE`       | `krypton_woosoo`         |                                        |
| `WOOSOO_POS_USERNAME`       | `krypton_readonly`       |                                        |
| `WOOSOO_POS_PASSWORD`       | _(from POS admin)_       |                                        |
| `WOOSOO_DB_PASSWORD`        | _(strong, non-placeholder)_ |                                     |
| `WOOSOO_DB_ROOT_PASSWORD`   | _(strong, non-placeholder)_ |                                     |
| `WOOSOO_REVERB_APP_ID`      | `woosoo`                 |                                        |
| `WOOSOO_REVERB_APP_KEY`     | _(non-placeholder)_      | Reject `change_this_reverb_key`, etc.  |
| `WOOSOO_REVERB_APP_SECRET`  | _(non-placeholder)_      |                                        |
| `WOOSOO_DEVICE_AUTH_PASSCODE` | _(non-placeholder)_    | PIN tablets use to register            |
| `WOOSOO_DEPLOY_BRANCH`      | `main`                   | Locked production release branch. Use `dev` for integration testing or `staging` for staging Pi. |

After editing, run `sudo bash scripts/deployment/doctor.sh` standalone to
verify all values are accepted before triggering a full deploy.

### 3.3 Full safe deploy (recommended every time)

> **Branch default warning:** `deploy.sh` defaults `NEXUS_BRANCH` and `TABLET_BRANCH` to `dev` if
> `WOOSOO_DEPLOY_BRANCH` is not set in the shell environment. Always export the branch before
> running the deploy, even if it is set in `.env` — `sudo` drops environment variables unless
> you pass `-E`.

```bash
cd /opt/woosoo/woosoo-platform
# Confirm branch before deploying — scripts default to dev if this is unset
export WOOSOO_DEPLOY_BRANCH=main   # or staging / dev as appropriate
echo "Deploying branch: $WOOSOO_DEPLOY_BRANCH"
sudo -E bash scripts/deployment/deploy-all.sh
```

This is the single CI-style command. It runs `check → backup → deploy → health`
in strict order and aborts on the first failure (`check` is informational and
never blocks). The `deploy` step itself runs:

1. `git pull` on each app repo at `WOOSOO_*_BRANCH` (with retry on transient
   network failures) + a pre-deploy snapshot to
   `/opt/woosoo/backups/update-YYYYMMDD-HHMMSS/` (the input `rollback-client.sh` uses)
2. `apply-woosoo-config.sh` — writes `woosoo-nexus/.env` (and applies host/network
   config), so the generated env exists before it is validated
3. **Preflight gate** — `doctor.sh` (the hard gate; rejects placeholder/empty
   secrets and config drift). Always runs, no skip flag. Everything below is gated on it.
4. `docker compose build` (with retry). The tablet image is cache-busted by its
   build sha so a UI update is never served stale; if the tablet code actually
   moved, it is rebuilt `--no-cache`. PHP deps are hydrated (`composer install`)
   onto the bind-mounted `woosoo-nexus` when `vendor/` is missing or `composer.lock`
   changed; Vite assets build once
5. `php artisan migrate --force` in a one-off container — before any long-running
   service starts. A migration failure aborts the deploy so queue workers and the
   scheduler never boot on a stale schema
6. `docker compose up -d --remove-orphans`
7. Warms Laravel caches (config, route, view)

> The `doctor.sh` gate runs **inside** `deploy` (step 3), right after
> `apply-woosoo-config.sh` writes `woosoo-nexus/.env` — so it validates the
> generated env and is never blocked on a fresh machine where that file does not
> exist yet.

Tablets auto-update within ~1 minute of completion (see `production-docker.md`
§ "Tablet PWA auto-update").

### 3.4 Pi: update existing deploy after `git pull`

If you already pulled the platform repo manually:

```bash
cd /opt/woosoo/woosoo-platform
git pull origin main
sudo bash scripts/deployment/deploy-all.sh
```

That's it. `deploy-all.sh` handles the rest, including pulling the app repos
(inside the platform directory) to their configured branches.

### 3.5 Pi: post-reboot check (no deploy)

```bash
sudo bash scripts/deployment/pi-reboot-health.sh
```

---

## 4. Path B — Dev deploy on WSL2 / Docker Desktop / dev Linux

### 4.1 First-time dev setup

```bash
# 1. Clone the repos (app repos go inside the platform directory)
mkdir -p ~/projects && cd ~/projects
git clone https://github.com/ryanpastorizadev-bit/woosoo-platform.git
cd woosoo-platform
git clone https://github.com/tech-artificer/woosoo-nexus.git
git clone https://github.com/tech-artificer/tablet-ordering-pwa.git

# 2. Install the woosoo CLI command (once — creates /usr/local/bin/woosoo)
bash scripts/install.sh

# 3. Run the full dev pipeline (bootstrap + build + up + migrate + warm + health)
woosoo dev
```

`woosoo dev` handles everything: writes `woosoo-nexus/.env` (if needed), builds images,
starts the stack, migrates, warms caches, and prints a health summary. First build takes
~10 minutes; subsequent runs with `--no-pull --no-build` complete in under 30 seconds.

**Fast iteration after the first build:**
```bash
woosoo dev --no-pull --no-build   # skip pull + build (source changes only)
woosoo dev --from-step 4          # resume from a specific step
woosoo health                     # health check only
woosoo logs                       # tail logs
```

### 4.1.1 LAN access and `PUBLIC_HOST` (WSL2)

On WSL2, Docker binds ports inside the WSL VM. `localhost` works from Windows and WSL;
the physical LAN IP (`PUBLIC_HOST`) requires a Windows portproxy bridge.

| Mode | Command | What it does |
| ---- | ------- | ------------ |
| Passive (default) | `woosoo dev` | Detects LAN IP; **WARNs** if it drifts from `PUBLIC_HOST` — no `.env` writes |
| Active | `woosoo network` | Detect → sync `PUBLIC_HOST` → portproxy bridge → verify |
| TLS regen (opt-in) | `woosoo network --regen-certs` | Above + regenerate dev certs + restart nginx |
| Preview | `woosoo network --dry-run` | Show what would change; no writes |

**When to run `woosoo network`:**
- After `wsl --shutdown` (WSL VM IP changes → stale portproxy)
- After moving the laptop to a new network
- When `woosoo dev` preflight WARNs about `PUBLIC_HOST` drift
- Before testing from a LAN tablet

**Overrides:**
```bash
WOOSOO_PUBLIC_HOST=192.168.1.55 woosoo network   # skip auto-detection
WOOSOO_AUTO_SYNC=1 woosoo dev                    # opt-in silent PUBLIC_HOST sync (no portproxy)
```

**Tablet URL:** `https://<PUBLIC_HOST>:4443`  
**CA bootstrap:** `http://<PUBLIC_HOST>/woosoo-ca.crt`

Do **not** call `scripts/windows/setup-wsl-lan-access.ps1` directly — `woosoo network`
delegates to it via `invoke-elevated.ps1`. The first run from WSL may show a **Windows
UAC prompt**; approve once to create portproxy rules.

**Equivalent manual commands** (if you prefer not to use the pipeline):
```bash
# Bootstrap .env
bash scripts/deployment/dev-docker-bootstrap.sh

# Build + start
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml build
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml up -d

# First-run key + migrate
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml \
  exec -T app php artisan key:generate --force
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml \
  exec -T app php artisan migrate --force
```

`dev-docker-bootstrap.sh` deliberately skips: nmcli static IP, dnsmasq
install, systemd-resolved disable, apt packages, /etc/hosts edits. It only
writes `woosoo-nexus/.env` (and optionally `tablet-ordering-pwa/.env`)
with dev defaults.

### 4.2 Dev: update existing checkout after `git pull`

The stack uses **bind-mounts** for `woosoo-nexus/` and `tablet-ordering-pwa/`,
so PHP and JS source edits are visible immediately inside running containers
with no rebuild. You only rebuild when:

| Changed                                  | Action                                                |
| ---------------------------------------- | ----------------------------------------------------- |
| PHP / Blade / JS / Vue source only       | nothing; bind-mount picks it up                       |
| `composer.json` / `package.json`         | rebuild the affected service                          |
| `Dockerfile`                             | rebuild the affected service                          |
| `compose.yaml`                           | `up -d` to apply (Docker recreates only what changed) |
| `woosoo-nexus/.env`                      | `up -d --force-recreate <service>`                    |
| Migrations                               | `exec app php artisan migrate`                        |

Pattern: pull, then run only what changed.

```bash
cd ~/projects/woosoo-platform
git pull origin main
cd woosoo-nexus && git pull && cd ..
cd tablet-ordering-pwa && git pull && cd ..

# If composer / package / Dockerfile changed:
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml build
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml up -d --remove-orphans

# If only source changed, clear Laravel caches:
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml \
  exec -T app php artisan optimize:clear

# If migrations changed:
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml \
  exec -T app php artisan migrate
```

### 4.3 Testing the deploy pipeline on WSL2 (staging-parity)

Agents and operators who need to verify the deploy script flow before a Pi deploy
can run a staging-parity test from WSL2.

**Enter WSL from Windows cmd or PowerShell:**

```cmd
wsl
cd ~/projects/woosoo-platform
```

**Run the full pipeline with the Pi-guard bypassed:**

```bash
bash scripts/deployment/init-woosoo-env.sh   # first time only — writes ./woosoo.env
WOOSOO_ALLOW_NON_PI=true sudo -E bash scripts/deployment/deploy-all.sh
```

This is Scenario B2 from `docs/cases/infra-case-004-script-flow-unification.md`.
It exercises every stage of `deploy-all.sh` (check → backup → deploy → health, with the
`doctor.sh` gate inside deploy after config hydration) except Pi system mutations (nmcli,
dnsmasq, systemd). See that case doc for the full overlap audit and what still requires Pi hardware.

---

### 4.4 Dev: fast tablet UI iteration (no rebuild)

The production `tablet-pwa` service is a static `nuxi generate` image with
no bind-mount. For instant hot-reload use the profile-gated dev service:

```bash
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml \
  --profile dev up tablet-pwa-dev
# open http://localhost:3000 — edits in ./tablet-ordering-pwa hot-reload
```

---

## 5. Common operations (both paths)

All commands run from `woosoo-platform/`. Shortcut: export
`DC="docker compose --env-file ./woosoo-nexus/.env -f compose.yaml"` for
the session.

| Goal                                | Command                                                                |
| ----------------------------------- | ---------------------------------------------------------------------- |
| Show running services               | `$DC ps`                                                               |
| Tail logs of one service            | `$DC logs -f --tail=200 app`                                           |
| Restart one service                 | `$DC restart app`                                                      |
| Recreate one service after env change | `$DC up -d --force-recreate app`                                     |
| Rebuild one service (no cache)      | `$DC build --no-cache tablet-pwa && $DC up -d tablet-pwa`              |
| Shell into a container              | `$DC exec app bash`                                                    |
| Run artisan                         | `$DC exec -T app php artisan <cmd>`                                    |
| Run a queue restart                 | `$DC exec -T app php artisan queue:restart`                            |
| Clear all Laravel caches            | `$DC exec -T app php artisan optimize:clear`                           |
| Verify what build is live           | `curl -ks https://$WOOSOO_HOST:4443/build-info.json`                   |
| Stop the whole stack                | `$DC down`  (keeps volumes)                                            |

**Never** run `$DC down --volumes`, `docker volume prune`, or
`docker system prune --volumes` on production. Named volumes
(`woosoo-nexus_mysql_data`, `_redis_data`, `_storage_data`) are production
state.

---

## 6. Recovery: I ran the Pi script on a dev host by accident

This happens when `apply-woosoo-config.sh` runs on WSL / Docker Desktop and
disables `systemd-resolved`, deletes `/etc/resolv.conf`, and installs a
broken `dnsmasq`. The current script refuses to run in these conditions,
but if an older version damaged your host, recover with:

```bash
# 1. Re-enable host DNS resolver
sudo systemctl unmask systemd-resolved 2>/dev/null || true
sudo systemctl enable --now systemd-resolved

# 2. Restore the systemd-resolved-managed /etc/resolv.conf symlink
sudo ln -sfn /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# 3. Stop and disable the dnsmasq the Pi script installed
sudo systemctl disable --now dnsmasq 2>/dev/null || true

# 4. Confirm DNS works again
getent hosts github.com    # expect an IP
```

The apt-installed packages (`dnsmasq`, `bind9-dnsutils`, etc.) can stay —
they are inert once dnsmasq is stopped. After recovery, switch to Path B
(`dev-docker-bootstrap.sh`).

---

## 7. Rollback

Three independent paths — pick based on what you need to undo.

### 7.1 Rollback the Docker stack to the previous deploy (Pi)

If `deploy.sh` ran and you need the previous image set back:

```bash
sudo ls -1dt /opt/woosoo/backups/update-* | head -5
sudo bash scripts/deployment/rollback-client.sh \
  "$(sudo ls -1dt /opt/woosoo/backups/update-* | head -1)"
```

`rollback-client.sh` writes a forward-roll snapshot to
`/opt/woosoo/backups/rollback-points/` before resetting, so you can step
forward again if the rollback target was also bad.

### 7.2 Revert the platform repo to the commit before a `git pull`

```bash
cd ~/projects/woosoo-platform     # or /opt/woosoo/woosoo-platform
git reflog | head -20
# Find the pull line:  abc1234 HEAD@{N}: pull origin main: Fast-forward
# The commit one line BELOW it (HEAD@{N+1}) is your pre-pull commit.

git diff --stat <pre-pull-sha>..HEAD   # confirm what came in
git status                             # must be clean before reset
git reset --hard <pre-pull-sha>
```

Repeat inside `woosoo-nexus/` and `tablet-ordering-pwa/` if those sub-repos
were also pulled. The reset is reversible via reflog for ~90 days:
`git reset --hard <new-sha>`.

### 7.3 Revert a single file or commit

```bash
git checkout HEAD~1 -- scripts/deployment/doctor.sh   # one file
git revert <sha>                                       # one commit, safely
```

---

## 8. Troubleshooting

### `doctor.sh` fails with `<service> is enabled (not-found)`

You are on an old version of `doctor.sh`. Pull the platform repo and re-run.
`not-found` means the service is not installed at all — that is the correct
"Docker owns the runtime" state and the current `doctor.sh` accepts it.

### `apply-woosoo-config.sh` exits with `is a Pi provisioning script`

The guard detected WSL or a Docker Desktop-style host. Use
`dev-docker-bootstrap.sh` instead (§ 4.1). If you genuinely need to bypass
on a non-Pi Linux box that should host the full stack:

```bash
WOOSOO_ALLOW_NON_PI=true sudo -E bash scripts/deployment/apply-woosoo-config.sh
```

### Tablet stuck on the old UI after a deploy

The tablet PWA auto-updates within ~1 minute when idle, or at the end of an
active dining session. To force immediately:

- **From the tablet:** `Settings (PIN) → Apply Update`
- **From the server:** verify the build is live —
  `curl -ks https://$WOOSOO_HOST:4443/build-info.json | grep sha`

If the server sha is new but the tablet sha is old after 10 minutes, the
worker recovery backstop has also failed; power-cycle the tablet.

### `compose interpolation emitted a REVERB_APP_KEY warning`

`woosoo-nexus/.env` is missing or `REVERB_APP_KEY` is unset there. On Pi,
re-run `apply-woosoo-config.sh`. On dev, re-run `dev-docker-bootstrap.sh`.

### Containers up but `https://$WOOSOO_HOST` returns 502

Usually the `app` (PHP-FPM) service crashed during boot. Check:

```bash
$DC logs --tail=200 app
$DC exec app php artisan about
```

A common cause is missing `APP_KEY` — generate with
`$DC exec -T app php artisan key:generate --force`.

### Reverb broadcast not reaching tablets

Verify the queue worker is running and `REVERB_BROADCAST_HOST=reverb` in
`woosoo-nexus/.env`:

```bash
$DC ps queue reverb
$DC logs --tail=100 reverb queue
$DC exec -T app sh -c 'grep REVERB_BROADCAST_HOST .env'
```

The admin print-health dashboard (`/monitoring`) surfaces broadcast latency
and clock-skew live.

---

## 9. Reference

- [`production-docker.md`](./production-docker.md) — compose authority,
  bind-mount model, tablet PWA auto-update mechanism
- [`../../scripts/deployment/README.md`](../../scripts/deployment/README.md)
  — per-script quick reference
- [`examples/woosoo.env.example`](./examples/woosoo.env.example) — annotated
  template for `/etc/woosoo/woosoo.env`
- `../../AGENTS.md` — operating rules (one app per task, contract integrity,
  POS static IP `192.168.1.32`)
