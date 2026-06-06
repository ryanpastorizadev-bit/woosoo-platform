#Requires -Version 5.1
<#
.SYNOPSIS
    Runs a PowerShell script elevated via UAC when the current session is not Administrator.

.DESCRIPTION
    Called from WSL via host-network.sh / woosoo network. If already Admin, runs the
    target script in-process. Otherwise shows a Windows UAC prompt and waits for the
    elevated child to finish.

.PARAMETER TargetScript
    Windows path to the .ps1 to run elevated (e.g. setup-wsl-lan-access.ps1).

.EXAMPLE
    .\invoke-elevated.ps1 -TargetScript "E:\Projects\woosoo-platform\scripts\windows\setup-wsl-lan-access.ps1"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$TargetScript
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-IsAdministrator {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (Test-IsAdministrator) {
    & $TargetScript
    exit $LASTEXITCODE
}

$argumentList = @(
    '-NoProfile'
    '-ExecutionPolicy', 'Bypass'
    '-File', $TargetScript
)

try {
    $process = Start-Process `
        -FilePath 'powershell.exe' `
        -ArgumentList $argumentList `
        -Verb RunAs `
        -Wait `
        -PassThru

    if ($null -eq $process) {
        Write-Error 'Elevation declined — portproxy not configured'
        exit 1
    }

    if ($null -eq $process.ExitCode) {
        exit 0
    }

    exit $process.ExitCode
}
catch [System.ComponentModel.Win32Exception] {
    # User declined UAC or elevation was cancelled.
    Write-Error 'Elevation declined — portproxy not configured'
    exit 1
}
