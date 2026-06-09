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
- Automated: `CHK-PS-ASCII` (`scripts/recurrence-check.{ps1,sh}`, via `pre-merge-check`) — every `scripts/**/*.ps1` is scanned for non-ASCII bytes; a re-introduced glyph fails the merge gate.
- Promoted: no — ledger only.

### L-002 — PowerShell `Get-Content -Raw` mangles UTF-8 (mojibake)
- Tags: #env/powershell #tooling
- Symptom: generated markdown shows `â€"` where an em-dash should be.
- Root cause: `Get-Content`/`Set-Content` default to Windows-1252 in PS 5.1; reading a UTF-8 source then re-writing doubles the corruption.
- Guard: read with `[System.IO.File]::ReadAllText($p,[Text.Encoding]::UTF8)`; write with `[System.IO.File]::WriteAllText($p,$s,(New-Object Text.UTF8Encoding($false)))` (UTF-8, no BOM).
- Evidence: `scripts/obsidian-case-registry.ps1` (2026-06-08).
- Automated: `CHK-PS-ASCII` keeps `.ps1` source ASCII at the boundary; mojibake from read/write re-encoding cannot survive once the source is clean.
- Promoted: no — ledger only.

### L-003 — `&&` is not a statement separator in PowerShell 5.1
- Tags: #env/powershell #tooling
- Symptom: `The token '&&' is not a valid statement separator in this version.`
- Root cause: chaining `cd x && cmd` — bash syntax. PS 5.1 has no `&&`.
- Guard: use the Shell tool's `working_directory`, or chain with `;` (no short-circuit) / explicit `if ($LASTEXITCODE -eq 0)`. Prefer separate tool calls.
- Evidence: orphan-scan command (2026-06-08).
- Automated: `CHK-PS-PARSE` (`scripts/recurrence-check.{ps1,sh}`) — `&&` in a `.ps1` is a parse error, caught by `[Parser]::ParseFile` across all scripts.
- Promoted: no — ledger only.

### L-004 — Obsidian wikilinks do not resolve `../` relative paths
- Tags: #tool/obsidian #docs
- Symptom: links render unresolved in Obsidian graph despite the target existing.
- Root cause: `[[../FOO]]` is markdown/filesystem syntax. Obsidian resolves wikilinks by note name or vault-root-relative path suffix — **never** `../`.
- Guard: use bare note name `[[FOO]]` (unique names) or vault-root path `[[folder/FOO]]`. Reserve `../` for standard markdown links `[text](../path.md)`.
- Evidence: `CASE_INDEX`, `OPERATOR_HOME`, `CASE_REGISTRY`, generator script (2026-06-08).
- Automated: `CHK-WIKILINK-RELATIVE` (`scripts/recurrence-check.{ps1,sh}`) — flags any `[[../...]]` in `docs/**/*.md` (code spans excluded, so this ledger example does not self-trip).
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

### L-009 — `Remove-Item -Force` throws `NullReferenceException` on directory junctions (PS 5.1)
- Tags: #env/powershell #env/windows #tooling
- Symptom: `Remove-Item : Object reference not set to an instance of an object.` on a reparse-point dir; with `$ErrorActionPreference = "Stop"` the script then hangs instead of exiting (one run sat ~4.7h until killed).
- Root cause: PS 5.1 `Remove-Item` mishandles directory junctions (tries to follow/recurse the reparse point). Distinct from L-006 (which is about *broken* junctions crashing Obsidian) — this is the *removal* during repair.
- Guard: delete junctions with `cmd /c rmdir "$LinkPath"` (removes only the link, never the target); never `Remove-Item` a reparse point. Always bound long script runs with a timeout when launching in background.
- Evidence: `scripts/obsidian-bootstrap.ps1:42` (2026-06-08; fix verified exit 0, ~24s).
- Promoted: no — ledger only.

### L-010 — Self-signed cert generation can write a half-pair if openssl fails mid-stream
- Tags: #infra #scripts #docker
- Symptom: `pld certs` succeeds but nginx won't start; `SSL_ERROR_BAD_CERT_DOMAIN` or cert/key mismatch when device connects.
- Root cause: cert generation writes `privkey.pem` + `fullchain.pem` directly to live paths in a single `openssl req` call. If the call is interrupted or openssl fails after the first file, the pair is incomplete — the second file may be missing or corrupted, leaving nginx with a half-written cert.
- Guard: write to `.tmp` files first. After both files are written, extract public keys from both and compare them (keypair verification). **Only after verification succeeds**, back up the old certs to `.bak` and atomically promote `.tmp` → live with `mv`. On any failure, clean up `.tmp` and exit non-zero. Live certs are never touched unless the new pair is valid.
- Evidence: `pld-cli-hardening` case — F1 fix, `docker/certs/generate-dev-certs.sh` (2026-06-08).
- Promoted: no — ledger only (may promote to lint rule if `.env` / script-generation patterns grow).

### L-011 — `sed s|...|...| ` breaks when RHS contains `|` or `&` (unescaped metacharacters)
- Tags: #infra #scripts #bash
- Symptom: env vars containing `|` (pipe), `&` (ampersand), or other sed metacharacters corrupt `.env` files: `API_URL="http://a|b"` becomes `API_URL="http://a.bERROR"` or similar.
- Root cause: `sed s|delimiter|replacement|` treats the delimiter and **RHS replacement characters as literal metacharacters**. A bare `|` in the value is interpreted as sed's end-of-pattern, and `&` in the RHS means "original matched text", breaking the line.
- Guard: avoid using a **delimiter that can appear in the value**. For arbitrary key=value pairs, use `awk` (or `perl`) to match and rewrite lines — no metacharacter interpretation. If using sed, choose a delimiter that is **impossible in the values** (e.g. NUL byte, or a multi-char sentinel) and **escape all RHS special chars** (`&`, `\`). Safest: use awk with `-v key=... -v val=...` and string-match on `$0 ~ "^" key "="`.
- Evidence: `pld-cli-hardening` case — F2 fix, `scripts/deployment/dev-preflight.sh:env_set()` (2026-06-08).
- Promoted: no — ledger only (test-gate script-env changes if pattern recurs).

### L-012 — Parallel sessions in one working tree clobber each other (claimed-but-absent fix)
- Tags: #process #git #agent-os
- Symptom: a fix the audit doc claimed was applied was absent from the code; concurrent sessions in the same tree overwrote each other's edits and spawned transient branches.
- Root cause: more than one runner editing the same working tree at once — a later write silently clobbered the registry anchoring fix.
- Guard: run ONE runner at a time per working tree. Trust the case file over chat history, and verify a claimed fix against the actual code before building on it.
- Evidence: `plt-case-governance-hardening-2026-06-08` (2026-06-09; root cause of the whole case).
- Automated: partial — the regression half is enforced by `CHK-STATUS-CLASSIFY` (a clobbered classifier fix fails the gate); the single-runner discipline itself is process-only.
- Promoted: no — ledger only (process rule; see the case "Careful Attention" callouts).

### L-013 — Frontmatter `#`-fence mistaken for the H1 title
- Tags: #tool/obsidian #docs #tooling
- Symptom: every projected case rendered its Summary as `app: <x>` in `CASE_REGISTRY.md`.
- Root cause: the generated `# --- generated ... ---` fence line written inside YAML frontmatter was grabbed by `^#`-based H1 detection, so the next frontmatter key became the "summary".
- Guard: skip the leading YAML frontmatter block before locating the H1 title in any case-file parser.
- Evidence: `scripts/obsidian-case-registry.ps1`, `plt-case-governance-hardening-2026-06-08` (2026-06-09).
- Automated: `CHK-REGISTRY-SUMMARY` (`scripts/recurrence-check.{ps1,sh}`) — flags any frontmatter key leaked as a case summary in the generated registry.
- Promoted: no — ledger only.

### L-014 — A lint can pass for the wrong reason
- Tags: #tooling #docs #tool/obsidian
- Symptom: `obsidian-lint.ps1` reported "0 broken links" while `[[CASES.base]]` was actually unresolvable.
- Root cause: the lint silently skipped table-escaped aliased links (`[[Foo\|Bar]]`) and never indexed `.base`, so a real broken link appeared clean.
- Guard: confirm a passing check actually resolves a known-good case — a green result with no positive control is not evidence. (Fixed: split on `/`, trim the escape, strip `.md|.canvas|.base`, index `.canvas`/`.base`.)
- Evidence: `scripts/obsidian-lint.ps1`, `plt-case-governance-hardening-2026-06-08` (2026-06-09).
- Automated: no — `obsidian-lint.ps1` always exits 0, so `recurrence-check` enforces the specific link/canvas invariants directly (`CHK-WIKILINK-RELATIVE`, `CHK-CANVAS-TRACKED`) rather than trusting the lint's exit code.
- Promoted: no — ledger only.

### L-015 — PowerShell `-Include` multi-pattern dir scans are flaky
- Tags: #env/powershell #tooling
- Symptom: `Get-ChildItem -Recurse -Include '*.a','*.b'` intermittently returned nothing on some hosts.
- Root cause: PS 5.1 `-Include` is unreliable for multi-pattern directory scans (it needs a trailing path wildcard to engage).
- Guard: enumerate with `... -File | Where-Object { $_.Extension -in '.a','.b' }` instead of `-Include`.
- Evidence: `scripts/obsidian-lint.ps1`, `scripts/recurrence-check.ps1` (2026-06-09).
- Automated: no — covered by the authoring pattern; `recurrence-check.ps1` and `obsidian-lint.ps1` both use the `-File | Where-Object` idiom.
- Promoted: no — ledger only.

---

## Promotion candidates (watchlist)

Entries that will become enforced rules if they recur once more:

- **Enforced (2026-06-09):** L-001 / L-002 (ASCII), L-003 (`&&`/parse), and L-004 (relative wikilinks) are now mechanically gated by `scripts/recurrence-check.{ps1,sh}` via `pre-merge-check`. The "CI ASCII-lint for `*.ps1`" anticipated below shipped as `CHK-PS-ASCII`; see `AGENTS.md § Immutable Rules` and `AGENT_DEFAULT_INSTRUCTIONS.md § Promoted rules`.
- L-009 — PowerShell filesystem footguns (`Remove-Item` on junctions). Consider a short "PS 5.1 gotchas" block in `scripts/`-authoring guidance if one more lands.
