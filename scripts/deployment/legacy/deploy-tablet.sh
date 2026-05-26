#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NEXUS_DIR="${NEXUS_DIR:-$ROOT_DIR}"
TABLET_DIR="${TABLET_DIR:-$(cd "$NEXUS_DIR/.." && pwd)/tablet-ordering-pwa}"
COMPOSE_FILE="${COMPOSE_FILE:-$NEXUS_DIR/compose.yaml}"
ALLOW_DIRTY="${ALLOW_DIRTY:-0}"

nexus_current_branch="$(git -C "$NEXUS_DIR" rev-parse --abbrev-ref HEAD)"
NEXUS_DEPLOY_BRANCH="${NEXUS_DEPLOY_BRANCH:-${NEXUS_BRANCH:-$nexus_current_branch}}"
TABLET_DEPLOY_BRANCH="${TABLET_DEPLOY_BRANCH:-${TABLET_BRANCH:-$NEXUS_DEPLOY_BRANCH}}"
NEXUS_DEPLOY_REF="${NEXUS_DEPLOY_REF:-}"
TABLET_DEPLOY_REF="${TABLET_DEPLOY_REF:-}"

if [[ -z "$NEXUS_DEPLOY_REF" || -z "$TABLET_DEPLOY_REF" ]]; then
  echo "ERROR: Explicit NEXUS_DEPLOY_REF and TABLET_DEPLOY_REF are required for tablet deployments." >&2
  echo "Set both refs to immutable commit SHAs or tags before deploying." >&2
  exit 1
fi

compose_cmd=(docker compose -f "$COMPOSE_FILE")
verify_script="$NEXUS_DIR/scripts/deployment/verify-tablet-deploy-context.sh"

require_clean_if_needed() {
  local dir="$1"
  local name="$2"
  if [[ "$ALLOW_DIRTY" == "1" ]]; then
    return
  fi

  if [[ -n "$(git -C "$dir" status --porcelain)" ]]; then
    echo "ERROR: ${name} repo is dirty. Commit/stash changes or set ALLOW_DIRTY=1." >&2
    exit 1
  fi
}

sync_repo() {
  local dir="$1"
  local label="$2"
  local branch="$3"
  local ref="$4"

  if [[ ! -d "$dir/.git" ]]; then
    echo "ERROR: ${label} repo not found at ${dir}" >&2
    exit 1
  fi

  require_clean_if_needed "$dir" "$label"

  echo "Syncing ${label} repo to branch ${branch}..."
  git -C "$dir" fetch --prune origin "$branch"

  if git -C "$dir" show-ref --verify --quiet "refs/heads/${branch}"; then
    git -C "$dir" checkout "$branch"
  else
    git -C "$dir" checkout -b "$branch" "origin/$branch"
  fi

  git -C "$dir" pull --ff-only origin "$branch"

  if [[ -n "$ref" ]]; then
    echo "Pinning ${label} repo to ref ${ref}..."
    git -C "$dir" fetch --prune origin
    # Check if ref is an existing local branch; if not, create/update a deployment branch
    if git -C "$dir" show-ref --verify --quiet "refs/heads/${ref}"; then
      git -C "$dir" checkout "$ref"
    else
      # ref is a commit hash or tag - create/update a deployment branch to avoid detached HEAD
      local deploy_branch="deploy/${ref}"
      echo "Creating deployment branch ${deploy_branch} for ref ${ref}..."
      git -C "$dir" checkout -B "$deploy_branch" "$ref"
    fi
  fi
}

sync_repo "$NEXUS_DIR" "Nexus" "$NEXUS_DEPLOY_BRANCH" "$NEXUS_DEPLOY_REF"
sync_repo "$TABLET_DIR" "Tablet" "$TABLET_DEPLOY_BRANCH" "$TABLET_DEPLOY_REF"

nexus_branch="$(git -C "$NEXUS_DIR" rev-parse --abbrev-ref HEAD)"
nexus_commit="$(git -C "$NEXUS_DIR" rev-parse HEAD)"
tablet_branch="$(git -C "$TABLET_DIR" rev-parse --abbrev-ref HEAD)"
tablet_commit="$(git -C "$TABLET_DIR" rev-parse HEAD)"

export TABLET_BUILD_NEXUS_BRANCH="$nexus_branch"
export TABLET_BUILD_NEXUS_COMMIT="$nexus_commit"
export TABLET_BUILD_TABLET_BRANCH="$tablet_branch"
export TABLET_BUILD_TABLET_COMMIT="$tablet_commit"
export TABLET_BUILD_FINGERPRINT="${nexus_commit:0:12}-${tablet_commit:0:12}"

if [[ ! -f "$verify_script" ]]; then
  echo "ERROR: verify script not found: ${verify_script}" >&2
  exit 1
fi
if [[ ! -x "$verify_script" ]]; then
  echo "ERROR: verify script is not executable: ${verify_script}" >&2
  echo "Run: chmod +x ${verify_script}" >&2
  exit 1
fi
"$verify_script"

echo "Building and deploying tablet-pwa with fingerprint ${TABLET_BUILD_FINGERPRINT}..."
"${compose_cmd[@]}" build tablet-pwa
"${compose_cmd[@]}" up -d tablet-pwa nginx
"${compose_cmd[@]}" ps tablet-pwa nginx

echo "Done. Tablet deploy branch=${tablet_branch} commit=${tablet_commit} fingerprint=${TABLET_BUILD_FINGERPRINT}"
