# Obsidian vault linter. Three checks:
#   1. Orphans      - docs/ files with zero inbound wikilinks (graph hygiene).
#   2. Broken links - [[target]] / ![[target#heading]] whose file or heading does not resolve
#                     (catches a reworded embed heading silently breaking OPERATOR_HOME, etc.).
#   3. Missing tags - case files carrying run-state frontmatter that lack required app/status tags
#                     (the taxonomy projected by obsidian-case-registry.ps1).
# Read-only: reports, never edits. Usage: .\scripts\obsidian-lint.ps1

param(
    [string]$VaultPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$Scope = "docs"
)

$ErrorActionPreference = "Stop"
Set-Location $VaultPath

# --- Vault file index (for link resolution): vault-relevant dirs minus sibling app repos. ---
$linkDirs = @('docs', 'state', 'contracts', 'hooks', 'inbox', 'Templates') |
    ForEach-Object { Join-Path $VaultPath $_ } | Where-Object { Test-Path $_ }
$indexFiles = @()
foreach ($d in $linkDirs) { $indexFiles += Get-ChildItem -Path $d -Recurse -Filter '*.md' -File }
$indexFiles += Get-ChildItem -Path $VaultPath -Filter '*.md' -File   # root-level notes
# basename (lower) -> fullpath (first wins; slugs are unique in this vault)
$byBase = @{}
foreach ($f in $indexFiles) {
    $k = [IO.Path]::GetFileNameWithoutExtension($f.Name).ToLower()
    if (-not $byBase.ContainsKey($k)) { $byBase[$k] = $f.FullName }
}
# Canvas and Bases notes are linkable too ([[Name.canvas]], [[Name.base]], or [[Name]]);
# index them by basename so wikilinks to them resolve. Filter on .Extension rather than
# -Include (which is unreliable for multi-pattern dir scans on some hosts).
$extraFiles = @()
foreach ($d in $linkDirs) {
    $extraFiles += Get-ChildItem -Path $d -Recurse -File | Where-Object { $_.Extension -in '.canvas', '.base' }
}
$extraFiles += Get-ChildItem -Path $VaultPath -File | Where-Object { $_.Extension -in '.canvas', '.base' }
foreach ($f in $extraFiles) {
    $k = [IO.Path]::GetFileNameWithoutExtension($f.Name).ToLower()
    if (-not $byBase.ContainsKey($k)) { $byBase[$k] = $f.FullName }
}

function Get-Headings([string]$path) {
    $set = New-Object System.Collections.Generic.HashSet[string]
    foreach ($l in (Get-Content $path -ErrorAction SilentlyContinue)) {
        if ($l -match '^#{1,6}\s+(.+?)\s*$') { [void]$set.Add($Matches[1].Trim().ToLower()) }
    }
    return $set
}

# Basename of a wikilink target WITHOUT using [IO.Path], which throws
# "Illegal characters in path" on chars that are legal inside wikilink/heading
# text (e.g. ':' '?' '*') but illegal in filesystem paths. Preserves case.
function Get-LinkBase([string]$target) {
    if (-not $target) { return '' }
    # Wikilinks use '/' separators; a trailing '\' is the markdown table-escape from
    # '\|' (e.g. [[Foo\|Bar]]) and must be stripped so the target still resolves.
    $seg = ($target.Trim().TrimEnd('\') -split '/')[-1]
    return ($seg -replace '\.(md|canvas|base)$', '').Trim()
}

# Strip fenced code blocks and inline code spans so wikilink-looking EXAMPLES
# inside them (e.g. `[[case-slug]]`, ```[[wikilinks]]```) are not scanned as real
# links/embeds. Docs and templates legitimately illustrate link syntax.
function Remove-CodeSpans([string]$text) {
    if (-not $text) { return $text }
    $t = [regex]::Replace($text, '(?s)```.*?```', '')
    $t = [regex]::Replace($t, '`[^`]*`', '')
    return $t
}

# --- Check 1: orphans (docs scope) ---
$scopePath = Join-Path $VaultPath $Scope
$vault = Get-ChildItem -Path $scopePath -Recurse -Filter '*.md' -File
$allPaths = @{}
foreach ($f in $vault) {
    $rel = $f.FullName.Substring($VaultPath.Length + 1) -replace '\\', '/'
    $allPaths[$rel] = [IO.Path]::GetFileNameWithoutExtension($f.Name)
}
$inbound = @{}
foreach ($rel in $allPaths.Keys) { $inbound[$rel] = 0 }
$linkPattern = '!?\[\[([^\]|#]+)(?:#[^\]|]+)?(?:\|[^\]]+)?\]\]'
foreach ($f in $vault) {
    $content = Remove-CodeSpans (Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue)
    if (-not $content) { continue }
    foreach ($m in [regex]::Matches($content, $linkPattern)) {
        $targetBase = Get-LinkBase (($m.Groups[1].Value -split '#')[0])
        foreach ($rel in $allPaths.Keys) {
            if ($allPaths[$rel] -eq $targetBase) { $inbound[$rel]++ }
        }
    }
}
$expected = @('docs/cases/_TEMPLATE.md', 'docs/README.md')
$orphans = $inbound.GetEnumerator() | Where-Object { $_.Value -eq 0 } | Sort-Object Name

# --- Checks 2 & 3: walk every vault-indexed file once ---
$brokenLinks = @()
$missingTags = @()
$fullLink = '(!)?\[\[([^\]|]+?)\]\](?:\|[^\]]+)?'   # capture full inner incl. optional #heading/#^block
foreach ($f in $indexFiles) {
    $raw = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $raw) { continue }
    $relF = $f.FullName.Substring($VaultPath.Length + 1) -replace '\\', '/'

    # Check 2: broken link/embed targets and headings (ignore code-span examples)
    foreach ($m in [regex]::Matches((Remove-CodeSpans $raw), '!?\[\[([^\]|]+?)(?:\|[^\]]+)?\]\]')) {
        $inner = $m.Groups[1].Value.Trim()
        $parts = $inner -split '#', 2
        $base = (Get-LinkBase $parts[0]).ToLower()
        if ($base -eq '') { continue }   # same-file heading link [[#heading]]
        if (-not $byBase.ContainsKey($base)) {
            $brokenLinks += "$relF  ->  [[$inner]]  (no such note)"
            continue
        }
        if ($parts.Count -eq 2 -and $parts[1] -notmatch '^\^') {   # heading link, not a block ref
            $heading = $parts[1].Trim().ToLower()
            $headings = Get-Headings $byBase[$base]
            if (-not $headings.Contains($heading)) {
                $brokenLinks += "$relF  ->  [[$inner]]  (heading not found)"
            }
        }
    }

    # Check 3: case files with run-state frontmatter must carry app/* and status/* tags
    if ($relF -match '^docs/cases/' -and $raw -match '(?m)^run_status:\s*\S') {
        $tagLine = ([regex]::Match($raw, '(?m)^tags:\s*(.+)$')).Groups[1].Value
        if ($tagLine -notmatch 'app/' -or $tagLine -notmatch 'status/') {
            $missingTags += "$relF  (tags: $tagLine)"
        }
    }
}

# --- Report ---
Write-Host "Scope: $Scope  ($($allPaths.Count) docs, $($indexFiles.Count) indexed notes)"
Write-Host ""
Write-Host "=== Orphans: $($orphans.Count) / $($allPaths.Count) ==="
Write-Host "Expected (linked from VAULT_INDEX, not graph): hooks/, state/, inbox/, Templates/"
Write-Host "--- Actionable docs orphans (link from DOCS_HUB) ---"
$orphans | Where-Object { $expected -notcontains $_.Key -and $_.Key -notmatch '^docs/cases/' } | ForEach-Object { Write-Host "  $($_.Key)" }
Write-Host "--- Case orphans (should appear in CASE_REGISTRY) ---"
$orphans | Where-Object { $_.Key -match '^docs/cases/' -and $_.Key -notmatch 'CASE_|OPERATOR|CONTRACTS|OPS_|_TEMPLATE' } | ForEach-Object { Write-Host "  $($_.Key)" }
Write-Host ""
Write-Host "=== Broken links / embeds: $($brokenLinks.Count) ==="
$brokenLinks | Sort-Object -Unique | ForEach-Object { Write-Host "  $_" }
Write-Host ""
Write-Host "=== Cases missing required tags: $($missingTags.Count) ==="
Write-Host "(run obsidian-case-registry.ps1 to regenerate frontmatter tags)"
$missingTags | ForEach-Object { Write-Host "  $_" }
