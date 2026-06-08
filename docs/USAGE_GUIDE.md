---
status: canonical
last_reviewed: 2026-06-08
scope: ecosystem
---

# Usage Guide — Driving the Woosoo 4-Agent System

Operator-facing runbook. This guide **navigates**; the authoritative rules live in the files it
points to (`AGENTS.md`, `docs/AGENT_DEFAULT_INSTRUCTIONS.md`, `docs/RESUME_PROTOCOL.md`,
`PROTOCOL.md`). Where this guide and those files appear to differ, the rule files win.

## 1. How to drive it

You type a short phrase; one chatbox plays all four roles — **Contrarian → Specialist → Verifier
→ Executioner** — and the durable state lives in `docs/cases/<slug>.md`, not the chat. A task is
done only when the **Executioner returns `APPROVED`**.

| You type | What happens |
| -------- | ------------ |
| `intake this: <bug/feature>` | Fresh case — Contrarian challenges, sets tier, picks specialist |
| `work` / `continue` / `next` / `go` | Resume the active/queued task from its last gate |
| `status` | Print in-progress work + last gate |
| `triage` / `make a case` | Convert a raw report into a case file |
| `execute <case>` | Run the implementation chain |
| `verify` / `did it work` | Run the Verifier (tests/build/lint) |
| `review` | Inspect partial/unfinished work |
| `blocked` / `unlock` | Dependency check |
| `handover` / `sync` | Write the post-completion handover |

Full hook map + tiers + routing: `AGENTS.md`. Concise routing reference: `PROTOCOL.md`.

## 2. Continuing from a session summary

A chat summary (or `CLAUDE.local.md`) is **not** durable state — the case file is. To continue
correctly, convert each open item into the case system:

1. Split the summary into individual tasks — **one app each**.
2. `intake this: <one item>` → the Contrarian triages it and creates `docs/cases/<slug>.md`.
3. Backlog with ordering/blockers → rows in `state/QUEUE.md` (+ `state/DEPS.md` for cross-app
   dependencies).
4. `work` / `what's next` resumes from the case files + queue.
5. If the summary is old, the case is created with a **"verify against current code"** note —
   never assume a stale item is still open.

## 3. Common scenarios → where the protocol lives

These are codified and enforced at the gates; this table is the index.

| Scenario | Protocol |
| -------- | -------- |
| **Uncommitted changes** in the working tree | `AGENT_DEFAULT_INSTRUCTIONS.md` → *Working Tree Preservation* (decision tree; stage only your files by path; never `git add .`) |
| **A fix must not recur** | *Regression Lock — A Fix Stays Fixed* (fail-before/pass-after test required) + *Root Cause Proof Standard* |
| **A fix failed / REJECTED** | Revert only the bad file; re-run Verifier clean before fix-forward. Never `git reset --hard` / `git clean -fd` (*Destructive Git Operations Are Absolutely Forbidden*) |
| **Work spans two apps** | Executioner returns `SPLIT_REQUIRED`; split into per-app cases (`AGENTS.md` → Workspace Split Rule) |
| **Interrupted / machine switch** | `git pull && git switch agent/<slug>`, then `resume` — case file's `next_agent` is the resume point (`RESUME_PROTOCOL.md`) |
| **Test on WSL after Windows push** | `USAGE_GUIDE.md § 6` + `deployment/DEPLOYMENT_GUIDE.md § 4` (Docker from platform root; not host `composer dev`) |
| **Touching auth/POS/order-state/payment/print/deploy** | Auto-escalates to Tier 3 (deep Contrarian + risk analysis + contract reference) |
| **Test counts look off / "pre-existing" claims** | *Report Rejection Protocol*, *Full-Suite Requirement*, *No "Pre-existing" Hand-Waves* |

## 4. Skills

The Contrarian picks from the **scenario → skill map** in `AGENTS.md` → *Skill Discovery*; the
Specialist loads only those. `agent-sequence` is mandatory every task; `test-verification` on every
code task; `code-simplifier` on Tier 2–3 code tasks (runs `dead-code-cleanup` internally before
Verifier). Specialists also load `dead-code-cleanup` for incremental hygiene during implementation.

## 5. Cursor Hybrid Workflow (EXPERIMENTAL — Tier 1–2 only)

Use Cursor for the Specialist (code-writing) phase. Claude Code keeps all orchestration gates.
**Tier 3 tasks must use a Claude Code Specialist — do not use Cursor.**
Full rules and rationale: `AGENTS.md § Cursor Specialist Mode`.

### Mandatory session preamble (paste at the start of every Cursor session)

> **Why mandatory:** Cursor has a known bug loading `.cursor/rules` in multi-root workspaces
> (confirmed 2025–2026). Until Phase 2 (per-app repo rules files) lands, this paste-preamble
> is the safety mechanism for Gaps 2 (app boundaries) and 3 (immutable rules). Do not skip it.

```
Woosoo Platform — session rules (mandatory, paste before any other prompt):

IMMUTABLE RULES — never violate:
1. Backend owns truth. Tablet sends only { guest_count, package_id, items:[{menu_id,quantity}] }.
   Never send pricing, tax, modifiers, totals, POS mapping, or order state from the tablet.
2. Order states: pending confirmed in_progress ready served completed cancelled voided archived.
   Terminal: completed|cancelled|voided|archived. Do not invent states.
3. No raw errors in customer UI. Friendly messages only; stack traces go to logs.
4. No hardcoded LAN IPs or Reverb hosts in tablet or bridge code.
5. No secrets in .env without operator review.

APP BOUNDARY — edit only: [INSERT one of: woosoo-nexus/** | tablet-ordering-pwa/** | woosoo-print-bridge/**]
If asked to touch a second app: STOP and request a SPLIT.

TIER 3 STOP LIST — refuse and tell operator to use Claude Code if task touches:
order state · session lifecycle · payment/pricing · printing · auth/tokens · API contracts ·
Reverb/broadcasting · queues · race conditions · DB migrations · cross-app · production deploy

GIT — do NOT: git commit, git add . / -A, git reset --hard, git clean, force-push.
Branch must already be agent/<slug>. Operator stages and commits.

HYGIENE (mandatory on every code task): after POST_EDIT, invoke code-simplifier subagent on changed
files (runs dead-code-cleanup internally). Record under ## Code Simplification in the case file.

CHECKPOINT (your last action): write ## Specialist Investigation & Implementation and
## Code Simplification to docs/cases/<slug>.md, and refresh ## Run State:
  last_completed_agent: specialist:<agent-name>
  next_agent: verifier
  active_runner: cursor
  status: IN_PROGRESS
  updated: <YYYY-MM-DD>
If you cannot find the case file: STOP.

PRE_EDIT — before first file edit: complete hooks/pre-edit-gate.md output in chat (files table,
minimal patch, non-goals, risks). Do not edit until done.
POST_EDIT — before hygiene gates: complete hooks/post-edit-review.md output (behavior diff, contract
check, rollback).
```

### Step-by-step

1. **Claude Code:** `intake this: <task>` → Contrarian triages, creates `docs/cases/<slug>.md`.
   For Tier 1, run a minimal precheck: slug + case file + Run State — slug/resume discipline is never skipped.
2. Read the case file's `## Contrarian Review` and `## Handoff` blocks — this is Cursor's brief.
3. **Cursor:** open **`woosoo-platform.code-workspace`** (multi-root). Confirm branch `agent/<slug>`.
4. **Cursor:** paste preamble + Contrarian brief. Run **PRE_EDIT_GATE** before first edit. Implement
   — editing only the active app's `<app>/**`. Run **POST_EDIT_REVIEW**, then **code-simplifier**
   (hygiene gates) on all code tasks before checkpoint.
5. **Cursor:** final action — write Specialist + Code Simplification checkpoint to `docs/cases/<slug>.md`.
   **Operator confirms the checkpoint is present before continuing.**
6. **Operator:** `git diff` to review changes; stage specific files by path; commit.
7. **Claude Code:** `verify` → Verifier runs `scripts/pre-merge-check.sh --app <name>`.
8. **Claude Code:** `work` → Executioner returns `APPROVED` / `REJECTED` / `SPLIT_REQUIRED`.

### On REJECTED

`git restore <specific-files>` (restore only Cursor's files — **never** `git restore .`).
Re-run Verifier clean before any fix-forward. If Cursor caused the failure, consider switching to a Claude Code Specialist for fix-forward.

### Context7 documentation lookup

For up-to-date library/framework docs inside Cursor (Nuxt, Laravel, Flutter, etc.), see
[CONTEXT7_GUIDE.md](CONTEXT7_GUIDE.md). Ask library-specific questions in chat or use the
`/docs` command; never paste secrets or `.env` values into Context7 queries.

### Rule sync

`.cursor/rules/woosoo.mdc` mirrors `AGENTS.md § Immutable Rules`. When immutable rules change, update both files. `AGENTS.md` is canonical; the `.mdc` file is a Cursor-side copy.

### Phase 2 (recommended — removes paste-preamble requirement)

Create one case per app repo (`plt-case-NNN-cursor-rules-<app>`) to add a scoped
`.cursor/rules/<app>.mdc` to each of `woosoo-nexus`, `tablet-ordering-pwa`, and
`woosoo-print-bridge`. Each is the platform `.mdc` scoped to that app's paths and verification
commands. Once each app repo has its own rules file and it is verified to load in a single-root
Cursor session, the paste-preamble for that app becomes optional.

---

## 6. WSL dev test (Windows edit → Docker run)

Use this when you **edit on Windows** (Cursor) and **run/test on WSL** with Docker.
Full Path B detail: [`deployment/DEPLOYMENT_GUIDE.md § 4`](deployment/DEPLOYMENT_GUIDE.md#4-path-b--dev-deploy-on-wsl2--docker-desktop--dev-linux).

### Two clones, one workflow

| Where | Path | Role |
| ----- | ---- | ---- |
| **Windows** | `E:\Projects\woosoo-platform\` | Edit, commit, `git push` (per app repo) |
| **WSL** | `~/projects/woosoo-platform/` | Pull, `./run dev` / `woosoo dev`, browser test |

These are **separate git working trees**. After every Windows push, pull the matching app repo on WSL
(e.g. `git -C woosoo-nexus pull origin dev`). If you pushed the **platform** repo itself, pull that
clone too: `git -C ~/projects/woosoo-platform pull origin dev`. Do **not** treat `/mnt/e/Projects/...` as the canonical
WSL path — use `~/projects/woosoo-platform/`.

### Stack

Docker Compose runs from **platform root**, never host Laravel on the WSL shell.

**Canonical post-push flow** (after Windows `git push` in `woosoo-nexus`; if you pushed the **platform** repo itself, run `git pull origin dev` in `~/projects/woosoo-platform` first — `pld sync` does not pull the platform root):

```bash
cd ~
cd projects/woosoo-platform          # platform root — NOT woosoo-nexus/

pld sync                             # Palisade CLI (preferred)
# legacy: woosoo sync
```

Install CLI on WSL: `bash scripts/install.sh` (creates `/usr/local/bin/pld` + deprecated `woosoo`).

Windows (WSL required for stack): `.\pld.cmd sync` from platform root — see [pld-cli-decision.md](architecture/pld-cli-decision.md).

| Command | When |
| ------- | ---- |
| `pld sync` | Daily: after Windows push, source-only changes |
| `pld sync --full` | First run, deps/Dockerfile change |
| `pld sync --build` | Sync + `docker compose build` |
| `pld rebuild` | Vue/KDS frontend — Vite rebuild in container |
| `pld rebuild --php` | `composer install` in app container |
| `pld certs` | Missing `docker/certs/fullchain.pem` or TLS drift |
| `pld network` | LAN / PUBLIC_HOST / portproxy after WSL restart |

`woosoo *` is a deprecated alias (same commands).

Legacy equivalent: `git -C woosoo-nexus pull origin dev` then `./run dev --no-pull --no-build`.

First-time setup: `bash scripts/install.sh` then `woosoo dev` or `woosoo sync --full` — see DEPLOYMENT_GUIDE § 4.1.

### Browser URL

On this operator's home network, admin/nexus UI is tested at **`https://192.168.100.7`**
(e.g. `/login`, `/kds`). That is the **`PUBLIC_HOST`** value for home mode
(`switch-network.sh home`); other networks use auto-detected LAN IP via `woosoo network`.

`localhost` reaches Docker from the same machine but is **not** the primary URL for LAN/tablet
parity testing. Run `woosoo network` if LAN access fails after a WSL restart.

### Agent anti-patterns (never suggest on WSL)

| Wrong | Right |
| ----- | ----- |
| `cd woosoo-nexus` then host `composer dev` / `composer install` | `pld sync` from platform root |
| Host `npm run dev` inside `woosoo-nexus` | Rebuild in Docker (below) or bind-mount picks up PHP/Vue |
| `http://localhost:8000` as primary test URL | **`https://192.168.100.7`** (home example) or `$PUBLIC_HOST` |
| `/mnt/e/Projects/woosoo-platform` as canonical WSL path | `~/projects/woosoo-platform` |

Host `composer` on WSL resolves to Windows Composer and fails with **`php: not found`**. PHP, Composer,
and npm for the app run **inside** the `app` container:

```bash
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml exec app composer install
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml exec app npm run build
```

### After frontend (Vue/KDS) changes

```bash
cd ~/projects/woosoo-platform
woosoo rebuild
```

Manual escape hatch:

```bash
WOOSOO_FORCE_VITE_BUILD=true docker compose --env-file ./woosoo-nexus/.env -f compose.yaml up -d --build app
```

### Verification gates on WSL

Run from platform root using Docker where needed — not host `composer test` unless PHP is natively
installed in WSL (this operator's setup uses containers):

```bash
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml exec app php artisan test tests/Feature/Admin/KdsDisplayTest.php
```

Windows-side pre-merge gates (`scripts/pre-merge-check.ps1`) remain the canonical CI path before push.

---

## 7. Obsidian operator workspace

Obsidian is the **operator UI** on the same Git-tracked markdown agents use. It does not replace
the case system — it makes `docs/cases/`, `state/`, and `contracts/` easier to navigate.

| Step | Action |
|------|--------|
| Bootstrap | `.\scripts\obsidian-bootstrap.ps1` from platform root (Windows junction repair + 6 plugins) |
| Open vault | Obsidian → Open folder as vault → `woosoo-platform/` |
| Pin home | `docs/cases/OPERATOR_HOME.md` — embeds `state/WORK`, queue, stability runbook |
| Pi ops board | `docs/cases/OPS_KANBAN.md` — switch to **Kanban** view |
| Contracts | `docs/cases/CONTRACTS_HUB.md` — wiki-links to `contracts/*.md` |
| All cases | `docs/cases/CASE_REGISTRY.md` — full wikilink index (fixes graph orphans) |
| Vault map | `docs/VAULT_INDEX.md` — agent + operator navigation entry |
| Daily log | Calendar plugin → today → `docs/operator/daily/` via `Templates/OPERATOR_LOG.md` |
| New case | Templater → `Templates/CASE_FILE.md` → save under `docs/cases/<slug>.md` → `obsidian-case-registry.ps1` |

**Agents** refer to `VAULT_INDEX`, `CASE_REGISTRY`, and `CONTRACTS_HUB`; add `[[wikilinks]]` in case files.
Lint orphans: `scripts/obsidian-lint.ps1`. Full setup: [obsidian-setup-guide.md](obsidian-setup-guide.md).
Resume: `docs/cases/<slug>.md` per `RESUME_PROTOCOL.md`.

---

## 8. How docs stay current — and keep improving (anti-degradation loop)

Nothing auto-updates. `hooks/*.md` are markdown playbooks, not executable hooks; README/CHANGELOG
do not self-write. Currency is **gate-enforced**, and the system is designed to ratchet forward,
not rot:

- **Checkpoint discipline** — every agent writes its output + `## Run State` to the case file
  before handing off. No checkpoint = the phase did not happen.
- **Handover + `state/DONE.md`** — completion is recorded; knowledge is captured, not lost.
- **Regression Lock** — a fixed defect gets a test, so it cannot silently return.
- **Documentation-truth gate** — `scribe` + `documentation-truth-audit` + the Executioner
  **reject** a task whose docs claim things the code doesn't do, link to missing files, or leave
  the case file unupdated. (This is what catches stale inventories and dead links.)
- **Lessons Ledger → evidence-derived rules** — every observed failure mode is logged in
  `docs/LESSONS.md` (symptom → root cause → guard). Agents read it before non-trivial work and
  append after any mistake. On recurrence or high severity, the guard is **promoted** to a binding
  rule in `AGENT_DEFAULT_INSTRUCTIONS.md § Extended Rules (Evidence-Derived from Production
  Failures)`. The ruleset only grows tighter; the same mistake is never made twice.
- **Periodic orchestration audit** — re-run the structural checks (agents/skills/hooks resolve,
  no dead links, docs match code) when the system changes; fix drift immediately.

The rule of thumb: **every fix leaves behind a guard** (a test, a rule, or a corrected doc) so the
same problem cannot return — that is what keeps the system improving rather than degrading.
