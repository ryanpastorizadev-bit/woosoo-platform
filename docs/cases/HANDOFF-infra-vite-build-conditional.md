---
status: under-review
last_reviewed: 2026-05-30
scope: woosoo-nexus
---

# HANDOFF — infra-vite-build-conditional

Complete, copy-paste-ready implementation instructions for the infra Specialist.
Authoritative durable state is the case file: `docs/cases/infra-vite-build-conditional.md`.
Approved plan: `~/.claude/plans/review-this-plan-plan-cozy-hippo.md`.

> **Golden rule:** anchor every edit on the quoted CONTENT below, never on line numbers. Line
> numbers in this repo drift between edits and disagree between tools. Each block below shows
> the exact BEFORE text to match and the exact AFTER text to write.

---

## 0. Pre-flight

| Item | Value |
|---|---|
| Task slug | `infra-vite-build-conditional` |
| Tier | 2 (Standard) |
| Specialist | infra |
| Scope | woosoo-nexus entrypoint + woosoo-platform compose/deploy — **one task, no app split** |
| Branch | `agent/vite-build-conditional` |
| Contract impact | none |
| Sequence | Contrarian ✅ → **Specialist (you)** → Verifier → Executioner |

Before editing:

```bash
# From platform root: E:\Projects\woosoo-platform
git -C woosoo-nexus status --short      # expect clean (entrypoint untouched so far)
git status --short                      # platform: compose.yaml may show the prior 502 fix — leave it
```

Do **not** revert the existing `nginx.depends_on … condition: service_healthy` block in
`compose.yaml` — that is a separate, already-shipped 502 fix.

---

## 1. `woosoo-nexus/docker/docker-entrypoint.sh`

**Find this block (BEFORE):**

```sh
# Build Vite assets on web server startup so public/build/ is always in sync
# with the current source tree. Runs only for the php-fpm process (not for
# queue, scheduler, or reverb which share this entrypoint via CMD override).
# node_modules comes from the image's anonymous volume (compose.yaml), so
# this works identically on Linux (Pi) and Docker Desktop Windows.
if [ "${1:-}" = "php-fpm" ]; then
  echo "[entrypoint] Building Vite assets..."
  npm run build && echo "[entrypoint] Vite build complete." \
    || echo "[entrypoint] WARNING: Vite build failed; serving existing assets from nexus_build volume"
fi
```

**Replace with (AFTER):**

```sh
# Build Vite assets only when needed. Runs only for the php-fpm process (not
# for queue, scheduler, or reverb which share this entrypoint via CMD override).
# node_modules comes from the image's anonymous volume (compose.yaml), so this
# works identically on Linux (Pi) and Docker Desktop Windows.
#
# Build triggers ONLY when:
#   - public/build is missing/empty (fresh checkout — self-healing), OR
#   - WOOSOO_FORCE_VITE_BUILD=true (deploy of new code forces fresh assets).
# A plain container restart (crash/OOM/reboot) with assets already present
# SKIPS the build, so recovery is fast instead of a ~1-minute rebuild.
if [ "${1:-}" = "php-fpm" ]; then
  if [ "${WOOSOO_FORCE_VITE_BUILD:-false}" = "true" ] \
     || [ ! -d public/build ] \
     || [ -z "$(ls -A public/build 2>/dev/null)" ]; then
    echo "[entrypoint] Building Vite assets..."
    npm run build && echo "[entrypoint] Vite build complete." \
      || echo "[entrypoint] WARNING: Vite build failed; serving existing assets"
  else
    echo "[entrypoint] public/build present — skipping Vite build (set WOOSOO_FORCE_VITE_BUILD=true to force)."
  fi
fi
```

Why nested `if` (not `&&`/`||` on one line): mixing `&&` and `||` in POSIX `sh` has
precedence traps; the nested form is unambiguous. Note the file is `#!/usr/bin/env sh` with
`set -e`, and the build line already self-defuses failure via `|| echo …`, so a failed build
does not abort the container — `exec "$@"` still runs.

---

## 2. `compose.yaml` (platform root)

Edit **only** the `app:` service's `environment:` block.

**Find (BEFORE):**

```yaml
      service name; tablet/browser clients still use REVERB_PUBLIC_HOST.
      REVERB_BROADCAST_HOST: reverb
    volumes:
      - ./woosoo-nexus:/var/www/html  # dev/staging: bind-mount; remove for immutable production image
```

**Replace with (AFTER):**

```yaml
      service name; tablet/browser clients still use REVERB_PUBLIC_HOST.
      REVERB_BROADCAST_HOST: reverb
      # Force a Vite rebuild on container start even when public/build is already
      # populated. Default false = restart-safe (the entrypoint skips the build
      # when assets exist). The deploy script builds assets out-of-band, so this
      # is only a manual escape hatch: WOOSOO_FORCE_VITE_BUILD=true docker compose up -d app
      WOOSOO_FORCE_VITE_BUILD: ${WOOSOO_FORCE_VITE_BUILD:-false}
    volumes:
      - ./woosoo-nexus:/var/www/html  # dev/staging: bind-mount; remove for immutable production image
```

> The `reverb:` service also has a `REVERB_BROADCAST_HOST: reverb` line. Make sure you edit the
> one inside the **`app`** service (its `volumes:` lists `node_modules` and `local.ini`), not
> the reverb one.

---

## 3. `scripts/deployment/deploy.sh` (platform root)

Two insertions, both in/around Steps 3–4.

### 3a. One-off asset pre-build (mechanism a)

**Find (BEFORE):**

```sh
# ── Step 3: Build Docker images ───────────────────────────────────────────────
echo ">>> [3/5] Building Docker images ..."
$COMPOSE_CMD build
echo "OK: Images built"
echo
```

**Replace with (AFTER):**

```sh
# ── Step 3: Build Docker images + frontend assets ─────────────────────────────
echo ">>> [3/5] Building Docker images ..."
$COMPOSE_CMD build
echo "OK: Images built"

# Build Vite assets exactly once, here, because this deploy just pulled new code.
# A one-off `run --rm app npm run build` writes the compiled bundle into the
# bind-mounted woosoo-nexus/public/build on the host. The subsequent `up -d`
# then starts `app` with WOOSOO_FORCE_VITE_BUILD=false (default), so the
# entrypoint sees populated assets and SKIPS the build — and every later plain
# container restart stays fast and build-free. (Forcing via `up` instead would
# bake the flag into the container and make restarts rebuild too.)
echo "  Building frontend assets (one-off) ..."
WOOSOO_FORCE_VITE_BUILD=true $COMPOSE_CMD run --rm app npm run build
echo "OK: Frontend assets built"
echo
```

### 3b. Idempotent orphan-volume cleanup

**Find (BEFORE):**

```sh
# ── Step 4: Start / restart services ─────────────────────────────────────────
echo ">>> [4/5] Starting services ..."
$COMPOSE_CMD up -d --remove-orphans
```

**Replace with (AFTER):**

```sh
# ── Step 4: Start / restart services ─────────────────────────────────────────
echo ">>> [4/5] Starting services ..."
# One-time cleanup: the nexus_build named volume was removed from compose.yaml;
# drop the now-orphaned Docker volume. Idempotent — ignore error if absent/in-use.
docker volume rm woosoo-nexus_nexus_build 2>/dev/null || true
$COMPOSE_CMD up -d --remove-orphans
```

> `run --rm app npm run build` runs the build in the **app image's own container** (linux,
> correct per-host arch — amd64 on Docker Desktop, arm64 on the Pi). This is the whole reason
> the build stays in-container and not on the host. Do not "optimize" it to a host `npm`.

---

## 4. Verification (raw output required — paste into the case file)

Per `docs/AGENT_DEFAULT_INSTRUCTIONS.md` + `.claude/skills/test-verification`: no-error ≠
working. Capture **raw** command output. Run on Docker Desktop first, then mirror on the Pi.

```bash
# Compose still parses with the new env var
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml config --quiet && echo "CONFIG OK"
```

1. **Fresh build ships.** With `public/build` empty (or first run), `up -d` →
   logs `Building Vite assets...` → admin panel at `https://<host>` loads styled + WS connects.
   ```bash
   docker compose --env-file ./woosoo-nexus/.env -f compose.yaml logs app | grep -i vite
   ```
2. **Restart skips build (THE FIX).**
   ```bash
   docker compose --env-file ./woosoo-nexus/.env -f compose.yaml restart app
   docker compose --env-file ./woosoo-nexus/.env -f compose.yaml logs --tail=20 app
   # expect: "public/build present — skipping Vite build"; app healthy in seconds
   ```
3. **Crash recovery is fast & build-free.**
   ```bash
   docker compose --env-file ./woosoo-nexus/.env -f compose.yaml kill app
   docker compose --env-file ./woosoo-nexus/.env -f compose.yaml up -d app
   # expect: skip line again, no rebuild
   ```
4. **Deploy rebuilds.** Run `scripts/deployment/deploy.sh` (Pi) → logs show the one-off
   `run --rm app npm run build` → bump a visible asset and confirm the served hash changes.
5. **Orphan volume gone.**
   ```bash
   docker volume ls | grep nexus_build   # expect: no output
   # re-run deploy → the `volume rm` line must NOT error
   ```
6. **Manual force escape hatch works.**
   ```bash
   WOOSOO_FORCE_VITE_BUILD=true docker compose --env-file ./woosoo-nexus/.env -f compose.yaml up -d app
   # expect: "Building Vite assets..." even though public/build is populated
   ```
7. **Pi parity.** Repeat 1–4 on the Pi; confirm the build runs arm64 in-container and the host
   has no Node: `which node` on the Pi host → not found is expected and fine.
8. **Pre-merge gate.**
   ```bash
   bash scripts/pre-merge-check.sh --app woosoo-nexus
   ```
   (If a wrapped command cannot run in your environment, say so explicitly — do not claim a
   pass you did not observe.)

---

## 5. Checkpoint & sequence discipline

- After implementing, **before handing off**, write your raw verification output into
  `docs/cases/infra-vite-build-conditional.md` → `## Verification`, and rewrite `## Run State`
  (`last_completed_agent: specialist:infra`, `next_agent: verifier`). Update `state/WORK.md` to
  match. No checkpoint = the phase did not happen.
- Then the **Verifier** re-runs the gate (raw output, PASS/FAIL).
- Then the **Executioner** returns exactly `APPROVED | REJECTED | SPLIT_REQUIRED`.
- On `REJECTED`: `git restore .` in the affected repo, then fix-forward only after the Verifier
  re-runs clean.
- The task is complete **only** when the Executioner returns `APPROVED`. End with the Agent
  Chain block from `.claude/skills/agent-sequence/SKILL.md`.

---

## 6. Rollback

```bash
# woosoo-nexus
git -C woosoo-nexus checkout -- docker/docker-entrypoint.sh
# platform
git checkout -- compose.yaml scripts/deployment/deploy.sh
```

Restores the prior rebuild-every-start behavior. The orphan-volume `rm` is inert (the volume is
already unreferenced) — no rollback action needed for it.

---

## 7. Out of scope (do NOT do here)

- Removing the `./woosoo-nexus:/var/www/html` bind-mount / immutable-image migration. That is
  the strategic root cause, tracked separately as
  `docs/cases/nex-case-010-immutable-image-production-migration.md` (Tier 3, BLOCKED, not
  started). Do not bundle it.
- Creating `scripts/deploy.sh` or `scripts/deploy.ps1`, or any host-side Node bootstrap. The
  existing `scripts/deployment/deploy.sh` is the one and only deploy entrypoint.
