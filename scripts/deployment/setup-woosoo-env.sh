#!/usr/bin/env bash
# =============================================================================
# Woosoo Operator Config Setup
# Creates or updates /etc/woosoo/woosoo.env interactively.
#
# Usage:
#   sudo bash scripts/deployment/setup-woosoo-env.sh
#
# Re-runnable: if /etc/woosoo/woosoo.env already exists its values are loaded
# as defaults so you only need to update what has changed.
#
# Non-interactive (CI/scripted): pre-export variables before calling.
#   WOOSOO_HOST=woosoo.local WOOSOO_ENV=production ... sudo -E bash setup-woosoo-env.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="${CONFIG_FILE:-/etc/woosoo/woosoo.env}"
DOCTOR_SCRIPT="$SCRIPT_DIR/doctor.sh"

# ── Colors ────────────────────────────────────────────────────────────────────
_G='\033[0;32m'; _Y='\033[1;33m'; _C='\033[0;36m'; _B='\033[1m'; _NC='\033[0m'
note()   { printf "${_Y}[note]${_NC} %s\n" "$*"; }
ok()     { printf "${_G}[ok]${_NC} %s\n" "$*"; }
section(){ printf "\n${_B}── %s ──${_NC}\n" "$*"; }

# ── Root check ────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: Run as root: sudo bash scripts/deployment/setup-woosoo-env.sh"
  exit 1
fi

printf "\n========================================\n"
printf "  Woosoo Operator Config Setup\n"
printf "  Target: %s\n" "$CONFIG_FILE"
printf "========================================\n"

# ── Load existing config as defaults ─────────────────────────────────────────
if [[ -f "$CONFIG_FILE" && -r "$CONFIG_FILE" ]]; then
  note "Existing config found — loading as defaults."
  set -a
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
  set +a
fi
echo

# ── Helpers ───────────────────────────────────────────────────────────────────

# ask VAR "Label" ["fallback_default"]
ask() {
  local var="$1" label="$2" fallback="${3:-}"
  local current="${!var:-$fallback}"
  local input
  if [[ -n "$current" ]]; then
    read -r -p "  $label [$current]: " input
    input="${input:-$current}"
  else
    read -r -p "  $label: " input
  fi
  printf -v "$var" '%s' "$input"
}

# ask_secret VAR "Label"  (no-echo; required unless current value exists)
ask_secret() {
  local var="$1" label="$2"
  local current="${!var:-}"
  local input=""
  if [[ -n "$current" ]]; then
    read -r -s -p "  $label [keep current, press Enter]: " input
    echo
    input="${input:-$current}"
  else
    while [[ -z "$input" ]]; do
      read -r -s -p "  $label: " input
      echo
      [[ -z "$input" ]] && echo "  (required — please enter a value)"
    done
  fi
  printf -v "$var" '%s' "$input"
}

# ask_optional_secret VAR "Label"  (blank is allowed)
ask_optional_secret() {
  local var="$1" label="$2"
  local current="${!var:-}"
  local input=""
  if [[ -n "$current" ]]; then
    read -r -s -p "  $label [keep current, press Enter]: " input
    echo
    input="${input:-$current}"
  else
    read -r -s -p "  $label (optional, press Enter to skip): " input
    echo
  fi
  printf -v "$var" '%s' "$input"
}

# pick_menu VAR "Prompt" opt1 opt2 ...
pick_menu() {
  local var="$1" prompt="$2"; shift 2
  local opts=("$@") current="${!var:-}" n=${#opts[@]}
  printf "  ${_C}%s${_NC}\n" "$prompt"
  local i=1
  for o in "${opts[@]}"; do
    local tag=""
    [[ "$o" == "$current" ]] && tag=" ◄"
    printf "    %d) %s%s\n" "$i" "$o" "$tag"
    i=$((i+1))
  done
  local c
  while true; do
    read -r -p "  Choice [1-$n]: " c
    if [[ "$c" =~ ^[0-9]+$ ]] && (( c >= 1 && c <= n )); then
      printf -v "$var" '%s' "${opts[$((c-1))]}"
      break
    fi
    printf "  Enter a number 1-%d.\n" "$n"
  done
}

# q "value"  — bash-safe env quoting (double-quote with escapes)
q() {
  local v="$1"
  v="${v//\\/\\\\}"
  v="${v//\"/\\\"}"
  printf '"%s"' "$v"
}

# ── 1. Network ────────────────────────────────────────────────────────────────
section "Network"

# Auto-detect current subnet from host IPs
_detected_net=""
if ip -4 addr 2>/dev/null | grep -qE 'inet 192\.168\.100\.'; then
  _detected_net="home"
elif ip -4 addr 2>/dev/null | grep -qE 'inet 192\.168\.1\.'; then
  _detected_net="resto"
fi

# Derive current selection from loaded POS host
_NETWORK_CHOICE="${_NETWORK_CHOICE:-}"
if [[ -z "$_NETWORK_CHOICE" ]]; then
  case "${WOOSOO_POS_HOST:-}" in
    192.168.100.*) _NETWORK_CHOICE="home" ;;
    192.168.1.*)   _NETWORK_CHOICE="resto" ;;
    *)             _NETWORK_CHOICE="${_detected_net:-home}" ;;
  esac
fi

printf "  Known networks:\n"
printf "    home  — Pi 192.168.100.42 / POS 192.168.100.7  / gw 192.168.100.1\n"
printf "    resto — Pi 192.168.1.31   / POS 192.168.1.32   / gw 192.168.1.1\n"
[[ -n "$_detected_net" ]] && note "auto-detected subnet: $_detected_net"
echo

pick_menu _NETWORK_CHOICE "Select your network:" "home" "resto"

case "$_NETWORK_CHOICE" in
  home)
    # Reset IPs if they point at the resto subnet or are unset
    [[ "${WOOSOO_SERVER_IP:-}" != 192.168.100.* ]] && WOOSOO_SERVER_IP="192.168.100.42"
    [[ "${WOOSOO_GATEWAY:-}"   != 192.168.100.* ]] && WOOSOO_GATEWAY="192.168.100.1"
    [[ "${WOOSOO_POS_HOST:-}"  != 192.168.100.* ]] && WOOSOO_POS_HOST="192.168.100.7"
    ;;
  resto)
    [[ "${WOOSOO_SERVER_IP:-}" != 192.168.1.* ]] && WOOSOO_SERVER_IP="192.168.1.31"
    [[ "${WOOSOO_GATEWAY:-}"   != 192.168.1.* ]] && WOOSOO_GATEWAY="192.168.1.1"
    [[ "${WOOSOO_POS_HOST:-}"  != 192.168.1.* ]] && WOOSOO_POS_HOST="192.168.1.32"
    ;;
esac

echo
ask WOOSOO_SERVER_IP "Pi server IP"
ask WOOSOO_GATEWAY   "Gateway IP"
ask WOOSOO_CIDR      "CIDR prefix" "24"

# ── 2. Environment profile ────────────────────────────────────────────────────
section "Environment profile"
printf "  Controls APP_ENV / APP_DEBUG / LOG_LEVEL in the Laravel .env.\n\n"
WOOSOO_ENV="${WOOSOO_ENV:-production}"
pick_menu WOOSOO_ENV "WOOSOO_ENV:" "production" "staging" "local"

# ── 3. Host + scheme ──────────────────────────────────────────────────────────
section "Host"
ask WOOSOO_HOST   "Hostname / domain" "woosoo.local"
WOOSOO_SCHEME="${WOOSOO_SCHEME:-https}"
pick_menu WOOSOO_SCHEME "Scheme:" "https" "http"

# ── 4. Paths ──────────────────────────────────────────────────────────────────
section "Paths"
note "Auto-detected from script location. Change only if repos live elsewhere."
WOOSOO_NEXUS_PATH="${WOOSOO_NEXUS_PATH:-$PLATFORM_ROOT/woosoo-nexus}"
WOOSOO_PLATFORM_PATH="${WOOSOO_PLATFORM_PATH:-$PLATFORM_ROOT}"
ask WOOSOO_NEXUS_PATH    "Laravel app path (woosoo-nexus)"
ask WOOSOO_PLATFORM_PATH "Platform root path"

# ── 5. POS database ───────────────────────────────────────────────────────────
section "POS Database (read-only connection to Krypton)"
ask WOOSOO_POS_HOST     "POS DB host"
ask WOOSOO_POS_PORT     "POS DB port"     "3308"
ask WOOSOO_POS_DATABASE "POS DB name"     "krypton_woosoo"
ask WOOSOO_POS_USERNAME "POS DB username" "krypton_readonly"
ask_optional_secret WOOSOO_POS_PASSWORD "POS DB password"

# ── 6. Woosoo database ────────────────────────────────────────────────────────
section "Woosoo Database"
ask WOOSOO_DB_DATABASE "DB name" "woosoo"
ask WOOSOO_DB_USERNAME "DB user" "woosoo"
ask_secret WOOSOO_DB_PASSWORD      "DB password"
ask_secret WOOSOO_DB_ROOT_PASSWORD "DB root password"

# ── 7. Reverb ─────────────────────────────────────────────────────────────────
section "Reverb (WebSocket)"
ask WOOSOO_REVERB_APP_ID "Reverb App ID" "woosoo"
ask_secret WOOSOO_REVERB_APP_KEY    "Reverb App Key"
ask_secret WOOSOO_REVERB_APP_SECRET "Reverb App Secret"

# ── 8. Device auth ────────────────────────────────────────────────────────────
section "Device Auth"
ask_secret WOOSOO_DEVICE_AUTH_PASSCODE "Device auth passcode"

# ── 9. Per-network POS credentials (switch-network.sh) ───────────────────────
section "Per-network POS credentials (for switch-network.sh)"
note "Only needed if you use switch-network.sh to change LAN environments."
ask HOME_DB_POS_USERNAME  "Home POS DB username" "woosoo_pos"
ask_optional_secret HOME_DB_POS_PASSWORD  "Home POS DB password"
ask RESTO_DB_POS_USERNAME "Resto POS DB username" "user_1"
ask_optional_secret RESTO_DB_POS_PASSWORD "Resto POS DB password"

# ── Write config ──────────────────────────────────────────────────────────────
section "Writing config"

mkdir -p /etc/woosoo
TMPFILE="$(mktemp /etc/woosoo/woosoo.env.XXXXXX)"

{
  printf '# Woosoo Operator Config\n'
  printf '# Generated by setup-woosoo-env.sh on %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  printf '# Edit this file, then run: sudo bash scripts/deployment/apply-woosoo-config.sh\n'
  printf '\n'

  printf '# REQUIRED\n'
  printf 'WOOSOO_HOST=%s\n'       "$(q "$WOOSOO_HOST")"
  printf 'WOOSOO_SERVER_IP=%s\n'  "$(q "$WOOSOO_SERVER_IP")"
  printf 'WOOSOO_GATEWAY=%s\n'    "$(q "$WOOSOO_GATEWAY")"
  printf 'WOOSOO_CIDR=%s\n'       "$(q "$WOOSOO_CIDR")"
  printf 'WOOSOO_NEXUS_PATH=%s\n' "$(q "$WOOSOO_NEXUS_PATH")"
  printf 'WOOSOO_SCHEME=%s\n'     "$(q "$WOOSOO_SCHEME")"
  printf '\n'

  printf '# Environment profile: local | staging | production\n'
  printf '# Drives APP_ENV / APP_DEBUG / LOG_LEVEL in the Laravel .env.\n'
  printf '# SESSION_SECURE_COOKIE is derived from WOOSOO_SCHEME (https → true).\n'
  printf 'WOOSOO_ENV=%s\n' "$(q "$WOOSOO_ENV")"
  printf '\n'

  printf '# OPTIONAL (has defaults)\n'
  printf 'WOOSOO_PLATFORM_PATH=%s\n'         "$(q "$WOOSOO_PLATFORM_PATH")"
  printf 'WOOSOO_DEPLOY_BRANCH=%s\n'         "$(q "${WOOSOO_DEPLOY_BRANCH:-dev}")"
  printf 'WOOSOO_NEXUS_BRANCH=%s\n'          "$(q "${WOOSOO_NEXUS_BRANCH:-dev}")"
  printf 'WOOSOO_TABLET_BRANCH=%s\n'         "$(q "${WOOSOO_TABLET_BRANCH:-dev}")"
  printf 'WOOSOO_DNS_FORWARDERS=%s\n'        "$(q "${WOOSOO_DNS_FORWARDERS:-1.1.1.1 8.8.8.8}")"
  printf 'WOOSOO_NM_CONNECTION=%s\n'         "$(q "${WOOSOO_NM_CONNECTION:-}")"
  printf 'WOOSOO_DOCKER_COMPOSE=%s\n'        "$(q "${WOOSOO_DOCKER_COMPOSE:-docker compose --env-file ./woosoo-nexus/.env -f compose.yaml}")"
  printf 'WOOSOO_TIMEZONE=%s\n'              "$(q "${WOOSOO_TIMEZONE:-Asia/Manila}")"
  printf '\n'

  printf '# POS (Krypton read-only)\n'
  printf 'WOOSOO_POS_HOST=%s\n'     "$(q "$WOOSOO_POS_HOST")"
  printf 'WOOSOO_POS_PORT=%s\n'     "$(q "${WOOSOO_POS_PORT:-3308}")"
  printf 'WOOSOO_POS_DATABASE=%s\n' "$(q "${WOOSOO_POS_DATABASE:-krypton_woosoo}")"
  printf 'WOOSOO_POS_USERNAME=%s\n' "$(q "${WOOSOO_POS_USERNAME:-krypton_readonly}")"
  printf 'WOOSOO_POS_PASSWORD=%s\n' "$(q "${WOOSOO_POS_PASSWORD:-}")"
  printf '\n'

  printf '# Per-network POS credentials (switch-network.sh)\n'
  printf 'HOME_DB_POS_USERNAME=%s\n'  "$(q "${HOME_DB_POS_USERNAME:-woosoo_pos}")"
  printf 'HOME_DB_POS_PASSWORD=%s\n'  "$(q "${HOME_DB_POS_PASSWORD:-}")"
  printf 'RESTO_DB_POS_USERNAME=%s\n' "$(q "${RESTO_DB_POS_USERNAME:-user_1}")"
  printf 'RESTO_DB_POS_PASSWORD=%s\n' "$(q "${RESTO_DB_POS_PASSWORD:-}")"
  printf '\n'

  printf '# Woosoo database\n'
  printf 'WOOSOO_DB_DATABASE=%s\n'      "$(q "${WOOSOO_DB_DATABASE:-woosoo}")"
  printf 'WOOSOO_DB_USERNAME=%s\n'      "$(q "${WOOSOO_DB_USERNAME:-woosoo}")"
  printf 'WOOSOO_DB_PASSWORD=%s\n'      "$(q "$WOOSOO_DB_PASSWORD")"
  printf 'WOOSOO_DB_ROOT_PASSWORD=%s\n' "$(q "$WOOSOO_DB_ROOT_PASSWORD")"
  printf '\n'

  printf '# Reverb (WebSocket)\n'
  printf 'WOOSOO_REVERB_APP_ID=%s\n'     "$(q "${WOOSOO_REVERB_APP_ID:-woosoo}")"
  printf 'WOOSOO_REVERB_APP_KEY=%s\n'    "$(q "$WOOSOO_REVERB_APP_KEY")"
  printf 'WOOSOO_REVERB_APP_SECRET=%s\n' "$(q "$WOOSOO_REVERB_APP_SECRET")"
  printf '\n'

  printf '# Device auth\n'
  printf 'WOOSOO_DEVICE_AUTH_PASSCODE=%s\n' "$(q "$WOOSOO_DEVICE_AUTH_PASSCODE")"
  printf '\n'

  printf '# Service names\n'
  printf 'WOOSOO_APP_SERVICE=%s\n'       "$(q "${WOOSOO_APP_SERVICE:-app}")"
  printf 'WOOSOO_NGINX_SERVICE=%s\n'     "$(q "${WOOSOO_NGINX_SERVICE:-nginx}")"
  printf 'WOOSOO_REVERB_SERVICE=%s\n'    "$(q "${WOOSOO_REVERB_SERVICE:-reverb}")"
  printf 'WOOSOO_QUEUE_SERVICE=%s\n'     "$(q "${WOOSOO_QUEUE_SERVICE:-queue}")"
  printf 'WOOSOO_SCHEDULER_SERVICE=%s\n' "$(q "${WOOSOO_SCHEDULER_SERVICE:-scheduler}")"
  printf 'WOOSOO_MYSQL_SERVICE=%s\n'     "$(q "${WOOSOO_MYSQL_SERVICE:-mysql}")"
  printf '\n'

  printf '# Backup\n'
  printf 'WOOSOO_BACKUP_DIR=%s\n'              "$(q "${WOOSOO_BACKUP_DIR:-/opt/woosoo/backups}")"
  printf 'WOOSOO_BACKUP_RETENTION_DAYS=%s\n'   "$(q "${WOOSOO_BACKUP_RETENTION_DAYS:-14}")"
  printf '\n'

  printf '# Deploy\n'
  printf 'WOOSOO_APPLY_STATIC_IP=%s\n' "$(q "${WOOSOO_APPLY_STATIC_IP:-true}")"
  printf 'WOOSOO_RESTART_DOCKER=%s\n'  "$(q "${WOOSOO_RESTART_DOCKER:-true}")"
  printf '# Set to true only when applying static IP over SSH and you accept the disconnect risk.\n'
  printf 'FORCE_APPLY_STATIC_IP=%s\n'  "$(q "${FORCE_APPLY_STATIC_IP:-false}")"
  printf '\n'

  printf 'WOOSOO_ALIASES=%s\n' "$(q "${WOOSOO_ALIASES:-api.woosoo.local tablet.woosoo.local}")"
} > "$TMPFILE"

chown root:root "$TMPFILE"
chmod 640 "$TMPFILE"
mv "$TMPFILE" "$CONFIG_FILE"

ok "Config written: $CONFIG_FILE"

# ── Run doctor ────────────────────────────────────────────────────────────────
echo
if [[ -f "$DOCTOR_SCRIPT" ]]; then
  read -r -p "Run doctor.sh now to verify the config? [Y/n]: " _run_doctor
  _run_doctor="${_run_doctor:-Y}"
  if [[ "$_run_doctor" =~ ^[Yy] ]]; then
    echo
    bash "$DOCTOR_SCRIPT"
  else
    echo
    note "Skipped. Run manually: sudo bash scripts/deployment/doctor.sh"
  fi
fi

printf "\n${_G}Setup complete.${_NC}\n"
printf "  Next: sudo bash scripts/deployment/deploy-all.sh\n\n"
