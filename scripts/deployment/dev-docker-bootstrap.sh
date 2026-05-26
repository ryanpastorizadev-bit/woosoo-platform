#!/usr/bin/env bash
# =============================================================================
# Woosoo Dev Docker Bootstrap  (Windows / Docker Desktop / WSL — NOT for Pi)
# =============================================================================
# Local-dev counterpart to apply-woosoo-config.sh. Writes a fresh
# woosoo-nexus/.env (and optional tablet-ordering-pwa/.env) suitable for
# running the platform stack on Docker Desktop. Skips Pi-only setup:
# NetworkManager static IP, dnsmasq, systemd-resolved, apt packages, /etc/hosts.
#
# Usage (from platform repo root):
#   bash scripts/deployment/dev-docker-bootstrap.sh
#
# After this completes:
#   docker compose --env-file ./woosoo-nexus/.env -f compose.yaml build
#   docker compose --env-file ./woosoo-nexus/.env -f compose.yaml up -d
#   docker compose --env-file ./woosoo-nexus/.env -f compose.yaml \
#     exec -T app php artisan key:generate --force
#   docker compose --env-file ./woosoo-nexus/.env -f compose.yaml \
#     exec -T app php artisan migrate --force
#
# This script never starts containers — you control when to build/up.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
NEXUS_DIR="$PLATFORM_ROOT/woosoo-nexus"
TABLET_DIR="$PLATFORM_ROOT/tablet-ordering-pwa"

# Dev-mode defaults. Override by setting these env vars before invocation.
DEV_PUBLIC_HOST="${DEV_PUBLIC_HOST:-192.168.100.7}"     # this PC (also home POS)
DEV_PUBLIC_SCHEME="${DEV_PUBLIC_SCHEME:-https}"
DEV_SERVER_IP="${DEV_SERVER_IP:-192.168.100.7}"
DEV_TIMEZONE="${DEV_TIMEZONE:-Asia/Manila}"

# POS DB connection (krypton_woosoo on the same dev PC).
DEV_POS_HOST="${DEV_POS_HOST:-host.docker.internal}"   # reach Windows host from container
DEV_POS_PORT="${DEV_POS_PORT:-3308}"
DEV_POS_DATABASE="${DEV_POS_DATABASE:-krypton_woosoo}"
DEV_POS_USERNAME="${DEV_POS_USERNAME:-krypton_readonly}"
DEV_POS_PASSWORD="${DEV_POS_PASSWORD:-}"

# Local MySQL (containerised) credentials.
DEV_DB_DATABASE="${DEV_DB_DATABASE:-woosoo}"
DEV_DB_USERNAME="${DEV_DB_USERNAME:-woosoo}"
DEV_DB_PASSWORD="${DEV_DB_PASSWORD:-dev_db_password_change_me}"
DEV_DB_ROOT_PASSWORD="${DEV_DB_ROOT_PASSWORD:-dev_root_password_change_me}"

# Reverb dev keys (deterministic, dev-only).
DEV_REVERB_APP_ID="${DEV_REVERB_APP_ID:-woosoo}"
DEV_REVERB_APP_KEY="${DEV_REVERB_APP_KEY:-dev-reverb-key-please-rotate}"
DEV_REVERB_APP_SECRET="${DEV_REVERB_APP_SECRET:-dev-reverb-secret-please-rotate}"

DEV_DEVICE_AUTH_PASSCODE="${DEV_DEVICE_AUTH_PASSCODE:-123456}"

# ── Guards ────────────────────────────────────────────────────────────────────
if [[ ! -d "$NEXUS_DIR" ]]; then
  echo "ERROR: nexus app dir not found: $NEXUS_DIR"
  echo "  Clone tech-artificer/woosoo-nexus into $NEXUS_DIR first."
  exit 1
fi

if [[ ! -f "$NEXUS_DIR/.env.example" ]]; then
  echo "ERROR: $NEXUS_DIR/.env.example missing. The nexus repo seems incomplete."
  exit 1
fi

if [[ ! -d "$TABLET_DIR" ]]; then
  echo "ERROR: tablet app dir not found: $TABLET_DIR"
  echo "  Clone tech-artificer/tablet-ordering-pwa into $TABLET_DIR first."
  exit 1
fi

cd "$PLATFORM_ROOT"

echo "========================================"
echo "  Woosoo Dev Docker Bootstrap"
echo "  Platform : $PLATFORM_ROOT"
echo "  Nexus    : $NEXUS_DIR"
echo "  Tablet   : $TABLET_DIR"
echo "  Host     : ${DEV_PUBLIC_SCHEME}://${DEV_PUBLIC_HOST}"
echo "========================================"
echo

# ── Step 1: Seed woosoo-nexus/.env ───────────────────────────────────────────
NEXUS_ENV="$NEXUS_DIR/.env"

if [[ -f "$NEXUS_ENV" ]]; then
  BACKUP_NAME="$NEXUS_ENV.bak.$(date +%F_%H%M%S)"
  cp "$NEXUS_ENV" "$BACKUP_NAME"
  echo "Backed up existing .env -> $BACKUP_NAME"
fi

cp "$NEXUS_DIR/.env.example" "$NEXUS_ENV"
echo "Seeded nexus/.env from .env.example"

# ── Step 2: set_env mirror of apply-woosoo-config.sh logic ───────────────────
quote_env_value() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '"%s"' "$value"
}
escape_ere() {
  printf '%s' "$1" | sed -e 's/[][(){}.^$*+?|\\/]/\\&/g'
}
set_env() {
  local key="$1" value="$2" file="$NEXUS_ENV" rendered escaped_key
  rendered="$(quote_env_value "$value")"
  escaped_key="$(escape_ere "$key")"
  if grep -qE "^${escaped_key}=" "$file"; then
    SET_ENV_KEY="$key" SET_ENV_REPLACEMENT="${key}=${rendered}" \
      perl -0pi -e 'BEGIN{$k=$ENV{"SET_ENV_KEY"};$r=$ENV{"SET_ENV_REPLACEMENT"}} s/^\Q$k\E=.*$/$r/m' "$file"
  else
    printf '%s\n' "${key}=${rendered}" >> "$file"
  fi
}

echo "Writing dev-mode values into nexus/.env..."

# Public-facing URL + scheme
set_env "PUBLIC_SCHEME"     "$DEV_PUBLIC_SCHEME"
set_env "PUBLIC_HOST"       "$DEV_PUBLIC_HOST"
set_env "PUBLIC_HTTP_PORT"  "80"
set_env "PUBLIC_HTTPS_PORT" "443"

# Laravel basics — dev (not production)
set_env "APP_ENV"      "local"
set_env "APP_DEBUG"    "true"
set_env "APP_URL"      "${DEV_PUBLIC_SCHEME}://${DEV_PUBLIC_HOST}"
set_env "ASSET_URL"    ""
set_env "APP_TIMEZONE" "$DEV_TIMEZONE"
set_env "LOG_LEVEL"    "debug"

# Local MySQL (containerised)
set_env "DB_CONNECTION"     "mysql"
set_env "DB_HOST"           "mysql"
set_env "DB_PORT"           "3306"
set_env "DB_DATABASE"       "$DEV_DB_DATABASE"
set_env "DB_USERNAME"       "$DEV_DB_USERNAME"
set_env "DB_PASSWORD"       "$DEV_DB_PASSWORD"
set_env "DB_ROOT_PASSWORD"  "$DEV_DB_ROOT_PASSWORD"

# POS DB (krypton_woosoo) — reach Windows host from container
set_env "DB_POS_HOST"     "$DEV_POS_HOST"
set_env "DB_POS_PORT"     "$DEV_POS_PORT"
set_env "DB_POS_DATABASE" "$DEV_POS_DATABASE"
set_env "DB_POS_USERNAME" "$DEV_POS_USERNAME"
set_env "DB_POS_PASSWORD" "$DEV_POS_PASSWORD"

# Cache / queue / session — redis (containerised)
set_env "CACHE_DRIVER"     "redis"
set_env "QUEUE_CONNECTION" "redis"
set_env "SESSION_DRIVER"   "redis"
set_env "REDIS_HOST"       "redis"
set_env "REDIS_PASSWORD"   "null"
set_env "REDIS_PORT"       "6379"

# Broadcast / Reverb
set_env "BROADCAST_DRIVER"     "reverb"
set_env "BROADCAST_CONNECTION" "reverb"
set_env "REVERB_APP_ID"        "$DEV_REVERB_APP_ID"
set_env "REVERB_APP_KEY"       "$DEV_REVERB_APP_KEY"
set_env "REVERB_APP_SECRET"    "$DEV_REVERB_APP_SECRET"
set_env "REVERB_HOST"          "reverb"
set_env "REVERB_PUBLIC_HOST"   "$DEV_PUBLIC_HOST"
set_env "REVERB_BROADCAST_HOST" "reverb"
set_env "REVERB_PORT"          "8080"
set_env "REVERB_SCHEME"        "http"

# Vite (browser-side) Reverb config
set_env "VITE_REVERB_APP_KEY" "$DEV_REVERB_APP_KEY"
set_env "VITE_REVERB_HOST"    "$DEV_PUBLIC_HOST"
set_env "VITE_REVERB_PORT"    "443"
set_env "VITE_REVERB_SCHEME"  "$DEV_PUBLIC_SCHEME"

# Session / Sanctum / CORS — wide enough for local dev access
set_env "SESSION_DOMAIN"        ""
set_env "SESSION_SECURE_COOKIE" "true"
set_env "SESSION_SAME_SITE"     "lax"
set_env "SANCTUM_STATEFUL_DOMAINS" "${DEV_PUBLIC_HOST},${DEV_PUBLIC_HOST}:443,${DEV_PUBLIC_HOST}:4443,localhost,localhost:443,localhost:4443"
set_env "CORS_ALLOWED_ORIGINS"     "${DEV_PUBLIC_SCHEME}://${DEV_PUBLIC_HOST},${DEV_PUBLIC_SCHEME}://${DEV_PUBLIC_HOST}:4443,https://localhost,https://localhost:4443"

# Device auth
set_env "DEVICE_AUTH_PASSCODE" "$DEV_DEVICE_AUTH_PASSCODE"

echo "OK: nexus/.env written"
echo

# ── Step 3: Tablet PWA env (optional — tablet container reads almost nothing from .env at runtime) ──
TABLET_ENV="$TABLET_DIR/.env"
if [[ -f "$TABLET_DIR/.env.example" ]]; then
  if [[ -f "$TABLET_ENV" ]]; then
    cp "$TABLET_ENV" "$TABLET_ENV.bak.$(date +%F_%H%M%S)"
    echo "Backed up existing tablet .env"
  fi
  cp "$TABLET_DIR/.env.example" "$TABLET_ENV"
  echo "Seeded tablet/.env from .env.example"
else
  echo "  (no tablet .env.example — tablet container relies on compose env vars only)"
fi
echo

# ── Step 4: Reminder on APP_KEY ─────────────────────────────────────────────
if ! grep -qE '^APP_KEY=base64:.+' "$NEXUS_ENV"; then
  echo "NOTE: APP_KEY is not yet set. After the stack is up, run:"
  echo "  docker compose --env-file ./woosoo-nexus/.env -f compose.yaml \\"
  echo "    exec -T app php artisan key:generate --force"
fi

# ── Step 5: Summary ─────────────────────────────────────────────────────────
echo "========================================"
echo "  Bootstrap complete — next steps:"
echo "========================================"
echo
echo "  1. Build images (heavy; first time ~10 min):"
echo "     docker compose --env-file ./woosoo-nexus/.env -f compose.yaml build"
echo
echo "  2. Start the stack:"
echo "     docker compose --env-file ./woosoo-nexus/.env -f compose.yaml up -d"
echo
echo "  3. Generate Laravel APP_KEY + migrate:"
echo "     docker compose --env-file ./woosoo-nexus/.env -f compose.yaml exec -T app php artisan key:generate --force"
echo "     docker compose --env-file ./woosoo-nexus/.env -f compose.yaml exec -T app php artisan migrate --force"
echo
echo "  4. Smoke test:"
echo "     docker compose --env-file ./woosoo-nexus/.env -f compose.yaml ps"
echo "     curl -k https://${DEV_PUBLIC_HOST}/"
echo "     curl -k https://${DEV_PUBLIC_HOST}:4443/build-info.json"
echo
echo "  Tear down (keeps volumes):  docker compose --env-file ./woosoo-nexus/.env -f compose.yaml down"
echo "  WIPE volumes (DESTRUCTIVE): docker compose --env-file ./woosoo-nexus/.env -f compose.yaml down -v"
echo
