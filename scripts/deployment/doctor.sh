#!/usr/bin/env bash
# =============================================================================
# Woosoo Pi Docker Runtime Preflight Doctor
# =============================================================================
# Diagnostic only. This script validates production deployment prerequisites.
# It does not edit compose files, nginx config, env files, Docker resources, or
# application code.
#
# Usage:
#   sudo bash scripts/deployment/doctor.sh
#
# Exit codes:
#   0 = all required checks passed
#   1 = one or more required checks failed
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PLATFORM_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
if [[ -z "${CONFIG_FILE:-}" ]]; then
  if [[ -f "$_PLATFORM_ROOT/woosoo.env" ]]; then
    CONFIG_FILE="$_PLATFORM_ROOT/woosoo.env"
  else
    CONFIG_FILE="/etc/woosoo/woosoo.env"
  fi
fi

# Validate the config before sourcing it (doctor runs under sudo via deploy/deploy-all).
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_config-guard.sh"
woosoo_assert_safe_config "$CONFIG_FILE" || exit 1

PASS=0
WARN=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $*"; PASS=$((PASS + 1)); }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; WARN=$((WARN + 1)); }
fail() { echo -e "${RED}[FAIL]${NC} $*"; FAIL=$((FAIL + 1)); }
info() { echo "[INFO] $*"; }
section() { echo; echo "== $* =="; }

require_command() {
  local command_name="$1"

  if command -v "$command_name" >/dev/null 2>&1; then
    pass "command available: $command_name"
  else
    fail "missing required command: $command_name"
  fi
}

check_required() {
  local var_name="$1"
  shift || true

  local var_value="${!var_name:-}"
  if [[ -z "$var_value" ]]; then
    fail "$var_name is not set"
    return 0
  fi

  local forbidden
  for forbidden in "$@"; do
    if [[ "$var_value" == "$forbidden" ]]; then
      fail "$var_name is using placeholder value: $forbidden"
      return 0
    fi
  done

  pass "$var_name is set"
}

compose() {
  (
    cd "$WOOSOO_PLATFORM_PATH"
    # WOOSOO_DOCKER_COMPOSE is intentionally a command string from the root-owned
    # deployment config. Keep it unquoted so configured compose flags are honored.
    # shellcheck disable=SC2086
    $WOOSOO_DOCKER_COMPOSE "$@"
  )
}

service_is_disabled() {
  local service_name="$1"
  local state

  if ! command -v systemctl >/dev/null 2>&1; then
    warn "systemctl unavailable; cannot check $service_name enablement"
    return 0
  fi

  state="$(systemctl is-enabled "$service_name" 2>/dev/null || true)"
  case "$state" in
    disabled|masked|not-found|"")
      pass "$service_name is not enabled (state: ${state:-empty})"
      ;;
    *)
      fail "$service_name is enabled ($state); Docker must own production runtime"
      ;;
  esac
}

service_is_inactive() {
  local service_name="$1"
  local state

  if ! command -v systemctl >/dev/null 2>&1; then
    warn "systemctl unavailable; cannot check $service_name activity"
    return 0
  fi

  state="$(systemctl is-active "$service_name" 2>/dev/null || true)"
  case "$state" in
    inactive|failed|unknown|"")
      pass "$service_name is not active"
      ;;
    *)
      fail "$service_name is active ($state); stop it before deploying Docker runtime"
      ;;
  esac
}

check_no_host_native_listener() {
  local port="$1"
  local lines

  lines="$(ss -ltnp 2>/dev/null | grep -E ":${port}\b" | grep -Ev 'docker-proxy|containerd|dockerd' || true)"
  if [[ -z "$lines" ]]; then
    pass "no host-native listener on port $port"
  else
    fail "host-native listener found on port $port"
    echo "$lines"
  fi
}

echo "========================================"
echo "  Woosoo Pi Docker Runtime Doctor"
echo "========================================"

section "Config file"
if [[ ! -f "$CONFIG_FILE" || -L "$CONFIG_FILE" ]]; then
  fail "missing regular config file: $CONFIG_FILE"
  info "Copy docs/deployment/examples/woosoo.env.example to $CONFIG_FILE first."
else
  pass "config file exists: $CONFIG_FILE"
fi

if [[ ! -r "$CONFIG_FILE" ]]; then
  fail "config file is not readable: $CONFIG_FILE"
else
  # shellcheck source=/dev/null
  set -a
  source "$CONFIG_FILE"
  set +a
  pass "config file loaded"
fi

WOOSOO_NEXUS_PATH="${WOOSOO_NEXUS_PATH:-}"
WOOSOO_PLATFORM_PATH="${WOOSOO_PLATFORM_PATH:-${WOOSOO_NEXUS_PATH:+$(dirname "$WOOSOO_NEXUS_PATH")}}"
WOOSOO_DOCKER_COMPOSE="${WOOSOO_DOCKER_COMPOSE:-docker compose --env-file ./woosoo-nexus/.env -f compose.yaml}"

section "Required commands"
require_command docker
require_command ss
require_command curl

section "Core configuration"
check_required WOOSOO_HOST
check_required WOOSOO_SERVER_IP
check_required WOOSOO_GATEWAY
check_required WOOSOO_CIDR
check_required WOOSOO_NEXUS_PATH
check_required WOOSOO_SCHEME


section "Platform-root compose authority"
if [[ -n "$WOOSOO_PLATFORM_PATH" && -d "$WOOSOO_PLATFORM_PATH" ]]; then
  pass "platform path exists: $WOOSOO_PLATFORM_PATH"
else
  fail "platform path missing: ${WOOSOO_PLATFORM_PATH:-<not set>}"
fi

if [[ -n "$WOOSOO_PLATFORM_PATH" && -f "$WOOSOO_PLATFORM_PATH/compose.yaml" ]]; then
  pass "platform compose.yaml exists"
else
  fail "platform compose.yaml missing at ${WOOSOO_PLATFORM_PATH:-<not set>}/compose.yaml"
fi

if [[ -n "$WOOSOO_PLATFORM_PATH" && -f "$WOOSOO_PLATFORM_PATH/woosoo-nexus/.env" ]]; then
  pass "compose env file exists at platform root"
else
  fail "compose env file missing: ${WOOSOO_PLATFORM_PATH:-<not set>}/woosoo-nexus/.env"
fi

if [[ -n "$WOOSOO_PLATFORM_PATH" ]]; then
  # nginx serves /woosoo-ca.crt → /etc/nginx/certs/rootCA.crt as the trust-bootstrap
  # endpoint for tablets/devices. If this file is missing the endpoint 404s and new
  # devices cannot install the CA. generate-dev-certs.sh creates it as a copy of
  # fullchain.pem; in production it is the mkcert CA root.
  if [[ -f "$WOOSOO_PLATFORM_PATH/docker/certs/rootCA.crt" ]]; then
    pass "docker/certs/rootCA.crt exists (bootstrap endpoint will resolve)"
    if [[ -f "$WOOSOO_PLATFORM_PATH/docker/certs/fullchain.pem" ]] && command -v openssl >/dev/null 2>&1; then
      # A device installs rootCA.crt as its trust anchor; nginx serves fullchain.pem.
      # Trust holds in two valid topologies: dev self-signed (rootCA is a byte copy of
      # fullchain) and production mkcert (rootCA is the CA that signed fullchain). Only
      # warn when rootCA is NEITHER — e.g. a stale dev copy left after regenerating
      # fullchain. Fingerprint equality alone would false-positive on the prod CA root.
      root_fp="$(openssl x509 -in "$WOOSOO_PLATFORM_PATH/docker/certs/rootCA.crt" -noout -fingerprint -sha256 2>/dev/null || true)"
      chain_fp="$(openssl x509 -in "$WOOSOO_PLATFORM_PATH/docker/certs/fullchain.pem" -noout -fingerprint -sha256 2>/dev/null || true)"
      if [[ "$root_fp" != "$chain_fp" ]] \
         && ! openssl verify -CAfile "$WOOSOO_PLATFORM_PATH/docker/certs/rootCA.crt" \
              "$WOOSOO_PLATFORM_PATH/docker/certs/fullchain.pem" >/dev/null 2>&1; then
        warn "rootCA.crt neither matches nor signed fullchain.pem — devices that install the CA will still distrust HTTPS"
        warn "Dev: re-run docker/certs/generate-dev-certs.sh. Prod: ensure rootCA.crt is the CA that issued fullchain.pem."
      fi
    fi
  else
    fail "docker/certs/rootCA.crt missing — /woosoo-ca.crt will 404. Run docker/certs/generate-dev-certs.sh or copy the mkcert CA."
  fi
fi

if [[ -n "$WOOSOO_PLATFORM_PATH" && -f "$WOOSOO_PLATFORM_PATH/compose.yaml" ]]; then
  compose_stderr="$(mktemp)"
  if compose config --quiet >/dev/null 2>"$compose_stderr"; then
    pass "docker compose config is valid"
  else
    fail "docker compose config failed"
    sed 's/^/  /' "$compose_stderr"
  fi

  if grep -qi 'REVERB_APP_KEY.*not set\|Defaulting to a blank string' "$compose_stderr"; then
    fail "compose interpolation emitted a REVERB_APP_KEY warning"
  else
    pass "compose interpolation emitted no REVERB_APP_KEY warning"
  fi
  rm -f "$compose_stderr"
fi

section "POS integration"
check_required WOOSOO_POS_HOST "192.168.100.20"
# Production POS uses the static IP 192.168.1.32 (per AGENTS.md "Config integrity").
# 192.168.100.7 is the dev/home POS; warn rather than fail so the doctor can run
# in dev mode, but make the mismatch loud.
case "${WOOSOO_POS_HOST:-}" in
  192.168.1.32)
    pass "WOOSOO_POS_HOST matches production static IP (192.168.1.32)"
    ;;
  192.168.100.7)
    warn "WOOSOO_POS_HOST=192.168.100.7 (dev/home network); production requires 192.168.1.32"
    ;;
  "")
    : # already failed by check_required above
    ;;
  *)
    fail "WOOSOO_POS_HOST=${WOOSOO_POS_HOST} is neither prod (192.168.1.32) nor dev (192.168.100.7)"
    ;;
esac
check_required WOOSOO_POS_PORT
check_required WOOSOO_POS_DATABASE
check_required WOOSOO_POS_USERNAME
if [[ -z "${WOOSOO_POS_PASSWORD:-}" ]]; then
  warn "WOOSOO_POS_PASSWORD is not set; confirm this is intentional for the POS"
else
  pass "WOOSOO_POS_PASSWORD is set"
fi

section "Reverb configuration"
check_required WOOSOO_REVERB_APP_KEY "change_this_reverb_key" "your_reverb_key_here" "woosoo" "REVERB_APP_KEY_REQUIRED"
check_required WOOSOO_REVERB_APP_SECRET "change_this_reverb_secret" "your_reverb_secret_here"
check_required WOOSOO_REVERB_APP_ID

section "Database credentials"
check_required WOOSOO_DB_PASSWORD "change_this_password"
check_required WOOSOO_DB_ROOT_PASSWORD "change_this_root_password"

section "Docker-only host runtime ownership"
for service_name in mariadb redis-server php8.4-fpm supervisor; do
  service_is_disabled "$service_name"
  service_is_inactive "$service_name"
done

for port in 3306 6379 8080; do
  check_no_host_native_listener "$port"
done

section "Pi resource preflight"
if command -v vcgencmd >/dev/null 2>&1; then
  vcgencmd get_throttled || warn "could not read Pi throttle flags"
  vcgencmd measure_temp || warn "could not read Pi temperature"
else
  warn "vcgencmd unavailable; skipping Pi throttle/temperature checks"
fi

df -h /
free -h || warn "free command failed"
docker system df || warn "docker system df failed"

section "Summary"
echo "Passed: $PASS"
echo "Warned: $WARN"
echo "Failed: $FAIL"

if [[ "$FAIL" -gt 0 ]]; then
  echo
  echo "Preflight FAILED. Resolve failures before deploying."
  exit 1
fi

echo
echo "Preflight PASSED."
