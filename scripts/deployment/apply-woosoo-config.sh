#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="/etc/woosoo/woosoo.env"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo bash scripts/deployment/apply-woosoo-config.sh"
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" || -L "$CONFIG_FILE" ]]; then
  echo "Missing regular config file: $CONFIG_FILE"
  echo "Copy docs/deployment/examples/woosoo.env.example to $CONFIG_FILE first."
  exit 1
fi

config_uid="$(stat -c '%u' "$CONFIG_FILE")"
config_mode="$(stat -c '%a' "$CONFIG_FILE")"
if [[ "$config_uid" != "0" ]]; then
  echo "ERROR: $CONFIG_FILE must be owned by root (UID 0)." >&2
  exit 1
fi
if (( (8#$config_mode & 0022) != 0 )); then
  echo "ERROR: $CONFIG_FILE must not be writable by group or other users." >&2
  exit 1
fi

set -a
# shellcheck source=/dev/null
source "$CONFIG_FILE"
set +a

require_var() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required config: $name"
    exit 1
  fi
}

require_var WOOSOO_HOST
require_var WOOSOO_SERVER_IP
require_var WOOSOO_GATEWAY
require_var WOOSOO_CIDR
require_var WOOSOO_NEXUS_PATH
require_var WOOSOO_SCHEME
require_var WOOSOO_POS_HOST
require_var WOOSOO_POS_PORT
require_var WOOSOO_REVERB_APP_KEY
require_var WOOSOO_REVERB_APP_SECRET

# Platform repo root (governance + orchestration). Default: parent of the
# Laravel app repo. docker compose + compose.yaml + docker/ live here.
WOOSOO_PLATFORM_PATH="${WOOSOO_PLATFORM_PATH:-$(dirname "$WOOSOO_NEXUS_PATH")}"
WOOSOO_APPLY_STATIC_IP="${WOOSOO_APPLY_STATIC_IP:-true}"
WOOSOO_RESTART_DOCKER="${WOOSOO_RESTART_DOCKER:-true}"
WOOSOO_DOCKER_COMPOSE="${WOOSOO_DOCKER_COMPOSE:-docker compose --env-file ./woosoo-nexus/.env -f compose.yaml}"
WOOSOO_APP_SERVICE="${WOOSOO_APP_SERVICE:-app}"
WOOSOO_NGINX_SERVICE="${WOOSOO_NGINX_SERVICE:-nginx}"
WOOSOO_REVERB_SERVICE="${WOOSOO_REVERB_SERVICE:-reverb}"
WOOSOO_QUEUE_SERVICE="${WOOSOO_QUEUE_SERVICE:-queue}"
WOOSOO_SCHEDULER_SERVICE="${WOOSOO_SCHEDULER_SERVICE:-scheduler}"
WOOSOO_BACKUP_DIR="${WOOSOO_BACKUP_DIR:-/opt/woosoo/backups}"
WOOSOO_DNS_FORWARDERS="${WOOSOO_DNS_FORWARDERS:-1.1.1.1 8.8.8.8}"
FORCE_APPLY_STATIC_IP="${FORCE_APPLY_STATIC_IP:-false}"

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

safe_backup_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    mkdir -p "$WOOSOO_BACKUP_DIR/config"
    cp "$file" "$WOOSOO_BACKUP_DIR/config/$(basename "$file").$(date +%F_%H%M%S).bak"
  fi
}

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
  local key="$1"
  local value="$2"
  local file=".env"
  local rendered escaped_key

  rendered="$(quote_env_value "$value")"
  escaped_key="$(escape_ere "$key")"

  if grep -qE "^${escaped_key}=" "$file"; then
    SET_ENV_KEY="$key" SET_ENV_REPLACEMENT="${key}=${rendered}" perl -0pi -e 'BEGIN { $key = $ENV{"SET_ENV_KEY"}; $replacement = $ENV{"SET_ENV_REPLACEMENT"}; } s/^\Q$key\E=.*$/$replacement/m' "$file"
  else
    printf '%s\n' "${key}=${rendered}" >> "$file"
  fi
}

install_packages_if_missing() {
  local packages=(dnsmasq dnsutils curl iproute2 ca-certificates)
  local missing=()
  for package in "${packages[@]}"; do
    if ! dpkg -s "$package" >/dev/null 2>&1; then
      missing+=("$package")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    apt-get update
    apt-get install -y --no-install-recommends "${missing[@]}"
  else
    echo "OK: required OS packages already installed"
  fi
}

get_connection_device() {
  local connection="$1"
  nmcli -t -f NAME,DEVICE connection show --active | awk -F: -v name="$connection" '$1==name {print $2; exit}'
}

get_device_ipv4() {
  local device="$1"
  ip -4 -o addr show dev "$device" | awk '{print $4}' | cut -d/ -f1 | head -n1
}

assert_static_ip_change_safe() {
  local connection="$1"
  local device current_ip

  if [[ -z "${SSH_CONNECTION:-}${SSH_CLIENT:-}" ]]; then
    return 0
  fi

  device="$(get_connection_device "$connection" || true)"
  current_ip=""
  if [[ -n "$device" ]]; then
    current_ip="$(get_device_ipv4 "$device" || true)"
  fi

  if [[ "$current_ip" == "$WOOSOO_SERVER_IP" ]]; then
    return 0
  fi

  if [[ "$FORCE_APPLY_STATIC_IP" == "true" ]]; then
    echo "WARNING: SSH session detected, but FORCE_APPLY_STATIC_IP=true."
    echo "Proceeding with nmcli connection modify and nmcli connection up for WOOSOO_NM_CONNECTION=$connection to WOOSOO_SERVER_IP=$WOOSOO_SERVER_IP."
    return 0
  fi

  echo "ERROR: SSH session detected. Refusing to change active network settings remotely."
  echo "WOOSOO_NM_CONNECTION=$connection"
  echo "Current interface=${device:-unknown} current IP=${current_ip:-unknown}"
  echo "Target WOOSOO_SERVER_IP=$WOOSOO_SERVER_IP"
  echo "The script would run: nmcli connection modify \"$connection\" ... ipv4.method manual"
  echo "Then: nmcli connection up \"$connection\""
  echo "Run locally on the Pi console, or rerun with FORCE_APPLY_STATIC_IP=true if you accept the risk."
  exit 1
}

wait_for_app_service() {
  local attempts=60
  local delay=2

  if ! $WOOSOO_DOCKER_COMPOSE ps --services | grep -qx "$WOOSOO_APP_SERVICE"; then
    echo "WARNING: app service not found in compose: $WOOSOO_APP_SERVICE"
    return 1
  fi

  echo "Waiting for Laravel app service to become ready..."
  for _ in $(seq 1 "$attempts"); do
    if $WOOSOO_DOCKER_COMPOSE exec -T "$WOOSOO_APP_SERVICE" php artisan --version >/dev/null 2>&1; then
      echo "OK: Laravel app service is ready"
      return 0
    fi
    sleep "$delay"
  done

  echo "WARNING: Laravel app service did not become ready in time. On first Pi builds, Docker image pull/build can take several minutes. Rerun this script after the stack finishes building."
  return 1
}

echo "=== Woosoo Configuration Apply ==="
echo "Host:          $WOOSOO_HOST"
echo "Server IP:     $WOOSOO_SERVER_IP/$WOOSOO_CIDR"
echo "Gateway:       $WOOSOO_GATEWAY"
echo "Nexus path:    $WOOSOO_NEXUS_PATH"
echo "Platform path: $WOOSOO_PLATFORM_PATH"
echo "Compose:       $WOOSOO_DOCKER_COMPOSE  (run from platform path)"
echo

install_packages_if_missing

if systemctl is-active --quiet systemd-resolved; then
  echo "Disabling systemd-resolved to avoid port 53 conflict with dnsmasq..."
  systemctl disable --now systemd-resolved || true
  safe_backup_file "/etc/resolv.conf"
  rm -f /etc/resolv.conf
  for dns in $WOOSOO_DNS_FORWARDERS; do
    echo "nameserver $dns" >> /etc/resolv.conf
  done
fi

if [[ "$WOOSOO_APPLY_STATIC_IP" == "true" ]]; then
  if command_exists nmcli; then
    if [[ -z "${WOOSOO_NM_CONNECTION:-}" ]]; then
      WOOSOO_NM_CONNECTION="$(nmcli -t -f NAME,TYPE,DEVICE connection show --active | awk -F: '$2=="ethernet" && $3!="" {print $1; exit}' || true)"
    fi
    if [[ -n "$WOOSOO_NM_CONNECTION" ]]; then
      assert_static_ip_change_safe "$WOOSOO_NM_CONNECTION"
      echo "Applying static IP to NetworkManager connection: $WOOSOO_NM_CONNECTION"
      nmcli connection modify "$WOOSOO_NM_CONNECTION" \
        ipv4.addresses "${WOOSOO_SERVER_IP}/${WOOSOO_CIDR}" \
        ipv4.gateway "$WOOSOO_GATEWAY" \
        ipv4.dns "$WOOSOO_DNS_FORWARDERS" \
        ipv4.method manual
      nmcli connection up "$WOOSOO_NM_CONNECTION" || true
    else
      echo "WARNING: Could not detect wired NetworkManager connection."
    fi
  else
    echo "WARNING: nmcli not found. Static IP not applied."
  fi
fi

sleep 2
if ip -4 addr | grep -Fq "$WOOSOO_SERVER_IP"; then
  echo "OK: Server IP is active: $WOOSOO_SERVER_IP"
else
  echo "WARNING: Server IP $WOOSOO_SERVER_IP not detected on active interfaces."
fi

DNSMASQ_CONF="/etc/dnsmasq.d/woosoo.conf"
safe_backup_file "$DNSMASQ_CONF"
cat > "$DNSMASQ_CONF" <<EOF
# Generated by Woosoo deploy script.
# Edit /etc/woosoo/woosoo.env then rerun this script.

domain-needed
bogus-priv
address=/${WOOSOO_HOST}/${WOOSOO_SERVER_IP}
EOF
for alias in ${WOOSOO_ALIASES:-}; do
  echo "address=/${alias}/${WOOSOO_SERVER_IP}" >> "$DNSMASQ_CONF"
done
cat >> "$DNSMASQ_CONF" <<EOF

# Forward normal DNS.
EOF
for dns in $WOOSOO_DNS_FORWARDERS; do
  echo "server=${dns}" >> "$DNSMASQ_CONF"
done

dnsmasq --test
systemctl enable dnsmasq
systemctl restart dnsmasq

DNS_RESULT="$(dig "$WOOSOO_HOST" "@127.0.0.1" +short | tail -n1 || true)"
if [[ "$DNS_RESULT" != "$WOOSOO_SERVER_IP" ]]; then
  echo "ERROR: DNS test failed. Expected $WOOSOO_SERVER_IP, got ${DNS_RESULT:-empty}"
  exit 1
fi

echo "OK: $WOOSOO_HOST resolves to $WOOSOO_SERVER_IP"

safe_backup_file "/etc/hosts"
sed -i '/# BEGIN WOOSOO HOSTS/,/# END WOOSOO HOSTS/d' /etc/hosts
{
  echo "# BEGIN WOOSOO HOSTS"
  echo "$WOOSOO_SERVER_IP $WOOSOO_HOST ${WOOSOO_ALIASES:-}"
  echo "# END WOOSOO HOSTS"
} >> /etc/hosts

if [[ ! -d "$WOOSOO_NEXUS_PATH" ]]; then
  echo "ERROR: Laravel project path not found: $WOOSOO_NEXUS_PATH"
  exit 1
fi

cd "$WOOSOO_NEXUS_PATH"

if [[ ! -f artisan ]]; then
  echo "ERROR: artisan not found in $WOOSOO_NEXUS_PATH"
  exit 1
fi

if [[ ! -f "$WOOSOO_PLATFORM_PATH/compose.yaml" ]]; then
  echo "ERROR: Platform compose.yaml not found at $WOOSOO_PLATFORM_PATH/compose.yaml"
  echo "  Orchestration authority is the platform repo, not woosoo-nexus."
  exit 1
fi

if [[ ! -f .env ]]; then
  if [[ -f .env.example ]]; then
    cp .env.example .env
  else
    touch .env
  fi
fi

safe_backup_file ".env"

echo "Updating Laravel .env..."
db_password_value="${WOOSOO_DB_PASSWORD:-change_this_password}"
db_root_password_value="${WOOSOO_DB_ROOT_PASSWORD:-change_this_root_password}"
set_env "PUBLIC_SCHEME" "$WOOSOO_SCHEME"
set_env "PUBLIC_HOST" "$WOOSOO_HOST"
set_env "PUBLIC_HTTP_PORT" "80"
set_env "PUBLIC_HTTPS_PORT" "443"
set_env "APP_ENV" "production"
set_env "APP_DEBUG" "false"
set_env "APP_URL" "${WOOSOO_SCHEME}://${WOOSOO_HOST}"
# ASSET_URL intentionally left empty — assets use root-relative paths so the
# admin panel works from any hostname or IP without cross-origin blocking.
set_env "ASSET_URL" ""
set_env "APP_TIMEZONE" "${WOOSOO_TIMEZONE:-Asia/Manila}"
set_env "DB_CONNECTION" "mysql"
set_env "DB_HOST" "mysql"
set_env "DB_PORT" "3306"
set_env "DB_DATABASE" "${WOOSOO_DB_DATABASE:-woosoo}"
set_env "DB_USERNAME" "${WOOSOO_DB_USERNAME:-woosoo}"
set_env "DB_PASSWORD" "$db_password_value"
set_env "DB_ROOT_PASSWORD" "$db_root_password_value"
if [[ -z "${WOOSOO_DB_PASSWORD:-}" && "$db_password_value" == "change_this_password" ]]; then
  echo "WARNING: DB_PASSWORD is using default credentials because WOOSOO_DB_PASSWORD is unset. Do not use default credentials in production; set WOOSOO_DB_PASSWORD in $CONFIG_FILE." >&2
fi
if [[ -z "${WOOSOO_DB_ROOT_PASSWORD:-}" && "$db_root_password_value" == "change_this_root_password" ]]; then
  echo "WARNING: DB_ROOT_PASSWORD is using default credentials because WOOSOO_DB_ROOT_PASSWORD is unset. Do not use default credentials in production; set WOOSOO_DB_ROOT_PASSWORD in $CONFIG_FILE." >&2
fi
set_env "DB_POS_HOST" "$WOOSOO_POS_HOST"
set_env "DB_POS_PORT" "$WOOSOO_POS_PORT"
set_env "DB_POS_DATABASE" "${WOOSOO_POS_DATABASE:-krypton_woosoo}"
set_env "DB_POS_USERNAME" "${WOOSOO_POS_USERNAME:-krypton_readonly}"
set_env "DB_POS_PASSWORD" "${WOOSOO_POS_PASSWORD:-}"
set_env "CACHE_DRIVER" "redis"
set_env "QUEUE_CONNECTION" "redis"
set_env "SESSION_DRIVER" "redis"
set_env "REDIS_HOST" "redis"
set_env "REDIS_PASSWORD" "null"
set_env "REDIS_PORT" "6379"
set_env "BROADCAST_DRIVER" "reverb"
set_env "BROADCAST_CONNECTION" "reverb"
set_env "REVERB_APP_ID" "${WOOSOO_REVERB_APP_ID:-woosoo}"
set_env "REVERB_APP_KEY" "$WOOSOO_REVERB_APP_KEY"
set_env "REVERB_APP_SECRET" "$WOOSOO_REVERB_APP_SECRET"
set_env "REVERB_HOST" "reverb"
set_env "REVERB_PUBLIC_HOST" "$WOOSOO_HOST"
set_env "REVERB_PORT" "8080"
set_env "REVERB_SCHEME" "http"
set_env "VITE_REVERB_APP_KEY" "$WOOSOO_REVERB_APP_KEY"
set_env "VITE_REVERB_HOST" "$WOOSOO_HOST"
set_env "VITE_REVERB_PORT" "443"
set_env "VITE_REVERB_SCHEME" "$WOOSOO_SCHEME"
set_env "SESSION_DOMAIN" "$WOOSOO_HOST"
set_env "SESSION_SECURE_COOKIE" "true"
set_env "SESSION_SAME_SITE" "lax"
set_env "SANCTUM_STATEFUL_DOMAINS" "${WOOSOO_HOST},${WOOSOO_HOST}:443,${WOOSOO_HOST}:80,${WOOSOO_HOST}:4443"
set_env "CORS_ALLOWED_ORIGINS" "${WOOSOO_SCHEME}://${WOOSOO_HOST},http://${WOOSOO_HOST},${WOOSOO_SCHEME}://${WOOSOO_HOST}:4443"
set_env "DEVICE_AUTH_PASSCODE" "${WOOSOO_DEVICE_AUTH_PASSCODE:-}"
set_env "LOG_LEVEL" "error"

if ! grep -qE '^APP_KEY=base64:.+' .env; then
  echo "INFO: APP_KEY is not set. Before first production use, run: $WOOSOO_DOCKER_COMPOSE exec -T $WOOSOO_APP_SERVICE php artisan key:generate"
fi

CERT_DIR="$WOOSOO_PLATFORM_PATH/docker/certs"
mkdir -p "$CERT_DIR"
if [[ ! -f "$CERT_DIR/fullchain.pem" || ! -f "$CERT_DIR/privkey.pem" ]]; then
  echo "WARNING: TLS certificate files are missing."
  echo "Expected host files:"
  echo "  $CERT_DIR/fullchain.pem"
  echo "  $CERT_DIR/privkey.pem"
  echo "Platform compose.yaml mounts ./docker/certs:/etc/nginx/certs:ro."
fi

if [[ "$WOOSOO_RESTART_DOCKER" == "true" ]]; then
  if command_exists docker; then
    # Compose + --env-file ./woosoo-nexus/.env are platform-root-relative.
    cd "$WOOSOO_PLATFORM_PATH"
    $WOOSOO_DOCKER_COMPOSE up -d --build
    if wait_for_app_service; then
      $WOOSOO_DOCKER_COMPOSE exec -T "$WOOSOO_APP_SERVICE" php artisan config:clear || true
      $WOOSOO_DOCKER_COMPOSE exec -T "$WOOSOO_APP_SERVICE" php artisan cache:clear || true
      $WOOSOO_DOCKER_COMPOSE exec -T "$WOOSOO_APP_SERVICE" php artisan route:clear || true
      $WOOSOO_DOCKER_COMPOSE exec -T "$WOOSOO_APP_SERVICE" php artisan view:clear || true
      $WOOSOO_DOCKER_COMPOSE exec -T "$WOOSOO_APP_SERVICE" php artisan config:cache || true
      $WOOSOO_DOCKER_COMPOSE exec -T "$WOOSOO_APP_SERVICE" php artisan route:cache || true
      $WOOSOO_DOCKER_COMPOSE exec -T "$WOOSOO_APP_SERVICE" php artisan view:cache || true
    fi
    $WOOSOO_DOCKER_COMPOSE ps
  else
    echo "WARNING: Docker not installed. Skipping Docker operations."
  fi
fi

echo
echo "=== Final Checks ==="
dig "$WOOSOO_HOST" "@127.0.0.1" +short || true
curl -k -I --max-time 10 "${WOOSOO_SCHEME}://${WOOSOO_HOST}" || true
df -h /
free -h
if command_exists vcgencmd; then vcgencmd measure_temp || true; fi

echo
echo "Done. Tablet DNS must point to: ${WOOSOO_SERVER_IP}"
echo "Admin URL: ${WOOSOO_SCHEME}://${WOOSOO_HOST}"
echo "Tablet PWA URL (platform compose.yaml): ${WOOSOO_SCHEME}://${WOOSOO_HOST}:4443"
