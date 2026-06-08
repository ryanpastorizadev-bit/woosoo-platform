---
status: canonical
last_reviewed: 2026-06-08
scope: ecosystem
---

# Lessons Ledger — Recurring Issues & Guards

Append-only ledger of mistakes that **happened more than once** or **cost real time**, each paired
with the **guard** that prevents recurrence. The point: never make the same mistake twice — get
smarter every session.

Hub: [[DOCS_HUB]] · Vault: [[VAULT_INDEX]] · Enforced rules: [AGENT_DEFAULT_INSTRUCTIONS.md](AGENT_DEFAULT_INSTRUCTIONS.md)

---

## Two-tier model

| Tier | File | Holds |
|------|------|-------|
| **Ledger** (this file) | `docs/LESSONS.md` | Every observed failure mode + its guard. Low friction to append. |
| **Enforced rules** | `docs/AGENT_DEFAULT_INSTRUCTIONS.md § Extended Rules` | Lessons promoted to binding, gate-enforced rules after recurrence or high severity. |

Flow: **incident → ledger entry (guard noted) → if it recurs or is high-risk, promote to an enforced rule** and link it back here.

## How to use (every agent)

- **Before** a non-trivial task: skim entries tagged for your tool/app (`#env/powershell`, `#tool/obsidian`, `#app/nexus`, `#app/tablet`, `#app/print`, …).
- **After** a mistake — yours or one you spot: add a row. Symptom + root cause + guard + evidence.
- **On recurrence** (same root cause twice): escalate the guard — write a test, a lint rule, or promote to an enforced rule in `AGENT_DEFAULT_INSTRUCTIONS.md`. A guard that does not prevent recurrence is not a guard.
- Keep entries short. Link the case/commit for detail; do not paste logs here.

### Entry format

```md
### L-NNN — <one-line title>
- Tags: #env/<x> #tool/<y> #app/<z>
- Symptom: <observable failure>
- Root cause: <why it actually happened>
- Guard: <the concrete thing that prevents it — rule, test, lint, pattern>
- Evidence: <case slug / commit / file> (<date>)
- Promoted: <link to enforced rule, or "no — ledger only">
```

---

## Ledger

### L-001 — PowerShell 5.1 fails to parse non-ASCII in `.ps1` source
- Tags: #env/powershell #tooling
- Symptom: `Unexpected token` / `The string is missing the terminator` on scripts that ran fine when authored.
- Root cause: em-dash (`—`), middle-dot (`·`), ellipsis (`…`), or emoji in the **script source**; Windows PowerShell 5.1 reads the file as Windows-1252, corrupting multibyte UTF-8.
- Guard: keep `.ps1` **source ASCII-only**. If the *output* needs glyphs/emoji, build them at runtime via `[char]::ConvertFromUtf32(0xXXXX)`.
- Evidence: `scripts/obsidian-bootstrap.ps1`, `scripts/obsidian-case-registry.ps1` (2026-06-08, hit twice).
- Promoted: no — ledger only.

### L-002 — PowerShell `Get-Content -Raw` mangles UTF-8 (mojibake)
- Tags: #env/powershell #tooling
- Symptom: generated markdown shows `â€"` where an em-dash should be.
- Root cause: `Get-Content`/`Set-Content` default to Windows-1252 in PS 5.1; reading a UTF-8 source then re-writing doubles the corruption.
- Guard: read with `[System.IO.File]::ReadAllText($p,[Text.Encoding]::UTF8)`; write with `[System.IO.File]::WriteAllText($p,$s,(New-Object Text.UTF8Encoding($false)))` (UTF-8, no BOM).
- Evidence: `scripts/obsidian-case-registry.ps1` (2026-06-08).
- Promoted: no — ledger only.

### L-003 — `&&` is not a statement separator in PowerShell 5.1
- Tags: #env/powershell #tooling
- Symptom: `The token '&&' is not a valid statement separator in this version.`
- Root cause: chaining `cd x && cmd` — bash syntax. PS 5.1 has no `&&`.
- Guard: use the Shell tool's `working_directory`, or chain with `;` (no short-circuit) / explicit `if ($LASTEXITCODE -eq 0)`. Prefer separate tool calls.
- Evidence: orphan-scan command (2026-06-08).
- Promoted: no — ledger only.

### L-004 — Obsidian wikilinks do not resolve `../` relative paths
- Tags: #tool/obsidian #docs
- Symptom: links render unresolved in Obsidian graph despite the target existing.
- Root cause: `[[../FOO]]` is markdown/filesystem syntax. Obsidian resolves wikilinks by note name or vault-root-relative path suffix — **never** `../`.
- Guard: use bare note name `[[FOO]]` (unique names) or vault-root path `[[folder/FOO]]`. Reserve `../` for standard markdown links `[text](../path.md)`.
- Evidence: `CASE_INDEX`, `OPERATOR_HOME`, `CASE_REGISTRY`, generator script (2026-06-08).
- Promoted: no — ledger only.

### L-005 — Ambiguous Obsidian wikilink when basenames collide
- Tags: #tool/obsidian #docs
- Symptom: `[[README]]` silently links to the wrong note.
- Root cause: multiple files share a basename (`docs/README.md` + `docs/operator/README.md`); Obsidian picks one arbitrarily.
- Guard: qualify colliding links with a path: `[[docs/README|README]]`. Run `scripts/obsidian-lint.ps1` after adding hub pages.
- Evidence: `docs/VAULT_INDEX.md` (2026-06-08).
- Promoted: no — ledger only.

### L-006 — Obsidian crashes (`EACCES`) on Windows from broken sibling-repo junctions
- Tags: #tool/obsidian #env/windows #infra
- Symptom: Obsidian fails to open the vault; `EACCES` at startup.
- Root cause: Obsidian `lstat`s the entire vault before `userIgnoreFilters` apply; broken Docker/Linux junctions in sibling repos (e.g. `woosoo-nexus/public/storage` → `/var/www/html/...`) throw.
- Guard: `scripts/obsidian-bootstrap.ps1` repairs known junctions to local Windows paths before first open; re-run after Docker dev sessions. Exclusions alone do **not** prevent the crash.
- Evidence: setup session (per `docs/obsidian-setup-guide.md`).
- Promoted: no — ledger only.

### L-007 — Wrong upstream repo slug when fetching Obsidian plugins
- Tags: #tool/obsidian #tooling
- Symptom: GitHub release fetch 404s during bootstrap.
- Root cause: guessed repo name (`Templater-Obsidian`) instead of the real one (`SilentVoid13/Templater`).
- Guard: pin verified `owner/repo` slugs in the bootstrap `$Plugins` table; never guess a slug — confirm on GitHub first.
- Evidence: `scripts/obsidian-bootstrap.ps1` (plugin table).
- Promoted: no — ledger only.

### L-008 — Doc claims drift from code (e.g. "Nexus = KDS")
- Tags: #docs #doc-truth
- Symptom: a doc describes a feature/role the code does not implement (portfolio called Nexus a "Kitchen Display System"; KDS is a deferred feature).
- Root cause: marketing/summary prose written without verifying against contracts; no doc-truth pass.
- Guard: every doc claim must be verifiable against code/contracts. `documentation-truth-audit` skill + scribe + Executioner reject unverifiable claims. Only `status: canonical` docs are source of truth.
- Evidence: `APPLICATION_MATERIALS.md` (2026-06-08, flagged not fixed — personal doc).
- Promoted: yes — `AGENT_DEFAULT_INSTRUCTIONS.md` (Documentation Truth) + `AGENTS.md § Documentation Truth`.

---

## Promotion candidates (watchlist)

Entries that will become enforced rules if they recur once more:

- L-001 / L-002 — PowerShell encoding. If a third encoding bug lands, add a `scripts/` authoring rule + a CI ASCII-lint for `*.ps1`.
