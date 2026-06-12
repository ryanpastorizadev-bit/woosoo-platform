#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Removes the Woosoo WSL LAN bridge scheduled task (portproxy rules are left intact).

.DESCRIPTION
    Unregisters 'Woosoo-WSL-LAN-Bridge'. To also remove portproxy + firewall rules,
    run teardown-wsl-lan-access.ps1 afterward.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts\windows\unregister-wsl-lan-startup-task.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskName = 'Woosoo-WSL-LAN-Bridge'

$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if (-not $existing) {
    Write-Host "No scheduled task named '$TaskName' - nothing to remove." -ForegroundColor Yellow
    exit 0
}

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
Write-Host "Removed scheduled task '$TaskName'." -ForegroundColor Green
Write-Host "Portproxy rules unchanged. To remove them: scripts\windows\teardown-wsl-lan-access.ps1" -ForegroundColor DarkGray
