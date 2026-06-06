#!/usr/bin/env bash
# =============================================================================
# scripts/pipeline.sh — Woosoo local CI/CD pipeline runner
# =============================================================================
# Usage:
#   bash scripts/pipeline.sh <target> [flags]
#   ./run <target> [flags]          # via root entry point
#   woosoo <target> [flags]         # after: bash scripts/install.sh
#
# Targets:
#   dev       Local Docker dev deploy (pull → bootstrap → build → up → migrate → warm → health)
#   staging   Staging-parity on WSL/dev host (requires woosoo.env; uses WOOSOO_ALLOW_NON_PI)
#   pi        Production Pi deploy (requires root + woosoo.env)
#   health    Inline dev health check (services + HTTP endpoints)
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

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-pull)     NO_PULL=1 ;;
    --no-build)    NO_BUILD=1 ;;
    --dry-run)     DRY_RUN=1 ;;
    --from-step)   FROM_STEP="${2:?--from-step requires a step number}"; shift ;;
    --from-step=*) FROM_STEP="${1#*=}" ;;
    -h|--help)     TARGET="help" ;;
    *)
      echo "Unknown flag: $1" >&2
      echo "Run 'woosoo help' for usage." >&2
      exit 1
      ;;
  esac
  shift
done

export DRY_RUN

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

_dev_bootstrap_needed() {
  # Returns 0 (true) if bootstrap should run; 1 (false) if already configured.
  [[ ! -f "$_env_file" ]] && return 0
  grep -qE '^APP_ENV="?local"?' "$_env_file" || return 0
  grep -qE '^APP_KEY=base64:' "$_env_file"    || return 0
  # SESSION_DOMAIN must be empty
  local sd; sd="$(grep -E '^SESSION_DOMAIN=' "$_env_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' || echo '')"
  [[ -n "$sd" ]] && return 0
  return 1  # all checks passed — skip bootstrap
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
  $DC up -d --remove-orphans
  # Generate APP_KEY if missing (first run)
  if ! grep -qE '^APP_KEY=base64:' "$_env_file" 2>/dev/null; then
    echo "  APP_KEY missing — generating..."
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

  # Read host/scheme from .env
  local host scheme
  host="$(grep -E '^PUBLIC_HOST=' "$_env_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' || echo '192.168.100.7')"
  scheme="$(grep -E '^PUBLIC_SCHEME=' "$_env_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' || echo 'https')"
  host="${host:-192.168.100.7}"
  scheme="${scheme:-https}"

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

  # Admin HTTP
  if curl -ksf --max-time 10 "${scheme}://${host}/" -o /dev/null 2>/dev/null; then
    echo -e "  ${_C_GREEN}✓${_C_RESET}  ${scheme}://${host}/"
  else
    echo -e "  ${_C_YELLOW}⚠${_C_RESET}  ${scheme}://${host}/ — not reachable (may still be starting)"
    _PIPELINE_WARN=$(( _PIPELINE_WARN + 1 ))
  fi

  # Tablet build-info
  local sha; sha="$(curl -ksf --max-time 5 "${scheme}://${host}:4443/build-info.json" 2>/dev/null \
    | grep -o '"sha":"[^"]*"' | cut -d'"' -f4 || echo '')"
  if [[ -n "$sha" ]]; then
    echo -e "  ${_C_GREEN}✓${_C_RESET}  tablet build-info.json → sha: ${sha:0:7}"
  else
    echo -e "  ${_C_YELLOW}⚠${_C_RESET}  build-info.json — not reachable (tablet may still be starting)"
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

  woosoo <target> [flags]

  Targets:
    dev       Local Docker dev deploy
    staging   Staging-parity (requires woosoo.env; uses WOOSOO_ALLOW_NON_PI)
    pi        Production Pi deploy (requires root + woosoo.env)
    health    Dev health check
    logs      Tail all service logs
    check     Preflight check

  Dev flags:
    --no-pull        Skip git pull
    --no-build       Skip docker compose build
    --from-step N    Resume from step N (1–7)
    --dry-run        Print without executing

  Examples:
    woosoo dev
    woosoo dev --no-pull --no-build
    woosoo dev --from-step 4
    woosoo health
    woosoo logs

EOF
}

target_dev() {
  cd "$PLATFORM_ROOT"
  local total=7
  pipeline_banner "dev"

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
    pipeline_skip 2 $total "Bootstrap .env" "already configured (APP_ENV=local, APP_KEY set, SESSION_DOMAIN empty)"
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
  pipeline_step 1 1 "Preflight check" bash "$SCRIPT_DIR/deployment/check.sh"
  pipeline_summary
}

# =============================================================================
# Dispatch
# =============================================================================
case "$TARGET" in
  dev)     target_dev ;;
  staging) target_staging ;;
  pi)      target_pi ;;
  health)  target_health ;;
  logs)    target_logs ;;
  check)   target_check ;;
  help|-h|--help) target_help ;;
  *)
    echo "Unknown target: $TARGET" >&2
    target_help
    exit 1
    ;;
esac
