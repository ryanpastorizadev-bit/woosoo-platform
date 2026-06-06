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
#   0. check.sh          — informational preflight (never blocks)
#   1. woosoo-backup.sh  — DB backup BEFORE any change (no-op on a fresh machine)
#   2. deploy.sh         — pull repos, apply config, PREFLIGHT GATE (doctor.sh),
#                          hydrate deps, build fresh, migrate, up, warm cache
#   3. woosoo-health.sh  — post-deploy smoke verify (grace + retry)
#
# The doctor.sh gate runs INSIDE deploy.sh, right after apply-woosoo-config.sh has
# written woosoo-nexus/.env — so it can validate the generated env and is never
# blocked on a fresh machine where that file doesn't exist yet. It is unbypassable
# (deploy.sh always runs it; no skip flag) and gates build/migrate/up.
#
# On any failure the wrapper prints a diagnosis bundle (container status + recent
# logs) and the exact rollback command, then exits non-zero. Rollback is manual
# by design: blind auto-revert is unsafe while DB migrations are forward-only.
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
echo "  Sequence: check -> backup -> deploy (apply config -> doctor gate -> build -> migrate -> up) -> health"
echo "========================================"
echo

PLATFORM_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DC="${WOOSOO_DOCKER_COMPOSE:-docker compose --env-file ./woosoo-nexus/.env -f compose.yaml}"

latest_snapshot() {
  ls -1dt "${WOOSOO_BACKUP_DIR:-/opt/woosoo/backups}"/update-* 2>/dev/null | head -n 1
}

# Best-effort diagnosis bundle so the operator can decide fix-forward vs rollback
# without hunting. Never fails the script itself.
diagnostics() {
  echo "       --- container status ---"
  ( cd "$PLATFORM_ROOT" && $DC ps ) 2>/dev/null || true
  echo "       --- recent logs (app, nginx, reverb, queue) ---"
  ( cd "$PLATFORM_ROOT" && $DC logs --tail=50 app nginx reverb queue ) 2>/dev/null || true
}

# Shared failure handler: diagnosis bundle + exact rollback command, then abort.
# Rollback is intentionally manual — see the header note.
fail_step() {
  local label="$1"
  echo
  echo "ERROR: step failed: $label"
  echo "       Aborting. Inspect the output above before retrying."
  diagnostics
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
}

run_step() {
  local label="$1"; shift
  echo "########################################"
  echo "# $label"
  echo "########################################"
  if ! "$@"; then
    fail_step "$label"
  fi
  echo
}

# Step 0 — informational preflight. check.sh reports anything missing or not
# running (tools, certs, config, app repos, built images, containers) with FIX
# hints. It never blocks the deploy: the doctor.sh gate (inside deploy.sh, after
# config hydration) is the hard gate.
echo "########################################"
echo "# [0/3] check.sh — environment preflight (informational)"
echo "########################################"
if ! bash "$SCRIPT_DIR/check.sh"; then
  echo "NOTE: check.sh reported warnings/failures above. The doctor.sh gate inside deploy.sh will block a bad deploy."
fi
echo

run_step "[1/3] woosoo-backup.sh — DB backup" bash "$SCRIPT_DIR/woosoo-backup.sh"
# deploy.sh runs the doctor.sh gate itself, right after apply-woosoo-config.sh writes
# woosoo-nexus/.env — so the gate validates the generated env and is never blocked on
# a fresh machine. It is unbypassable (no skip flag) and gates build/migrate/up.
run_step "[2/3] deploy.sh — config + gate + build + up" bash "$SCRIPT_DIR/deploy.sh"

# Step 3 — health with grace + retry. The app container has a 90s start_period,
# so a check run too early can report a false failure. Re-try with a grace gap
# before declaring the deploy failed.
echo "########################################"
echo "# [3/3] woosoo-health.sh — verify (grace + retry)"
echo "########################################"
_health_ok=0
# Initial run + up to 2 retries with a 45s gap = 90s grace, matching the app
# container's 90s start_period so a slow warmup isn't mistaken for a failure.
for _attempt in 1 2 3; do
  if bash "$SCRIPT_DIR/woosoo-health.sh"; then _health_ok=1; break; fi
  if [[ "$_attempt" -lt 3 ]]; then
    echo "  health not green yet (attempt ${_attempt}/3); waiting 45s for containers to settle ..."
    sleep 45
  fi
done
[[ "$_health_ok" -eq 1 ]] || fail_step "[3/3] woosoo-health.sh — verify"
echo

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
