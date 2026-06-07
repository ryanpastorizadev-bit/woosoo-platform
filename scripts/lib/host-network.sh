#!/usr/bin/env bash
# =============================================================================
# scripts/lib/host-network.sh — Unified LAN host detection (Pi + WSL + native)
# =============================================================================
# Sourced by dev-preflight.sh, pipeline.sh (woosoo network), dev-docker-bootstrap.
#
# Passive (woosoo dev):  woosoo_check_public_host_drift, woosoo_check_tls_san, woosoo_check_pos_db_host
# Active (woosoo network): woosoo_sync_public_host, woosoo_ensure_lan_access, woosoo_verify_lan_reachability
# Health (woosoo health): woosoo_check_pos_db_connectivity (WARN-only TCP probe via WOOSOO_POS_DC_CMD)
# Opt-in auto-sync:       WOOSOO_AUTO_SYNC=1 in dev-preflight
#
# WSL ↔ Windows boundary: read woosoo-nexus/.env only on the WSL/bash side.
# Delegate to .ps1 via wslpath -w + -File (never inline -Command). PowerShell
# scripts may read .env from the Windows path; do not pass .env values through
# wsl bash -c "..." from PowerShell — quoting breaks on nested quotes.
# get-windows-lan-ip.ps1 must emit a bare IPv4 string (no extra stdout).
# =============================================================================

if [[ -n "${_WOOSOO_HOST_NETWORK_LOADED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
_WOOSOO_HOST_NETWORK_LOADED=1

_HOST_NETWORK_ROOT="${HOST_NETWORK_PLATFORM_ROOT:-}"
if [[ -z "$_HOST_NETWORK_ROOT" ]]; then
  _hn_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  _HOST_NETWORK_ROOT="$(cd "$_hn_script_dir/../.." && pwd)"
fi

_NEXUS_ENV="${HOST_NETWORK_NEXUS_ENV:-$_HOST_NETWORK_ROOT/woosoo-nexus/.env}"
_CERT_FILE="${HOST_NETWORK_CERT_FILE:-$_HOST_NETWORK_ROOT/docker/certs/fullchain.pem}"

_hn_env_get() {
  local key="$1" file="${2:-$_NEXUS_ENV}"
  grep -E "^${key}=" "$file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'"
}

_hn_warn() {
  printf '[WARN] %s\n' "$*" >&2
}

_hn_info() {
  printf '[INFO] %s\n' "$*" >&2
}

_hn_sync_log() {
  printf '[SYNC] %s\n' "$*" >&2
}

# Sync REVERB_ALLOWED_ORIGINS for active LAN IP.
# With old_ip: remove old_ip, ensure active_ip, preserve other entries (Pi dual-network).
# Without old_ip: active_ip + hostname + non-IPv4 only; prune other stale IPv4s (dev preflight).
woosoo_reverb_allowed_origins_sync() {
  local active_ip="$1"
  local existing="${2:-}"
  local old_ip="${3:-}"
  local -a entries=()
  local -a result=()
  local -a seen=()
  local entry hostname woosoo_env dup e s out

  if [[ -n "$existing" ]]; then
    IFS=',' read -ra entries <<< "$existing"
    for entry in "${entries[@]}"; do
      entry="${entry// /}"
      [[ -z "$entry" ]] && continue
      if [[ -n "$old_ip" && "$entry" == "$old_ip" ]]; then
        continue
      fi
      if [[ -z "$old_ip" && "$entry" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ && "$entry" != "$active_ip" ]]; then
        continue
      fi
      result+=("$entry")
    done
  fi

  woosoo_env=""
  if [[ -f "$_HOST_NETWORK_ROOT/woosoo.env" ]]; then
    woosoo_env="$_HOST_NETWORK_ROOT/woosoo.env"
  elif [[ -f /etc/woosoo/woosoo.env ]]; then
    woosoo_env="/etc/woosoo/woosoo.env"
  fi
  if [[ -n "$woosoo_env" ]]; then
    hostname="$(grep -E '^WOOSOO_HOST=' "$woosoo_env" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'")"
    if [[ -n "$hostname" ]]; then
      result+=("$hostname")
    fi
  fi
  result+=("$active_ip")

  out=""
  for e in "${result[@]}"; do
    dup=0
    for s in "${seen[@]:-}"; do
      if [[ "$s" == "$e" ]]; then
        dup=1
        break
      fi
    done
    if [[ "$dup" -eq 0 ]]; then
      seen+=("$e")
      if [[ -n "$out" ]]; then
        out+=","
      fi
      out+="$e"
    fi
  done
  printf '%s' "$out"
}

# Print operator steps after woosoo-nexus/.env mutation (env_file baked at container create).
woosoo_print_nexus_env_reload_steps() {
  printf '       Recreate: docker compose --env-file ./woosoo-nexus/.env -f compose.yaml up -d --force-recreate app queue scheduler reverb\n' >&2
  printf '       Clear cache: docker compose --env-file ./woosoo-nexus/.env -f compose.yaml exec -T app php artisan optimize:clear\n' >&2
}

# ── woosoo_detect_runtime ─────────────────────────────────────────────────────
# Returns: pi | wsl | native
woosoo_detect_runtime() {
  if command -v vcgencmd >/dev/null 2>&1; then
    echo pi
    return 0
  fi
  if [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qiE 'microsoft|WSL' /proc/version 2>/dev/null; then
    echo wsl
    return 0
  fi
  echo native
}

# ── woosoo_detect_lan_ip ────────────────────────────────────────────────────
# Returns LAN IP clients use to reach nginx. Empty string on failure.
# Override: WOOSOO_PUBLIC_HOST
woosoo_detect_lan_ip() {
  if [[ -n "${WOOSOO_PUBLIC_HOST:-}" ]]; then
    echo "$WOOSOO_PUBLIC_HOST"
    return 0
  fi

  local runtime
  runtime="$(woosoo_detect_runtime)"

  case "$runtime" in
    pi|native)
      local woosoo_env=""
      if [[ -f "$_HOST_NETWORK_ROOT/woosoo.env" ]]; then
        woosoo_env="$_HOST_NETWORK_ROOT/woosoo.env"
      elif [[ -f /etc/woosoo/woosoo.env ]]; then
        woosoo_env="/etc/woosoo/woosoo.env"
      fi
      if [[ -n "$woosoo_env" ]]; then
        local server_ip
        server_ip="$(grep -E '^WOOSOO_SERVER_IP=' "$woosoo_env" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'")"
        if [[ -n "$server_ip" ]]; then
          echo "$server_ip"
          return 0
        fi
      fi
      ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}'
      ;;
    wsl)
      local ps1="$_HOST_NETWORK_ROOT/scripts/windows/get-windows-lan-ip.ps1"
      if [[ ! -f "$ps1" ]]; then
        _hn_warn "get-windows-lan-ip.ps1 missing at $ps1"
        return 1
      fi
      local win_ps1
      win_ps1="$(wslpath -w "$ps1" 2>/dev/null || echo "")"
      if [[ -z "$win_ps1" ]]; then
        _hn_warn "wslpath failed — cannot call Windows LAN IP detector"
        return 1
      fi
      powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$win_ps1" 2>/dev/null | tr -d '\r' | head -1
      ;;
  esac
}

# ── woosoo_check_public_host_drift ──────────────────────────────────────────
# WARN if detected LAN IP differs from PUBLIC_HOST in .env. No writes.
woosoo_check_public_host_drift() {
  if [[ ! -f "$_NEXUS_ENV" ]]; then
    _hn_warn "nexus .env missing — cannot check PUBLIC_HOST drift"
    return 0
  fi

  local detected current
  detected="$(woosoo_detect_lan_ip 2>/dev/null || true)"
  detected="${detected//$'\n'/}"
  detected="${detected//$'\r'/}"
  current="$(_hn_env_get PUBLIC_HOST)"

  if [[ -z "$detected" ]]; then
    _hn_warn "Could not detect LAN IP — set WOOSOO_PUBLIC_HOST or run: woosoo network"
    return 0
  fi

  if [[ -z "$current" ]]; then
    _hn_warn "PUBLIC_HOST is not set in nexus .env (detected LAN IP=$detected)"
    printf '       FIX: woosoo network\n' >&2
    return 0
  fi

  if [[ "$detected" != "$current" ]]; then
    _hn_warn "PUBLIC_HOST=$current but detected LAN IP=$detected"
    printf '       Tablets configured for the old IP will fail. Run: woosoo network\n' >&2
    printf '       (or WOOSOO_AUTO_SYNC=1 woosoo dev to opt in to silent sync)\n' >&2
  fi
}

# ── woosoo_check_tls_san ────────────────────────────────────────────────────
# WARN if cert SAN does not cover PUBLIC_HOST. Never auto-regenerates.
woosoo_check_tls_san() {
  if [[ ! -f "$_NEXUS_ENV" ]]; then
    return 0
  fi
  local host
  host="$(_hn_env_get PUBLIC_HOST)"
  if [[ -z "$host" ]]; then
    return 0
  fi
  if [[ ! -f "$_CERT_FILE" ]]; then
    _hn_warn "TLS cert not found at $_CERT_FILE"
    printf '       FIX: woosoo network --regen-certs\n' >&2
    return 0
  fi
  if openssl x509 -in "$_CERT_FILE" -noout -text 2>/dev/null | grep -qF "$host"; then
    return 0
  fi
  _hn_warn "TLS cert does not include PUBLIC_HOST=$host"
  printf '       FIX: woosoo network --regen-certs\n' >&2
}

# ── woosoo_sync_public_host ───────────────────────────────────────────────────
# Rewrite PUBLIC_HOST + derived URL vars. Opt-in only (woosoo network / WOOSOO_AUTO_SYNC).
woosoo_sync_public_host() {
  local new_ip="${1:-}"
  if [[ -z "$new_ip" ]]; then
    new_ip="$(woosoo_detect_lan_ip 2>/dev/null || true)"
    new_ip="${new_ip//$'\n'/}"
    new_ip="${new_ip//$'\r'/}"
  fi
  if [[ -z "$new_ip" ]]; then
    _hn_warn "Cannot sync PUBLIC_HOST — no LAN IP detected"
    return 1
  fi
  if [[ ! -f "$_NEXUS_ENV" ]]; then
    _hn_warn "Cannot sync — $_NEXUS_ENV missing"
    return 1
  fi

  local old_ip scheme dry
  old_ip="$(_hn_env_get PUBLIC_HOST)"
  scheme="$(_hn_env_get PUBLIC_SCHEME)"
  scheme="${scheme:-https}"
  dry="${HOST_NETWORK_DRY_RUN:-0}"

  if [[ "$old_ip" == "$new_ip" ]]; then
    _hn_info "PUBLIC_HOST already $new_ip — no sync needed"
    return 0
  fi

  if [[ "$dry" == "1" ]]; then
    _hn_info "DRY-RUN: would sync PUBLIC_HOST: ${old_ip:-<unset>} → $new_ip"
    return 0
  fi

  cp "$_NEXUS_ENV" "$_NEXUS_ENV.bak.$(date +%F_%H%M%S)"
  chmod 600 "$_NEXUS_ENV.bak."* 2>/dev/null || true

  _hn_sync_log "PUBLIC_HOST: ${old_ip:-<unset>} → $new_ip (Reverb/CORS/Sanctum updated)"

  _hn_env_set() {
    local key="$1" value="$2"
    local escaped_key quoted
    escaped_key="$(printf '%s' "$key" | sed 's/[[\.*^$()+?{|]/\\&/g')"
    quoted="\"$(printf '%s' "$value" | sed 's/"/\\"/g')\""
    if grep -qE "^${escaped_key}=" "$_NEXUS_ENV" 2>/dev/null; then
      sed -i "s|^${escaped_key}=.*|${key}=${quoted}|" "$_NEXUS_ENV"
    else
      printf '%s=%s\n' "$key" "$quoted" >> "$_NEXUS_ENV"
    fi
  }

  _hn_env_set PUBLIC_HOST "$new_ip"
  _hn_env_set APP_URL "${scheme}://${new_ip}"
  _hn_env_set REVERB_PUBLIC_HOST "$new_ip"
  _hn_env_set VITE_REVERB_HOST "$new_ip"
  _hn_env_set NUXT_PUBLIC_REVERB_HOST "$new_ip"
  _hn_env_set APP_RUNTIME_REVERB_HOST "$new_ip"
  _hn_env_set NUXT_PUBLIC_API_BASE_URL "${scheme}://${new_ip}/api"
  _hn_env_set APP_RUNTIME_API_BASE_URL "${scheme}://${new_ip}/api"
  _hn_env_set MAIN_API_URL "${scheme}://${new_ip}"
  _hn_env_set SANCTUM_STATEFUL_DOMAINS "${new_ip},${new_ip}:443,${new_ip}:4443,localhost,localhost:443,localhost:4443"
  _hn_env_set CORS_ALLOWED_ORIGINS "${scheme}://${new_ip},${scheme}://${new_ip}:4443,https://localhost,https://localhost:4443"

  local allowed origins
  allowed="$(_hn_env_get REVERB_ALLOWED_ORIGINS)"
  origins="$(woosoo_reverb_allowed_origins_sync "$new_ip" "$allowed" "$old_ip")"
  _hn_env_set REVERB_ALLOWED_ORIGINS "$origins"

  woosoo_print_nexus_env_reload_steps
  return 0
}

# ── woosoo_ensure_lan_access ──────────────────────────────────────────────────
woosoo_ensure_lan_access() {
  local runtime dry
  runtime="$(woosoo_detect_runtime)"
  dry="${HOST_NETWORK_DRY_RUN:-0}"

  case "$runtime" in
    pi|native)
      local ok=0
      if command -v ss >/dev/null 2>&1; then
        for port in 80 443 4443; do
          if ss -ltn 2>/dev/null | grep -qE "0\.0\.0\.0:${port}\b|:::${port}\b|\[::\]:${port}\b"; then
            _hn_info "Port $port listening on all interfaces"
          else
            _hn_warn "Port $port not bound on 0.0.0.0 — LAN clients may not reach nginx"
            ok=1
          fi
        done
        return $ok
      fi
      _hn_info "ss not available — skipping bind check"
      return 0
      ;;
    wsl)
      local ps1="$_HOST_NETWORK_ROOT/scripts/windows/setup-wsl-lan-access.ps1"
      if [[ ! -f "$ps1" ]]; then
        _hn_warn "setup-wsl-lan-access.ps1 missing"
        return 1
      fi
      if [[ "$dry" == "1" ]]; then
        _hn_info "DRY-RUN: would run invoke-elevated.ps1 → setup-wsl-lan-access.ps1 (UAC may prompt)"
        return 0
      fi
      local wrapper win_ps1 win_wrapper
      wrapper="$_HOST_NETWORK_ROOT/scripts/windows/invoke-elevated.ps1"
      if [[ ! -f "$wrapper" ]]; then
        _hn_warn "invoke-elevated.ps1 missing at $wrapper"
        return 1
      fi
      win_ps1="$(wslpath -w "$ps1")"
      win_wrapper="$(wslpath -w "$wrapper")"
      _hn_info "Windows UAC prompt may appear for portproxy setup..."
      _hn_info "Delegating LAN bridge to setup-wsl-lan-access.ps1 via invoke-elevated.ps1..."
      if ! powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$win_wrapper" -TargetScript "$win_ps1"; then
        _hn_warn "Portproxy setup failed (UAC declined or script error)"
        printf '       Approve the Windows UAC prompt, or run elevated PowerShell:\n' >&2
        printf '       powershell -ExecutionPolicy Bypass -File "%s"\n' "$win_ps1" >&2
        return 1
      fi
      return 0
      ;;
  esac
}

# ── woosoo_verify_lan_reachability ────────────────────────────────────────────
woosoo_verify_lan_reachability() {
  local host scheme
  host="$(_hn_env_get PUBLIC_HOST)"
  scheme="$(_hn_env_get PUBLIC_SCHEME)"
  scheme="${scheme:-https}"

  if [[ -z "$host" ]]; then
    _hn_warn "PUBLIC_HOST unset — skipping LAN reachability verify"
    return 1
  fi

  local ok=0
  if curl -ksf --max-time 5 "${scheme}://${host}:4443/build-info.json" -o /dev/null 2>/dev/null; then
    _hn_info "Reachable: ${scheme}://${host}:4443/build-info.json"
  else
    _hn_warn "Not reachable: ${scheme}://${host}:4443/build-info.json"
    ok=1
  fi

  if [[ "$(woosoo_detect_runtime)" == "wsl" ]] && command -v curl.exe >/dev/null 2>&1; then
    if curl.exe -ksf --max-time 5 "${scheme}://${host}:4443/build-info.json" -o NUL 2>/dev/null; then
      _hn_info "Reachable from Windows: ${scheme}://${host}:4443/build-info.json"
    else
      _hn_warn "Not reachable from Windows: ${scheme}://${host}:4443 — run: woosoo network"
      ok=1
    fi
  fi

  return $ok
}

# ── woosoo_recommended_pos_db_host ─────────────────────────────────────────────
# Dev default for DB_POS_HOST. WSL → Windows LAN IP; native/Docker Desktop → host.docker.internal.
woosoo_recommended_pos_db_host() {
  local runtime ip
  runtime="$(woosoo_detect_runtime)"
  case "$runtime" in
    wsl)
      ip="$(_hn_env_get PUBLIC_HOST)"
      if [[ -z "$ip" ]]; then
        ip="$(woosoo_detect_lan_ip 2>/dev/null || true)"
      fi
      echo "$ip"
      ;;
    *)
      echo "host.docker.internal"
      ;;
  esac
}

# ── woosoo_check_pos_db_host ───────────────────────────────────────────────────
# WARN or auto-fix DB_POS_HOST=host.docker.internal on WSL (wrong target for Krypton on Windows).
# Set HOST_NETWORK_DRY_RUN=1 to skip writes. Returns 0 if OK, 1 if drift remains.
woosoo_check_pos_db_host() {
  local current recommended runtime dry
  current="$(_hn_env_get DB_POS_HOST)"
  runtime="$(woosoo_detect_runtime)"
  dry="${HOST_NETWORK_DRY_RUN:-0}"

  if [[ "$runtime" != "wsl" ]]; then
    return 0
  fi

  recommended="$(woosoo_recommended_pos_db_host)"
  if [[ -z "$recommended" ]]; then
    _hn_warn "Cannot recommend DB_POS_HOST — PUBLIC_HOST and LAN IP detection both failed"
    return 1
  fi

  if [[ "$current" == "$recommended" ]]; then
    return 0
  fi

  if [[ "$current" == "host.docker.internal" || -z "$current" ]]; then
    _hn_warn "DB_POS_HOST=${current:-empty} — WSL dev must use Windows LAN IP ($recommended), not host.docker.internal"
    if [[ "$dry" == "1" ]]; then
      _hn_info "DRY-RUN: would set DB_POS_HOST=$recommended in woosoo-nexus/.env"
      return 1
    fi
    if grep -qE '^DB_POS_HOST=' "$_NEXUS_ENV" 2>/dev/null; then
      sed -i "s|^DB_POS_HOST=.*|DB_POS_HOST=\"${recommended}\"|" "$_NEXUS_ENV"
    else
      printf 'DB_POS_HOST="%s"\n' "$recommended" >> "$_NEXUS_ENV"
    fi
    _hn_sync_log "DB_POS_HOST → $recommended (Krypton on Windows host)"
    woosoo_print_nexus_env_reload_steps
    return 0
  fi

  _hn_warn "DB_POS_HOST=$current — expected $recommended for WSL dev (Krypton on Windows :3308)"
  return 1
}

# ── woosoo_check_pos_db_connectivity ───────────────────────────────────────────
# WARN-only TCP probe from the app container. Requires WOOSOO_POS_DC_CMD (docker compose string).
# Returns 0 if reachable, 1 otherwise.
woosoo_check_pos_db_connectivity() {
  local pos_host pos_port dc
  pos_host="$(_hn_env_get DB_POS_HOST)"
  pos_port="$(_hn_env_get DB_POS_PORT)"
  pos_port="${pos_port:-3308}"
  dc="${WOOSOO_POS_DC_CMD:-}"

  if [[ -z "$pos_host" ]]; then
    _hn_warn "DB_POS_HOST unset — skipping POS DB connectivity probe"
    return 1
  fi

  if [[ -z "$dc" ]]; then
    _hn_warn "WOOSOO_POS_DC_CMD unset — skipping POS DB connectivity probe"
    return 1
  fi

  # shellcheck disable=SC2086
  if ! $dc ps app 2>/dev/null | grep -qiE '(up|running|healthy)'; then
    _hn_warn "app container not running — skipping POS DB connectivity probe"
    return 1
  fi

  # shellcheck disable=SC2086
  if $dc exec -T app sh -c "nc -z -w 3 '${pos_host}' '${pos_port}'" 2>/dev/null; then
    _hn_info "POS DB reachable: ${pos_host}:${pos_port}"
    return 0
  fi

  _hn_warn "POS DB not reachable from app container: ${pos_host}:${pos_port}"
  if [[ "$pos_host" == "host.docker.internal" ]]; then
    printf '       WSL dev: set DB_POS_HOST to your Windows LAN IP (same as PUBLIC_HOST), not host.docker.internal\n' >&2
  else
    printf '       Ensure Krypton/MariaDB is listening on Windows port %s (netstat -an | findstr \":%s\")\n' "$pos_port" "$pos_port" >&2
    printf '       If listening but probe fails, allow inbound TCP %s from the WSL subnet in Windows Firewall\n' "$pos_port" >&2
  fi
  if [[ -z "$(_hn_env_get DB_POS_PASSWORD)" ]]; then
    printf '       DB_POS_PASSWORD is empty — set it from Krypton POS admin after TCP connects\n' >&2
  fi
  return 1
}

# ── woosoo_regen_dev_certs ────────────────────────────────────────────────────
woosoo_regen_dev_certs() {
  local host dry
  host="$(_hn_env_get PUBLIC_HOST)"
  if [[ -z "$host" ]]; then
    host="$(woosoo_detect_lan_ip 2>/dev/null || true)"
  fi
  if [[ -z "$host" ]]; then
    _hn_warn "Cannot regen certs — no PUBLIC_HOST or detected IP"
    return 1
  fi
  dry="${HOST_NETWORK_DRY_RUN:-0}"
  local gen="$_HOST_NETWORK_ROOT/docker/certs/generate-dev-certs.sh"
  if [[ ! -f "$gen" ]]; then
    _hn_warn "generate-dev-certs.sh missing"
    return 1
  fi
  if [[ "$dry" == "1" ]]; then
    _hn_info "DRY-RUN: would run generate-dev-certs.sh $host"
    return 0
  fi
  bash "$gen" "$host"
  _hn_info "Certs regenerated for $host — restart nginx: docker compose restart nginx"
}
