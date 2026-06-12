#!/usr/bin/env bash
# =============================================================================
# Woosoo Config Init
# Seeds ./woosoo.env from existing app .env files, then prompts to confirm.
#
# Usage (from platform root — no sudo needed):
#   bash scripts/deployment/init-woosoo-env.sh
#
# Re-runnable: reloads existing ./woosoo.env as starting defaults.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
NEXUS_ENV="$ROOT/woosoo-nexus/.env"
OUT="$ROOT/woosoo.env"

Y='\033[1;33m'; G='\033[0;32m'; B='\033[1m'; NC='\033[0m'
note() { printf "${Y}[!]${NC} %s\n" "$*"; }
ok()   { printf "${G}[ok]${NC} %s\n" "$*"; }
hdr()  { printf "\n${B}%s${NC}\n" "$*"; }

# Read a single value from a .env file (strips surrounding quotes)
ev() { grep -E "^${2}=" "$1" 2>/dev/null | head -1 | sed 's/^[^=]*=//; s/^"//; s/"$//'; }

# Confirm or replace a value: ask VAR "label" "current"
ask() {
  local var="$1" label="$2" cur="${3:-}"
  local masked=""
  # Mask secrets in display
  case "$label" in *password*|*PASSWORD*|*secret*|*SECRET*|*passcode*|*PASSCODE*|*key*|*KEY*)
    [[ -n "$cur" ]] && masked="****" || masked="(empty)" ;;
  esac

  local shown="${masked:-$cur}"
  [[ -z "$shown" ]] && shown="(empty)"

  local input
  printf "  ${B}%-30s${NC} [%s]: " "$label" "$shown"
  read -r input
  # For masked fields, empty input = keep current
  if [[ -z "$input" ]]; then
    printf -v "$var" '%s' "$cur"
  else
    printf -v "$var" '%s' "$input"
  fi
}

# ── Load nexus .env for initial values ────────────────────────────────────────
if [[ -f "$NEXUS_ENV" ]]; then
  ok "Reading: $NEXUS_ENV"
else
  note "woosoo-nexus/.env not found — starting from scratch"
fi

_n() { [[ -f "$NEXUS_ENV" ]] && ev "$NEXUS_ENV" "$1" || true; }

# ── Load existing woosoo.env as override defaults ─────────────────────────────
[[ -f "$OUT" ]] && { note "Loading existing $OUT"; set -a; source "$OUT"; set +a; }

# Auto-detect network values from host interfaces
_auto_ip="$(ip -4 addr 2>/dev/null | grep -oE '192\.[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
_auto_gw="$(ip route 2>/dev/null | awk '/default via/{print $3; exit}' || true)"

# Merge: woosoo.env > nexus/.env > auto-detect > hardcoded defaults
WOOSOO_HOST="${WOOSOO_HOST:-$(_n PUBLIC_HOST)}"
WOOSOO_HOST="${WOOSOO_HOST:-woosoo.local}"
WOOSOO_SERVER_IP="${WOOSOO_SERVER_IP:-$_auto_ip}"
WOOSOO_GATEWAY="${WOOSOO_GATEWAY:-$_auto_gw}"
WOOSOO_CIDR="${WOOSOO_CIDR:-24}"
WOOSOO_SCHEME="${WOOSOO_SCHEME:-$(_n PUBLIC_SCHEME)}"; WOOSOO_SCHEME="${WOOSOO_SCHEME:-https}"
WOOSOO_ENV="${WOOSOO_ENV:-production}"
WOOSOO_NEXUS_PATH="${WOOSOO_NEXUS_PATH:-$ROOT/woosoo-nexus}"
WOOSOO_PLATFORM_PATH="${WOOSOO_PLATFORM_PATH:-$ROOT}"

WOOSOO_POS_HOST="${WOOSOO_POS_HOST:-$(_n DB_POS_HOST)}"
WOOSOO_POS_PORT="${WOOSOO_POS_PORT:-$(_n DB_POS_PORT)}"; WOOSOO_POS_PORT="${WOOSOO_POS_PORT:-3308}"
WOOSOO_POS_DATABASE="${WOOSOO_POS_DATABASE:-$(_n DB_POS_DATABASE)}"; WOOSOO_POS_DATABASE="${WOOSOO_POS_DATABASE:-krypton_woosoo}"
WOOSOO_POS_USERNAME="${WOOSOO_POS_USERNAME:-$(_n DB_POS_USERNAME)}"; WOOSOO_POS_USERNAME="${WOOSOO_POS_USERNAME:-krypton_readonly}"
WOOSOO_POS_PASSWORD="${WOOSOO_POS_PASSWORD:-$(_n DB_POS_PASSWORD)}"

# Per-network POS credentials for switch-network.sh (home vs resto LAN).
HOME_DB_POS_USERNAME="${HOME_DB_POS_USERNAME:-woosoo_pos}"
HOME_DB_POS_PASSWORD="${HOME_DB_POS_PASSWORD:-}"
RESTO_DB_POS_USERNAME="${RESTO_DB_POS_USERNAME:-user_1}"
RESTO_DB_POS_PASSWORD="${RESTO_DB_POS_PASSWORD:-}"

WOOSOO_DB_DATABASE="${WOOSOO_DB_DATABASE:-$(_n DB_DATABASE)}"; WOOSOO_DB_DATABASE="${WOOSOO_DB_DATABASE:-woosoo}"
WOOSOO_DB_USERNAME="${WOOSOO_DB_USERNAME:-$(_n DB_USERNAME)}"; WOOSOO_DB_USERNAME="${WOOSOO_DB_USERNAME:-woosoo}"
WOOSOO_DB_PASSWORD="${WOOSOO_DB_PASSWORD:-$(_n DB_PASSWORD)}"
WOOSOO_DB_ROOT_PASSWORD="${WOOSOO_DB_ROOT_PASSWORD:-$(_n DB_ROOT_PASSWORD)}"

WOOSOO_REVERB_APP_ID="${WOOSOO_REVERB_APP_ID:-$(_n REVERB_APP_ID)}"; WOOSOO_REVERB_APP_ID="${WOOSOO_REVERB_APP_ID:-woosoo}"
WOOSOO_REVERB_APP_KEY="${WOOSOO_REVERB_APP_KEY:-$(_n REVERB_APP_KEY)}"
WOOSOO_REVERB_APP_SECRET="${WOOSOO_REVERB_APP_SECRET:-$(_n REVERB_APP_SECRET)}"
WOOSOO_DEVICE_AUTH_PASSCODE="${WOOSOO_DEVICE_AUTH_PASSCODE:-$(_n DEVICE_AUTH_PASSCODE)}"

# Auto-generate placeholder Reverb keys
_is_placeholder() { case "$1" in ""|"dev-reverb-"*|"change_this"*|"your_"*|"REVERB_APP_KEY_REQUIRED") return 0;; *) return 1;; esac; }
if _is_placeholder "$WOOSOO_REVERB_APP_KEY";    then WOOSOO_REVERB_APP_KEY="$(openssl rand -hex 32)";    note "Generated WOOSOO_REVERB_APP_KEY"; fi
if _is_placeholder "$WOOSOO_REVERB_APP_SECRET"; then WOOSOO_REVERB_APP_SECRET="$(openssl rand -hex 32)"; note "Generated WOOSOO_REVERB_APP_SECRET"; fi

# ── Interactive confirm ───────────────────────────────────────────────────────
printf "\n========================================\n"
printf "  Woosoo Config Init  →  %s\n" "$OUT"
printf "  Press Enter to keep shown value.\n"
printf "========================================\n"

hdr "Network"
ask WOOSOO_HOST      "WOOSOO_HOST (admin/tablet reach)" "$WOOSOO_HOST"
ask WOOSOO_SERVER_IP "WOOSOO_SERVER_IP"                 "$WOOSOO_SERVER_IP"
ask WOOSOO_GATEWAY   "WOOSOO_GATEWAY"                   "$WOOSOO_GATEWAY"
ask WOOSOO_CIDR      "WOOSOO_CIDR"                      "$WOOSOO_CIDR"
ask WOOSOO_SCHEME    "WOOSOO_SCHEME (https/http)"        "$WOOSOO_SCHEME"
ask WOOSOO_ENV       "WOOSOO_ENV (local/staging/production)" "$WOOSOO_ENV"

hdr "Paths  (auto-derived — change only if repos are elsewhere)"
ask WOOSOO_NEXUS_PATH    "WOOSOO_NEXUS_PATH"    "$WOOSOO_NEXUS_PATH"
ask WOOSOO_PLATFORM_PATH "WOOSOO_PLATFORM_PATH" "$WOOSOO_PLATFORM_PATH"

hdr "POS database (Krypton read-only)"
ask WOOSOO_POS_HOST     "WOOSOO_POS_HOST"     "$WOOSOO_POS_HOST"
ask WOOSOO_POS_PORT     "WOOSOO_POS_PORT"     "$WOOSOO_POS_PORT"
ask WOOSOO_POS_DATABASE "WOOSOO_POS_DATABASE" "$WOOSOO_POS_DATABASE"
ask WOOSOO_POS_USERNAME "WOOSOO_POS_USERNAME" "$WOOSOO_POS_USERNAME"
ask WOOSOO_POS_PASSWORD "WOOSOO_POS_PASSWORD" "$WOOSOO_POS_PASSWORD"

hdr "Network switch (switch-network.sh home/resto)"
note "Resto POS uses port 2121; home uses 3308. switch-network.sh reads these per-network creds."
ask HOME_DB_POS_USERNAME "HOME_DB_POS_USERNAME (home 192.168.100.x)" "$HOME_DB_POS_USERNAME"
ask HOME_DB_POS_PASSWORD "HOME_DB_POS_PASSWORD" "$HOME_DB_POS_PASSWORD"
ask RESTO_DB_POS_USERNAME "RESTO_DB_POS_USERNAME (resto 192.168.1.32)" "$RESTO_DB_POS_USERNAME"
ask RESTO_DB_POS_PASSWORD "RESTO_DB_POS_PASSWORD" "$RESTO_DB_POS_PASSWORD"

hdr "Woosoo database"
ask WOOSOO_DB_DATABASE      "WOOSOO_DB_DATABASE"      "$WOOSOO_DB_DATABASE"
ask WOOSOO_DB_USERNAME      "WOOSOO_DB_USERNAME"       "$WOOSOO_DB_USERNAME"
ask WOOSOO_DB_PASSWORD      "WOOSOO_DB_PASSWORD"      "$WOOSOO_DB_PASSWORD"
ask WOOSOO_DB_ROOT_PASSWORD "WOOSOO_DB_ROOT_PASSWORD" "$WOOSOO_DB_ROOT_PASSWORD"

hdr "Reverb (WebSocket)"
ask WOOSOO_REVERB_APP_ID     "WOOSOO_REVERB_APP_ID"     "$WOOSOO_REVERB_APP_ID"
ask WOOSOO_REVERB_APP_KEY    "WOOSOO_REVERB_APP_KEY"    "$WOOSOO_REVERB_APP_KEY"
ask WOOSOO_REVERB_APP_SECRET "WOOSOO_REVERB_APP_SECRET" "$WOOSOO_REVERB_APP_SECRET"

hdr "Device auth"
ask WOOSOO_DEVICE_AUTH_PASSCODE "WOOSOO_DEVICE_AUTH_PASSCODE" "$WOOSOO_DEVICE_AUTH_PASSCODE"

# ── Write ./woosoo.env ────────────────────────────────────────────────────────
q() { local v="${1//\\/\\\\}"; v="${v//\"/\\\"}"; v="${v//\$/\\$}"; printf '"%s"' "$v"; }

cat > "$OUT" <<ENVEOF
# Woosoo Operator Config — generated $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Edit freely; re-run init-woosoo-env.sh to regenerate from app .envs.
# NEVER commit this file (it contains secrets).

WOOSOO_HOST=$(q "$WOOSOO_HOST")
WOOSOO_SERVER_IP=$(q "$WOOSOO_SERVER_IP")
WOOSOO_GATEWAY=$(q "$WOOSOO_GATEWAY")
WOOSOO_CIDR=$(q "$WOOSOO_CIDR")
WOOSOO_SCHEME=$(q "$WOOSOO_SCHEME")
WOOSOO_ENV=$(q "$WOOSOO_ENV")
WOOSOO_NEXUS_PATH=$(q "$WOOSOO_NEXUS_PATH")
WOOSOO_PLATFORM_PATH=$(q "$WOOSOO_PLATFORM_PATH")

WOOSOO_POS_HOST=$(q "$WOOSOO_POS_HOST")
WOOSOO_POS_PORT=$(q "$WOOSOO_POS_PORT")
WOOSOO_POS_DATABASE=$(q "$WOOSOO_POS_DATABASE")
WOOSOO_POS_USERNAME=$(q "$WOOSOO_POS_USERNAME")
WOOSOO_POS_PASSWORD=$(q "$WOOSOO_POS_PASSWORD")

HOME_DB_POS_USERNAME=$(q "$HOME_DB_POS_USERNAME")
HOME_DB_POS_PASSWORD=$(q "$HOME_DB_POS_PASSWORD")
RESTO_DB_POS_USERNAME=$(q "$RESTO_DB_POS_USERNAME")
RESTO_DB_POS_PASSWORD=$(q "$RESTO_DB_POS_PASSWORD")

WOOSOO_DB_DATABASE=$(q "$WOOSOO_DB_DATABASE")
WOOSOO_DB_USERNAME=$(q "$WOOSOO_DB_USERNAME")
WOOSOO_DB_PASSWORD=$(q "$WOOSOO_DB_PASSWORD")
WOOSOO_DB_ROOT_PASSWORD=$(q "$WOOSOO_DB_ROOT_PASSWORD")

WOOSOO_REVERB_APP_ID=$(q "$WOOSOO_REVERB_APP_ID")
WOOSOO_REVERB_APP_KEY=$(q "$WOOSOO_REVERB_APP_KEY")
WOOSOO_REVERB_APP_SECRET=$(q "$WOOSOO_REVERB_APP_SECRET")

WOOSOO_DEVICE_AUTH_PASSCODE=$(q "$WOOSOO_DEVICE_AUTH_PASSCODE")

# Deploy branches (defaults to dev — override per-repo only when needed)
WOOSOO_DEPLOY_BRANCH="${WOOSOO_DEPLOY_BRANCH:-dev}"
WOOSOO_NEXUS_BRANCH="${WOOSOO_NEXUS_BRANCH:-dev}"
WOOSOO_TABLET_BRANCH="${WOOSOO_TABLET_BRANCH:-dev}"
ENVEOF

chmod 600 "$OUT"
ok "Written: $OUT"
printf "\n  Next: %s\n\n" "WOOSOO_ALLOW_NON_PI=true sudo -E bash scripts/deployment/deploy-all.sh"
