#!/usr/bin/env bash
# Woosoo pre-merge validation.
# Usage: bash scripts/pre-merge-check.sh --app <woosoo-nexus|tablet-ordering-pwa|woosoo-print-bridge>
# Exits non-zero if any sub-command fails.

set -u

APP=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)
      APP="$2"
      shift 2
      ;;
    --app=*)
      APP="${1#*=}"
      shift
      ;;
    -h|--help)
      cat <<EOF
Usage: bash scripts/pre-merge-check.sh --app <name>

Valid --app values:
  woosoo-nexus
  tablet-ordering-pwa
  woosoo-print-bridge

Runs per-app validation. Fails fast on the first error.
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$APP" ]]; then
  echo "ERROR: --app is required. See --help." >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo
  echo "================================================================"
  echo "  VALIDATION FAILED ($APP) — do not mark work complete"
  echo "  failed step: $1"
  echo "================================================================"
  exit 1
}

run_step() {
  local label="$1"
  shift
  echo
  echo "---- [$APP] $label ----"
  if ! "$@"; then
    fail "$label"
  fi
}

case "$APP" in
  woosoo-nexus)
    cd "$ROOT_DIR/woosoo-nexus" || fail "cd woosoo-nexus"
    run_step "composer test" composer test
    run_step "php artisan route:list" php artisan route:list
    run_step "php artisan config:clear" php artisan config:clear
    ;;

  tablet-ordering-pwa)
    cd "$ROOT_DIR/tablet-ordering-pwa" || fail "cd tablet-ordering-pwa"
    run_step "npm run typecheck" npm run typecheck
    run_step "npm run lint" npm run lint
    run_step "npm run test" npm run test
    run_step "npm run build" npm run build
    run_step "npm run generate" npm run generate
    ;;

  woosoo-print-bridge)
    cd "$ROOT_DIR/woosoo-print-bridge" || fail "cd woosoo-print-bridge"
    # NOTE: The Flutter test suite is currently red per the 2026-05-14 audit.
    # `flutter test` is still required, but a known-failing baseline does not
    # excuse skipping the script — investigate first and update the audit.
    run_step "flutter analyze" flutter analyze
    run_step "flutter test" flutter test
    ;;

  *)
    echo "ERROR: unknown --app value: $APP" >&2
    echo "Valid: woosoo-nexus | tablet-ordering-pwa | woosoo-print-bridge" >&2
    exit 2
    ;;
esac

echo
echo "================================================================"
echo "  pre-merge-check OK ($APP)"
echo "================================================================"
exit 0
