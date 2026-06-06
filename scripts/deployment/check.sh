#!/usr/bin/env bash
# =============================================================================
# Woosoo Platform — Environment Check
# =============================================================================
# Run this FIRST on any machine before deploying. It checks every prerequisite
# and prints the exact fix command for anything that's missing or wrong.
#
# Usage (no sudo needed):
#   bash scripts/deployment/check.sh
#
# Exit codes:
#   0 = all checks passed
#   1 = one or more checks failed (see FIX lines)
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── Output helpers ────────────────────────────────────────────────────────────
PASS=0; WARN=0; FAIL=0
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1m'; NC='\033[0m'
pass() { printf "${G}[PASS]${NC} %s\n"    "$*"; PASS=$((PASS+1)); }
warn() { printf "${Y}[WARN]${NC} %s\n"    "$*"; WARN=$((WARN+1)); }
fail() { printf "${R}[FAIL]${NC} %s\n"    "$*"; FAIL=$((FAIL+1)); }
fix()  { printf "       ${B}FIX:${NC}  %s\n" "$*"; }
info() { printf "       %s\n"             "$*"; }
section() { printf "\n${B}── %s ──${NC}\n" "$*"; }

# ── Detect runtime context ────────────────────────────────────────────────────
_is_wsl=false
_is_pi=false
grep -qiE 'microsoft|WSL' /proc/version 2>/dev/null && _is_wsl=true
command -v vcgencmd >/dev/null 2>&1 && _is_pi=true
[[ -n "${WSL_DISTRO_NAME:-}" ]] && _is_wsl=true

printf "\n${B}========================================${NC}\n"
printf "${B}  Woosoo Platform — Environment Check${NC}\n"
printf "${B}  Platform root: %s${NC}\n" "$ROOT"
if [[ "$_is_pi" == "true" ]]; then
  printf "  Runtime: Raspberry Pi\n"
elif [[ "$_is_wsl" == "true" ]]; then
  printf "  Runtime: WSL2 (dev/test — not Pi)\n"
else
  printf "  Runtime: Linux\n"
fi
printf "${B}========================================${NC}\n"

# ── 1. Platform repo ──────────────────────────────────────────────────────────
section "Platform repo"

if [[ -f "$ROOT/compose.yaml" ]]; then
  pass "compose.yaml present"
else
  fail "compose.yaml missing — this does not look like the platform root"
  fix "cd to the woosoo-platform directory and re-run"
fi

_branch="$(git -C "$ROOT" branch --show-current 2>/dev/null || true)"
if [[ "$_branch" == "dev" || "$_branch" == "main" ]]; then
  pass "platform branch: $_branch"
else
  warn "platform branch is '$_branch' (expected dev or main)"
  fix "git -C $ROOT checkout dev && git -C $ROOT pull origin dev"
fi

_behind="$(git -C "$ROOT" rev-list --count HEAD..origin/dev 2>/dev/null || echo '?')"
if [[ "$_behind" == "0" ]]; then
  pass "platform repo is up to date with origin/dev"
elif [[ "$_behind" == "?" ]]; then
  warn "could not check origin/dev (no network or not fetched yet)"
  fix "git -C $ROOT fetch origin"
else
  warn "platform repo is $_behind commit(s) behind origin/dev"
  fix "git -C $ROOT pull origin dev"
fi

# ── 2. App repos ──────────────────────────────────────────────────────────────
section "App repos (must be present as subdirectories)"

for _repo in woosoo-nexus tablet-ordering-pwa; do
  _dir="$ROOT/$_repo"
  if [[ -d "$_dir/.git" ]]; then
    _rb="$(git -C "$_dir" branch --show-current 2>/dev/null || echo '?')"
    pass "$_repo present (branch: $_rb)"
    if [[ "$_rb" != "dev" && "$_rb" != "main" ]]; then
      warn "$_repo is on branch '$_rb' — expected dev"
      fix "git -C $ROOT/$_repo checkout dev"
    fi
    _b="$(git -C "$_dir" rev-list --count HEAD..origin/dev 2>/dev/null || echo '?')"
    if [[ "$_b" != "0" && "$_b" != "?" ]]; then
      warn "$_repo is $_b commit(s) behind origin/dev"
      fix "git -C $ROOT/$_repo pull origin dev"
    fi
  else
    fail "$_repo missing at $ROOT/$_repo"
    fix "git clone <remote-url> $ROOT/$_repo"
    info "Check AGENTS.md for the correct remote URL"
  fi
done

# ── 3. Required tools ─────────────────────────────────────────────────────────
section "Required tools"

check_tool() {
  local cmd="$1" install_hint="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    pass "tool available: $cmd"
  else
    fail "missing tool: $cmd"
    fix "$install_hint"
  fi
}

# NOTE: docker / curl / ss tool-availability are validated by doctor.sh (which
# runs as the deploy gate). Only the checks unique to check.sh live here — git,
# openssl, and the "Docker engine actually reachable" probe below.
check_tool git     "sudo apt install git"
check_tool openssl "sudo apt install openssl"

# Docker must be reachable (not just installed)
if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    _dver="$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo '?')"
    pass "Docker Engine running (v$_dver)"
  else
    fail "Docker installed but engine is not running"
    if [[ "$_is_wsl" == "true" ]]; then
      fix "Start Docker Engine in WSL2: sudo service docker start"
    else
      fix "sudo systemctl start docker"
    fi
  fi
fi

# ── 4. TLS certificates ───────────────────────────────────────────────────────
section "TLS certificates (docker/certs/)"

# rootCA.crt presence is validated by doctor.sh (bootstrap-endpoint authority);
# check.sh covers the unique TLS-serving cert pair + expiry only.
_cert_dir="$ROOT/docker/certs"
_certs_ok=true
for _cf in fullchain.pem privkey.pem; do
  if [[ -f "$_cert_dir/$_cf" ]]; then
    pass "cert present: $_cf"
  else
    fail "cert missing: $_cf"
    _certs_ok=false
  fi
done
if [[ "$_certs_ok" == "false" ]]; then
  fix "bash $ROOT/docker/certs/generate-dev-certs.sh <SERVER_IP>"
  info "Example: bash docker/certs/generate-dev-certs.sh 192.168.100.42"
fi

# Check cert expiry
if [[ -f "$_cert_dir/fullchain.pem" ]]; then
  _expiry="$(openssl x509 -enddate -noout -in "$_cert_dir/fullchain.pem" 2>/dev/null | cut -d= -f2 || true)"
  if [[ -n "$_expiry" ]]; then
    _exp_epoch="$(date -d "$_expiry" +%s 2>/dev/null || true)"
    _now_epoch="$(date +%s)"
    if [[ -n "$_exp_epoch" ]] && (( _exp_epoch < _now_epoch )); then
      fail "TLS certificate has EXPIRED (was: $_expiry)"
      fix "bash $ROOT/docker/certs/generate-dev-certs.sh <SERVER_IP>"
    elif [[ -n "$_exp_epoch" ]] && (( _exp_epoch - _now_epoch < 30*86400 )); then
      warn "TLS certificate expires soon: $_expiry"
      fix "bash $ROOT/docker/certs/generate-dev-certs.sh <SERVER_IP>"
    else
      pass "TLS certificate valid (expires: $_expiry)"
    fi
  fi
fi

# ── 5. Operator config (woosoo.env) ───────────────────────────────────────────
section "Operator config (woosoo.env)"

_cfg=""
if [[ -f "$ROOT/woosoo.env" ]]; then
  _cfg="$ROOT/woosoo.env"
  pass "woosoo.env found: $ROOT/woosoo.env"
elif [[ -f /etc/woosoo/woosoo.env ]]; then
  _cfg="/etc/woosoo/woosoo.env"
  pass "woosoo.env found: /etc/woosoo/woosoo.env"
else
  fail "woosoo.env not found (neither $ROOT/woosoo.env nor /etc/woosoo/woosoo.env)"
  fix "bash $ROOT/scripts/deployment/init-woosoo-env.sh"
fi

# Check for placeholder credentials in woosoo.env
if [[ -n "$_cfg" ]]; then
  _placeholders=()
  while IFS= read -r line; do
    [[ "$line" =~ ^# ]] && continue
    [[ -z "$line" ]] && continue
    key="${line%%=*}"
    val="${line#*=}"; val="${val#\"}"; val="${val%\"}"
    case "$val" in
      change_this*|"dev-reverb-"*|dev_db_password*|dev_root_password*)
        _placeholders+=("$key") ;;
    esac
  done < "$_cfg"
  if [[ ${#_placeholders[@]} -gt 0 ]]; then
    warn "placeholder values detected in woosoo.env: ${_placeholders[*]}"
    fix "bash $ROOT/scripts/deployment/init-woosoo-env.sh   (re-run to update)"
  else
    pass "no placeholder credentials detected"
  fi
fi

# ── 6. App .env files ─────────────────────────────────────────────────────────
section "App .env files"

if [[ -f "$ROOT/woosoo-nexus/.env" ]]; then
  pass "woosoo-nexus/.env present"
  # Check APP_KEY
  _appkey="$(grep -E '^APP_KEY=' "$ROOT/woosoo-nexus/.env" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' || true)"
  if [[ "$_appkey" == base64:* ]] && [[ ${#_appkey} -gt 30 ]]; then
    pass "APP_KEY is set"
  else
    fail "APP_KEY is missing or not a base64 key"
    fix "After containers are up: docker compose --env-file ./woosoo-nexus/.env -f compose.yaml exec -T app php artisan key:generate --force"
  fi
else
  fail "woosoo-nexus/.env missing"
  fix "bash $ROOT/scripts/deployment/dev-docker-bootstrap.sh   (dev only)"
  info "On Pi: run apply-woosoo-config.sh after woosoo.env is present"
fi

if [[ -f "$ROOT/tablet-ordering-pwa/.env" ]]; then
  pass "tablet-ordering-pwa/.env present"
else
  warn "tablet-ordering-pwa/.env missing (usually not required for deploy)"
  fix "cp $ROOT/tablet-ordering-pwa/.env.example $ROOT/tablet-ordering-pwa/.env"
fi

# ── 7. Docker compose validation ─────────────────────────────────────────────
section "Docker compose"

if [[ -f "$ROOT/compose.yaml" ]]; then
  cd "$ROOT"
  if docker compose --env-file ./woosoo-nexus/.env -f compose.yaml config --quiet 2>/dev/null; then
    pass "compose.yaml parses cleanly"
    _svcs="$(docker compose --env-file ./woosoo-nexus/.env -f compose.yaml config --services 2>/dev/null | tr '\n' ' ')"
    info "services: $_svcs"
  else
    fail "compose.yaml failed validation"
    fix "docker compose --env-file ./woosoo-nexus/.env -f compose.yaml config   (see errors above)"
  fi
fi

# ── 8. Docker images ──────────────────────────────────────────────────────────
section "Docker images"

_required_images=(app reverb queue scheduler tablet-pwa)
_project="woosoo-nexus"
_images_missing=()
for _svc in "${_required_images[@]}"; do
  _img="${_project}-${_svc}"
  if docker image inspect "${_img}:latest" >/dev/null 2>&1; then
    pass "image: ${_img}"
  else
    warn "image not built: ${_img}"
    _images_missing+=("$_svc")
  fi
done
if [[ ${#_images_missing[@]} -gt 0 ]]; then
  fix "cd $ROOT && docker compose --env-file ./woosoo-nexus/.env -f compose.yaml build"
fi

# ── 9. Running containers ─────────────────────────────────────────────────────
section "Containers"

_running="$(docker ps --format '{{.Names}}' 2>/dev/null | tr '\n' ' ')"
if [[ -n "$_running" ]]; then
  pass "running: $_running"
else
  info "no containers running"
  info "To start: WOOSOO_ALLOW_NON_PI=true sudo -E bash $ROOT/scripts/deployment/deploy-all.sh"
fi

# ── 10. Port conflicts ────────────────────────────────────────────────────────
section "Port conflicts"

for _port in 80 443 3306 6379 8080; do
  _listeners="$(ss -ltnp 2>/dev/null | grep -E ":${_port}\b" | grep -Ev 'docker-proxy|containerd|dockerd' || true)"
  if [[ -z "$_listeners" ]]; then
    pass "port $_port: free"
  else
    warn "port $_port: in use by non-Docker process"
    info "$_listeners"
    fix "Stop the conflicting service or change the compose port mapping"
  fi
done

# ── WSL2-specific notes ───────────────────────────────────────────────────────
if [[ "$_is_wsl" == "true" ]]; then
  section "WSL2 notes"
  info "Pi-specific checks (static IP, dnsmasq, systemd, nmcli) are skipped on WSL2."
  info "To deploy on WSL2: WOOSOO_ALLOW_NON_PI=true sudo -E bash scripts/deployment/deploy-all.sh"
  info "To deploy on Pi:   sudo bash scripts/deployment/deploy-all.sh"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
printf "\n${B}========================================${NC}\n"
printf "  Passed: %d   Warned: %d   Failed: %d\n" "$PASS" "$WARN" "$FAIL"
printf "${B}========================================${NC}\n\n"

if [[ "$FAIL" -gt 0 ]]; then
  printf "${R}Some checks failed. Follow the FIX lines above before deploying.${NC}\n\n"
  exit 1
elif [[ "$WARN" -gt 0 ]]; then
  printf "${Y}All required checks passed with warnings. Review before deploying.${NC}\n\n"
  exit 0
else
  printf "${G}All checks passed. Ready to deploy.${NC}\n\n"
  exit 0
fi
