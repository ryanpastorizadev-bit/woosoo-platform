# Bootstrap Obsidian vault config + community plugins for woosoo-platform.
# Idempotent - safe to re-run. Does not auto-push; Obsidian Git pull-on-boot only.
#
# Usage (from platform root):
#   .\scripts\obsidian-bootstrap.ps1
#   .\scripts\obsidian-bootstrap.ps1 -VaultPath "E:\Projects\woosoo-platform"

param(
    [string]$VaultPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

# plugin-id | GitHub owner/repo
$Plugins = @(
    @{ Id = "dataview";              Repo = "blacksmithgu/obsidian-dataview" },
    @{ Id = "templater-obsidian";    Repo = "SilentVoid13/Templater" },
    @{ Id = "obsidian-git";          Repo = "Vinzent03/obsidian-git" },
    @{ Id = "calendar";              Repo = "liamcain/obsidian-calendar-plugin" },
    @{ Id = "obsidian-kanban";       Repo = "mgmeyers/obsidian-kanban" },
    @{ Id = "obsidian-icon-folder";  Repo = "FlorianWoelki/obsidian-icon-folder" }
)

$ObsidianDir = Join-Path $VaultPath ".obsidian"
$PluginsDir  = Join-Path $ObsidianDir "plugins"
$ConfigDir   = Join-Path $PSScriptRoot "obsidian"

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    $msg" -ForegroundColor Green }

function Repair-Junction {
    param([string]$LinkPath, [string]$TargetPath)

    if (-not (Test-Path $TargetPath)) {
        Write-Host "    skip $LinkPath (target missing: $TargetPath)" -ForegroundColor DarkYellow
        return
    }

    if (Test-Path $LinkPath) {
        $item = Get-Item $LinkPath -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            # Remove-Item -Force throws NullReferenceException on directory junctions in
            # PS 5.1; rmdir removes only the link and never follows into the target.
            cmd /c rmdir "$LinkPath" | Out-Null
        } else {
            Write-Host "    skip $LinkPath (exists and is not a junction)" -ForegroundColor DarkYellow
            return
        }
    }

    cmd /c mklink /J "$LinkPath" "$TargetPath" | Out-Null
    Write-Ok "junction $LinkPath -> $TargetPath"
}

# Obsidian lstat's the whole vault at startup - broken Docker/Linux junctions crash before
# userIgnoreFilters apply. Repair known sibling-repo links on Windows.
Write-Step "Repairing sibling-repo junctions (Obsidian startup requirement)"
Repair-Junction `
    (Join-Path $VaultPath "woosoo-nexus\public\storage") `
    (Join-Path $VaultPath "woosoo-nexus\storage\app\public")
Repair-Junction `
    (Join-Path $VaultPath "tablet-ordering-pwa\dist") `
    (Join-Path $VaultPath "tablet-ordering-pwa\.output\public")

New-Item -ItemType Directory -Force -Path $ObsidianDir, $PluginsDir | Out-Null

# --- Vault config (committed templates in scripts/obsidian/) ---
Write-Step "Writing vault config"
Copy-Item -Force (Join-Path $ConfigDir "app.json") (Join-Path $ObsidianDir "app.json")
Copy-Item -Force (Join-Path $ConfigDir "community-plugins.json") (Join-Path $ObsidianDir "community-plugins.json")
Copy-Item -Force (Join-Path $ConfigDir "core-plugins.json") (Join-Path $ObsidianDir "core-plugins.json")
Copy-Item -Force (Join-Path $ConfigDir "templates.json") (Join-Path $ObsidianDir "templates.json")
Copy-Item -Force (Join-Path $ConfigDir "daily-notes.json") (Join-Path $ObsidianDir "daily-notes.json")
Copy-Item -Force (Join-Path $ConfigDir "graph.json") (Join-Path $ObsidianDir "graph.json")
Write-Ok "app.json, community-plugins.json, core-plugins.json, templates.json, daily-notes.json, graph.json"

# Operator daily-log folder (Calendar plugin target)
$DailyDir = Join-Path $VaultPath "docs\operator\daily"
New-Item -ItemType Directory -Force -Path $DailyDir | Out-Null
Write-Ok "docs/operator/daily/"

# --- Plugin-specific settings ---
$TemplaterDir = Join-Path $PluginsDir "templater-obsidian"
$GitDir       = Join-Path $PluginsDir "obsidian-git"
New-Item -ItemType Directory -Force -Path $TemplaterDir, $GitDir | Out-Null
Copy-Item -Force (Join-Path $ConfigDir "templater-data.json") (Join-Path $TemplaterDir "data.json")
Copy-Item -Force (Join-Path $ConfigDir "obsidian-git-data.json") (Join-Path $GitDir "data.json")
Write-Ok "Templater + Obsidian Git settings"

function Install-ObsidianPlugin {
    param([string]$Id, [string]$Repo)

    $dest = Join-Path $PluginsDir $Id
    New-Item -ItemType Directory -Force -Path $dest | Out-Null

    $headers = @{ "User-Agent" = "woosoo-platform-obsidian-bootstrap" }
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers $headers

    $files = @("main.js", "manifest.json", "styles.css")
    foreach ($name in $files) {
        $asset = $release.assets | Where-Object { $_.name -eq $name }
        if (-not $asset) { continue }
        $out = Join-Path $dest $name
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $out -Headers $headers
    }

    if (-not (Test-Path (Join-Path $dest "main.js"))) {
        throw "Failed to download main.js for $Id from $Repo"
    }

    $version = (Get-Content (Join-Path $dest "manifest.json") | ConvertFrom-Json).version
    Write-Ok "$Id @ $version"
}

Write-Step "Downloading community plugins from GitHub releases"
foreach ($p in $Plugins) {
    Install-ObsidianPlugin -Id $p.Id -Repo $p.Repo
}

Write-Step "Done"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Open Obsidian -> Open folder as vault -> $VaultPath"
Write-Host "  2. If prompted about community plugins, choose Enable / Trust"
Write-Host "  3. Open and pin docs/cases/OPERATOR_HOME.md"
Write-Host "  4. Settings -> Community plugins -> confirm all six are ON"
Write-Host "  5. CASE_INDEX.md should render a Dataview table (not a code block)"
Write-Host "  6. Open OPS_KANBAN.md in Kanban view; Calendar -> today for operator log"
Write-Host "  7. Graph view (Ctrl+G) - color groups for cases/contracts/state"
Write-Host "  8. Open docs/VAULT_INDEX.md and docs/cases/CASE_REGISTRY.md (graph hubs)"
Write-Host ""
