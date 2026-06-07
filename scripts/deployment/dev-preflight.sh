#!/usr/bin/env bash
# =============================================================================
# scripts/deployment/dev-preflight.sh — Dev preflight checker + auto-fixer
# =============================================================================
# Run before every dev deploy. Detects and (where safe) automatically fixes
# configuration drift that causes deployment failures.
#
# Usage:
#   bash scripts/deployment/dev-preflight.sh           # check + auto-fix
#   bash scripts/deployment/dev-preflight.sh --dry-run # check only, no writes
#
# Exit codes:
#   0 = all checks passed (or auto-fixed)
#   1 = hard failure requiring manual action
#
# What it checks and fixes:
#   [AUTO-FIX] REVERB host vars (VITE, NUXT_PUBLIC, APP_RUNTIME) out of sync
#              with PUBLIC_HOST in nexus .env
#   [AUTO-FIX] REVERB_APP_KEY variants out of sync with canonical REVERB_APP_KEY
#   [AUTO-FIX] REVERB_ALLOWED_ORIGINS synced to PUBLIC_HOST (stale IPs pruned)
#   [AUTO-FIX] SESSION_DOMAIN pinned to an IP/hostname (causes 419s)
#   [AUTO-FIX] API URL vars (NUXT_PUBLIC_API_BASE_URL, etc.) pointing to wrong host
#   [CHECK]    Docker daemon running
#   [CHECK]    App repos present
#   [CHECK]    APP_KEY set in nexus .env
#   [CHECK]    Secrets are non-placeholder
#   [CHECK]    Ports 80/443/4443/8080/3306/6379 not conflicted by external processes
#   [CHECK]    vendor/autoload.php present (bind-mount target)
#   [AUTO-FIX] DB_POS_HOST=host.docker.internal on WSL → Windows LAN IP (PUBLIC_HOST)
#   [WARN]     PUBLIC_HOST drift vs detected LAN IP (no auto-write unless WOOSOO_AUTO_SYNC=1)
#   [WARN]     TLS cert SAN mismatch vs PUBLIC_HOST
#   [WARN]     DB_POS_PASSWORD unset (Krypton readonly creds)
#   [WARN]     .env.docker SESSION_DOMAIN / REVERB_BROADCAST_HOST drift vs .env
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
NEXUS_ENV="$PLATFORM_ROOT/woosoo-nexus/.env"
TABLET_ENV="$PLATFORM_ROOT/tablet-ordering-pwa/.env"

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

# ── Output helpers ─────────────────────────────────────────────────────────────
PASS=0; WARN=0; FAIL=0; FIXED=0
if [[ -t 1 ]]; then
  G='\033[0;32m'; Y='\033[0;33m'; R='\033[0;31m'; C='\033[0;36m'; B='\033[1m'; NC='\033[0m'
else
  G=''; Y=''; R=''; C=''; B=''; NC=''
fi
_pass()  { printf "${G}[PASS ]${NC} %s\n" "$*"; PASS=$(( PASS+1 )); }
_warn()  { printf "${Y}[WARN ]${NC} %s\n" "$*"; WARN=$(( WARN+1 )); }
_fail()  { printf "${R}[FAIL ]${NC} %s\n" "$*"; FAIL=$(( FAIL+1 )); }
_fix()   { printf "${C}[FIX  ]${NC} %s\n" "$*"; FIXED=$(( FIXED+1 )); }
_skip()  { printf "${Y}[SKIP ]${NC} %s (dry-run)\n" "$*"; }
_sec()   { printf "\n${B}── %s ──${NC}\n" "$*"; }

# ── Env read/write helpers ─────────────────────────────────────────────────────

# Read a value from an env file: env_get KEY FILE
env_get() {
  local key="$1" file="$2"
  grep -E "^${key}=" "$file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'"
}

# Write/update a key in an env file: env_set KEY VALUE FILE
# Uses the same sed approach as apply-woosoo-config.sh.
env_set() {
  local key="$1" value="$2" file="$3"
  if (( DRY_RUN )); then
    _skip "would set ${key}=\"${value}\" in $(basename "$file")"
    return 0
  fi
  local escaped_key escaped_value
  escaped_key="$(printf '%s' "$key" | sed 's/[[\.*^$()+?{|]/\\&/g')"
  # Quote value and escape internal double-quotes
  local quoted; quoted="\"$(printf '%s' "$value" | sed 's/"/\\"/g')\""
  if grep -qE "^${escaped_key}=" "$file" 2>/dev/null; then
    sed -i "s|^${escaped_key}=.*|${key}=${quoted}|" "$file" || return 1
  else
    printf '%s=%s\n' "$key" "$quoted" >> "$file" || return 1
  fi
}

# Append a value to a comma-separated list if not already present
env_list_append() {
  local key="$1" new_val="$2" file="$3"
  local current; current="$(env_get "$key" "$file")"
  if echo "$current" | grep -qF "$new_val"; then
    return 0  # already present
  fi
  local updated
  if [[ -z "$current" ]]; then
    updated="$new_val"
  else
    updated="${current},${new_val}"
  fi
  env_set "$key" "$updated" "$file"
}

# ── Banner ─────────────────────────────────────────────────────────────────────
printf "\n${B}══════════════════════════════════════════════${NC}\n"
printf "${B}  Woosoo Dev Preflight  (auto-fix enabled)${NC}\n"
(( DRY_RUN )) && printf "${Y}  DRY-RUN: no writes${NC}\n"
printf "${B}══════════════════════════════════════════════${NC}\n"

# =============================================================================
# 1. Hard prerequisites (fail fast if these are missing)
# =============================================================================
_sec "Prerequisites"

# Docker daemon
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  _pass "Docker daemon running ($(docker version --format '{{.Server.Version}}' 2>/dev/null || echo '?'))"
else
  _fail "Docker daemon not running — start it first"
  printf "       FIX: sudo service docker start\n"
  exit 1
fi

# App repos
for _r in woosoo-nexus tablet-ordering-pwa; do
  if [[ -d "$PLATFORM_ROOT/$_r/.git" ]]; then
    _pass "$_r present"
  else
    _fail "$_r not found at $PLATFORM_ROOT/$_r"
    printf "       FIX: git clone <url> %s/%s\n" "$PLATFORM_ROOT" "$_r"
    exit 1
  fi
done

# nexus .env
if [[ ! -f "$NEXUS_ENV" ]]; then
  _fail "woosoo-nexus/.env missing"
  printf "       FIX: woosoo dev  (pipeline runs bootstrap automatically)\n"
  exit 1
fi
_pass "nexus .env present"

# =============================================================================
# 1b. Host network (PUBLIC_HOST drift + TLS SAN — warn only)
# =============================================================================
_sec "Host network (PUBLIC_HOST)"

# shellcheck source=scripts/lib/host-network.sh
source "$PLATFORM_ROOT/scripts/lib/host-network.sh"
export HOST_NETWORK_DRY_RUN="$DRY_RUN"
export HOST_NETWORK_PLATFORM_ROOT="$PLATFORM_ROOT"
export HOST_NETWORK_NEXUS_ENV="$NEXUS_ENV"

woosoo_check_public_host_drift
woosoo_check_tls_san

if [[ "${WOOSOO_AUTO_SYNC:-0}" == "1" ]]; then
  if (( DRY_RUN )); then
    _skip "WOOSOO_AUTO_SYNC=1 would sync PUBLIC_HOST to detected LAN IP"
  else
    if woosoo_sync_public_host; then
      _fix "WOOSOO_AUTO_SYNC=1: synced PUBLIC_HOST to detected LAN IP"
    else
      _warn "WOOSOO_AUTO_SYNC=1: sync failed — run: woosoo network"
    fi
  fi
fi

# =============================================================================
# 1c. POS DB host (WSL → Windows LAN IP for Krypton on :3308)
# =============================================================================
_sec "POS DB host (DB_POS_HOST)"

_pos_before="$(env_get DB_POS_HOST "$NEXUS_ENV")"
_pos_port="$(env_get DB_POS_PORT "$NEXUS_ENV")"
_pos_port="${_pos_port:-3308}"

if woosoo_check_pos_db_host; then
  _pos_after="$(env_get DB_POS_HOST "$NEXUS_ENV")"
  if [[ "$_pos_before" != "$_pos_after" ]]; then
    _fix "DB_POS_HOST: \"${_pos_before:-empty}\" → \"${_pos_after}\" (WSL → Windows LAN)"
    woosoo_print_nexus_env_reload_steps
  else
    _pass "DB_POS_HOST=${_pos_after:-unset}"
  fi
else
  _warn "DB_POS_HOST=${_pos_before:-unset} — expected Windows LAN IP for WSL dev (Krypton :${_pos_port})"
  printf "       Run: woosoo check  (auto-fixes host.docker.internal) or set DB_POS_HOST in woosoo-nexus/.env\n"
fi

_pos_pwd="$(env_get DB_POS_PASSWORD "$NEXUS_ENV")"
if [[ -z "$_pos_pwd" ]]; then
  _warn "DB_POS_PASSWORD unset — admin POS pages need Krypton readonly password after TCP connects"
  printf "       Set DB_POS_PASSWORD in woosoo-nexus/.env from Krypton POS admin\n"
else
  _pass "DB_POS_PASSWORD is set"
fi

# =============================================================================
# 1d. .env.docker drift (queue + scheduler overlay only)
# =============================================================================
_sec ".env.docker drift (queue + scheduler)"

ENV_DOCKER="$PLATFORM_ROOT/woosoo-nexus/.env.docker"
if [[ ! -f "$ENV_DOCKER" ]]; then
  _pass ".env.docker absent (queue/scheduler use .env only)"
else
  _docker_drift=0
  for _dk in SESSION_DOMAIN REVERB_BROADCAST_HOST; do
    _main_val="$(env_get "$_dk" "$NEXUS_ENV")"
    _dock_val="$(env_get "$_dk" "$ENV_DOCKER")"
    if [[ -n "$_dock_val" && "$_main_val" != "$_dock_val" ]]; then
      _warn ".env.docker ${_dk}=\"${_dock_val}\" drifts from .env (\"${_main_val:-empty}\") — queue/scheduler may hit wrong host/session"
      _docker_drift=1
    fi
  done
  if (( _docker_drift == 0 )); then
    _pass ".env.docker SESSION_DOMAIN and REVERB_BROADCAST_HOST align with .env"
  else
    printf "       Align keys in woosoo-nexus/.env.docker or remove the file; then force-recreate queue scheduler\n"
  fi
fi

# =============================================================================
# 2. APP_KEY
# =============================================================================
_sec "APP_KEY"

_app_key="$(env_get APP_KEY "$NEXUS_ENV")"
if [[ "$_app_key" =~ ^base64: ]]; then
  _pass "APP_KEY is set"
elif [[ -z "$_app_key" ]]; then
  _warn "APP_KEY missing — will be generated after stack starts (pipeline step 4)"
else
  _warn "APP_KEY looks wrong (expected base64:... prefix)"
fi

# =============================================================================
# 3. SESSION_DOMAIN
# =============================================================================
_sec "SESSION_DOMAIN (must be empty to avoid 419s on multi-host dev)"

_sd="$(env_get SESSION_DOMAIN "$NEXUS_ENV")"
if [[ -n "$_sd" ]]; then
  if env_set SESSION_DOMAIN "" "$NEXUS_ENV"; then
    _fix "SESSION_DOMAIN was \"${_sd}\" — clearing to empty"
  else
    _fail "failed to clear SESSION_DOMAIN in woosoo-nexus/.env"
  fi
else
  _pass "SESSION_DOMAIN is empty"
fi

# =============================================================================
# 4. Reverb alignment
# =============================================================================
_sec "Reverb config alignment"

_pub_host="$(env_get PUBLIC_HOST "$NEXUS_ENV")"
_reverb_key="$(env_get REVERB_APP_KEY "$NEXUS_ENV")"
_scheme="$(env_get PUBLIC_SCHEME "$NEXUS_ENV")"
_scheme="${_scheme:-https}"

if [[ -z "$_pub_host" ]]; then
  _fail "PUBLIC_HOST is not set in nexus .env — cannot align Reverb vars"
  printf "       FIX: re-run dev-docker-bootstrap.sh\n"
elif [[ -z "$_reverb_key" || "$_reverb_key" == "REVERB_APP_KEY_REQUIRED" || "$_reverb_key" == "change_this_reverb_key" ]]; then
  _fail "REVERB_APP_KEY is unset or placeholder (\"${_reverb_key:-empty}\") — compose will inject REVERB_APP_KEY_REQUIRED into tablet"
  printf "       FIX: set REVERB_APP_KEY to a unique value in woosoo-nexus/.env\n"
else
  _pass "PUBLIC_HOST=$_pub_host  REVERB_APP_KEY=${_reverb_key:0:20}..."

  # ── 4a. Host vars ── all derived from PUBLIC_HOST ────────────────────────────
  # Authoritative source: PUBLIC_HOST
  # Maps: VITE_REVERB_HOST, NUXT_PUBLIC_REVERB_HOST, APP_RUNTIME_REVERB_HOST
  #       NUXT_PUBLIC_API_BASE_URL, APP_RUNTIME_API_BASE_URL, MAIN_API_URL
  declare -A _host_checks=(
    [VITE_REVERB_HOST]="$_pub_host"
    [NUXT_PUBLIC_REVERB_HOST]="$_pub_host"
    [APP_RUNTIME_REVERB_HOST]="$_pub_host"
    [REVERB_PUBLIC_HOST]="$_pub_host"
  )
  for _k in "${!_host_checks[@]}"; do
    _expected="${_host_checks[$_k]}"
    _current="$(env_get "$_k" "$NEXUS_ENV")"
    if [[ "$_current" != "$_expected" ]]; then
      if env_set "$_k" "$_expected" "$NEXUS_ENV"; then
        _fix "${_k}: \"${_current}\" → \"${_expected}\""
      else
        _fail "failed to write ${_k} to woosoo-nexus/.env"
      fi
    else
      _pass "${_k}=${_current}"
    fi
  done

  # URL vars that embed the host
  declare -A _url_checks=(
    [NUXT_PUBLIC_API_BASE_URL]="${_scheme}://${_pub_host}/api"
    [APP_RUNTIME_API_BASE_URL]="${_scheme}://${_pub_host}/api"
    [MAIN_API_URL]="${_scheme}://${_pub_host}"
  )
  for _k in "${!_url_checks[@]}"; do
    _expected="${_url_checks[$_k]}"
    _current="$(env_get "$_k" "$NEXUS_ENV")"
    if [[ "$_current" != "$_expected" ]]; then
      if env_set "$_k" "$_expected" "$NEXUS_ENV"; then
        _fix "${_k}: \"${_current}\" → \"${_expected}\""
      else
        _fail "failed to write ${_k} to woosoo-nexus/.env"
      fi
    else
      _pass "${_k}=${_current}"
    fi
  done

  # ── 4b. REVERB_APP_KEY variants ─────────────────────────────────────────────
  for _k in VITE_REVERB_APP_KEY NUXT_PUBLIC_REVERB_APP_KEY APP_RUNTIME_REVERB_APP_KEY NUXT_PUBLIC_PUSHER_KEY; do
    _current="$(env_get "$_k" "$NEXUS_ENV")"
    if [[ "$_current" != "$_reverb_key" ]]; then
      if env_set "$_k" "$_reverb_key" "$NEXUS_ENV"; then
        _fix "${_k}: \"${_current}\" → \"${_reverb_key:0:20}...\""
      else
        _fail "failed to write ${_k} to woosoo-nexus/.env"
      fi
    else
      _pass "${_k} matches REVERB_APP_KEY"
    fi
  done

  # ── 4c. REVERB_ALLOWED_ORIGINS must include PUBLIC_HOST (prune stale IPs) ───
  _allowed="$(env_get REVERB_ALLOWED_ORIGINS "$NEXUS_ENV")"
  _expected="$(woosoo_reverb_allowed_origins_sync "$_pub_host" "$_allowed" "")"
  if [[ "$_allowed" == "$_expected" ]]; then
    _pass "REVERB_ALLOWED_ORIGINS includes $_pub_host"
  else
    if env_set REVERB_ALLOWED_ORIGINS "$_expected" "$NEXUS_ENV"; then
      _fix "REVERB_ALLOWED_ORIGINS → \"${_expected}\" (synced; stale IPs pruned)"
    else
      _fail "failed to write REVERB_ALLOWED_ORIGINS to woosoo-nexus/.env"
    fi
  fi

  # ── 4d. tablet-ordering-pwa/.env (used by Nuxt dev server / tablet-pwa-dev) ─
  if [[ -f "$TABLET_ENV" ]]; then
    _t_key="$(env_get NUXT_PUBLIC_REVERB_APP_KEY "$TABLET_ENV")"
    _t_host="$(env_get NUXT_PUBLIC_REVERB_HOST "$TABLET_ENV")"
    if [[ -n "$_t_key" && "$_t_key" != "$_reverb_key" ]]; then
      if env_set NUXT_PUBLIC_REVERB_APP_KEY "$_reverb_key" "$TABLET_ENV"; then
        _fix "tablet/.env NUXT_PUBLIC_REVERB_APP_KEY out of sync — aligning"
      else
        _fail "failed to write NUXT_PUBLIC_REVERB_APP_KEY to tablet-ordering-pwa/.env"
      fi
    fi
    if [[ -n "$_t_host" && "$_t_host" != "$_pub_host" ]]; then
      if env_set NUXT_PUBLIC_REVERB_HOST "$_pub_host" "$TABLET_ENV"; then
        _fix "tablet/.env NUXT_PUBLIC_REVERB_HOST: \"${_t_host}\" → \"${_pub_host}\""
      else
        _fail "failed to write NUXT_PUBLIC_REVERB_HOST to tablet-ordering-pwa/.env"
      fi
    fi
    for _k in NUXT_PUBLIC_API_BASE_URL APP_RUNTIME_API_BASE_URL MAIN_API_URL; do
      _t_url="$(env_get "$_k" "$TABLET_ENV")"
      _expected_url="${_scheme}://${_pub_host}$(echo "$_t_url" | grep -o '/api$' || true)"
      if [[ -n "$_t_url" && "$_t_url" != *"$_pub_host"* ]]; then
        _new_url="${_scheme}://${_pub_host}$(echo "$_t_url" | sed "s|https\?://[^/]*||")"
        if env_set "$_k" "$_new_url" "$TABLET_ENV"; then
          _fix "tablet/.env ${_k}: updating host to $_pub_host"
        else
          _fail "failed to write ${_k} to tablet-ordering-pwa/.env"
        fi
      fi
    done
  fi
fi

# =============================================================================
# 5. Placeholder secrets
# =============================================================================
_sec "Secrets (placeholder check)"

_check_placeholder() {
  local key="$1" file="$2"
  local val; val="$(env_get "$key" "$file")"
  if [[ "$val" =~ (change_this|please_rotate|REQUIRED|changeme|password123|your_|example) ]]; then
    _warn "${key} looks like a placeholder: \"${val:0:40}\""
    printf "       NOTE: safe for dev; MUST be changed before production\n"
  fi
}
_check_placeholder REVERB_APP_SECRET "$NEXUS_ENV"
_check_placeholder DB_PASSWORD       "$NEXUS_ENV"
_check_placeholder DB_ROOT_PASSWORD  "$NEXUS_ENV"

# =============================================================================
# 6. Port conflicts
# =============================================================================
_sec "Port availability"

_check_port() {
  local port="$1" service="$2"
  # Check if something OTHER than docker is using the port (ss or netstat)
  local in_use=false
  if command -v ss >/dev/null 2>&1; then
    ss -tlnp 2>/dev/null | grep -qE ":${port}\b" && in_use=true
  elif command -v netstat >/dev/null 2>&1; then
    netstat -tlnp 2>/dev/null | grep -qE ":${port}\b" && in_use=true
  fi
  if $in_use; then
    # Distinguish docker vs external
    if ss -tlnp 2>/dev/null | grep -E ":${port}\b" | grep -q docker 2>/dev/null; then
      _pass "port $port in use by docker ($service)"
    else
      _warn "port $port may conflict with external process — check: ss -tlnp | grep :${port}"
    fi
  else
    _pass "port $port available ($service)"
  fi
}

_check_port 80   "nginx HTTP"
_check_port 443  "nginx HTTPS"
_check_port 4443 "nginx tablet"
_check_port 8080 "reverb WS"
_check_port 3306 "mysql"
_check_port 6379 "redis"

# =============================================================================
# 7. PHP vendor
# =============================================================================
_sec "PHP vendor"

if [[ -f "$PLATFORM_ROOT/woosoo-nexus/vendor/autoload.php" ]]; then
  _pass "vendor/autoload.php present (bind-mount target OK)"
else
  _warn "vendor/autoload.php missing — pipeline will install via composer"
  printf "       This is normal on a fresh clone. 'woosoo dev' handles it.\n"
fi

# =============================================================================
# Summary
# =============================================================================
printf "\n${B}══════════════════════════════════════════════${NC}\n"
if (( FAIL > 0 )); then
  printf "${R}${B}  Preflight FAILED${NC}  pass:${PASS} fixed:${FIXED} warn:${WARN} fail:${FAIL}\n"
  printf "${B}══════════════════════════════════════════════${NC}\n\n"
  exit 1
elif (( FIXED > 0 )); then
  printf "${C}${B}  Preflight PASSED (${FIXED} auto-fixed)${NC}  pass:${PASS} warn:${WARN}\n"
  if (( ! DRY_RUN )); then
    printf "\n${Y}  .env was modified — apply before testing:${NC}\n"
    woosoo_print_nexus_env_reload_steps
  else
    printf "${Y}  No changes written (dry-run)${NC}\n"
  fi
else
  printf "${G}${B}  Preflight PASSED${NC}  pass:${PASS} warn:${WARN}\n"
fi
printf "${B}══════════════════════════════════════════════${NC}\n\n"
exit 0
