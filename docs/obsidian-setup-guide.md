---
status: canonical
last_reviewed: 2026-06-07
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

## Essential Plugins (Community)

Enable via: Settings → Community Plugins → Browse

| Plugin | Purpose |
|---|---|
| **Dataview** | Query the vault like a database — live case status views |
| **Templater** | Auto-fill a new case file from the `_TEMPLATE.md` structure |
| **Calendar** | Daily notes navigator |
| **Kanban** | Visual board for task tracking |
| **Git** | Auto-commit vault changes to GitHub |
| **Iconize** | Folder icons for visual navigation |

---

## Dataview Example

Open `docs/cases/CASE_INDEX.md` for a live Dataview index of canonical cases. Case file
frontmatter uses `status`, `last_reviewed`, and `scope`.

> Note: task-level run state (IN_PROGRESS, BLOCKED, COMPLETE) lives in the `## Run State`
> body section of each case file, not in YAML frontmatter. Dataview cannot query it directly.
> Use `state/WORK.md` and `state/QUEUE.md` for live orchestration status.

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

### Daily workflow

1. Open **OPERATOR_HOME** — embeds show `state/WORK`, stability priorities, Bucket B queue, KDS blockers
2. Click through to the active case (`[[plt-case-stability-remediation]]`, etc.)
3. Edit case files or queue rows as ops progress; commit via Git or Obsidian Git plugin
4. Start or resume agents from Claude Code — they read the same files you edited
