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

CONFIG_FILE="/etc/woosoo/woosoo.env"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: secrets file not found: $CONFIG_FILE" >&2
  echo "Copy docs/deployment/examples/woosoo.env.example to $CONFIG_FILE first." >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

require_secret() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "ERROR: required var $name is unset in $CONFIG_FILE" >&2
    exit 1
  fi
}
require_secret HOME_DB_POS_USERNAME
require_secret HOME_DB_POS_PASSWORD
require_secret RESTO_DB_POS_USERNAME
require_secret RESTO_DB_POS_PASSWORD

LOC="${1:-}"
case "$LOC" in
  home)
    PUBLIC_HOST_VAL="192.168.100.42"
    DB_POS_HOST_VAL="192.168.100.7"
    DB_POS_PORT_VAL="3308"
    DB_POS_DATABASE_VAL="krypton_woosoo"
    DB_POS_USERNAME_VAL="$HOME_DB_POS_USERNAME"
    DB_POS_PASSWORD_VAL="$HOME_DB_POS_PASSWORD"
    ;;
  resto)
    PUBLIC_HOST_VAL="192.168.1.31"
    DB_POS_HOST_VAL="192.168.1.32"
    DB_POS_PORT_VAL="2121"
    DB_POS_DATABASE_VAL="krypton_woosoo"
    DB_POS_USERNAME_VAL="$RESTO_DB_POS_USERNAME"
    DB_POS_PASSWORD_VAL="$RESTO_DB_POS_PASSWORD"
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
  # Wrap value in double quotes so spaces and most shell metacharacters are safe.
  # Single quotes inside the value are escaped as '\''.
  printf "%s=\"%s\"\n" "$key" "${value//\"/\\\"}" >> "$ENV_FILE"
}

env_value() {
  local key="$1"
  awk -F= -v key="$key" '$1 == key { value = substr($0, length(key) + 2) } END { print value }' "$ENV_FILE" \
    | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//"
}

REVERB_APP_KEY_VAL="$(env_value REVERB_APP_KEY)"

set_env PUBLIC_HOST              "$PUBLIC_HOST_VAL"
set_env APP_URL                  "https://${PUBLIC_HOST_VAL}"
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

# Keep Docker-internal publish config separate from browser/tablet public config.
set_env REVERB_HOST              "reverb"
set_env REVERB_PUBLIC_HOST       "$PUBLIC_HOST_VAL"
set_env REVERB_BROADCAST_HOST    "reverb"
set_env REVERB_PORT              "8080"
set_env REVERB_SCHEME            "http"
set_env VITE_REVERB_HOST         "$PUBLIC_HOST_VAL"
set_env VITE_REVERB_PORT         "443"
set_env VITE_REVERB_SCHEME       "https"
set_env NUXT_PUBLIC_API_BASE_URL "https://${PUBLIC_HOST_VAL}/api"
set_env NUXT_PUBLIC_REVERB_HOST  "$PUBLIC_HOST_VAL"
set_env NUXT_PUBLIC_REVERB_PORT  "443"
set_env NUXT_PUBLIC_REVERB_SCHEME "https"
set_env MAIN_API_URL             "https://${PUBLIC_HOST_VAL}"
set_env APP_RUNTIME_API_BASE_URL "https://${PUBLIC_HOST_VAL}/api"
set_env APP_RUNTIME_REVERB_HOST  "$PUBLIC_HOST_VAL"
set_env APP_RUNTIME_REVERB_PORT  "443"
set_env APP_RUNTIME_REVERB_SCHEME "https"

if [[ -n "$REVERB_APP_KEY_VAL" ]]; then
  set_env VITE_REVERB_APP_KEY        "$REVERB_APP_KEY_VAL"
  set_env NUXT_PUBLIC_REVERB_APP_KEY "$REVERB_APP_KEY_VAL"
  set_env NUXT_PUBLIC_PUSHER_KEY     "$REVERB_APP_KEY_VAL"
  set_env APP_RUNTIME_REVERB_APP_KEY "$REVERB_APP_KEY_VAL"
fi

echo
echo "Applied .env values:"
grep -E "^(PUBLIC_HOST|APP_URL|DB_POS_|SANCTUM_STATEFUL_DOMAINS|CORS_ALLOWED_ORIGINS|REVERB_ALLOWED_ORIGINS|REVERB_HOST|REVERB_PUBLIC_HOST|REVERB_BROADCAST_HOST|REVERB_PORT|REVERB_SCHEME|VITE_REVERB_HOST|VITE_REVERB_PORT|VITE_REVERB_SCHEME|NUXT_PUBLIC_API_BASE_URL|NUXT_PUBLIC_REVERB_HOST|NUXT_PUBLIC_REVERB_PORT|NUXT_PUBLIC_REVERB_SCHEME|APP_RUNTIME_API_BASE_URL|APP_RUNTIME_REVERB_HOST|APP_RUNTIME_REVERB_PORT|APP_RUNTIME_REVERB_SCHEME)=" "$ENV_FILE"

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
echo "Verification (Reverb/Laravel runtime host split):"
"${COMPOSE[@]}" exec -T reverb php artisan tinker --execute="echo json_encode(['allowed_origins'=>config('reverb.apps.apps.0.allowed_origins'),'public_host'=>env('PUBLIC_HOST'),'reverb_public_host'=>env('REVERB_PUBLIC_HOST'),'reverb_host'=>env('REVERB_HOST'),'broadcast_host'=>config('reverb.apps.apps.0.options.host'),'broadcast_port'=>config('reverb.apps.apps.0.options.port'),'broadcast_scheme'=>config('reverb.apps.apps.0.options.scheme')]);"

echo
echo "Verification (tablet runtime env):"
"${COMPOSE[@]}" exec -T tablet-pwa printenv | grep -E "^(APP_RUNTIME_API_BASE_URL|APP_RUNTIME_REVERB_HOST|APP_RUNTIME_REVERB_PORT|APP_RUNTIME_REVERB_SCHEME|NUXT_PUBLIC_API_BASE_URL|NUXT_PUBLIC_REVERB_HOST|NUXT_PUBLIC_REVERB_PORT|NUXT_PUBLIC_REVERB_SCHEME)="

echo
echo "Done. Network switched to: $LOC"
echo "If a tablet was authenticated against the previous network, re-register"
echo "it so its persisted broadcastConfig picks up the new host."
