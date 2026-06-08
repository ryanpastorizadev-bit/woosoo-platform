#!/usr/bin/env bash
# =============================================================================
# scripts/pipeline.sh — Woosoo local CI/CD pipeline runner
# =============================================================================
# Usage:
#   bash scripts/pipeline.sh <target> [flags]
#   ./run <target> [flags]          # via root entry point
#   pld <target> [flags]            # preferred (Palisade CLI)
#   woosoo <target> [flags]         # deprecated alias
#   ./run <target> [flags]
#
# Targets:
#   sync      Post-push fast path (nexus pull → up → APP_KEY fix → optimize:clear)
#   rebuild   Frontend Vite rebuild in Docker (--php for composer install)
#   certs     Regenerate dev TLS certs + restart nginx (alias: network --regen-certs)
#   dev       Local Docker dev deploy (pull → bootstrap → build → up → migrate → warm → health)
#   staging   Staging-parity on WSL/dev host (requires woosoo.env; uses WOOSOO_ALLOW_NON_PI)
#   pi        Production Pi deploy (requires root + woosoo.env)
#   health    Inline dev health check (services + HTTP endpoints)
#   network   Sync PUBLIC_HOST + ensure LAN bridge + verify (WSL portproxy)
#   logs      Tail all service logs
#   check     Preflight check (scripts/deployment/check.sh)
#
# Flags (dev target only):
#   --no-pull       Skip git pull step
#   --no-build      Skip docker compose build step
#   --from-step N   Start from step N (1–7); earlier steps are skipped
#   --dry-run       Print steps without executing
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# shellcheck source=scripts/lib/pipeline-ui.sh
source "$LIB_DIR/pipeline-ui.sh"

# ── Argument parsing ──────────────────────────────────────────────────────────
TARGET="${1:-help}"
shift || true

NO_PULL=0
NO_BUILD=0
FROM_STEP=1
DRY_RUN=0
REGEN_CERTS=0
SYNC_FULL=0
SYNC_BUILD=0
REBUILD_PHP=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-pull)       NO_PULL=1 ;;
    --no-build)      NO_BUILD=1 ;;
    --dry-run)       DRY_RUN=1 ;;
    --regen-certs)   REGEN_CERTS=1 ;;
    --full)          SYNC_FULL=1 ;;
    --build)         SYNC_BUILD=1 ;;
    --php)           REBUILD_PHP=1 ;;
    --from-step)   FROM_STEP="${2:?--from-step requires a step number}"; shift ;;
    --from-step=*) FROM_STEP="${1#*=}" ;;
    -h|--help)     TARGET="help" ;;
    *)
      echo "Unknown flag: $1" >&2
      echo "Run 'pld help' for usage." >&2
      exit 1
      ;;
  esac
  shift
done

export DRY_RUN

# ── CLI name (pld vs deprecated woosoo) ───────────────────────────────────────
CLI_NAME="${WOOSOO_CLI_INVOKED_AS:-run}"
CLI_NAME="${CLI_NAME%.exe}"
export CLI_NAME

if [[ "$CLI_NAME" == "woosoo" && "$TARGET" != "help" && "$TARGET" != "-h" && "$TARGET" != "--help" ]]; then
  echo -e "${_C_YELLOW}Note:${_C_RESET} 'woosoo' is deprecated — use 'pld' instead (Palisade CLI). See docs/architecture/pld-cli-decision.md" >&2
  echo >&2
fi

# ── Compose helper ────────────────────────────────────────────────────────────
_env_file="$PLATFORM_ROOT/woosoo-nexus/.env"
DC="docker compose --env-file ${_env_file} -f ${PLATFORM_ROOT}/compose.yaml"

# ── Retry helper (mirrors deploy.sh) ─────────────────────────────────────────
_retry() {
  local max="$1" desc="$2"; shift 2
  local attempt=1 rc=0
  until "$@"; do
    rc=$?
    if (( attempt >= max )); then
      echo "ERROR: ${desc} failed after ${max} attempt(s) (exit ${rc})." >&2
      return "$rc"
    fi
    echo "  WARN: ${desc} failed (attempt ${attempt}/${max}); retrying in 5s ..." >&2
    sleep 5
    attempt=$(( attempt + 1 ))
  done
}

# ── Step helper: skip if before FROM_STEP ─────────────────────────────────────
# Usage: _step N TOTAL "label" cmd [args...]
#        _step N TOTAL "label" --skip "reason"
_step() {
  local n="$1" total="$2" label="$3"; shift 3
  if (( n < FROM_STEP )); then
    pipeline_skip "$n" "$total" "$label" "--from-step ${FROM_STEP}"
    return 0
  fi
  if [[ "${1:-}" == "--skip" ]]; then
    pipeline_skip "$n" "$total" "$label" "${2:-}"
    return 0
  fi
  pipeline_step "$n" "$total" "$label" "$@"
}

# =============================================================================
# dev step implementations
# =============================================================================

_dev_pull() {
  local branch="${WOOSOO_DEPLOY_BRANCH:-dev}"
  local dirs=("$PLATFORM_ROOT" "$PLATFORM_ROOT/woosoo-nexus" "$PLATFORM_ROOT/tablet-ordering-pwa")
  local names=("platform" "nexus  " "tablet ")  # padded for alignment
  local i
  for i in "${!dirs[@]}"; do
    local dir="${dirs[$i]}" name="${names[$i]}"
    if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git -C "$dir" fetch origin "$branch" --quiet 2>/dev/null || true
      git -C "$dir" checkout "$branch" --quiet 2>/dev/null
      git -C "$dir" pull origin "$branch" --quiet
      local sha; sha="$(git -C "$dir" rev-parse --short HEAD)"
      echo "  ${name}  ${sha}  (${branch})"
    else
      echo "  ${name}  (not a git repo — skipping pull)"
    fi
  done
}

_dev_pull_nexus() {
  local branch="${WOOSOO_DEPLOY_BRANCH:-dev}"
  local dir="$PLATFORM_ROOT/woosoo-nexus"
  if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$dir" fetch origin "$branch" --quiet 2>/dev/null || true
    git -C "$dir" checkout "$branch" --quiet 2>/dev/null
    git -C "$dir" pull origin "$branch" --quiet
    local sha; sha="$(git -C "$dir" rev-parse --short HEAD)"
    echo "  nexus    ${sha}  (${branch})"
  else
    echo "  nexus    (not a git repo — skipping pull)"
  fi
}

_dev_bootstrap_needed() {
  # Returns 0 (true) if bootstrap should run; 1 (false) if already configured.
  # Missing APP_KEY alone does NOT trigger bootstrap — use _dev_ensure_app_key after stack is up.
  [[ ! -f "$_env_file" ]] && return 0
  grep -qE '^APP_ENV="?local"?' "$_env_file" || return 0
  # SESSION_DOMAIN must be empty
  local sd; sd="$(grep -E '^SESSION_DOMAIN=' "$_env_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' || echo '')"
  [[ -n "$sd" ]] && return 0
  # WSL: host.docker.internal does not reach Krypton on Windows — re-bootstrap POS host
  if grep -qiE 'microsoft|WSL' /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    if grep -qE '^DB_POS_HOST=.*host\.docker\.internal' "$_env_file" 2>/dev/null; then
      return 0
    fi
  fi
  return 1  # all checks passed — skip bootstrap
}

_dev_app_key_ok() {
  local val len
  [[ -f "$_env_file" ]] || return 1
  val="$(grep -E '^APP_KEY=' "$_env_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' || true)"
  [[ "$val" == base64:* ]] || return 1
  len="${#val}"
  (( len >= 40 && len <= 80 ))
}

_dev_ensure_app_key() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "  (dry-run) would ensure APP_KEY via php artisan key:generate --force"
    return 0
  fi
  if _dev_app_key_ok; then
    echo "  APP_KEY OK"
    return 0
  fi
  echo "  APP_KEY missing or invalid — generating..."
  $DC exec -T app php artisan key:generate --force
}

_dev_optimize_clear() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "  (dry-run) would run php artisan optimize:clear"
    return 0
  fi
  $DC exec -T app php artisan optimize:clear
}

_print_dev_urls() {
  local pub_host scheme
  pub_host="$(grep -E '^PUBLIC_HOST=' "$_env_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' || true)"
  scheme="$(grep -E '^PUBLIC_SCHEME=' "$_env_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' || echo 'https')"
  scheme="${scheme:-https}"
  if [[ -n "$pub_host" ]]; then
    echo
    echo -e "${_C_GREEN}Admin URL:${_C_RESET}  ${scheme}://${pub_host}/"
    echo -e "${_C_GREEN}Tablet URL:${_C_RESET} ${scheme}://${pub_host}:4443"
  fi
  if [[ ! -f "$PLATFORM_ROOT/docker/certs/fullchain.pem" ]]; then
    echo
    echo -e "${_C_YELLOW}⚠${_C_RESET}  TLS cert missing (docker/certs/fullchain.pem). Run: pld certs"
  fi
}

_dev_build() {
  # Export tablet build metadata for compose build-args (mirrors deploy.sh)
  local tablet_dir="$PLATFORM_ROOT/tablet-ordering-pwa"
  export TABLET_BUILD_SHA;    TABLET_BUILD_SHA="$(git -C "$tablet_dir" rev-parse HEAD 2>/dev/null || echo unknown)"
  export TABLET_BUILD_BRANCH; TABLET_BUILD_BRANCH="$(git -C "$tablet_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  export TABLET_BUILD_TIME;   TABLET_BUILD_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  _retry 3 "docker compose build" $DC build
}

_dev_start_migrate() {
  # Start the stack. Reverb can be slow on first boot — if it's the only
  # unhealthy service, restart it once and give it another 60s.
  $DC up -d --remove-orphans || {
    local rc=$?
    # Check if only reverb is unhealthy (common on dev first run)
    if $DC ps reverb 2>/dev/null | grep -qi 'unhealthy'; then
      echo "  Reverb unhealthy on first start — restarting once..."
      $DC restart reverb
      local waited=0
      while (( waited < 60 )); do
        sleep 5; waited=$(( waited + 5 ))
        if $DC ps reverb 2>/dev/null | grep -qiE "(healthy|running)"; then
          echo "  Reverb recovered after ${waited}s"
          break
        fi
        echo "  Waiting for Reverb... (${waited}s)"
      done
      if ! $DC ps reverb 2>/dev/null | grep -qiE "(healthy|running)"; then
        echo "  ERROR: Reverb did not recover after 60s" >&2
        return 1
      fi
    else
      return $rc
    fi
  }
  # Generate APP_KEY if missing (first run)
  if ! _dev_app_key_ok; then
    echo "  APP_KEY missing or invalid — generating..."
    $DC exec -T app php artisan key:generate --force
  fi
  $DC exec -T app php artisan migrate --force
}

_dev_warm() {
  $DC exec -T app php artisan optimize:clear
  $DC exec -T app php artisan config:cache
  $DC exec -T app php artisan route:cache
  $DC exec -T app php artisan view:cache
}

# Inline health check (does NOT use woosoo-health.sh — that requires root + woosoo.env)
_dev_health() {
  local n="$1" total="$2"
  local step_start=$SECONDS
  echo
  echo -e "${_C_BOLD}[${n}/${total}]${_C_RESET} ${_C_CYAN}Health check${_C_RESET}"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo -e "  ${_C_YELLOW}~${_C_RESET}  dry-run: check 8 services + HTTP endpoints"
    _PIPELINE_SKIP=$(( _PIPELINE_SKIP + 1 ))
    return 0
  fi

  # Read host/scheme from .env — localhost fallback when PUBLIC_HOST unset
  local pub_host scheme localhost_host
  pub_host="$(grep -E '^PUBLIC_HOST=' "$_env_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' || true)"
  scheme="$(grep -E '^PUBLIC_SCHEME=' "$_env_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' || echo 'https')"
  pub_host="${pub_host:-}"
  scheme="${scheme:-https}"
  localhost_host="localhost"

  local health_fail=0

  # Service checks
  local services=(nginx app queue scheduler reverb tablet-pwa mysql redis)
  local svc
  for svc in "${services[@]}"; do
    if $DC ps "$svc" 2>/dev/null | grep -qiE "(up|running|healthy)"; then
      echo -e "  ${_C_GREEN}✓${_C_RESET}  $svc"
    else
      echo -e "  ${_C_RED}✗${_C_RESET}  $svc — not running"
      health_fail=1
    fi
  done

  # Baseline: localhost (always reachable from WSL when stack is up)
  if curl -ksf --max-time 10 "${scheme}://${localhost_host}/" -o /dev/null 2>/dev/null; then
    echo -e "  ${_C_GREEN}✓${_C_RESET}  ${scheme}://${localhost_host}/"
  else
    echo -e "  ${_C_YELLOW}⚠${_C_RESET}  ${scheme}://${localhost_host}/ — not reachable (may still be starting)"
    _PIPELINE_WARN=$(( _PIPELINE_WARN + 1 ))
  fi

  local sha_local
  sha_local="$(curl -ksf --max-time 5 "${scheme}://${localhost_host}:4443/build-info.json" 2>/dev/null \
    | grep -o '"sha":"[^"]*"' | cut -d'"' -f4 || echo '')"
  if [[ -n "$sha_local" ]]; then
    echo -e "  ${_C_GREEN}✓${_C_RESET}  ${localhost_host}:4443 build-info.json → sha: ${sha_local:0:7}"
  else
    echo -e "  ${_C_YELLOW}⚠${_C_RESET}  ${localhost_host}:4443 build-info.json — not reachable"
    _PIPELINE_WARN=$(( _PIPELINE_WARN + 1 ))
  fi

  # LAN probe when PUBLIC_HOST is set
  if [[ -n "$pub_host" && "$pub_host" != "$localhost_host" && "$pub_host" != "127.0.0.1" ]]; then
    if curl -ksf --max-time 10 "${scheme}://${pub_host}/" -o /dev/null 2>/dev/null; then
      echo -e "  ${_C_GREEN}✓${_C_RESET}  ${scheme}://${pub_host}/ (LAN)"
    else
      echo -e "  ${_C_YELLOW}⚠${_C_RESET}  ${scheme}://${pub_host}/ — LAN not reachable. Run: woosoo network"
      _PIPELINE_WARN=$(( _PIPELINE_WARN + 1 ))
    fi

    local sha_lan
    sha_lan="$(curl -ksf --max-time 5 "${scheme}://${pub_host}:4443/build-info.json" 2>/dev/null \
      | grep -o '"sha":"[^"]*"' | cut -d'"' -f4 || echo '')"
    if [[ -n "$sha_lan" ]]; then
      echo -e "  ${_C_GREEN}✓${_C_RESET}  ${pub_host}:4443 build-info.json (LAN) → sha: ${sha_lan:0:7}"
    else
      echo -e "  ${_C_YELLOW}⚠${_C_RESET}  ${pub_host}:4443 build-info.json — LAN not reachable. Run: woosoo network"
      _PIPELINE_WARN=$(( _PIPELINE_WARN + 1 ))
    fi
  elif [[ -z "$pub_host" ]]; then
    echo -e "  ${_C_YELLOW}⚠${_C_RESET}  PUBLIC_HOST unset — using localhost only. Run: woosoo network"
    _PIPELINE_WARN=$(( _PIPELINE_WARN + 1 ))
  fi

  # POS DB TCP probe (WARN only — admin POS pages need Krypton on Windows :3308)
  # shellcheck source=scripts/lib/host-network.sh
  source "$SCRIPT_DIR/lib/host-network.sh"
  export HOST_NETWORK_NEXUS_ENV="$_env_file"
  export WOOSOO_POS_DC_CMD="$DC"
  local pos_host pos_port
  pos_host="$(grep -E '^DB_POS_HOST=' "$_env_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' || true)"
  pos_port="$(grep -E '^DB_POS_PORT=' "$_env_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' || true)"
  pos_port="${pos_port:-3308}"
  if woosoo_check_pos_db_connectivity; then
    echo -e "  ${_C_GREEN}✓${_C_RESET}  POS DB reachable (${pos_host:-?}:${pos_port})"
  else
    echo -e "  ${_C_YELLOW}⚠${_C_RESET}  POS DB not reachable — admin POS pages will fail. See DEPLOYMENT_GUIDE §4.1.2"
    _PIPELINE_WARN=$(( _PIPELINE_WARN + 1 ))
  fi

  echo -e "  ${_C_GREEN}✓${_C_RESET}  $(_elapsed "$step_start")"

  if (( health_fail )); then
    _PIPELINE_FAIL=$(( _PIPELINE_FAIL + 1 ))
  else
    _PIPELINE_PASS=$(( _PIPELINE_PASS + 1 ))
  fi
}

# =============================================================================
# Targets
# =============================================================================

target_help() {
  cat <<'EOF'

  pld <target> [flags]          Palisade CLI (preferred)
  woosoo <target> [flags]       deprecated alias — same commands

  Targets:
    sync      Post-push fast path (nexus pull, up, APP_KEY, optimize:clear)
    rebuild   Vite rebuild in Docker (--php for composer install)
    certs     Regenerate dev TLS certs + restart nginx
    dev       Full local Docker dev deploy
    staging   Staging-parity (requires woosoo.env; uses WOOSOO_ALLOW_NON_PI)
    pi        Production Pi deploy (requires root + woosoo.env)
    health    Dev health check
    network   Sync PUBLIC_HOST + LAN bridge + verify
    logs      Tail all service logs
    check     Preflight + env alignment check (auto-fixes config drift)

  Sync flags:
    --full          Full deploy (same as woosoo dev)
    --build         Build images during sync (default: skip build)
    --no-pull       Skip git pull

  Rebuild flags:
    --php           composer install in app container (default: Vite rebuild)

  Network flags:
    --dry-run       Preview changes without writes
    --regen-certs   Regenerate dev TLS certs for PUBLIC_HOST + restart nginx

  Dev flags:
    --no-pull        Skip git pull
    --no-build       Skip docker compose build
    --from-step N    Resume from step N (1–7)
    --dry-run        Print without executing

  Examples:
    pld sync
    pld sync --full
    pld rebuild
    pld certs
    pld dev --no-pull --no-build
    pld network --regen-certs
    pld health
    pld logs

  woosoo * commands are identical but deprecated.

  Docs: docs/architecture/pld-cli-decision.md

EOF
}

target_network() {
  cd "$PLATFORM_ROOT"
  pipeline_banner "network"

  # shellcheck source=scripts/lib/host-network.sh
  source "$LIB_DIR/host-network.sh"
  export HOST_NETWORK_DRY_RUN="${DRY_RUN:-0}"
  export HOST_NETWORK_PLATFORM_ROOT="$PLATFORM_ROOT"

  local detected runtime net_fail=0
  runtime="$(woosoo_detect_runtime)"
  detected="$(woosoo_detect_lan_ip 2>/dev/null || true)"
  detected="${detected//$'\r'/}"
  detected="${detected//$'\n'/}"

  echo
  echo -e "  Runtime     : ${runtime}"
  echo -e "  Detected IP : ${detected:-<none>}"
  echo

  woosoo_check_public_host_drift
  woosoo_check_tls_san

  if ! woosoo_sync_public_host "$detected"; then
    net_fail=1
  fi

  if ! woosoo_ensure_lan_access; then
    _PIPELINE_WARN=$(( _PIPELINE_WARN + 1 ))
  fi

  if [[ "${REGEN_CERTS:-0}" == "1" ]]; then
    echo
    echo -e "${_C_CYAN}Regenerating TLS certs...${_C_RESET}"
    if woosoo_regen_dev_certs; then
      if [[ "${DRY_RUN:-0}" != "1" ]]; then
        $DC restart nginx 2>/dev/null || docker compose --env-file "$_env_file" -f "$PLATFORM_ROOT/compose.yaml" restart nginx
      fi
    else
      net_fail=1
    fi
  fi

  if [[ "${DRY_RUN:-0}" != "1" ]]; then
    echo
    echo -e "${_C_CYAN}Aligning derived Reverb/CORS vars...${_C_RESET}"
    bash "$SCRIPT_DIR/deployment/dev-preflight.sh"
  fi

  if ! woosoo_verify_lan_reachability; then
    _PIPELINE_WARN=$(( _PIPELINE_WARN + 1 ))
  fi

  if [[ -f "$_env_file" ]]; then
    local final_host
    final_host="$(grep -E '^PUBLIC_HOST=' "$_env_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' || true)"
    if [[ -n "$final_host" ]]; then
      echo
      echo -e "${_C_GREEN}Tablet URL:${_C_RESET} https://${final_host}:4443"
      echo -e "${_C_GREEN}Admin URL:${_C_RESET}  https://${final_host}/"
    fi
  fi

  pipeline_summary
  (( net_fail == 0 ))
}

target_sync() {
  cd "$PLATFORM_ROOT"

  if (( SYNC_FULL )); then
    target_dev
    return
  fi

  local total=5
  pipeline_banner "sync"

  echo
  echo -e "${_C_BOLD}[0/${total}]${_C_RESET} ${_C_CYAN}Preflight check + auto-fix${_C_RESET}"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    bash "$SCRIPT_DIR/deployment/dev-preflight.sh" --dry-run
  else
    bash "$SCRIPT_DIR/deployment/dev-preflight.sh"
  fi
  echo

  if (( NO_PULL )); then
    pipeline_skip 1 $total "Pull woosoo-nexus" "--no-pull flag set"
  else
    _step 1 $total "Pull woosoo-nexus" _dev_pull_nexus
  fi

  if _dev_bootstrap_needed; then
    pipeline_step 2 $total "Bootstrap .env" \
      env WOOSOO_DEV_CONFIRM=yes bash "$SCRIPT_DIR/deployment/dev-docker-bootstrap.sh"
  else
    pipeline_skip 2 $total "Bootstrap .env" "already configured"
  fi

  if (( SYNC_BUILD )); then
    _step 3 $total "Build images" _dev_build
  else
    pipeline_skip 3 $total "Build images" "use --build to include"
  fi

  _step 4 $total "Start stack + migrate" _dev_start_migrate

  pipeline_step 5 $total "Clear config cache" _dev_optimize_clear

  _print_dev_urls
  pipeline_summary
  (( _PIPELINE_FAIL == 0 ))
}

target_rebuild() {
  cd "$PLATFORM_ROOT"
  pipeline_banner "rebuild"

  if (( REBUILD_PHP )); then
    echo
    pipeline_step 1 1 "Composer install (app container)" \
      $DC exec -T app composer install --no-interaction --prefer-dist
  else
    echo
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      pipeline_skip 1 1 "Vite rebuild (app)" "dry-run: WOOSOO_FORCE_VITE_BUILD=true docker compose up -d --build app"
    else
      pipeline_step 1 1 "Vite rebuild (app)" \
        env WOOSOO_FORCE_VITE_BUILD=true $DC up -d --build app
    fi
  fi

  _print_dev_urls
  pipeline_summary
}

target_certs() {
  REGEN_CERTS=1
  target_network
}

target_dev() {
  cd "$PLATFORM_ROOT"
  local total=8
  pipeline_banner "dev"

  # Step 0 — Preflight (always runs, before --from-step applies)
  echo
  echo -e "${_C_BOLD}[0/${total}]${_C_RESET} ${_C_CYAN}Preflight check + auto-fix${_C_RESET}"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    bash "$SCRIPT_DIR/deployment/dev-preflight.sh" --dry-run
  else
    bash "$SCRIPT_DIR/deployment/dev-preflight.sh"
  fi
  echo
  # Re-number total for subsequent steps to stay readable
  total=7

  # 1 — Pull
  if (( NO_PULL )); then
    pipeline_skip 1 $total "Pull repos" "--no-pull flag set"
  else
    _step 1 $total "Pull repos" _dev_pull
  fi

  # 2 — Bootstrap .env
  if (( 2 < FROM_STEP )); then
    pipeline_skip 2 $total "Bootstrap .env" "--from-step ${FROM_STEP}"
  elif _dev_bootstrap_needed; then
    pipeline_step 2 $total "Bootstrap .env" \
      env WOOSOO_DEV_CONFIRM=yes bash "$SCRIPT_DIR/deployment/dev-docker-bootstrap.sh"
  else
    pipeline_skip 2 $total "Bootstrap .env" "already configured (APP_ENV=local, SESSION_DOMAIN empty)"
  fi

  # 3 — Build
  if (( NO_BUILD )); then
    pipeline_skip 3 $total "Build images" "--no-build flag set"
  else
    _step 3 $total "Build images" _dev_build
  fi

  # 4 — Start + migrate
  _step 4 $total "Start + migrate" _dev_start_migrate

  # 5 — Warm caches
  _step 5 $total "Warm caches" _dev_warm

  # 6 — POS triggers (v1 skip — Tier 3 POS territory)
  pipeline_skip 6 $total "POS triggers" \
    "v1 skip — run RELEASE_RUNBOOK manually if POS DB is accessible"

  # 7 — Health
  _dev_health 7 $total

  pipeline_summary
  (( _PIPELINE_FAIL == 0 ))
}

target_staging() {
  cd "$PLATFORM_ROOT"
  pipeline_banner "staging"

  # Staging requires woosoo.env
  local config_file=""
  if [[ -f "$PLATFORM_ROOT/woosoo.env" ]]; then
    config_file="$PLATFORM_ROOT/woosoo.env"
  elif [[ -f "/etc/woosoo/woosoo.env" ]]; then
    config_file="/etc/woosoo/woosoo.env"
  else
    echo -e "${_C_RED}ERROR:${_C_RESET} woosoo.env not found."
    echo "  Run first: bash scripts/deployment/init-woosoo-env.sh"
    exit 1
  fi

  export CONFIG_FILE="$config_file"
  export WOOSOO_ALLOW_NON_PI=true
  export WOOSOO_DEPLOY_BRANCH="${WOOSOO_DEPLOY_BRANCH:-dev}"

  echo
  echo -e "${_C_BOLD}[1/1]${_C_RESET} ${_C_CYAN}Staging-parity deploy${_C_RESET}"
  echo "  config: $config_file"
  echo "  branch: $WOOSOO_DEPLOY_BRANCH"
  echo "  mode:   WOOSOO_ALLOW_NON_PI=true (Pi mutations skipped)"
  echo

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "  (dry-run) sudo -E bash scripts/deployment/deploy-all.sh"
    pipeline_summary
    return 0
  fi

  sudo -E bash "$SCRIPT_DIR/deployment/deploy-all.sh"
  pipeline_summary
}

target_pi() {
  cd "$PLATFORM_ROOT"
  pipeline_banner "pi"

  local config_file=""
  if [[ -f "$PLATFORM_ROOT/woosoo.env" ]]; then
    config_file="$PLATFORM_ROOT/woosoo.env"
  elif [[ -f "/etc/woosoo/woosoo.env" ]]; then
    config_file="/etc/woosoo/woosoo.env"
  else
    echo -e "${_C_RED}ERROR:${_C_RESET} woosoo.env not found."
    echo "  Run first: bash scripts/deployment/init-woosoo-env.sh"
    exit 1
  fi

  export CONFIG_FILE="$config_file"
  export WOOSOO_DEPLOY_BRANCH="${WOOSOO_DEPLOY_BRANCH:-main}"

  echo
  echo -e "${_C_BOLD}[1/1]${_C_RESET} ${_C_CYAN}Pi production deploy${_C_RESET}"
  echo "  config: $config_file"
  echo "  branch: $WOOSOO_DEPLOY_BRANCH"
  echo

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "  (dry-run) sudo -E bash scripts/deployment/deploy-all.sh"
    pipeline_summary
    return 0
  fi

  sudo -E bash "$SCRIPT_DIR/deployment/deploy-all.sh"
  pipeline_summary
}

target_health() {
  cd "$PLATFORM_ROOT"
  pipeline_banner "health"
  _dev_health 1 1
  pipeline_summary
  (( _PIPELINE_FAIL == 0 ))
}

target_logs() {
  cd "$PLATFORM_ROOT"
  echo "Tailing logs (Ctrl+C to stop)..."
  $DC logs -f --tail=200
}

target_check() {
  cd "$PLATFORM_ROOT"
  pipeline_banner "check"
  # Run dev preflight (auto-fix + env alignment) then env check
  pipeline_step 1 2 "Dev preflight (auto-fix)" bash "$SCRIPT_DIR/deployment/dev-preflight.sh"
  pipeline_step 2 2 "Environment check" bash "$SCRIPT_DIR/deployment/check.sh"
  pipeline_summary
}

# =============================================================================
# Dispatch
# =============================================================================
case "$TARGET" in
  sync)    target_sync ;;
  rebuild) target_rebuild ;;
  certs)   target_certs ;;
  dev)     target_dev ;;
  staging) target_staging ;;
  pi)      target_pi ;;
  health)  target_health ;;
  network) target_network ;;
  logs)    target_logs ;;
  check)   target_check ;;
  help|-h|--help) target_help ;;
  *)
    echo "Unknown target: $TARGET" >&2
    target_help
    exit 1
    ;;
esac
