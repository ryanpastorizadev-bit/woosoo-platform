#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Bridges Windows LAN interface → WSL2 Docker so the dev stack is reachable
    at https://<PUBLIC_HOST> from Windows and LAN tablets.

.DESCRIPTION
    Docker Engine in WSL2 binds ports inside the WSL2 VM — Windows forwards
    localhost automatically but NOT the physical LAN IP. This script adds:
      • netsh portproxy rules   (listenaddress=0.0.0.0 → WSL VM IP)
      • Windows Firewall rules  (TCP 80/443/4443 inbound, Private profile)

    Re-run after every 'wsl --shutdown' because the WSL2 VM IP changes.
    Operators should use: woosoo network  (not this script directly).

.EXAMPLE
    # Invoked by woosoo network from WSL (Admin required):
    powershell.exe -File scripts\windows\setup-wsl-lan-access.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Ports        = @(80, 443, 4443)
$FirewallName = 'Woosoo-WSL-Dev'
$PlatformRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$NexusEnv     = Join-Path $PlatformRoot 'woosoo-nexus\.env'

function Get-PublicHost {
    if (Test-Path -LiteralPath $NexusEnv) {
        $line = Get-Content -LiteralPath $NexusEnv -ErrorAction SilentlyContinue |
            Where-Object { $_ -match '^PUBLIC_HOST=' } |
            Select-Object -First 1
        if ($line -match '^PUBLIC_HOST=(.+)$') {
            $val = $Matches[1].Trim().Trim('"').Trim("'")
            if ($val) { return $val }
        }
    }
    $lanScript = Join-Path $PSScriptRoot 'get-windows-lan-ip.ps1'
    if (Test-Path -LiteralPath $lanScript) {
        return & $lanScript
    }
    return 'localhost'
}

$PublicHost = Get-PublicHost

# ── 1. Detect WSL2 IP ─────────────────────────────────────────────────────────
Write-Host "`nDetecting WSL2 VM IP..." -ForegroundColor Cyan
$WslIp = (wsl hostname -I 2>$null).Trim().Split(' ')[0]
if (-not $WslIp -or $WslIp -notmatch '^\d+\.\d+\.\d+\.\d+$') {
    Write-Error "Could not determine WSL2 IP. Is WSL running? Try: wsl --list --running"
    exit 1
}
Write-Host "  WSL2 IP: $WslIp" -ForegroundColor Green
Write-Host "  PUBLIC_HOST: $PublicHost" -ForegroundColor Green

# ── 2. Remove stale portproxy rules (idempotent) ──────────────────────────────
Write-Host "`nRemoving stale portproxy rules..." -ForegroundColor Cyan
foreach ($Port in $Ports) {
    try {
        netsh interface portproxy delete v4tov4 listenport=$Port listenaddress=0.0.0.0 2>$null | Out-Null
    } catch { }
}

# ── 3. Add portproxy rules (0.0.0.0 → WSL IP, LAN-reachable) ─────────────────
Write-Host "Adding portproxy rules (0.0.0.0:80/443/4443 → $WslIp)..." -ForegroundColor Cyan
foreach ($Port in $Ports) {
    netsh interface portproxy add v4tov4 `
        listenport=$Port    listenaddress=0.0.0.0 `
        connectport=$Port   connectaddress=$WslIp
    Write-Host "  0.0.0.0:$Port → $WslIp`:$Port" -ForegroundColor Green
}

# ── 4. Windows Firewall — allow inbound TCP 80/443/4443 (Private) ─────────────
Write-Host "`nConfiguring Windows Firewall..." -ForegroundColor Cyan
Remove-NetFirewallRule -DisplayName "$FirewallName" -ErrorAction SilentlyContinue

New-NetFirewallRule `
    -DisplayName "$FirewallName" `
    -Direction   Inbound `
    -Protocol    TCP `
    -LocalPort   $Ports `
    -Action      Allow `
    -Profile     Private `
    -Description "Allow inbound access to Woosoo dev stack via WSL2 portproxy" | Out-Null

Write-Host "  Firewall rule '$FirewallName' added (TCP $($Ports -join '/'), Private)" -ForegroundColor Green

# ── 5. Show current portproxy state ──────────────────────────────────────────
Write-Host "`nActive portproxy rules:" -ForegroundColor Cyan
netsh interface portproxy show v4tov4

# ── 6. Verification URLs ──────────────────────────────────────────────────────
Write-Host @"

══════════════════════════════════════════════
  WSL LAN access ready
  WSL VM IP   : $WslIp
  PUBLIC_HOST : $PublicHost
══════════════════════════════════════════════

  Admin panel  : https://${PublicHost}
  Tablet PWA   : https://${PublicHost}:4443
  Localhost    : https://localhost  (always works)

  Browser cert warning: click Advanced → Proceed to ${PublicHost}
  Tablets on LAN: install docker\certs\rootCA.crt to trust the cert.

  NOTE: WSL2 IP changes after 'wsl --shutdown'. Re-run: woosoo network

  To remove: woosoo network teardown (or teardown-wsl-lan-access.ps1)
══════════════════════════════════════════════
"@ -ForegroundColor Green
