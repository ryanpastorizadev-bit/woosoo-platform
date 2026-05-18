#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Woosoo Client Verification Script
# Checks Git state, Docker state, Laravel routes, and URLs.
# ============================================================

NEXUS_DIR="/opt/woosoo/woosoo-nexus"
PWA_DIR="/opt/woosoo/tablet-ordering-pwa"
CLIENT_HOST="192.168.1.31"

echo "============================================================"
echo " Woosoo Client Verification"
echo " Started: $(date)"
echo "============================================================"

echo ""
echo "=== Network identity ==="

hostname -I
ip route

echo ""
echo "=== Nexus Git state ==="

cd "$NEXUS_DIR"
git branch --show-current
git status --short
git log --oneline -3

echo ""
echo "=== Tablet PWA Git state ==="

cd "$PWA_DIR"
git branch --show-current
git status --short
git log --oneline -3

echo ""
echo "=== Environment identity ==="

cd "$NEXUS_DIR"
grep -E "APP_URL|PUBLIC_HOST|PUBLIC_SCHEME|PUBLIC_HTTPS_PORT|PUBLIC_HTTP_PORT|CORS_ALLOWED_ORIGINS|SANCTUM_STATEFUL_DOMAINS|SESSION_DOMAIN" .env || true

echo ""
echo "=== Docker containers ==="

docker compose ps

echo ""
echo "=== Laravel routes ==="

docker compose exec -T app php artisan route:list | grep -E "pos|dashboard|login|api/health" || true

echo ""
echo "=== Laravel migration status tail ==="

docker compose exec -T app php artisan migrate:status | tail -30 || true

echo ""
echo "=== URL checks ==="

curl -k -I "https://$CLIENT_HOST" || true
curl -k -I "https://$CLIENT_HOST/login" || true
curl -k -I "https://$CLIENT_HOST/pos" || true
curl -k "https://$CLIENT_HOST/api/health" || true

echo ""
echo "=== Certificate check ==="

echo | openssl s_client -connect "$CLIENT_HOST:443" -servername "$CLIENT_HOST" -showcerts 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates -ext subjectAltName || true

echo ""
echo "============================================================"
echo " Verification complete"
echo " Finished: $(date)"
echo "============================================================"
