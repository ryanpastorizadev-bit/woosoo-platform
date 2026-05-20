#!/usr/bin/env bash
# =============================================================================
# Woosoo Deployment Pre-flight Doctor
# =============================================================================
# Usage: bash scripts/deployment/doctor.sh
#
# Validates critical deployment environment variables before deploy.sh runs.
# This script prevents placeholder secrets and missing critical config from
# reaching production.
#
# Exit codes:
#   0 = all checks passed
#   1 = one or more critical checks failed
# =============================================================================
set -euo pipefail

CONFIG_FILE="/etc/woosoo/woosoo.env"
ERRORS=()

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "  Woosoo Deployment Doctor"
echo "========================================"
echo

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo -e "${RED}ERROR: Config file not found: $CONFIG_FILE${NC}"
  echo "  Copy docs/deployment/examples/woosoo.env.example to $CONFIG_FILE first."
  exit 1
fi

# Source the config file
set -a
# shellcheck source=/dev/null
source "$CONFIG_FILE" 2>/dev/null || {
  echo -e "${RED}ERROR: Failed to source $CONFIG_FILE${NC}"
  exit 1
}
set +a

echo "Checking critical deployment variables..."
echo

# Function to check if a variable is set and not a placeholder
check_required() {
  local var_name="$1"
  local var_value="${!var_name:-}"
  local forbidden_patterns=("$@")  # Additional forbidden values after var_name
  shift  # Remove first argument (var_name)

  if [[ -z "$var_value" ]]; then
    ERRORS+=("${var_name} is not set")
    echo -e "${RED}✗ ${var_name}${NC} - NOT SET"
    return 1
  fi

  # Check against forbidden patterns (placeholders)
  for pattern in "$@"; do
    if [[ "$var_value" == "$pattern" ]]; then
      ERRORS+=("${var_name} is using placeholder value: ${pattern}")
      echo -e "${RED}✗ ${var_name}${NC} - PLACEHOLDER: ${pattern}"
      return 1
    fi
  done

  echo -e "${GREEN}✓ ${var_name}${NC}"
  return 0
}

# Critical variables that must be set and not placeholders
echo "--- Core Configuration ---"
check_required PUBLIC_HOST
check_required WOOSOO_HOST
check_required WOOSOO_SERVER_IP
check_required WOOSOO_GATEWAY
check_required WOOSOO_CIDR
check_required WOOSOO_NEXUS_PATH
check_required WOOSOO_SCHEME
echo

echo "--- POS Integration (Critical) ---"
check_required WOOSOO_POS_HOST "192.168.100.20"
check_required WOOSOO_POS_PORT "3308"
check_required WOOSOO_POS_DATABASE
check_required WOOSOO_POS_USERNAME
# WOOSOO_POS_PASSWORD can be empty for some setups, but warn if missing
if [[ -z "${WOOSOO_POS_PASSWORD:-}" ]]; then
  echo -e "${YELLOW}⚠ WOOSOO_POS_PASSWORD${NC} - NOT SET (may be acceptable for some POS configs)"
else
  echo -e "${GREEN}✓ WOOSOO_POS_PASSWORD${NC}"
fi
echo

echo "--- Reverb Broadcasting (Critical) ---"
check_required REVERB_APP_KEY "change_this_reverb_key" "your_reverb_key_here" "woosoo"
check_required REVERB_APP_SECRET "change_this_reverb_secret" "your_reverb_secret_here"
check_required REVERB_APP_ID
check_required WOOSOO_REVERB_APP_KEY "change_this_reverb_key" "your_reverb_key_here" "woosoo"
check_required WOOSOO_REVERB_APP_SECRET "change_this_reverb_secret" "your_reverb_secret_here"
check_required WOOSOO_REVERB_APP_ID
echo

echo "--- Database Credentials ---"
check_required WOOSOO_DB_PASSWORD "change_this_password"
check_required WOOSOO_DB_ROOT_PASSWORD "change_this_root_password"
echo

echo "--- Optional but Recommended ---"
if [[ -z "${WOOSOO_DEVICE_AUTH_PASSCODE:-}" ]]; then
  echo -e "${YELLOW}⚠ WOOSOO_DEVICE_AUTH_PASSCODE${NC} - NOT SET (tablets will not be able to register)"
else
  echo -e "${GREEN}✓ WOOSOO_DEVICE_AUTH_PASSCODE${NC}"
fi
echo

# Summary
echo "========================================"
if [[ ${#ERRORS[@]} -eq 0 ]]; then
  echo -e "${GREEN}✓ All checks passed${NC}"
  echo "========================================"
  echo
  exit 0
else
  echo -e "${RED}✗ ${#ERRORS[@]} error(s) found:${NC}"
  echo "========================================"
  for error in "${ERRORS[@]}"; do
    echo -e "${RED}  • ${error}${NC}"
  done
  echo
  echo "Fix these issues in $CONFIG_FILE before deploying."
  echo
  exit 1
fi
