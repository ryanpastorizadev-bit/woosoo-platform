# setup-skills.ps1
# Creates .claude/skills/ symlinks pointing to .agents/skills/ for each installed skill.
# Run once after cloning, or after adding new skills to .agents/skills/.
# Idempotent — skips entries that already exist.

$repo    = Split-Path $PSScriptRoot -Parent
$source  = Join-Path $repo ".agents\skills"
$target  = Join-Path $repo ".claude\skills"

if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target | Out-Null }

$skills = Get-ChildItem -Path $source -Directory
foreach ($skill in $skills) {
    $link = Join-Path $target $skill.Name
    if (Test-Path $link) {
        Write-Host "skip (exists): $($skill.Name)"
    } else {
        New-Item -ItemType SymbolicLink -Path $link -Target $skill.FullName | Out-Null
        Write-Host "linked: $($skill.Name)"
    }
}
Write-Host "Done — $($skills.Count) skills processed."
