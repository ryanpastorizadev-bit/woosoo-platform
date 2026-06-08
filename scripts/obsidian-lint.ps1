# Report Obsidian vault orphans (docs/ tree) — files with zero inbound wikilinks.
# Usage: .\scripts\obsidian-lint.ps1

param(
    [string]$VaultPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$Scope = "docs"
)

$ErrorActionPreference = "Stop"
Set-Location $VaultPath

$scopePath = Join-Path $VaultPath $Scope
$vault = Get-ChildItem -Path $scopePath -Recurse -Filter '*.md' -File
$allPaths = @{}
foreach ($f in $vault) {
    $rel = $f.FullName.Substring($VaultPath.Length + 1) -replace '\\', '/'
    $allPaths[$rel] = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
}

$inbound = @{}
foreach ($rel in $allPaths.Keys) { $inbound[$rel] = 0 }

$linkPattern = '\[\[([^\]|#]+)(?:\|[^\]]+)?\]\]'
$allMd = Get-ChildItem -Path $scopePath -Recurse -Filter '*.md' -File
foreach ($f in $allMd) {
    $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    foreach ($m in [regex]::Matches($content, $linkPattern)) {
        $targetBase = [System.IO.Path]::GetFileNameWithoutExtension(($m.Groups[1].Value.Trim() -split '#')[0])
        foreach ($rel in $allPaths.Keys) {
            if ($allPaths[$rel] -eq $targetBase) { $inbound[$rel]++ }
        }
    }
}

$expected = @(
    'docs/cases/_TEMPLATE.md',
    'docs/README.md'
)

$orphans = $inbound.GetEnumerator() | Where-Object { $_.Value -eq 0 } | Sort-Object Name
Write-Host "Scope: $Scope"
Write-Host "Orphans: $($orphans.Count) / $($allPaths.Count)"
Write-Host ""
Write-Host "=== Expected orphans (linked from VAULT_INDEX, not graph) ==="
Write-Host "  hooks/, state/, inbox/, Templates/"
Write-Host ""
Write-Host "=== Actionable orphans (should link from CASE_REGISTRY or DOCS_HUB) ==="
$orphans | Where-Object { $expected -notcontains $_.Key -and $_.Key -notmatch '^docs/cases/' } | ForEach-Object { Write-Host $_.Key }
Write-Host ""
Write-Host "=== Case orphans (should appear in CASE_REGISTRY) ==="
$orphans | Where-Object { $_.Key -match '^docs/cases/' -and $_.Key -notmatch 'CASE_|OPERATOR|CONTRACTS|OPS_|_TEMPLATE' } | ForEach-Object { Write-Host $_.Key }
