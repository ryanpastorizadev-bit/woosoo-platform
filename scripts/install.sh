#!/usr/bin/env bash
# =============================================================================
# scripts/install.sh — Install the `woosoo` CLI command
# =============================================================================
# Creates /usr/local/bin/woosoo -> <platform_root>/run
# Works on WSL2, Pi, or any Linux/macOS.
#
# Usage:
#   bash scripts/install.sh             # install
#   bash scripts/install.sh --uninstall # remove
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUN_SCRIPT="$PLATFORM_ROOT/run"
INSTALL_DIR="/usr/local/bin"
CMD_NAME="woosoo"
INSTALL_PATH="$INSTALL_DIR/$CMD_NAME"

# ── Uninstall ─────────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--uninstall" ]]; then
  if [[ -L "$INSTALL_PATH" || -f "$INSTALL_PATH" ]]; then
    if [[ -w "$INSTALL_DIR" ]]; then
      rm "$INSTALL_PATH"
    else
      sudo rm "$INSTALL_PATH"
    fi
    echo "Removed: $INSTALL_PATH"
  else
    echo "Not installed: $INSTALL_PATH"
  fi
  exit 0
fi

# ── Make run executable ───────────────────────────────────────────────────────
chmod +x "$RUN_SCRIPT"
echo "Made executable: $RUN_SCRIPT"

# ── Create symlink ────────────────────────────────────────────────────────────
if [[ -L "$INSTALL_PATH" ]]; then
  current_target="$(readlink "$INSTALL_PATH")"
  if [[ "$current_target" == "$RUN_SCRIPT" ]]; then
    echo "Already installed: $INSTALL_PATH -> $RUN_SCRIPT"
    _already_installed=1
  else
    echo "Updating: $INSTALL_PATH (was -> $current_target)"
    _already_installed=0
  fi
else
  _already_installed=0
fi

if [[ "${_already_installed:-0}" == "0" ]]; then
  if [[ -L "$INSTALL_PATH" || -f "$INSTALL_PATH" ]]; then
    [[ -w "$INSTALL_DIR" ]] && rm "$INSTALL_PATH" || sudo rm "$INSTALL_PATH"
  fi
  if [[ -w "$INSTALL_DIR" ]]; then
    ln -s "$RUN_SCRIPT" "$INSTALL_PATH"
  else
    sudo ln -s "$RUN_SCRIPT" "$INSTALL_PATH"
  fi
  echo "Installed: $INSTALL_PATH -> $RUN_SCRIPT"
fi

# ── Verify ────────────────────────────────────────────────────────────────────
if command -v woosoo >/dev/null 2>&1; then
  echo
  echo "✓ woosoo command is available"
else
  echo
  echo "NOTE: $INSTALL_DIR is not in your PATH."
  echo "Add to ~/.bashrc or ~/.bash_profile:"
  echo '  export PATH="/usr/local/bin:$PATH"'
  echo "Then reload: source ~/.bashrc"
fi

# ── Usage ─────────────────────────────────────────────────────────────────────
echo
echo "Usage:"
echo "  woosoo dev            # dev test deploy"
echo "  woosoo staging        # staging-parity (requires woosoo.env)"
echo "  woosoo pi             # Pi production deploy (requires root)"
echo "  woosoo health         # health check"
echo "  woosoo logs           # tail logs"
echo "  woosoo check          # preflight check"
echo "  woosoo dev --no-pull  # skip git pull"
echo "  woosoo dev --no-build # skip docker compose build"
echo "  woosoo dev --dry-run  # print steps without executing"
echo
echo "To uninstall: bash scripts/install.sh --uninstall"
