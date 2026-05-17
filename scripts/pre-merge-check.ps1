# Woosoo pre-merge validation (PowerShell wrapper).
# Usage: .\scripts\pre-merge-check.ps1 -App <woosoo-nexus|tablet-ordering-pwa|woosoo-print-bridge>
# Exits non-zero if any sub-command fails.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("woosoo-nexus", "tablet-ordering-pwa", "woosoo-print-bridge")]
    [string]$App
)

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent $PSScriptRoot

function Fail([string]$step) {
    Write-Host ""
    Write-Host "================================================================"
    Write-Host "  VALIDATION FAILED ($App) - do not mark work complete"
    Write-Host "  failed step: $step"
    Write-Host "================================================================"
    exit 1
}

function Invoke-Step([string]$label, [scriptblock]$action) {
    Write-Host ""
    Write-Host "---- [$App] $label ----"
    try {
        & $action
        if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
            Fail $label
        }
    } catch {
        Write-Host $_.Exception.Message
        Fail $label
    }
}

switch ($App) {
    "woosoo-nexus" {
        Push-Location (Join-Path $RootDir "woosoo-nexus")
        try {
            Invoke-Step "composer test" { composer test }
            Invoke-Step "php artisan route:list" { php artisan route:list }
            Invoke-Step "php artisan config:clear" { php artisan config:clear }
        } finally {
            Pop-Location
        }
    }
    "tablet-ordering-pwa" {
        Push-Location (Join-Path $RootDir "tablet-ordering-pwa")
        try {
            Invoke-Step "npm run typecheck" { npm run typecheck }
            Invoke-Step "npm run lint" { npm run lint }
            Invoke-Step "npm run test" { npm run test }
            Invoke-Step "npm run build" { npm run build }
            Invoke-Step "npm run generate" { npm run generate }
        } finally {
            Pop-Location
        }
    }
    "woosoo-print-bridge" {
        Push-Location (Join-Path $RootDir "woosoo-print-bridge")
        try {
            # NOTE: The Flutter test suite is currently red per the 2026-05-14
            # audit. Do not skip this step - investigate failures and update
            # the audit instead.
            Invoke-Step "flutter analyze" { flutter analyze }
            Invoke-Step "flutter test" { flutter test }
        } finally {
            Pop-Location
        }
    }
}

Write-Host ""
Write-Host "================================================================"
Write-Host "  pre-merge-check OK ($App)"
Write-Host "================================================================"
exit 0
