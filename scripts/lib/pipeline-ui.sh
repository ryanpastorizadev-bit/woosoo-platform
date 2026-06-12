#!/usr/bin/env bash
# =============================================================================
# scripts/lib/pipeline-ui.sh — Shared step engine, colors, timers
# Source this file; do not execute directly.
# =============================================================================

# ── Color setup ───────────────────────────────────────────────────────────────
if [[ -t 1 ]] && [[ "${NO_COLOR:-}" != "1" ]]; then
  _C_GREEN='\033[0;32m'
  _C_YELLOW='\033[0;33m'
  _C_RED='\033[0;31m'
  _C_CYAN='\033[0;36m'
  _C_BOLD='\033[1m'
  _C_DIM='\033[2m'
  _C_RESET='\033[0m'
else
  _C_GREEN='' _C_YELLOW='' _C_RED='' _C_CYAN='' _C_BOLD='' _C_DIM='' _C_RESET=''
fi

# ── Counters (reset by pipeline_banner) ───────────────────────────────────────
_PIPELINE_PASS=0
_PIPELINE_SKIP=0
_PIPELINE_WARN=0
_PIPELINE_FAIL=0
_PIPELINE_START=$SECONDS

_elapsed() {
  local s=$(( SECONDS - ${1:-$_PIPELINE_START} ))
  if (( s < 60 )); then echo "${s}s"; else echo "$(( s/60 ))m$(( s%60 ))s"; fi
}

# ── Banner ─────────────────────────────────────────────────────────────────────
pipeline_banner() {
  local target="$1"
  local branch; branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  _PIPELINE_PASS=0; _PIPELINE_SKIP=0; _PIPELINE_WARN=0; _PIPELINE_FAIL=0
  _PIPELINE_START=$SECONDS
  echo
  echo -e "${_C_BOLD}══════════════════════════════════════════════${_C_RESET}"
  echo -e "${_C_BOLD}  Woosoo Pipeline  ·  ${target}  ·  branch: ${branch}${_C_RESET}"
  echo -e "${_C_BOLD}══════════════════════════════════════════════${_C_RESET}"
}

# ── Summary ────────────────────────────────────────────────────────────────────
pipeline_summary() {
  local total; total="$(_elapsed "$_PIPELINE_START")"
  echo
  echo -e "${_C_BOLD}══════════════════════════════════════════════${_C_RESET}"
  if (( _PIPELINE_FAIL == 0 )); then
    local counts="${_C_DIM}(pass:${_PIPELINE_PASS} skip:${_PIPELINE_SKIP} warn:${_PIPELINE_WARN})${_C_RESET}"
    echo -e "${_C_GREEN}${_C_BOLD}  ✓ complete  ·  ${total}${_C_RESET}  ${counts}"
  else
    echo -e "${_C_RED}${_C_BOLD}  ✗ failed  ·  ${total}${_C_RESET}  ${_C_DIM}(pass:${_PIPELINE_PASS} fail:${_PIPELINE_FAIL})${_C_RESET}"
  fi
  echo -e "${_C_BOLD}══════════════════════════════════════════════${_C_RESET}"
  echo
}

# ── pipeline_step N TOTAL "label" cmd [args...] ───────────────────────────────
# Runs cmd with live streaming output.
# On failure: prints exit code and calls pipeline_summary + exit.
pipeline_step() {
  local n="$1" total="$2" label="$3"; shift 3
  local step_start=$SECONDS
  echo
  echo -e "${_C_BOLD}[${n}/${total}]${_C_RESET} ${_C_CYAN}${label}${_C_RESET}"

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo -e "  ${_C_YELLOW}~${_C_RESET}  dry-run: $*"
    _PIPELINE_SKIP=$(( _PIPELINE_SKIP + 1 ))
    return 0
  fi

  if "$@"; then
    echo -e "  ${_C_GREEN}✓${_C_RESET}  $(_elapsed "$step_start")"
    _PIPELINE_PASS=$(( _PIPELINE_PASS + 1 ))
  else
    local rc=$?
    echo -e "  ${_C_RED}✗${_C_RESET}  $(_elapsed "$step_start")  (exit ${rc})"
    _PIPELINE_FAIL=$(( _PIPELINE_FAIL + 1 ))
    pipeline_summary
    exit $rc
  fi
}

# ── pipeline_skip N TOTAL "label" "reason" ────────────────────────────────────
pipeline_skip() {
  local n="$1" total="$2" label="$3" reason="$4"
  echo
  echo -e "${_C_BOLD}[${n}/${total}]${_C_RESET} ${_C_DIM}${label}${_C_RESET}"
  echo -e "  ${_C_YELLOW}↷${_C_RESET}  skip — ${reason}"
  _PIPELINE_SKIP=$(( _PIPELINE_SKIP + 1 ))
}

# ── pipeline_warn N TOTAL "label" "reason" ────────────────────────────────────
pipeline_warn() {
  local n="$1" total="$2" label="$3" reason="$4"
  echo
  echo -e "${_C_BOLD}[${n}/${total}]${_C_RESET} ${_C_YELLOW}${label}${_C_RESET}"
  echo -e "  ${_C_YELLOW}⚠${_C_RESET}  warn — ${reason}"
  _PIPELINE_WARN=$(( _PIPELINE_WARN + 1 ))
}
