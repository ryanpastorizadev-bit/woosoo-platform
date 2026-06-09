#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Registers a Windows Scheduled Task that re-applies WSL2 portproxy + firewall on user logon.

.DESCRIPTION
    After wsl --shutdown or a reboot, the WSL2 VM IP changes and netsh portproxy rules
    point at a stale address. setup-wsl-lan-access.ps1 fixes that; this task runs it
    automatically at logon so https://<PUBLIC_HOST> works without manual steps.

    One-time setup (elevated PowerShell from platform root):
      powershell -ExecutionPolicy Bypass -File scripts\windows\register-wsl-lan-startup-task.ps1

    Remove:
      powershell -ExecutionPolicy Bypass -File scripts\windows\unregister-wsl-lan-startup-task.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts\windows\register-wsl-lan-startup-task.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskName   = 'Woosoo-WSL-LAN-Bridge'
$ScriptPath = Join-Path $PSScriptRoot 'setup-wsl-lan-access.ps1'

if (-not (Test-Path -LiteralPath $ScriptPath)) {
    Write-Error "Missing script: $ScriptPath"
    exit 1
}

$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Replacing existing scheduled task '$TaskName'..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

$action = New-ScheduledTaskAction `
    -Execute 'powershell.exe' `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""

$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

$principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Hours 1)

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description 'Re-apply WSL2 portproxy (80/443/4443) so Woosoo dev stack is LAN-reachable after WSL IP drift.' | Out-Null

Write-Host "Applying portproxy now (same script the task will run at logon)..." -ForegroundColor Cyan
& $ScriptPath

Write-Host @"

==============================================
  Scheduled task registered: $TaskName
  Trigger: At logon ($env:USERNAME)
  Action:  setup-wsl-lan-access.ps1

  Portproxy will refresh automatically after reboot / wsl --shutdown.
  Manual refresh anytime: woosoo network  (from WSL)
  Remove task: scripts\windows\unregister-wsl-lan-startup-task.ps1
==============================================
"@ -ForegroundColor Green
