#!/usr/bin/env bash
# =============================================================================
# Woosoo Pi Reboot Health Check
# =============================================================================
# Diagnostic only. Run this after a controlled reboot to confirm the Docker-only
# runtime returned cleanly and diagnostics survived the restart.
#
# Usage:
#   sudo bash scripts/deployment/pi-reboot-health.sh
# =============================================================================
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-/etc/woosoo/woosoo.env}"
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

service_is_disabled() {
  local service_name="$1"
  local state

  state="$(systemctl is-enabled "$service_name" 2>/dev/null || true)"
  case "$state" in
    disabled|masked|"")
      pass "$service_name is not enabled"
      ;;
    *)
      fail "$service_name is enabled after reboot ($state)"
      ;;
  esac
}

service_is_inactive() {
  local service_name="$1"
  local state

  state="$(systemctl is-active "$service_name" 2>/dev/null || true)"
  case "$state" in
    inactive|failed|unknown|"")
      pass "$service_name is not active"
      ;;
    *)
      fail "$service_name is active after reboot ($state)"
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

check_public_listener() {
  local port="$1"
  local lines

  lines="$(ss -ltnp 2>/dev/null | grep -E ":${port}\b" || true)"
  if [[ -z "$lines" ]]; then
    fail "no listener on public port $port"
  elif echo "$lines" | grep -Eq 'docker-proxy|nginx'; then
    pass "public port $port is owned by Docker/nginx"
  else
    fail "public port $port is not clearly owned by Docker/nginx"
    echo "$lines"
  fi
}

reverb_internal_listener() {
  if compose exec -T reverb sh -c "awk 'tolower(\$2) ~ /:1f90$/ && \$4 == \"0A\" { found=1 } END { exit found ? 0 : 1 }' /proc/net/tcp /proc/net/tcp6 2>/dev/null" >/dev/null 2>&1; then
    pass "reverb is listening on internal port 8080 after reboot"
  else
    fail "reverb is not listening on internal port 8080 after reboot"
  fi
}

echo "=== Woosoo Pi Reboot Health Check ==="

if [[ $EUID -ne 0 ]]; then
  fail "run as root: sudo bash scripts/deployment/pi-reboot-health.sh"
fi

section "Config"
if [[ -r "$CONFIG_FILE" && ! -L "$CONFIG_FILE" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
  set +a
  pass "config file loaded"
else
  fail "missing readable regular config file: $CONFIG_FILE"
fi

WOOSOO_NEXUS_PATH="${WOOSOO_NEXUS_PATH:-/opt/woosoo/woosoo-platform/woosoo-nexus}"
WOOSOO_PLATFORM_PATH="${WOOSOO_PLATFORM_PATH:-$(dirname "$WOOSOO_NEXUS_PATH")}"
WOOSOO_DOCKER_COMPOSE="${WOOSOO_DOCKER_COMPOSE:-docker compose --env-file ./woosoo-nexus/.env -f compose.yaml}"

section "Boot evidence"
uptime -s || warn "uptime -s failed"

boot_count="$(journalctl --list-boots 2>/dev/null | grep -c '^[[:space:]]*[-0-9]' || true)"
if [[ "$boot_count" -gt 1 ]]; then
  pass "persistent journal contains previous boot entries"
else
  fail "persistent journal does not show previous boots; enable persistent journald"
fi

if command -v vcgencmd >/dev/null 2>&1; then
  vcgencmd get_throttled || warn "could not read Pi throttle flags"
  vcgencmd measure_temp || warn "could not read Pi temperature"
else
  warn "vcgencmd unavailable; skipping Pi throttle/temperature checks"
fi

section "Host services after reboot"
for service_name in mariadb redis-server php8.4-fpm supervisor; do
  service_is_disabled "$service_name"
  service_is_inactive "$service_name"
done

section "Port ownership after reboot"
for port in 3306 6379 8080; do
  check_no_host_native_listener "$port"
done
for port in 80 443 4443; do
  check_public_listener "$port"
done

section "Docker stack after reboot"
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

reverb_id="$(compose ps -q reverb 2>/dev/null || true)"
if [[ -n "$reverb_id" ]]; then
  reverb_state="$(docker inspect "$reverb_id" --format 'RestartCount={{.RestartCount}} Started={{.State.StartedAt}} Finished={{.State.FinishedAt}} Exit={{.State.ExitCode}} OOM={{.State.OOMKilled}}' 2>/dev/null || true)"
  if [[ -n "$reverb_state" ]]; then
    pass "reverb container inspect succeeded"
    info "$reverb_state"
  else
    fail "reverb container inspect failed"
  fi
else
  fail "reverb container is missing after reboot"
fi

reverb_internal_listener

section "Summary"
echo "Passed: $PASS"
echo "Warned: $WARN"
echo "Failed: $FAIL"

if [[ "$FAIL" -gt 0 ]]; then
  echo
  echo "Reboot health check FAILED."
  exit 1
fi

echo
echo "Reboot health check PASSED."
