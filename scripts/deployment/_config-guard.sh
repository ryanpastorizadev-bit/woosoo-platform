#!/usr/bin/env bash
# =============================================================================
# Woosoo — operator-config safety guard  (sourced helper, NOT an entrypoint)
# =============================================================================
# Sourced by the root-run deploy scripts (apply-woosoo-config, deploy, doctor,
# woosoo-backup, woosoo-health) to validate the operator config (woosoo.env)
# BEFORE a root process `source`s it.
#
# `source` executes arbitrary shell, so a root deploy must refuse a config file
# that an unprivileged user could have written, replaced, or symlinked. This
# closes the gap where ./woosoo.env (the user-owned primary) was sourced by root
# with no ownership/mode validation — only /etc/woosoo/* was previously checked.
#
#   woosoo_assert_safe_config <path>   -> 0 if safe, non-zero (with reason) otherwise
#
# Rejects: missing file, symlink, group/other-writable mode, or ownership by
# neither root (0) nor the invoking (sudo) user. Callers should `|| exit 1`.
# =============================================================================

woosoo_assert_safe_config() {
  local file="${1:-}"
  if [[ -z "$file" ]]; then
    echo "ERROR: woosoo_assert_safe_config: no config path given." >&2
    return 1
  fi
  if [[ ! -f "$file" || -L "$file" ]]; then
    echo "ERROR: config file is missing or a symlink (refusing to source): $file" >&2
    return 1
  fi

  local uid mode allowed_uid
  uid="$(stat -c '%u' "$file" 2>/dev/null)" || { echo "ERROR: cannot stat config file: $file" >&2; return 1; }
  mode="$(stat -c '%a' "$file" 2>/dev/null)" || { echo "ERROR: cannot stat config file: $file" >&2; return 1; }

  # Allowed owners: root, or the human who invoked sudo (SUDO_UID); fall back to
  # the current EUID for non-sudo invocations.
  allowed_uid="${SUDO_UID:-$(id -u)}"
  if [[ "$uid" != "0" && "$uid" != "$allowed_uid" ]]; then
    echo "ERROR: $file must be owned by root or the deploying user (uid ${allowed_uid}); found uid ${uid}." >&2
    echo "       A root deploy will not source a config owned by another user (code-execution risk)." >&2
    echo "       Fix: sudo chown root:root \"$file\"   (or chown to the deploying user)" >&2
    return 1
  fi

  # Must not be writable by group or other (0022).
  if (( (8#$mode & 0022) != 0 )); then
    echo "ERROR: $file is group/other-writable (mode ${mode}); refusing to source as root." >&2
    echo "       Fix: chmod go-w \"$file\"   (expected 0600 for ./woosoo.env, 0640 for /etc/woosoo)" >&2
    return 1
  fi

  return 0
}
