#!/usr/bin/env bash
# =============================================================================
# Woosoo Pi Docker Runtime Smoke Test
# =============================================================================
# Diagnostic only. This script validates the live Docker runtime after deploy.
# It does not edit compose files, nginx config, env files, Docker resources, or
# application code.
#
# Usage:
#   sudo bash scripts/deployment/woosoo-health.sh
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
PASS=0
WARN=0
FAIL=0

pass() { echo "[PASS] $*"; PASS=$((PASS + 1)); }
warn() { echo "[WARN] $*"; WARN=$((WARN + 1)); }
fail() { echo "[FAIL] $*"; FAIL=$((FAIL + 1)); }
info() { echo "[INFO] $*"; }
section() { echo; echo "== $* =="; }

compose() {
  (
    cd "$WOOSOO_PLATFORM_PATH"
    # shellcheck disable=SC2086
    $WOOSOO_DOCKER_COMPOSE "$@"
  )
}

check_public_listener() {
  local port="$1"
  local lines

  lines="$(ss -ltnp 2>/dev/null | grep -E ":${port}\b" || true)"
  if [[ -z "$lines" ]]; then
    fail "no listener on public port $port"
    return 0
  fi

  if echo "$lines" | grep -Eq 'docker-proxy|nginx'; then
    pass "public port $port is owned by Docker/nginx"
  else
    fail "public port $port is not clearly owned by Docker/nginx"
    echo "$lines"
  fi
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

container_env_present() {
  local service="$1"
  local var_name="$2"

  if compose exec -T "$service" sh -c "test -n \"\${$var_name:-}\"" >/dev/null 2>&1; then
    pass "$service runtime has $var_name set"
  else
    fail "$service runtime is missing $var_name"
  fi
}

reverb_internal_listener() {
  if compose exec -T reverb sh -c "awk 'tolower(\$2) ~ /:1f90$/ && \$4 == \"0A\" { found=1 } END { exit found ? 0 : 1 }' /proc/net/tcp /proc/net/tcp6 2>/dev/null" >/dev/null 2>&1; then
    pass "reverb is listening on internal port 8080"
  else
    fail "reverb is not listening on internal port 8080"
  fi
}

runtime_config_value() {
  local field="$1"
  local config_body="$2"

  printf '%s\n' "$config_body" | sed -n "s/.*${field}: \"\\([^\"]*\\)\".*/\\1/p" | head -n 1
}

origin_allowed() {
  local allowed="$1"
  local runtime_host="$2"
  local runtime_origin="$3"

  [[ "$allowed" == "*" ]] && return 0
  printf '%s' "$allowed" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -Fxq "$runtime_host" && return 0
  printf '%s' "$allowed" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -Fxq "$runtime_origin" && return 0
  return 1
}

is_internal_reverb_host() {
  local host="$1"

  case "$host" in
    reverb|app|mysql|redis|tablet-pwa|localhost|127.0.0.1)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

echo "=== Woosoo Pi Docker Runtime Smoke Test ==="

if [[ $EUID -ne 0 ]]; then
  fail "run as root: sudo bash scripts/deployment/woosoo-health.sh"
fi

section "Config"
if [[ ! -f "$CONFIG_FILE" || -L "$CONFIG_FILE" ]]; then
  fail "missing regular config file: $CONFIG_FILE"
else
  pass "config file exists"
fi

# Validate the config before this root process sources it.
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_config-guard.sh"
woosoo_assert_safe_config "$CONFIG_FILE" || exit 1

if [[ -r "$CONFIG_FILE" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
  set +a
  pass "config file loaded"
else
  fail "config file is not readable: $CONFIG_FILE"
fi

WOOSOO_NEXUS_PATH="${WOOSOO_NEXUS_PATH:-/opt/woosoo/woosoo-platform/woosoo-nexus}"
WOOSOO_PLATFORM_PATH="${WOOSOO_PLATFORM_PATH:-$(dirname "$WOOSOO_NEXUS_PATH")}"
WOOSOO_DOCKER_COMPOSE="${WOOSOO_DOCKER_COMPOSE:-docker compose --env-file ./woosoo-nexus/.env -f compose.yaml}"
WOOSOO_SCHEME="${WOOSOO_SCHEME:-https}"
WOOSOO_HOST="${WOOSOO_HOST:-${PUBLIC_HOST:-woosoo.local}}"

section "Platform compose"
if [[ -d "$WOOSOO_PLATFORM_PATH" && -f "$WOOSOO_PLATFORM_PATH/compose.yaml" ]]; then
  pass "platform compose path exists"
  # Guard compose ps so a transient failure under set -e doesn't skip FAIL
  # accounting and the summary block.
  if compose_ps_out="$(compose ps 2>&1)"; then
    pass "docker compose ps succeeded"
    echo "$compose_ps_out"
  else
    fail "docker compose ps failed"
    echo "$compose_ps_out"
  fi
else
  fail "platform compose path is invalid: $WOOSOO_PLATFORM_PATH"
fi

section "Host runtime ownership"
for port in 3306 6379 8080; do
  check_no_host_native_listener "$port"
done
for port in 80 443 4443; do
  check_public_listener "$port"
done

section "HTTP endpoints"
if curl -ksfI --max-time 10 "${WOOSOO_SCHEME}://${WOOSOO_HOST}" >/dev/null; then
  pass "admin HTTPS responds"
else
  fail "admin HTTPS check failed"
fi

if curl -ksfI --max-time 10 "${WOOSOO_SCHEME}://${WOOSOO_HOST}:4443" >/dev/null; then
  pass "tablet PWA HTTPS responds"
else
  fail "tablet PWA HTTPS check failed"
fi

runtime_config_body="$(curl -ksf --max-time 10 "${WOOSOO_SCHEME}://${WOOSOO_HOST}:4443/runtime-config.js" || true)"
if [[ -n "$runtime_config_body" && "$runtime_config_body" == *"window.__APP_CONFIG__"* ]]; then
  pass "runtime-config.js is served"
else
  fail "runtime-config.js is missing or invalid"
fi

if curl -ksf --max-time 10 "${WOOSOO_SCHEME}://${WOOSOO_HOST}:4443/build-info.json" >/dev/null; then
  pass "build-info.json is served"
else
  fail "build-info.json check failed"
fi

section "Laravel container dependencies"
if compose exec -T app php artisan tinker --execute='DB::connection()->getPdo(); echo "ok\n";' 2>/dev/null | grep -q '^ok$'; then
  pass "Laravel app can connect to Docker MySQL"
else
  fail "Laravel app cannot connect to Docker MySQL"
fi

if compose exec -T app php artisan tinker --execute='echo app("redis")->connection()->ping().PHP_EOL;' 2>/dev/null | grep -Eq '^(1|PONG)$'; then
  pass "Laravel app can connect to Docker Redis"
else
  fail "Laravel app cannot connect to Docker Redis"
fi

section "Reverb runtime"
container_env_present reverb REVERB_APP_KEY
reverb_internal_listener

tablet_runtime_host="$(compose exec -T tablet-pwa printenv APP_RUNTIME_REVERB_HOST 2>/dev/null | tr -d '\r' || true)"
runtime_host_from_config="$(runtime_config_value "reverbHost" "$runtime_config_body")"
runtime_port_from_config="$(runtime_config_value "reverbPort" "$runtime_config_body")"

runtime_host="${runtime_host_from_config:-${tablet_runtime_host:-$WOOSOO_HOST}}"
runtime_port="${runtime_port_from_config:-443}"
if [[ -n "$runtime_host" ]] && is_internal_reverb_host "$runtime_host"; then
  warn "tablet runtime Reverb host is internal ($runtime_host); testing through public host $WOOSOO_HOST"
  runtime_host="$WOOSOO_HOST"
fi
tablet_origin="https://${runtime_host}:4443"
allowed_origins="$(compose exec -T reverb printenv REVERB_ALLOWED_ORIGINS 2>/dev/null | tr -d '\r' || true)"

if [[ -n "$runtime_host" ]]; then
  pass "tablet runtime Reverb host resolved"
else
  fail "tablet runtime Reverb host could not be resolved"
fi

if [[ -z "$allowed_origins" ]]; then
  warn "REVERB_ALLOWED_ORIGINS is not set in reverb runtime"
elif origin_allowed "$allowed_origins" "$runtime_host" "$tablet_origin"; then
  pass "REVERB_ALLOWED_ORIGINS permits tablet runtime host/origin"
else
  fail "REVERB_ALLOWED_ORIGINS does not permit tablet runtime host/origin"
  info "Expected allowed origins to include the runtime host or tablet origin; value not printed to avoid config leakage."
fi

reverb_app_key="$(compose exec -T reverb printenv REVERB_APP_KEY 2>/dev/null | tr -d '\r' || true)"
if [[ -n "$reverb_app_key" && -n "$runtime_host" ]]; then
  ws_path="/app/${reverb_app_key}?protocol=7&client=js&version=8.5.0&flash=false"
  http_code="$(curl -sk --max-time 10 --no-alpn -o /dev/null -w '%{http_code}' \
    -H 'Upgrade: websocket' \
    -H 'Connection: Upgrade' \
    -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
    -H 'Sec-WebSocket-Version: 13' \
    -H "Origin: ${tablet_origin}" \
    "https://${runtime_host}:${runtime_port}${ws_path}" 2>/dev/null || echo "000")"

  if [[ "$http_code" == "101" ]]; then
    pass "nginx WSS handshake returns 101 with tablet Origin"
  else
    fail "nginx WSS handshake returned HTTP $http_code instead of 101"
  fi

  if python3 -c 'import websockets' >/dev/null 2>&1; then
    sustained_result="$(WSS_URL="wss://${runtime_host}:${runtime_port}${ws_path}" WSS_ORIGIN="$tablet_origin" python3 - <<'PYEOF' 2>/dev/null || true
import asyncio
import json
import os
import ssl

import websockets

async def main():
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    async with websockets.connect(
        os.environ["WSS_URL"],
        ssl=ctx,
        origin=os.environ["WSS_ORIGIN"],
        open_timeout=5,
        ping_interval=None,
    ) as ws:
        message = await asyncio.wait_for(ws.recv(), timeout=5)
        data = json.loads(message)
        if data.get("event") != "pusher:connection_established":
            print("unexpected-event")
            return
        await asyncio.sleep(3)
        print("sustained")

asyncio.run(main())
PYEOF
)"
    if [[ "$sustained_result" == "sustained" ]]; then
      pass "WSS connection is sustained after connection_established"
    else
      fail "WSS connection was not sustained (${sustained_result:-no output})"
    fi
  else
    warn "python3 websockets module missing; sustained WSS check skipped"
    info "Install for full Pi smoke coverage: python3 -m pip install websockets --break-system-packages"
  fi

  unset reverb_app_key ws_path
else
  fail "cannot run WSS checks because Reverb key or runtime host is unavailable"
fi

section "Queue worker"
queue_logs="$(compose logs --tail=120 queue 2>/dev/null || true)"
if echo "$queue_logs" | grep -Eq 'DONE'; then
  pass "queue logs include recent completed jobs"
else
  warn "queue logs do not show recent DONE jobs in the last 120 lines"
fi

if echo "$queue_logs" | grep -Eiq '(^|[[:space:]])FAIL($|[[:space:]])|exception|fatal|error'; then
  fail "queue logs include recent failure/error signals"
else
  pass "queue logs contain no recent failure/error signals"
fi

section "Pi resources"
df -h /
free -h || warn "free command failed"
docker system df || warn "docker system df failed"
if command -v vcgencmd >/dev/null 2>&1; then
  vcgencmd get_throttled || warn "could not read Pi throttle flags"
  vcgencmd measure_temp || warn "could not read Pi temperature"
else
  warn "vcgencmd unavailable; skipping Pi throttle/temperature checks"
fi

section "Summary"
echo "Passed: $PASS"
echo "Warned: $WARN"
echo "Failed: $FAIL"

if [[ "$FAIL" -gt 0 ]]; then
  echo
  echo "Smoke test FAILED."
  exit 1
fi

echo
echo "Smoke test PASSED."
