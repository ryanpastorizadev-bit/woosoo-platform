#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="/etc/woosoo/woosoo.env"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo bash scripts/deployment/woosoo-health.sh"
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Missing $CONFIG_FILE"
  exit 1
fi

set -a
# shellcheck source=/dev/null
source "$CONFIG_FILE"
set +a

WOOSOO_DOCKER_COMPOSE="${WOOSOO_DOCKER_COMPOSE:-docker compose -f compose.yaml}"
WOOSOO_NEXUS_PATH="${WOOSOO_NEXUS_PATH:-/opt/woosoo/woosoo-nexus}"
WOOSOO_SCHEME="${WOOSOO_SCHEME:-https}"
WOOSOO_REVERB_APP_KEY="${WOOSOO_REVERB_APP_KEY:-}"

echo "=== Woosoo Health Check ==="
echo

if [[ -z "${WOOSOO_SERVER_IP:-}" ]]; then
  echo "Missing required config: WOOSOO_SERVER_IP"
  exit 1
fi
if [[ -z "${WOOSOO_HOST:-}" ]]; then
  echo "Missing required config: WOOSOO_HOST"
  exit 1
fi

echo "[1] Expected IP address"
ip -4 addr | grep -F "${WOOSOO_SERVER_IP}" || echo "WARNING: Expected IP not found: ${WOOSOO_SERVER_IP}"

echo
echo "[2] DNS local resolution"
dig "$WOOSOO_HOST" @127.0.0.1 +short || true

echo
echo "[3] dnsmasq status"
systemctl is-active dnsmasq || true

echo
echo "[4] Host port listeners"
ss -lntup | grep -E ':(53|80|443|4443)\b' || true

echo
echo "[5] Admin HTTPS check"
curl -k -I --max-time 10 "${WOOSOO_SCHEME}://${WOOSOO_HOST}" || true

echo
echo "[6] Tablet PWA HTTPS check"
curl -k -I --max-time 10 "${WOOSOO_SCHEME}://${WOOSOO_HOST}:4443" || true

echo
echo "[7] Reverb proxy route check"
if [[ -n "$WOOSOO_REVERB_APP_KEY" ]]; then
  curl -k -I --max-time 10 "${WOOSOO_SCHEME}://${WOOSOO_HOST}/app/${WOOSOO_REVERB_APP_KEY}" || true
else
  echo "WOOSOO_REVERB_APP_KEY not set; skipping Reverb proxy route check"
fi

echo
echo "[8] Docker containers"
if [[ -d "$WOOSOO_NEXUS_PATH" ]]; then
  cd "$WOOSOO_NEXUS_PATH"
  $WOOSOO_DOCKER_COMPOSE ps || true
else
  echo "Nexus path missing: $WOOSOO_NEXUS_PATH"
fi

echo
echo "[9] Disk"
df -h

echo
echo "[10] Memory"
free -h

echo
echo "[11] Temperature"
if command -v vcgencmd >/dev/null 2>&1; then
  vcgencmd measure_temp || true
else
  echo "vcgencmd not installed"
fi

echo
echo "[12] Recent dnsmasq logs"
journalctl -u dnsmasq -n 30 --no-pager || true
