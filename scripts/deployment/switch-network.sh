#!/usr/bin/env bash
# switch-network.sh — flip the Pi between home and restaurant configs.
#
# Usage (from /opt/woosoo/woosoo-platform or anywhere):
#   sudo bash scripts/deployment/switch-network.sh home    # 192.168.100.42 / .100.7 POS
#   sudo bash scripts/deployment/switch-network.sh resto   # 192.168.1.31  / .1.32 POS
#
# What it changes in woosoo-nexus/.env:
#   - PUBLIC_HOST: the active LAN IP (used for APP_URL, broadcast origin checks).
#   - DB_POS_HOST / USER / PASSWORD / PORT / DATABASE: the POS MySQL connection.
#   - SANCTUM_STATEFUL_DOMAINS / CORS_ALLOWED_ORIGINS / REVERB_ALLOWED_ORIGINS:
#     always contain BOTH networks, so no edits are needed to cross networks.
#
# After updating .env, it clears Laravel's config cache and restarts the
# containers whose configuration depends on these values.
#
# The script also de-duplicates each key: if .env has multiple lines for the
# same key (a common drift after manual edits), every old line is removed and
# replaced with exactly one canonical line.

set -euo pipefail

LOC="${1:-}"
case "$LOC" in
  home)
    PUBLIC_HOST_VAL="192.168.100.42"
    DB_POS_HOST_VAL="192.168.100.7"
    DB_POS_PORT_VAL="3308"
    DB_POS_DATABASE_VAL="krypton_woosoo"
    DB_POS_USERNAME_VAL="woosoo_pos"
    DB_POS_PASSWORD_VAL="password"
    ;;
  resto)
    PUBLIC_HOST_VAL="192.168.1.31"
    DB_POS_HOST_VAL="192.168.1.32"
    DB_POS_PORT_VAL="2121"
    DB_POS_DATABASE_VAL="krypton_woosoo"
    DB_POS_USERNAME_VAL="user_1"
    DB_POS_PASSWORD_VAL="user_1"
    ;;
  *)
    echo "Usage: $0 {home|resto}" >&2
    exit 1
    ;;
esac

PLATFORM_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
ENV_FILE="${PLATFORM_DIR}/woosoo-nexus/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found" >&2
  exit 1
fi

# Always back up before mutating.
BACKUP="${ENV_FILE}.bak.$(date +%Y%m%d-%H%M%S)"
cp "$ENV_FILE" "$BACKUP"
echo "Backup written: $BACKUP"

# Remove all existing lines for a key (so duplicates get cleaned up), then
# append exactly one canonical KEY=VALUE line.
set_env() {
  local key="$1"
  local value="$2"
  sed -i "/^${key}=/d" "$ENV_FILE"
  printf '%s=%s\n' "$key" "$value" >> "$ENV_FILE"
}

set_env PUBLIC_HOST              "$PUBLIC_HOST_VAL"
set_env DB_POS_HOST              "$DB_POS_HOST_VAL"
set_env DB_POS_PORT              "$DB_POS_PORT_VAL"
set_env DB_POS_DATABASE          "$DB_POS_DATABASE_VAL"
set_env DB_POS_USERNAME          "$DB_POS_USERNAME_VAL"
set_env DB_POS_PASSWORD          "$DB_POS_PASSWORD_VAL"

# Static allow-lists — both networks always present. Switching networks
# requires no edits here; only PUBLIC_HOST and the POS DB above flip.
set_env SANCTUM_STATEFUL_DOMAINS "192.168.100.42,192.168.100.42:443,192.168.100.42:4443,192.168.1.31,192.168.1.31:443,192.168.1.31:4443"
set_env CORS_ALLOWED_ORIGINS     "https://192.168.100.42,https://192.168.100.42:443,https://192.168.100.42:4443,https://192.168.1.31,https://192.168.1.31:443,https://192.168.1.31:4443"
set_env REVERB_ALLOWED_ORIGINS   "192.168.100.42,192.168.1.31"

echo
echo "Applied .env values:"
grep -E "^(PUBLIC_HOST|DB_POS_|SANCTUM_STATEFUL_DOMAINS|CORS_ALLOWED_ORIGINS|REVERB_ALLOWED_ORIGINS)=" "$ENV_FILE"

# Apply: clear Laravel config cache and restart anything whose configuration
# depends on PUBLIC_HOST / DB_POS_* / allow-lists.
cd "$PLATFORM_DIR"
COMPOSE=(docker compose --env-file ./woosoo-nexus/.env -f compose.yaml)

echo
echo "Clearing Laravel config cache..."
"${COMPOSE[@]}" exec -T app php artisan config:clear

echo "Recreating containers (--force-recreate so env_file changes take effect)..."
# A simple `restart` does NOT refresh a container's OS environment from
# env_file — env vars stick from container creation time. Force-recreate
# tears down and rebuilds each container so the new PUBLIC_HOST / DB_POS_*
# / allow-list values actually appear in process env.
"${COMPOSE[@]}" up -d --force-recreate app queue scheduler reverb nginx tablet-pwa

echo
echo "Verification (allowed_origins + public_host as seen by Reverb):"
"${COMPOSE[@]}" exec -T reverb php artisan tinker --execute="echo json_encode(['allowed_origins'=>config('reverb.apps.apps.0.allowed_origins'),'public_host'=>env('PUBLIC_HOST'),'broadcast_host'=>config('reverb.apps.apps.0.options.host')]);"

echo
echo "Done. Network switched to: $LOC"
echo "If a tablet was authenticated against the previous network, re-register"
echo "it so its persisted broadcastConfig picks up the new host."
