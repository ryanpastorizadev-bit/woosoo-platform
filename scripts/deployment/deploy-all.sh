#!/usr/bin/env bash
# =============================================================================
# Woosoo Pi5 — Safe Deploy Wrapper  (PLATFORM-ROOT AUTHORITY)
# =============================================================================
# Usage (from the Pi5 console, as root):
#   sudo bash scripts/deployment/deploy-all.sh
#
# This is the one operator command for a full safe deploy. It runs the
# canonical sequence in strict order with hard stops on any failure:
#
#   1. doctor.sh         — preflight diagnostic (read-only)
#   2. woosoo-backup.sh  — DB backup BEFORE any change
#   3. deploy.sh         — pull app repos, apply config, build + up, warm cache
#   4. woosoo-health.sh  — post-deploy smoke verify
#
# If any step fails the wrapper exits non-zero immediately. Subsequent steps
# do not run. No silent skipping.
#
# Rollback (if needed): sudo bash scripts/deployment/rollback-client.sh <backup-dir>
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: Run as root: sudo bash scripts/deployment/deploy-all.sh"
  exit 1
fi

echo "========================================"
echo "  Woosoo Pi5 Safe Deploy"
echo "  Sequence: doctor -> backup -> deploy -> health"
echo "========================================"
echo

latest_snapshot() {
  ls -1dt "${WOOSOO_BACKUP_DIR:-/opt/woosoo/backups}"/update-* 2>/dev/null | head -n 1
}

run_step() {
  local label="$1"; shift
  echo "########################################"
  echo "# $label"
  echo "########################################"
  if ! "$@"; then
    echo
    echo "ERROR: step failed: $label"
    echo "       Aborting. Inspect the output above before retrying."
    local snap
    snap="$(latest_snapshot)"
    if [[ -n "$snap" ]]; then
      echo "       Rollback (if needed):"
      echo "         sudo bash scripts/deployment/rollback-client.sh $snap"
    else
      echo "       No pre-deploy snapshot found yet (failed before deploy.sh ran)."
      echo "       Manual rollback path:"
      echo "         sudo bash scripts/deployment/rollback-client.sh <backup-dir>"
    fi
    exit 1
  fi
  echo
}

run_step "[1/4] doctor.sh — preflight"        bash "$SCRIPT_DIR/doctor.sh"
run_step "[2/4] woosoo-backup.sh — DB backup" bash "$SCRIPT_DIR/woosoo-backup.sh"
run_step "[3/4] deploy.sh — build + up"       bash "$SCRIPT_DIR/deploy.sh"
run_step "[4/4] woosoo-health.sh — verify"    bash "$SCRIPT_DIR/woosoo-health.sh"

SNAP="$(latest_snapshot)"

echo "========================================"
echo "  OK: deploy-all completed cleanly."
echo "========================================"
echo "  Verify live build:"
echo "    curl -ks https://\$WOOSOO_HOST:4443/build-info.json"
echo
if [[ -n "$SNAP" ]]; then
  echo "  If anything looks wrong, rollback:"
  echo "    sudo bash scripts/deployment/rollback-client.sh $SNAP"
else
  echo "  Rollback handle was not produced by deploy.sh — inspect /opt/woosoo/backups/."
fi
echo
