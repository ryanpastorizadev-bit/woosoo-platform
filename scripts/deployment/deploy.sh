#!/usr/bin/env bash
# =============================================================================
# Woosoo Pi5 — One-Command Deploy  (PLATFORM-ROOT AUTHORITY)
# =============================================================================
# Usage (from the Pi5 console, as root):
#   sudo bash scripts/deployment/deploy.sh
#
# Topology: 3 independent git repos in a sibling layout.
#   woosoo-platform/      <- this repo (governance + orchestration). Operator
#   │                        updates it out of band BEFORE running this script.
#   ├── woosoo-nexus/     <- Laravel app repo, pulled in place below
#   └── tablet-ordering-pwa/  <- Nuxt PWA repo, pulled in place below
#
# What it does:
#   1. Pulls each APP repo (woosoo-nexus, tablet-ordering-pwa) in place
#   2. Runs apply-woosoo-config.sh to enforce runtime config into woosoo-nexus/.env
#   3. Rebuilds Docker images from the platform-root compose.yaml
#   4. Runs database migrations (before services start)
#   5. Starts all services
#   6. Warms Laravel caches
#
# First-time setup? See docs/deployment/production-docker.md — you need
# /etc/woosoo/woosoo.env in place before running this.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# scripts/deployment/ lives at the PLATFORM repo root.
PLATFORM_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
NEXUS_DIR="$PLATFORM_ROOT/woosoo-nexus"
TABLET_DIR="$PLATFORM_ROOT/tablet-ordering-pwa"
NEXUS_BRANCH="${WOOSOO_NEXUS_BRANCH:-${WOOSOO_DEPLOY_BRANCH:-dev}}"
TABLET_BRANCH="${WOOSOO_TABLET_BRANCH:-${WOOSOO_DEPLOY_BRANCH:-dev}}"
CONFIG_SCRIPT="$SCRIPT_DIR/apply-woosoo-config.sh"
COMPOSE_CMD="${WOOSOO_DOCKER_COMPOSE:-docker compose --env-file ./woosoo-nexus/.env -f compose.yaml}"
APP_SERVICE="${WOOSOO_APP_SERVICE:-app}"

# ── Guards ────────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: Run as root: sudo bash scripts/deployment/deploy.sh"
  exit 1
fi

if [[ -z "${CONFIG_FILE:-}" ]]; then
  if [[ -f "$PLATFORM_ROOT/woosoo.env" ]]; then
    export CONFIG_FILE="$PLATFORM_ROOT/woosoo.env"
  elif [[ -f /etc/woosoo/woosoo.env ]]; then
    export CONFIG_FILE="/etc/woosoo/woosoo.env"
  else
    echo "ERROR: no config file found."
    echo "  Run: bash scripts/deployment/init-woosoo-env.sh"
    exit 1
  fi
fi

if [[ ! -f "$CONFIG_SCRIPT" ]]; then
  echo "ERROR: apply-woosoo-config.sh not found at $CONFIG_SCRIPT"
  exit 1
fi

cd "$PLATFORM_ROOT"

echo "========================================"
echo "  Woosoo Pi5 Deploy (platform root)"
echo "  Platform:      $PLATFORM_ROOT"
echo "  Nexus branch:  $NEXUS_BRANCH"
echo "  Tablet branch: $TABLET_BRANCH"
echo "========================================"
echo

# ── Step 1: Pull each app repo in place ───────────────────────────────────────
# NOTE: the platform repo (this dir) is intentionally NOT reset here — it is the
# repo the running script lives in. Update it out of band before deploying.
pull_repo() {
  local dir="$1" branch="$2" name="$3"
  if [[ ! -d "$dir" ]]; then
    echo "ERROR: $name repo missing: $dir"
    exit 1
  fi
  if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # Safety guard: refuse to reset if the working tree has uncommitted changes
    if [[ -n "$(git -C "$dir" status --porcelain)" ]]; then
      if [[ "${WOOSOO_FORCE_RESET:-false}" != "true" ]]; then
        echo "ERROR: $name has uncommitted changes. Refusing to deploy." >&2
        echo "Working tree status for $name:" >&2
        git -C "$dir" status --short >&2
        echo >&2
        echo "To proceed, either:" >&2
        echo "  1. Commit or stash your changes in $dir" >&2
        echo "  2. Set WOOSOO_FORCE_RESET=true to force reset (changes will be lost)" >&2
        exit 1
      else
        # WOOSOO_FORCE_RESET=true: save a backup patch before resetting.
        # Note: local variable names use DIFF_ prefix so they don't collide
        # with the script-level BACKUP_DIR snapshot path created below.
        echo "WARNING: $name has uncommitted changes, but WOOSOO_FORCE_RESET=true." >&2
        local DIFF_BACKUP_DIR DIFF_BACKUP_FILE
        DIFF_BACKUP_DIR="${WOOSOO_BACKUP_DIR:-/opt/woosoo/backups}/git-diffs"
        mkdir -p "$DIFF_BACKUP_DIR"
        DIFF_BACKUP_FILE="$DIFF_BACKUP_DIR/${name}-$(date +%F_%H%M%S).patch"
        git -C "$dir" diff > "$DIFF_BACKUP_FILE"
        git -C "$dir" diff --cached >> "$DIFF_BACKUP_FILE"
        echo "Backup saved: $DIFF_BACKUP_FILE" >&2
        echo "Proceeding with reset --hard..." >&2
      fi
    fi
    git -C "$dir" fetch origin
    git -C "$dir" checkout "$branch"
    git -C "$dir" reset --hard "origin/$branch"
    echo "OK: $name -> $(git -C "$dir" rev-parse --short HEAD)"
  else
    echo "WARNING: $name is not a git repo. Deploying from current files."
  fi
}

echo ">>> [1/6] Snapshot + pull app repos ..."

# Pre-deploy snapshot — written BEFORE git reset --hard so rollback-client.sh
# can restore the pre-deploy state by SHA + .env. This is the rollback handle.
WOOSOO_BACKUP_DIR="${WOOSOO_BACKUP_DIR:-/opt/woosoo/backups}"
BACKUP_DIR="$WOOSOO_BACKUP_DIR/update-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

snapshot_repo() {
  local dir="$1" name="$2"
  if [[ -d "$dir/.git" ]] && git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$dir" rev-parse HEAD > "$BACKUP_DIR/${name}.commit"
    echo "  snapshot $name -> $(git -C "$dir" rev-parse --short HEAD)"
  else
    echo "  snapshot $name -> SKIPPED (not a git repo)"
  fi
}

snapshot_repo "$NEXUS_DIR"  "woosoo-nexus"
snapshot_repo "$TABLET_DIR" "tablet-ordering-pwa"
if [[ -f "$NEXUS_DIR/.env" ]]; then
  cp "$NEXUS_DIR/.env" "$BACKUP_DIR/woosoo-nexus.env"
  echo "  snapshot woosoo-nexus/.env -> saved"
fi
echo "  rollback handle: $BACKUP_DIR"
echo

pull_repo "$NEXUS_DIR"  "$NEXUS_BRANCH"  "woosoo-nexus"
pull_repo "$TABLET_DIR" "$TABLET_BRANCH" "tablet-ordering-pwa"
echo

# ── Step 2: Apply config (writes correct values into woosoo-nexus/.env) ───────
echo ">>> [2/6] Applying Pi5 config (apply-woosoo-config.sh) ..."
WOOSOO_RESTART_DOCKER=false bash "$CONFIG_SCRIPT"
echo "OK: Config applied — woosoo-nexus/.env is authoritative for this host"
echo

# ── Step 3: Build Docker images + frontend assets ─────────────────────────────
echo ">>> [3/6] Building Docker images ..."
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

# ── Step 4: Run pending database migrations ───────────────────────────────────
# Migrations run in a one-off container before live services start so that
# queue workers and scheduler boot on the updated schema, not the old one.
# `docker compose run` respects depends_on service_healthy conditions, so
# mysql and redis are guaranteed healthy before the migration executes.
echo ">>> [4/6] Running database migrations ..."
if $COMPOSE_CMD run --rm "$APP_SERVICE" php artisan migrate --force; then
  echo "OK: Migrations applied"
else
  echo "ERROR: artisan migrate failed — aborting before services start." >&2
  exit 1
fi
echo

# ── Step 5: Start / restart services ─────────────────────────────────────────
echo ">>> [5/6] Starting services ..."
# One-time cleanup: the nexus_build named volume was removed from compose.yaml;
# drop the now-orphaned Docker volume. Idempotent — ignore error if absent/in-use.
docker volume rm woosoo-nexus_nexus_build 2>/dev/null || true
$COMPOSE_CMD up -d --remove-orphans
echo "OK: Services started"
echo

# ── Step 6: Warm Laravel caches ──────────────────────────────────────────────
echo ">>> [6/6] Warming Laravel caches ..."
echo "  Waiting for $APP_SERVICE to be ready (up to 60s) ..."
_app_ready=0
for _i in $(seq 1 30); do
  if $COMPOSE_CMD exec -T "$APP_SERVICE" php artisan --version >/dev/null 2>&1; then
    _app_ready=1
    break
  fi
  sleep 2
done
if [[ "$_app_ready" -ne 1 ]]; then
  echo "ERROR: $APP_SERVICE is not ready after 60s; aborting deploy." >&2
  $COMPOSE_CMD logs --tail=200 "$APP_SERVICE" || true
  exit 1
fi
$COMPOSE_CMD exec -T "$APP_SERVICE" php artisan config:clear  || true
$COMPOSE_CMD exec -T "$APP_SERVICE" php artisan cache:clear   || true
$COMPOSE_CMD exec -T "$APP_SERVICE" php artisan route:clear   || true
$COMPOSE_CMD exec -T "$APP_SERVICE" php artisan view:clear    || true
$COMPOSE_CMD exec -T "$APP_SERVICE" php artisan config:cache  || true
$COMPOSE_CMD exec -T "$APP_SERVICE" php artisan route:cache   || true
$COMPOSE_CMD exec -T "$APP_SERVICE" php artisan view:cache    || true
echo "OK: Caches warmed"
echo

# ── Summary ───────────────────────────────────────────────────────────────────
echo "========================================"
echo "  Deploy complete"
echo "========================================"
$COMPOSE_CMD ps
echo

source /etc/woosoo/woosoo.env 2>/dev/null || true
WOOSOO_HOST="${WOOSOO_HOST:-<host>}"
WOOSOO_SCHEME="${WOOSOO_SCHEME:-https}"

echo "  Admin panel : ${WOOSOO_SCHEME}://${WOOSOO_HOST}"
echo "  Tablet PWA  : ${WOOSOO_SCHEME}://${WOOSOO_HOST}:4443"
echo
echo "  Tablet DNS must point to: $(ip -4 addr | grep -Eo '192\.[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || echo '<server-ip>')"
echo
echo "  Rollback handle (if this deploy goes bad):"
echo "    sudo bash scripts/deployment/rollback-client.sh $BACKUP_DIR"
echo
