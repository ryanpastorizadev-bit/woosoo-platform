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
#   4. Starts all services
#   5. Warms Laravel caches
#   6. Shows service status
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
NEXUS_BRANCH="${WOOSOO_NEXUS_BRANCH:-${WOOSOO_DEPLOY_BRANCH:-staging}}"
TABLET_BRANCH="${WOOSOO_TABLET_BRANCH:-${WOOSOO_DEPLOY_BRANCH:-staging}}"
CONFIG_SCRIPT="$SCRIPT_DIR/apply-woosoo-config.sh"
COMPOSE_CMD="${WOOSOO_DOCKER_COMPOSE:-docker compose --env-file ./woosoo-nexus/.env -f compose.yaml}"
APP_SERVICE="${WOOSOO_APP_SERVICE:-app}"

# ── Guards ────────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: Run as root: sudo bash scripts/deployment/deploy.sh"
  exit 1
fi

if [[ ! -f /etc/woosoo/woosoo.env ]]; then
  echo "ERROR: /etc/woosoo/woosoo.env not found."
  echo "  See docs/deployment/production-docker.md."
  exit 1
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
        # WOOSOO_FORCE_RESET=true: save a backup patch before resetting
        echo "WARNING: $name has uncommitted changes, but WOOSOO_FORCE_RESET=true." >&2
        BACKUP_DIR="${WOOSOO_BACKUP_DIR:-/opt/woosoo/backups}/git-diffs"
        mkdir -p "$BACKUP_DIR"
        BACKUP_FILE="$BACKUP_DIR/${name}-$(date +%F_%H%M%S).patch"
        git -C "$dir" diff > "$BACKUP_FILE"
        git -C "$dir" diff --cached >> "$BACKUP_FILE"
        echo "Backup saved: $BACKUP_FILE" >&2
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

echo ">>> [1/5] Pulling app repos ..."
pull_repo "$NEXUS_DIR"  "$NEXUS_BRANCH"  "woosoo-nexus"
pull_repo "$TABLET_DIR" "$TABLET_BRANCH" "tablet-ordering-pwa"
echo

# ── Step 2: Apply config (writes correct values into woosoo-nexus/.env) ───────
echo ">>> [2/5] Applying Pi5 config (apply-woosoo-config.sh) ..."
WOOSOO_RESTART_DOCKER=false bash "$CONFIG_SCRIPT"
echo "OK: Config applied — woosoo-nexus/.env is authoritative for this host"
echo

# ── Step 3: Build Docker images ───────────────────────────────────────────────
echo ">>> [3/5] Building Docker images ..."
$COMPOSE_CMD build
echo "OK: Images built"
echo

# ── Step 4: Start / restart services ─────────────────────────────────────────
echo ">>> [4/5] Starting services ..."
$COMPOSE_CMD up -d --remove-orphans
echo "OK: Services started"
echo

# ── Step 5: Warm Laravel caches ──────────────────────────────────────────────
echo ">>> [5/5] Warming Laravel caches ..."
echo "  Waiting for app service..."
WAIT_ATTEMPTS=90
WAIT_DELAY=2
for i in $(seq 1 "$WAIT_ATTEMPTS"); do
  if $COMPOSE_CMD exec -T "$APP_SERVICE" php artisan --version >/dev/null 2>&1; then
    echo "  OK: app service ready"
    break
  fi
  if [[ "$i" -eq "$WAIT_ATTEMPTS" ]]; then
    echo "  WARNING: app service not ready after ${WAIT_ATTEMPTS}x${WAIT_DELAY}s — skipping cache warm."
    echo "  Run manually: $COMPOSE_CMD exec $APP_SERVICE php artisan config:cache"
    echo
    break
  fi
  sleep "$WAIT_DELAY"
done

if $COMPOSE_CMD exec -T "$APP_SERVICE" php artisan --version >/dev/null 2>&1; then
  $COMPOSE_CMD exec -T "$APP_SERVICE" php artisan config:clear  || true
  $COMPOSE_CMD exec -T "$APP_SERVICE" php artisan cache:clear   || true
  $COMPOSE_CMD exec -T "$APP_SERVICE" php artisan route:clear   || true
  $COMPOSE_CMD exec -T "$APP_SERVICE" php artisan view:clear    || true
  $COMPOSE_CMD exec -T "$APP_SERVICE" php artisan config:cache  || true
  $COMPOSE_CMD exec -T "$APP_SERVICE" php artisan route:cache   || true
  $COMPOSE_CMD exec -T "$APP_SERVICE" php artisan view:cache    || true
  echo "OK: Caches warmed"
fi
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
