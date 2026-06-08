#!/usr/bin/env bash
# =============================================================================
# scripts/install.sh — Install Palisade `pld` + legacy `woosoo` CLI commands
# =============================================================================
# Creates symlinks in /usr/local/bin:
#   pld    -> <platform_root>/run   (preferred — Palisade CLI)
#   woosoo -> <platform_root>/run   (deprecated alias)
#
# Works on WSL2, Pi, or any Linux/macOS.
#
# Usage:
#   bash scripts/install.sh             # install both
#   bash scripts/install.sh --uninstall # remove both
#   bash scripts/install.sh --woosoo-only   # legacy: woosoo only
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUN_SCRIPT="$PLATFORM_ROOT/run"
INSTALL_DIR="/usr/local/bin"
CMDS=(pld woosoo)
WOOSOO_ONLY=0

if [[ "${1:-}" == "--woosoo-only" ]]; then
  WOOSOO_ONLY=1
  CMDS=(woosoo)
  shift
fi

_install_one() {
  local name="$1"
  local path="$INSTALL_DIR/$name"
  if [[ -f "$path" && ! -L "$path" ]]; then
    echo "ERROR: $path exists and is not a symlink — refusing to overwrite." >&2
    exit 1
  fi
  if [[ -L "$path" ]]; then
    local current_target
    current_target="$(readlink "$path")"
    if [[ "$current_target" == "$RUN_SCRIPT" ]]; then
      echo "Already installed: $path -> $RUN_SCRIPT"
      return 0
    fi
    echo "ERROR: $path already points to $current_target — refusing to overwrite." >&2
    exit 1
  fi
  if [[ -w "$INSTALL_DIR" ]]; then
    ln -s "$RUN_SCRIPT" "$path"
  else
    sudo ln -s "$RUN_SCRIPT" "$path"
  fi
  echo "Installed: $path -> $RUN_SCRIPT"
}

_uninstall_one() {
  local name="$1"
  local path="$INSTALL_DIR/$name"
  if [[ -L "$path" ]]; then
    local current_target
    current_target="$(readlink "$path")"
    if [[ "$current_target" != "$RUN_SCRIPT" ]]; then
      echo "ERROR: $path points to $current_target — refusing to remove a foreign symlink." >&2
      exit 1
    fi
    if [[ -w "$INSTALL_DIR" ]]; then
      rm "$path"
    else
      sudo rm "$path"
    fi
    echo "Removed: $path"
  elif [[ -f "$path" ]]; then
    echo "ERROR: $path is a regular file — refusing to remove." >&2
    exit 1
  else
    echo "Not installed: $path"
  fi
}

# ── Uninstall ─────────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--uninstall" ]]; then
  _uninstall_one pld
  _uninstall_one woosoo
  exit 0
fi

# ── Make run executable ───────────────────────────────────────────────────────
chmod +x "$RUN_SCRIPT"
echo "Made executable: $RUN_SCRIPT"

# ── Create symlinks ───────────────────────────────────────────────────────────
if (( WOOSOO_ONLY )); then
  echo "NOTE: --woosoo-only skips pld; prefer: bash scripts/install.sh (installs both)"
fi

for cmd in "${CMDS[@]}"; do
  _install_one "$cmd"
done

# ── Verify ────────────────────────────────────────────────────────────────────
echo
if command -v pld >/dev/null 2>&1; then
  echo "✓ pld command is available (preferred)"
elif command -v woosoo >/dev/null 2>&1; then
  echo "✓ woosoo command is available (deprecated — re-run install for pld)"
else
  echo "NOTE: $INSTALL_DIR is not in your PATH."
  echo "Add to ~/.bashrc or ~/.bash_profile:"
  echo '  export PATH="/usr/local/bin:$PATH"'
  echo "Then reload: source ~/.bashrc"
fi

# ── Usage ─────────────────────────────────────────────────────────────────────
echo
echo "Usage (Palisade CLI — pld):"
echo "  pld sync              # post-push fast path (WSL after Windows push)"
echo "  pld sync --full       # full dev deploy"
echo "  pld rebuild           # Vite rebuild in Docker"
echo "  pld certs             # regenerate TLS certs"
echo "  pld dev               # full pipeline"
echo "  pld network           # LAN / PUBLIC_HOST sync"
echo "  pld help"
echo
echo "Legacy alias: woosoo (same commands; deprecation notice shown)"
echo "Windows: .\\pld.ps1 sync  or  pld.cmd sync  (WSL required for stack)"
echo
echo "To uninstall: bash scripts/install.sh --uninstall"
