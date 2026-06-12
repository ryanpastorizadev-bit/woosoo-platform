---
status: canonical
last_reviewed: 2026-06-10
scope: ecosystem
---

# Obsidian — Download & Setup Guide

Personal knowledge-management layer for the Woosoo platform. Obsidian opens the same
Git-tracked markdown files the agent chain reads and writes — it doesn't replace the
`docs/cases/` system, it gives you a richer local interface to it.

---

## Download

Go to: **https://obsidian.md/download** and pick your platform:

| Platform | Installer |
|---|---|
| Windows | `.exe` |
| macOS | `.dmg` |
| Linux | `.AppImage` or Flatpak |
| Android / iOS | respective app stores |

Check the download page for the current stable release version. Core Obsidian is free;
Obsidian Sync and Publish are optional paid add-ons. All core functionality works fully offline.

---

## Opening This Repo as Your Vault

Open `woosoo-platform/` as the vault root. The real folder structure is already there:

```
📁 woosoo-platform/          ← vault root (open this)
├── docs/
│   ├── cases/               ← all case files: nex-case-*, tab-case-*, prn-case-*, plt-case-*
│   ├── deployment/
│   ├── business/
│   └── ...
├── contracts/               ← cross-app API contracts
├── AGENTS.md
└── PROTOCOL.md
```

Obsidian reads every `.md` file in this tree. You get bidirectional links, graph view, and
Dataview over the same files the agents checkpoint to — no sync needed.

### Multi-repo note

The platform is split across four repos. Three vault strategies and why platform-only is correct:

| Strategy | Git integration | Cross-app linking | Verdict |
|---|---|---|---|
| Single vault (parent dir above all repos) | Broken — Obsidian Git tracks one `.git`; a parent dir has no `.git` | Full | Not recommended |
| **Platform-only (this repo)** | Clean — one vault = one `.git` | Sufficient — `docs/cases/` already tracks `nex-case-*`, `tab-case-*`, `prn-case-*` | **Recommended** |
| Multi-vault (one per repo) | Clean per vault | None across vaults | Only if repos are totally independent workstreams |

`docs/cases/` is the orchestration layer for all apps. Opening it in Obsidian here gives
cross-app visibility without breaking Git integration.

**Windows junction repair (required):** Obsidian scans the entire vault at startup — excluded
folders in `app.json` do **not** prevent crash. Sibling repos may contain Docker/Linux junctions
(e.g. `woosoo-nexus/public/storage` → `/var/www/html/...`) that cause `EACCES` on Windows.
`scripts/obsidian-bootstrap.ps1` repairs known junctions before you open the vault. Re-run it
after Docker dev sessions that recreate Linux paths.

---

## Core Features to Use

**Bidirectional linking** — the killer feature:
```
[[nex-case-007]] links to that note AND back-references appear automatically
```

**Tags** — use for status or priority:
```
#status/open  #status/blocked  #priority/critical
#agent/ranpo  #platform/nexus
```

**Mermaid diagrams** — built-in, no plugin needed. Existing case file diagrams render directly.

---

## Bootstrap (automated)

From the platform root (PowerShell):

```powershell
.\scripts\obsidian-bootstrap.ps1
```

This installs six community plugins from GitHub releases, enables them in
`.obsidian/community-plugins.json`, points Templater at `Templates/`, and sets Obsidian Git to
**pull on boot** (no auto-push). Re-run after cloning the repo on a new machine.

Then open Obsidian → **Open folder as vault** → `woosoo-platform/`. If prompted about community
plugins, choose **Enable / Trust**.

### Activate community plugins

Bootstrap installs plugin files and lists them in `community-plugins.json`, but **Obsidian still
requires you to enable them in the app**:

1. **Settings** (gear) → **Community plugins** → turn the **master switch ON**
2. When prompted, **Trust author and enable plugins** for this vault
3. **Settings → About** → confirm **Restricted mode** is **OFF** (it disables all community plugins)
4. Under Community plugins, confirm each plugin is ON — especially **Dataview** and **Kanban**
5. **Restart Obsidian** (full quit and reopen)
6. Open `docs/cases/CASE_INDEX.md` in **Preview** (`Ctrl+E`) — you should see a **table**, not a
   raw ` ```dataview ` code block
7. `Ctrl+P` → **Dataview: Force refresh** if tables are empty after a registry run

**Fallback without Dataview:** open `docs/cases/CASES.base` in **Bases** view (core plugin).

---

## Essential Plugins (Community)

Installed by `obsidian-bootstrap.ps1`. Manual install: Settings → Community Plugins → Browse

| Plugin | Purpose |
|---|---|
| **Dataview** | Query the vault like a database — live case status views |
| **Templater** | Auto-fill a new case file from the `_TEMPLATE.md` structure |
| **Calendar** | Daily notes navigator |
| **Kanban** | Visual board for task tracking |
| **Git** | Auto-commit vault changes to GitHub |
| **Iconize** | Folder icons for visual navigation |

---

## Query, signaling & visual layers

Open `docs/cases/CASE_DASHBOARD.md` (run-state tables) and `docs/cases/CASE_INDEX.md` (recently
reviewed cases). Each case's `## Run State` body is the source of truth;
`scripts/obsidian-case-registry.ps1` projects `run_status`, `app`, `tier`, `next_agent`, `branch`,
`interrupted`, `updated`, and `tags` into frontmatter (generated fence comment) — re-run after
run-state edits. Live orchestration queue: `state/WORK.md` and `state/QUEUE.md` (embedded in
[[OPERATOR_HOME]]).

### Querying — Dataview vs Bases

| Surface | File | Scope | Auto? |
|---|---|---|---|
| [[cases/CASE_DASHBOARD\|CASE_DASHBOARD]] | `docs/cases/CASE_DASHBOARD.md` | All cases — blocked, open-by-app, stale, counts | Auto (Dataview) |
| [[cases/CASES.base\|CASES.base]] | `docs/cases/CASES.base` | All cases — table + board-by-status + per-app | Auto (Bases, core) |
| [[cases/OPS_KANBAN\|OPS_KANBAN]] | `docs/cases/OPS_KANBAN.md` | Bucket-B Pi ops only | **Curated** (manual) |

`CASES.base` (auto board from frontmatter) and `OPS_KANBAN` (hand-ordered ops board) **coexist** —
they serve different scopes (all-cases vs Bucket-B ops) and neither supersedes the other.

### Visual signaling — callouts

Case templates seed a small callout vocabulary; use them so risk is visible at a glance:

| Callout | Where |
|---|---|
| `> [!danger]` | `## Handoff` blockers, active P0 gates |
| `> [!warning]` | `## Remaining Risks` |
| `> [!success]` / `> [!failure]` | `## Executioner Verdict` (APPROVED / REJECTED) |
| `> [!info]` | context / scope notes |

### Tags (auto-generated)

The registry projection emits `status/<run_status>`, `app/<app>`, and `tier/<n>` tags onto each
case, making the **tag pane** and graph tag groups navigable. `obsidian-lint.ps1` flags cases that
carry run-state frontmatter but are missing required tags.

### Canvas maps

| Canvas | Purpose |
|---|---|
| [[architecture/SYSTEM_MAP.canvas\|SYSTEM_MAP]] | Apps, data flow, and the contract on each boundary |
| [[cases/DEPLOY_SEQUENCE.canvas\|DEPLOY_SEQUENCE]] | Bucket B deploy-gate ordering (mirrors OPS_KANBAN) |

File nodes open the real `.md`; both are linked from [[VAULT_INDEX]] and [[DOCS_HUB]] so they are
not graph orphans.

---

## Templater — Case File Template

`Templates/CASE_FILE.md` is committed in this repo. It mirrors `docs/cases/_TEMPLATE.md` so
Obsidian-created cases are immediately compatible with the agent chain. In Templater settings,
set the templates folder to `Templates/` at the vault root.

To create a new case from Obsidian: Templater → Create new note from template → `CASE_FILE.md`,
then save as `docs/cases/<task-slug>.md`.

---

## Git Sync

Install the **Obsidian Git** plugin and point it at this repo. Every save or timed interval
auto-commits your vault edits — the same guarantee GitHub gives you, but accessible from
inside Obsidian.

**Start small:** open the vault, pin **`docs/cases/OPERATOR_HOME.md`** as your daily landing
page, wire up Dataview and Git. Everything else layers on top.

### Hub pages (wire these up first)

| Note | Plugin / view | Role |
|------|---------------|------|
| `docs/cases/OPERATOR_HOME.md` | Pin as default | Daily dashboard — embeds `state/WORK`, queue, stability |
| `docs/cases/CASE_DASHBOARD.md` | Dataview | Run-state tables — blocked, Bucket B, counts |
| `docs/cases/CASES.base` | Bases (core) | Table/board by status — works without Dataview |
| `docs/cases/OPS_KANBAN.md` | Kanban view | Drag-track Bucket B Pi ops |
| `docs/cases/CONTRACTS_HUB.md` | Normal / Graph | Wiki-links to `contracts/*.md` |
| `docs/cases/CASE_INDEX.md` | Dataview | Recently reviewed canonical cases |
| `docs/operator/daily/YYYY-MM-DD.md` | Calendar | Operator logs (Templater `OPERATOR_LOG`) |

Bootstrap copies `daily-notes.json` (Calendar folder + template) and `graph.json` (color groups).

### Daily workflow

1. Run `.\scripts\obsidian-bootstrap.ps1` on a new machine (junction repair + plugins)
2. Open **OPERATOR_HOME** — embeds show `state/WORK`, stability priorities, Bucket B queue
3. **Calendar** → today → auto-creates daily log from `Templates/OPERATOR_LOG.md`
4. **OPS_KANBAN** — move Pi cards as ops complete (mirror into `state/QUEUE.md` when status changes)
5. Click through to active case (`[[plt-case-stability-remediation]]`, etc.)
6. Edit case files or queue rows; commit via Git or Obsidian Git (pull-on-boot only)
7. Claude Code `work` / `execute` — agents read the same files; case `## Run State` is resume point

Agents **refer to** the vault hubs (`docs/VAULT_INDEX.md`, `docs/cases/CASE_REGISTRY.md`) for
navigation and use `[[wikilinks]]` in case files. Resume state stays in `## Run State` on disk.

### Orphan policy

Many notes show as "orphans" in Graph view until linked. **Expected orphans** (by design):
`hooks/`, `state/`, `inbox/`, `Templates/` — agent boot files, not case graph nodes.

**Fix case orphans:** `docs/cases/CASE_REGISTRY.md` wikilinks every case file. Regenerate:
```powershell
.\scripts\obsidian-case-registry.ps1
```

**Fix docs orphans:** `docs/DOCS_HUB.md` links canonical docs outside cases.

**Lint the vault** (orphans + broken links/embeds + missing tags; canvas-aware, ignores code-span examples):
```powershell
.\scripts\obsidian-lint.ps1
```

When triaging or completing work: add `[[related-case]]` in case bodies; run registry script for new slugs.

**Full hygiene runbook** (canonical-age, placeholder dates, malformed status, all checks in one command):
```powershell
.\scripts\vault-hygiene.ps1
```
See [[obsidian-vault-hygiene]] for the complete operator runbook — tiers, commands, and interpreting findings.
