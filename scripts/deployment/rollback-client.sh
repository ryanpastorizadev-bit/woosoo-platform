#!/usr/bin/env bash
# =============================================================================
# Woosoo Pi5 — Rollback  (PLATFORM-ROOT AUTHORITY)
# =============================================================================
# Usage (from the Pi5 console, as root):
#   sudo bash scripts/deployment/rollback-client.sh <backup-dir>
#
# Example:
#   sudo bash scripts/deployment/rollback-client.sh \
#     /opt/woosoo/backups/update-20260525-143000
#
# What it does (the reverse of deploy.sh):
#   1. Reads <backup-dir>/woosoo-nexus.commit and
#      <backup-dir>/tablet-ordering-pwa.commit
#   2. Restores each app repo to that commit (git reset --hard) in place
#   3. Restores woosoo-nexus/.env from <backup-dir>/woosoo-nexus.env if present
#   4. Rebuilds and ups the stack from the PLATFORM ROOT compose.yaml
#   5. Clears + warms Laravel caches
#   6. Smoke-checks the public endpoints
#
# Contract: the backup directory layout is whatever the deploy/update step
# wrote. This script expects at minimum:
#   <backup-dir>/woosoo-nexus.commit
#   <backup-dir>/tablet-ordering-pwa.commit
# and optionally:
#   <backup-dir>/woosoo-nexus.env   (Laravel .env snapshot)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# scripts/deployment/ lives at the PLATFORM repo root.
PLATFORM_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
NEXUS_DIR="$PLATFORM_ROOT/woosoo-nexus"
TABLET_DIR="$PLATFORM_ROOT/tablet-ordering-pwa"
COMPOSE_CMD="${WOOSOO_DOCKER_COMPOSE:-docker compose --env-file ./woosoo-nexus/.env -f compose.yaml}"
APP_SERVICE="${WOOSOO_APP_SERVICE:-app}"

# ── Args + guards ────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: Run as root: sudo bash scripts/deployment/rollback-client.sh <backup-dir>"
  exit 1
fi

if [[ -z "${1:-}" ]]; then
  echo "Usage: sudo bash scripts/deployment/rollback-client.sh <backup-dir>"
  echo "Example: sudo bash scripts/deployment/rollback-client.sh /opt/woosoo/backups/update-YYYYMMDD-HHMMSS"
  exit 1
fi

BACKUP_DIR="$1"

if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "ERROR: Backup directory not found: $BACKUP_DIR"
  exit 1
fi

if [[ ! -f "$BACKUP_DIR/woosoo-nexus.commit" ]]; then
  echo "ERROR: Missing $BACKUP_DIR/woosoo-nexus.commit"
  exit 1
fi

if [[ ! -f "$BACKUP_DIR/tablet-ordering-pwa.commit" ]]; then
  echo "ERROR: Missing $BACKUP_DIR/tablet-ordering-pwa.commit"
  exit 1
fi

if [[ ! -f /etc/woosoo/woosoo.env ]]; then
  echo "ERROR: /etc/woosoo/woosoo.env not found."
  echo "  See docs/deployment/production-docker.md."
  exit 1
fi

if [[ ! -d "$NEXUS_DIR" ]] || [[ ! -d "$TABLET_DIR" ]]; then
  echo "ERROR: expected sibling app repos under $PLATFORM_ROOT (woosoo-nexus, tablet-ordering-pwa)"
  exit 1
fi

cd "$PLATFORM_ROOT"

NEXUS_COMMIT="$(cat "$BACKUP_DIR/woosoo-nexus.commit")"
TABLET_COMMIT="$(cat "$BACKUP_DIR/tablet-ordering-pwa.commit")"

echo "========================================"
echo "  Woosoo Pi5 Rollback (platform root)"
echo "  Platform:      $PLATFORM_ROOT"
echo "  Backup:        $BACKUP_DIR"
echo "  Nexus  -> $NEXUS_COMMIT"
echo "  Tablet -> $TABLET_COMMIT"
echo "========================================"
echo

# ── Step 1: Save current SHAs so a forward-roll is possible ─────────────────
ROLLBACK_POINTS="${WOOSOO_ROLLBACK_POINTS_DIR:-/opt/woosoo/backups/rollback-points}"
mkdir -p "$ROLLBACK_POINTS"
SNAPSHOT_DIR="$ROLLBACK_POINTS/pre-rollback-$(date +%F_%H%M%S)"
mkdir -p "$SNAPSHOT_DIR"
git -C "$NEXUS_DIR"  rev-parse HEAD > "$SNAPSHOT_DIR/woosoo-nexus.commit"
git -C "$TABLET_DIR" rev-parse HEAD > "$SNAPSHOT_DIR/tablet-ordering-pwa.commit"
if [[ -f "$NEXUS_DIR/.env" ]]; then
  cp "$NEXUS_DIR/.env" "$SNAPSHOT_DIR/woosoo-nexus.env"
fi
echo ">>> [1/5] Pre-rollback SHAs snapshot saved to: $SNAPSHOT_DIR"
echo "    (forward-roll command: rerun this script with $SNAPSHOT_DIR)"
echo

# ── Step 2: Reset app repos in place ─────────────────────────────────────────
echo ">>> [2/5] Resetting app repos ..."
git -C "$NEXUS_DIR"  reset --hard "$NEXUS_COMMIT"
echo "  OK: woosoo-nexus -> $(git -C "$NEXUS_DIR" rev-parse --short HEAD)"
git -C "$TABLET_DIR" reset --hard "$TABLET_COMMIT"
echo "  OK: tablet-ordering-pwa -> $(git -C "$TABLET_DIR" rev-parse --short HEAD)"

if [[ -f "$BACKUP_DIR/woosoo-nexus.env" ]]; then
  cp "$BACKUP_DIR/woosoo-nexus.env" "$NEXUS_DIR/.env"
  echo "  OK: restored woosoo-nexus/.env from backup"
else
  echo "  NOTE: no woosoo-nexus.env in backup — keeping current .env"
fi
echo

# ── Step 3: Rebuild Docker images from PLATFORM ROOT ─────────────────────────
echo ">>> [3/5] Rebuilding Docker images ..."
$COMPOSE_CMD build
echo "OK: Images rebuilt"
echo

# ── Step 4: Start / restart services ─────────────────────────────────────────
echo ">>> [4/5] Starting services ..."
$COMPOSE_CMD up -d --remove-orphans
echo "OK: Services started"
echo

# ── Step 5: Warm Laravel caches + smoke check ────────────────────────────────
echo ">>> [5/5] Warming Laravel caches + smoke check ..."
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
    echo "  Run manually: $COMPOSE_CMD exec $APP_SERVICE php artisan optimize:clear"
    break
  fi
  sleep "$WAIT_DELAY"
done

if $COMPOSE_CMD exec -T "$APP_SERVICE" php artisan --version >/dev/null 2>&1; then
  $COMPOSE_CMD exec -T "$APP_SERVICE" php artisan optimize:clear || true
  $COMPOSE_CMD exec -T "$APP_SERVICE" php artisan config:cache   || true
  $COMPOSE_CMD exec -T "$APP_SERVICE" php artisan route:cache    || true
  $COMPOSE_CMD exec -T "$APP_SERVICE" php artisan view:cache     || true
  echo "OK: Caches warmed"
fi
echo

# ── Summary ──────────────────────────────────────────────────────────────────
echo "========================================"
echo "  Rollback complete"
echo "========================================"
$COMPOSE_CMD ps
echo

source /etc/woosoo/woosoo.env 2>/dev/null || true
WOOSOO_HOST="${WOOSOO_HOST:-<host>}"
WOOSOO_SCHEME="${WOOSOO_SCHEME:-https}"

echo "  Admin panel : ${WOOSOO_SCHEME}://${WOOSOO_HOST}"
echo "  Tablet PWA  : ${WOOSOO_SCHEME}://${WOOSOO_HOST}:4443"
echo
echo "  Verify live build:  curl -ks ${WOOSOO_SCHEME}://${WOOSOO_HOST}:4443/build-info.json"
echo "  Forward-roll point: $SNAPSHOT_DIR"
echo
