#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Removes the WSL -> Windows LAN portproxy and firewall rules created by
    setup-wsl-lan-access.ps1. Docker stack is untouched; localhost access
    continues to work after teardown.

.EXAMPLE
    # From an elevated PowerShell prompt:
    .\scripts\windows\teardown-wsl-lan-access.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'   # don't abort on already-removed entries

$Ports        = @(80, 443, 4443)
$FirewallName = 'Woosoo-WSL-Dev'

Write-Host "`nRemoving portproxy rules..." -ForegroundColor Cyan
$removedAny = $false
foreach ($Port in $Ports) {
    $beforeOutput = netsh interface portproxy show v4tov4 2>&1 | Out-String
    netsh interface portproxy delete v4tov4 listenport=$Port listenaddress=0.0.0.0 2>&1 | Out-Null
    $afterOutput = netsh interface portproxy show v4tov4 2>&1 | Out-String
    if ($beforeOutput -match "\b$Port\b" -and $afterOutput -notmatch "\b0\.0\.0\.0\s+$Port\b") {
        Write-Host "  removed 0.0.0.0:$Port" -ForegroundColor Green
        $removedAny = $true
    } else {
        Write-Host "  0.0.0.0:$Port - no rule present" -ForegroundColor DarkGray
    }
}

Write-Host "`nRemoving firewall rule '$FirewallName'..." -ForegroundColor Cyan
$rule = Get-NetFirewallRule -DisplayName "$FirewallName" -ErrorAction SilentlyContinue
if ($rule) {
    Remove-NetFirewallRule -DisplayName "$FirewallName"
    Write-Host "  removed firewall rule '$FirewallName'" -ForegroundColor Green
    $removedAny = $true
} else {
    Write-Host "  firewall rule '$FirewallName' - not present" -ForegroundColor DarkGray
}

Write-Host "`nRemaining portproxy rules:" -ForegroundColor Cyan
netsh interface portproxy show v4tov4

Write-Host @"

==============================================
  WSL LAN access removed
==============================================

  Docker stack is untouched. From WSL or Windows:
    https://localhost  - still works
    LAN PUBLIC_HOST  - no longer reachable from LAN

  To restore: woosoo network
==============================================
"@ -ForegroundColor Green
