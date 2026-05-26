#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Woosoo Client Deployment Script
# Pulls latest staging changes, rebuilds Docker services,
# runs migrations, refreshes Laravel caches, and verifies health.
# ============================================================

NEXUS_DIR="/opt/woosoo/woosoo-nexus"
PWA_DIR="/opt/woosoo/tablet-ordering-pwa"
BRANCH="staging"
CLIENT_HOST="192.168.1.31"
BACKUP_ROOT="/opt/woosoo/backups"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/update-$TIMESTAMP"
LOG_FILE="$NEXUS_DIR/update-$TIMESTAMP.log"

mkdir -p "$BACKUP_DIR"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "============================================================"
echo " Woosoo Client Update"
echo " Started: $(date)"
echo " Backup: $BACKUP_DIR"
echo " Log:    $LOG_FILE"
echo "============================================================"

echo ""
echo "=== Preflight: checking directories ==="

if [ ! -d "$NEXUS_DIR/.git" ]; then
  echo "ERROR: Nexus repo not found at $NEXUS_DIR"
  exit 1
fi

if [ ! -d "$PWA_DIR/.git" ]; then
  echo "ERROR: Tablet PWA repo not found at $PWA_DIR"
  exit 1
fi

echo ""
echo "=== Saving current deployment snapshot ==="

cd "$NEXUS_DIR"
git rev-parse HEAD > "$BACKUP_DIR/woosoo-nexus.commit"
cp .env "$BACKUP_DIR/woosoo-nexus.env" || true

cd "$PWA_DIR"
git rev-parse HEAD > "$BACKUP_DIR/tablet-ordering-pwa.commit"

echo "Saved Nexus commit: $(cat "$BACKUP_DIR/woosoo-nexus.commit")"
echo "Saved PWA commit:   $(cat "$BACKUP_DIR/tablet-ordering-pwa.commit")"

echo ""
echo "=== Updating woosoo-nexus ==="

cd "$NEXUS_DIR"
git fetch origin
git checkout "$BRANCH"
git pull --ff-only origin "$BRANCH"

CURRENT_BRANCH="$(git branch --show-current)"
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
  echo "ERROR: Nexus wrong branch: $CURRENT_BRANCH. Expected: $BRANCH"
  exit 1
fi

echo "Nexus now at:"
git log --oneline -1

echo ""
echo "=== Updating tablet-ordering-pwa ==="

cd "$PWA_DIR"
git fetch origin
git checkout "$BRANCH"
git pull --ff-only origin "$BRANCH"

CURRENT_BRANCH="$(git branch --show-current)"
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
  echo "ERROR: PWA wrong branch: $CURRENT_BRANCH. Expected: $BRANCH"
  exit 1
fi

echo "Tablet PWA now at:"
git log --oneline -1

echo ""
echo "=== Checking configured client identity ==="

cd "$NEXUS_DIR"
grep -E "APP_URL|PUBLIC_HOST|PUBLIC_SCHEME|PUBLIC_HTTPS_PORT|PUBLIC_HTTP_PORT|CORS_ALLOWED_ORIGINS|SANCTUM_STATEFUL_DOMAINS|SESSION_DOMAIN" .env || true

echo ""
echo "=== Building Docker images ==="

docker compose build app tablet-pwa

echo ""
echo "=== Starting Docker services ==="

docker compose up -d app queue scheduler reverb nginx tablet-pwa

echo ""
echo "=== Laravel maintenance ==="

docker compose exec -T app php artisan optimize:clear
docker compose exec -T app php artisan migrate --force
docker compose exec -T app php artisan config:cache
docker compose exec -T app php artisan route:cache
docker compose exec -T app php artisan view:cache

echo ""
echo "=== Route verification ==="

docker compose exec -T app php artisan route:list | grep -E "pos|dashboard|login|api/health" || true

echo ""
echo "=== Container status ==="

docker compose ps

echo ""
echo "=== Health checks ==="

curl -k -I "https://$CLIENT_HOST" || true
curl -k -I "https://$CLIENT_HOST/pos" || true
curl -k "https://$CLIENT_HOST/api/health" || true

echo ""
echo "============================================================"
echo " Update complete"
echo " Finished: $(date)"
echo " Backup:   $BACKUP_DIR"
echo " Log:      $LOG_FILE"
echo "============================================================"
