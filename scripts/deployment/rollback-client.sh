#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Woosoo Client Rollback Script
# Restores previous Git commits and .env snapshot, then rebuilds.
# ============================================================

NEXUS_DIR="/opt/woosoo/woosoo-nexus"
PWA_DIR="/opt/woosoo/tablet-ordering-pwa"
CLIENT_HOST="192.168.1.31"

if [ -z "${1:-}" ]; then
  echo "Usage:"
  echo "  ./rollback-client.sh /opt/woosoo/backups/update-YYYYMMDD-HHMMSS"
  exit 1
fi

BACKUP_DIR="$1"

if [ ! -d "$BACKUP_DIR" ]; then
  echo "ERROR: Backup directory not found: $BACKUP_DIR"
  exit 1
fi

if [ ! -f "$BACKUP_DIR/woosoo-nexus.commit" ]; then
  echo "ERROR: Missing woosoo-nexus.commit in backup"
  exit 1
fi

if [ ! -f "$BACKUP_DIR/tablet-ordering-pwa.commit" ]; then
  echo "ERROR: Missing tablet-ordering-pwa.commit in backup"
  exit 1
fi

echo "============================================================"
echo " Woosoo Client Rollback"
echo " Backup: $BACKUP_DIR"
echo " Started: $(date)"
echo "============================================================"

echo ""
echo "=== Rolling back woosoo-nexus ==="

cd "$NEXUS_DIR"
git reset --hard "$(cat "$BACKUP_DIR/woosoo-nexus.commit")"

if [ -f "$BACKUP_DIR/woosoo-nexus.env" ]; then
  cp "$BACKUP_DIR/woosoo-nexus.env" "$NEXUS_DIR/.env"
fi

echo "Nexus restored to:"
git log --oneline -1

echo ""
echo "=== Rolling back tablet-ordering-pwa ==="

cd "$PWA_DIR"
git reset --hard "$(cat "$BACKUP_DIR/tablet-ordering-pwa.commit")"

echo "Tablet PWA restored to:"
git log --oneline -1

echo ""
echo "=== Rebuilding Docker services after rollback ==="

cd "$NEXUS_DIR"
docker compose build app tablet-pwa
docker compose up -d app queue scheduler reverb nginx tablet-pwa

echo ""
echo "=== Laravel cache refresh ==="

docker compose exec -T app php artisan optimize:clear
docker compose exec -T app php artisan config:cache
docker compose exec -T app php artisan route:cache
docker compose exec -T app php artisan view:cache

echo ""
echo "=== Verifying rollback ==="

docker compose ps
docker compose exec -T app php artisan route:list | grep -E "pos|dashboard|login|api/health" || true

curl -k -I "https://$CLIENT_HOST" || true
curl -k -I "https://$CLIENT_HOST/pos" || true
curl -k "https://$CLIENT_HOST/api/health" || true

echo ""
echo "============================================================"
echo " Rollback complete"
echo " Finished: $(date)"
echo "============================================================"
