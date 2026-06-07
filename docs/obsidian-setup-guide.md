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

Case file frontmatter uses `status`, `last_reviewed`, and `scope`. Paste this in any note
for a live index of recently-reviewed cases:

````
```dataview
TABLE last_reviewed, scope
FROM "docs/cases"
WHERE status = "canonical"
SORT last_reviewed DESC
```
````

> Note: task-level run state (IN_PROGRESS, BLOCKED, COMPLETE) lives in the `## Run State`
> body section of each case file, not in YAML frontmatter. Dataview cannot query it directly.
> Use the `status` view in `state/WORK.md` for live run state.

---

## Templater — Case File Template

Create `Templates/CASE_FILE.md`. This mirrors `docs/cases/_TEMPLATE.md` so Obsidian-created
cases are immediately compatible with the agent chain:

```markdown
---
status: canonical
last_reviewed: <% tp.date.now("YYYY-MM-DD") %>
scope: ecosystem
---

# CASE: <slug>

## Run State
- task_slug:
- tier:
- branch:
- status: IN_PROGRESS
- last_completed_agent: none
- next_agent: contrarian
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: <% tp.date.now("YYYY-MM-DD HH:mm") %>

## Handoff
- Phase in progress:
- Done so far:
- Exact next action:
- Working-tree state:
- Risks / do-not-redo:

## Tier

## Branch

## Problem

## Contrarian Review

## Success Criterion

## Investigation

## Root Cause

## Proposed Fix

## Files Changed

## Verification

## Executioner Verdict

## Remaining Risks
```

---

## Git Sync

Install the **Obsidian Git** plugin and point it at this repo. Every save or timed interval
auto-commits your vault edits — the same guarantee GitHub gives you, but accessible from
inside Obsidian.

**Start small:** open the vault, navigate to `docs/cases/`, wire up Dataview and Git first.
Everything else layers on top.
