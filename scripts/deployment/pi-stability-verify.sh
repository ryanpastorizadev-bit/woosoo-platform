#!/usr/bin/env bash
# =============================================================================
# Pi Stability Verify — Bucket B gates for plt-case-stability-remediation
# =============================================================================
# Diagnostic only. Validates P0 (NEX-014 session/419) and P1a/b env/runtime
# signals after deploy. Does not edit env files, compose, or application code.
#
# Usage (on the Pi, from platform root):
#   sudo bash scripts/deployment/pi-stability-verify.sh
#   sudo bash scripts/deployment/pi-stability-verify.sh --host 192.168.1.31
#
# Exit codes:
#   0 = all required checks passed
#   1 = one or more required checks failed
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
NEXUS_ENV="$PLATFORM_ROOT/woosoo-nexus/.env"

VERIFY_HOST=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      VERIFY_HOST="${2:-}"
      shift 2
      ;;
    -h | --help)
      echo "Usage: sudo bash scripts/deployment/pi-stability-verify.sh [--host <ip-or-host>]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

PASS=0
WARN=0
FAIL=0

if [[ -t 1 ]]; then
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  NC='\033[0m'
else
  GREEN=''
  YELLOW=''
  RED=''
  NC=''
fi

pass() { echo -e "${GREEN}[PASS]${NC} $*"; PASS=$((PASS + 1)); }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; WARN=$((WARN + 1)); }
fail() { echo -e "${RED}[FAIL]${NC} $*"; FAIL=$((FAIL + 1)); }
info() { echo "[INFO] $*"; }
section() { echo; echo "== $* =="; }

env_get() {
  local key="$1" file="$2"
  grep -E "^${key}=" "$file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'"
}

compose() {
  (
    cd "$PLATFORM_ROOT"
    if [[ -n "${WOOSOO_DOCKER_COMPOSE:-}" ]]; then
      # shellcheck disable=SC2086
      $WOOSOO_DOCKER_COMPOSE "$@"
    elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
      docker compose "$@"
    else
      docker-compose "$@"
    fi
  )
}

section "Pi stability verify — $(date -Iseconds 2>/dev/null || date)"
info "Platform root: $PLATFORM_ROOT"

# ── P0 — NEX-014 session / 419 ───────────────────────────────────────────────
section "P0 — NEX-014 (SESSION_DOMAIN / 419)"

if [[ ! -f "$NEXUS_ENV" ]]; then
  fail "missing woosoo-nexus/.env — run deploy-all.sh first"
else
  pass "woosoo-nexus/.env exists"
fi

if [[ -f "$NEXUS_ENV" ]]; then
  _sd="$(env_get SESSION_DOMAIN "$NEXUS_ENV")"
  if [[ -z "$_sd" ]]; then
    pass "SESSION_DOMAIN is empty (host-scoped cookie)"
  else
    fail "SESSION_DOMAIN is pinned to \"${_sd}\" — re-run apply-woosoo-config.sh"
  fi

  _woosoo_env="$(env_get WOOSOO_ENV "$NEXUS_ENV")"
  if [[ -z "$_woosoo_env" ]]; then
    warn "WOOSOO_ENV unset in .env (apply-woosoo-config may use woosoo.env profile)"
  elif [[ "$_woosoo_env" == "production" ]]; then
    pass "WOOSOO_ENV=production"
  else
    warn "WOOSOO_ENV=${_woosoo_env} (expected production on live Pi)"
  fi

  if [[ -z "$VERIFY_HOST" ]]; then
    VERIFY_HOST="$(env_get PUBLIC_HOST "$NEXUS_ENV")"
  fi
  if [[ -z "$VERIFY_HOST" ]]; then
    VERIFY_HOST="$(hostname -I 2>/dev/null | awk '{print $1}')"
  fi
  if [[ -z "$VERIFY_HOST" ]]; then
    fail "could not determine verify host — pass --host <ip>"
  else
    pass "verify host: $VERIFY_HOST"
  fi
fi

if [[ -n "$VERIFY_HOST" ]] && command -v curl >/dev/null 2>&1; then
  _csrf_headers="$(mktemp)"
  _csrf_code="$(curl -k -sS -o /dev/null -w '%{http_code}' -D "$_csrf_headers" \
    "https://${VERIFY_HOST}/sanctum/csrf-cookie" 2>/dev/null || echo "000")"

  if [[ "$_csrf_code" == "204" || "$_csrf_code" == "200" ]]; then
    pass "GET /sanctum/csrf-cookie returned ${_csrf_code}"
  else
    fail "GET /sanctum/csrf-cookie returned ${_csrf_code} (expected 204 or 200)"
  fi

  if grep -qi '^set-cookie:.*domain=' "$_csrf_headers" 2>/dev/null; then
    fail "Set-Cookie includes domain= (SESSION_DOMAIN likely still pinned)"
  else
    pass "Set-Cookie has no domain= attribute (host-scoped)"
  fi

  _jar="$(mktemp)"
  curl -k -sS -c "$_jar" -b "$_jar" "https://${VERIFY_HOST}/sanctum/csrf-cookie" >/dev/null 2>&1 || true
  _xsrf="$(grep -i XSRF-TOKEN "$_jar" 2>/dev/null | awk '{print $NF}' | tail -1 | sed 's/%3D/=/g' || true)"
  if [[ -n "$_xsrf" ]]; then
    _login_code="$(curl -k -sS -o /dev/null -w '%{http_code}' -c "$_jar" -b "$_jar" \
      -X POST "https://${VERIFY_HOST}/login" \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -H "X-XSRF-TOKEN: ${_xsrf}" \
      -d '{"email":"pi-stability-verify@invalid.local","password":"wrong","remember":false}' \
      2>/dev/null || echo "000")"
    if [[ "$_login_code" == "422" ]]; then
      pass "bad-credentials login returned 422 (not 419)"
    elif [[ "$_login_code" == "419" ]]; then
      fail "bad-credentials login returned 419 — SESSION_DOMAIN / CSRF mismatch"
    else
      warn "bad-credentials login returned ${_login_code} (expected 422; 419 would fail)"
    fi
  else
    warn "could not read XSRF-TOKEN cookie — skipped 422-vs-419 login probe"
  fi
  rm -f "$_csrf_headers" "$_jar"
else
  warn "curl unavailable — skipped HTTP probes"
fi

# ── P1a — NEX-011 print path env ─────────────────────────────────────────────
section "P1a — NEX-011 (BT-only print env)"

if [[ -f "$NEXUS_ENV" ]]; then
  _print_events="$(env_get NEXUS_PRINT_EVENTS_ENABLED "$NEXUS_ENV")"
  if [[ "$_print_events" == "true" ]]; then
    pass "NEXUS_PRINT_EVENTS_ENABLED=true"
  elif [[ -z "$_print_events" || "$_print_events" == "false" ]]; then
    warn "NEXUS_PRINT_EVENTS_ENABLED is not true — BT print path may be off"
  else
    warn "NEXUS_PRINT_EVENTS_ENABLED=${_print_events} (expected true for BT-only)"
  fi
  info "Manual: disable 3rd-party Krypton POS printer; submit order → one BT ticket"
fi

# ── P1b — INFRA-003 runtime ────────────────────────────────────────────────────
section "P1b — INFRA-003 (Docker runtime)"

if command -v docker >/dev/null 2>&1; then
  if compose ps --status running 2>/dev/null | grep -qE 'app|tablet-pwa|nginx'; then
    pass "core compose services report running"
  else
    fail "expected app/tablet-pwa/nginx containers not all running"
    compose ps 2>/dev/null || true
  fi
else
  fail "docker command not available"
fi

section "Summary"
info "PASS=${PASS} WARN=${WARN} FAIL=${FAIL}"
if [[ "$FAIL" -gt 0 ]]; then
  echo
  echo "One or more required checks failed. See RELEASE_RUNBOOK_order-id-pos-sync.md Step 1.5+."
  exit 1
fi

echo
echo "Required checks passed. Complete manual P1a smoke (one ticket/order) and Step 5 acceptance."
exit 0
