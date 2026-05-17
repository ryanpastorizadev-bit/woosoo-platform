#!/usr/bin/env bash
# case-status — print or update the "## Run State" block in docs/cases/<slug>.md
#
# Cross-runner resume helper (Claude Code / Codex / Copilot). Dependency-free
# (bash + awk + sed). Keeps the Run State header consistent so any runner can
# resume. See docs/RESUME_PROTOCOL.md.
#
# Usage:
#   bash scripts/case-status.sh get  <slug>
#   bash scripts/case-status.sh set  <slug> key=value [key=value ...]
#   bash scripts/case-status.sh init <slug>     # create from _TEMPLATE.md if missing
#
# Keys: task_slug tier branch status last_completed_agent next_agent
#       active_runner interrupted interrupt_reason updated
# 'updated' is auto-set to the current time on 'set' unless passed explicitly.
# Only keys already present in the Run State block are updated (the template
# ships every key).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CASES_DIR="$ROOT_DIR/docs/cases"
TEMPLATE="$CASES_DIR/_TEMPLATE.md"
ALLOWED="task_slug tier branch status last_completed_agent next_agent active_runner interrupted interrupt_reason updated"

die() { echo "case-status: $*" >&2; exit 1; }
usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/case-status.sh get  <slug>
  bash scripts/case-status.sh set  <slug> key=value [key=value ...]
  bash scripts/case-status.sh init <slug>
Keys: task_slug tier branch status last_completed_agent next_agent
      active_runner interrupted interrupt_reason updated
EOF
  exit 2
}

print_block() {
  awk '/^## Run State/{f=1}
       f && /^## / && !/^## Run State/{exit}
       f{print}' "$1"
}

[ $# -ge 2 ] || usage
CMD="$1"; SLUG="$2"; shift 2
CASE_FILE="$CASES_DIR/$SLUG.md"

case "$CMD" in
  init)
    [ -f "$TEMPLATE" ] || die "template not found: $TEMPLATE"
    if [ -f "$CASE_FILE" ]; then
      echo "case-status: $CASE_FILE already exists (not overwritten)"
    else
      sed "s/<slug>/$SLUG/g" "$TEMPLATE" > "$CASE_FILE"
      echo "case-status: created $CASE_FILE"
    fi
    ;;
  get)
    [ -f "$CASE_FILE" ] || die "case file not found: $CASE_FILE"
    print_block "$CASE_FILE"
    ;;
  set)
    [ -f "$CASE_FILE" ] || die "case file not found: $CASE_FILE"
    [ $# -ge 1 ] || die "set requires at least one key=value"
    grep -q '^## Run State' "$CASE_FILE" || die "no '## Run State' block in $CASE_FILE"
    tmp="$(mktemp)"; cp "$CASE_FILE" "$tmp"
    have_updated=0
    for kv in "$@"; do
      key="${kv%%=*}"; val="${kv#*=}"
      [ "$key" = "$kv" ] && die "bad arg (need key=value): $kv"
      case " $ALLOWED " in *" $key "*) ;; *) die "unknown key: $key (allowed: $ALLOWED)";; esac
      [ "$key" = "updated" ] && have_updated=1
      awk -v k="$key" -v v="$val" '
        /^## Run State/{inblk=1}
        inblk && /^## / && !/^## Run State/{inblk=0}
        { if (inblk && $0 ~ ("^- " k ":")) print "- " k ": " v; else print }
      ' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
    done
    if [ "$have_updated" -eq 0 ]; then
      ts="$(date '+%Y-%m-%d %H:%M')"
      awk -v v="$ts" '
        /^## Run State/{inblk=1}
        inblk && /^## / && !/^## Run State/{inblk=0}
        { if (inblk && $0 ~ "^- updated:") print "- updated: " v; else print }
      ' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
    fi
    mv "$tmp" "$CASE_FILE"
    print_block "$CASE_FILE"
    ;;
  *)
    usage
    ;;
esac
