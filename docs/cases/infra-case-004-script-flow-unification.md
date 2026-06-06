---
status: COMPLETE
last_reviewed: 2026-06-05
scope: woosoo-platform
---

# INFRA-CASE-004: Deployment Script Flow Unification

> **Re-scoped 2026-06-05** from "doc/dedup cleanup" to **one robust deploy command +
> secure env handling**, at operator request ("simple working solution… secure .env…
> a command that pulls all app repos… composer/npm/build… no stale builds… retry logic…
> install missing dependencies… check if anything is missing/not running"). The original
> doc-reconciliation + check.sh dedup is folded in (Changes 5–6 below). Implementation plan:
> `~/.claude/plans/created-another-issue-deployment-nested-cupcake.md`.

## Run State
- task_slug: infra-case-004-script-flow-unification
- tier: 2
- branch: agent/infra-004-deploy-hardening
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: none
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-05

## Implementation (2026-06-05)

The single command remains `sudo bash scripts/deployment/deploy-all.sh`
(`check → doctor → backup → deploy → health`). It pulls/builds the **two deployable Docker app
repos** — `woosoo-nexus` + `tablet-ordering-pwa`; `woosoo-print-bridge` is an Android/APK relay,
not part of the Docker deploy. Changes — all edits to existing scripts/docs,
**no `compose.yaml` or `Dockerfile` changes**:

1. **`deploy.sh`** — added `retry()` (3-attempt, flat 5s gap) around `git fetch`,
   `composer install`, and `docker compose build`. Added **composer hydration**: a one-off
   `run --rm --no-deps app composer install --no-dev --optimize-autoloader` when
   `vendor/autoload.php` is missing or `composer.lock` is newer (fixes the bind-mount that
   shadows the image `vendor/`). Added **tablet UI freshness**: export real
   `TABLET_BUILD_SHA/BRANCH/TIME` (consumed by compose build-args; also fixes `build-info.json`)
   and `--no-cache tablet-pwa` when the tablet HEAD moved vs the pre-pull snapshot.
2. **`deploy.sh`** — **always** runs `doctor.sh` as step `[0/6]`; there is **no skip flag**, so the
   placeholder/empty-secret gate cannot be bypassed by calling `deploy.sh` directly. Also fixed the
   end-of-run summary to `source "$CONFIG_FILE"` (was hardcoded `/etc/woosoo/woosoo.env`, wrong for
   the `./woosoo.env` primary).
3. **`deploy-all.sh`** — `check.sh` wired as informational step `[0/4]` (never blocks); banner now
   reads `check -> doctor -> backup -> deploy -> health`. Deploy step runs `deploy.sh` plainly —
   doctor runs in both (step 1 + deploy.sh step 0); that intentional double read-only run is the
   price of an unbypassable gate. **Health step has grace + retry** (initial + 2 retries with 45s
   gaps = 90s, matching the app `start_period`), and **every failure prints a diagnosis bundle**
   (`docker compose ps` + tail logs) alongside the exact manual rollback command. Rollback stays
   manual by design (forward-only migrations make blind auto-revert unsafe).
4. **`apply-woosoo-config.sh`** — `chmod 600` the written `woosoo-nexus/.env`; `safe_backup_file`
   now `chmod 700` the config-backup dir and `chmod 600` each backup. **`dev-docker-bootstrap.sh`**
   — `chmod 600` the written `.env` and its `.env.bak` copy.
5. **Docs** — `production-docker.md` + `DEPLOYMENT_GUIDE.md` + `README.md` now teach one config
   method (`./woosoo.env`, 0600, via `init-woosoo-env.sh`; `/etc/woosoo` = root-owned fallback),
   reference `check.sh`, and describe `deploy-all.sh` as the one CI-style command. Removed the
   stale "7 scripts not migrated" claim and all `setup-woosoo-env.sh` references.
6. **`check.sh`** — dropped the `docker`/`ss`/`curl` and `rootCA.crt` checks that duplicate
   `doctor.sh`; kept git/openssl/docker-engine-running/TLS-expiry (unique to check.sh).

## Handoff
- Phase in progress: COMPLETE (Executioner APPROVED)
- Done so far: all changes implemented (see Implementation) + review blockers fixed
- Exact next action: operator review → commit on `agent/infra-004-deploy-hardening` → merge to `dev`
- Working-tree state: edits applied to deploy.sh, deploy-all.sh, apply-woosoo-config.sh,
  dev-docker-bootstrap.sh, check.sh, docs, QUEUE.md (uncommitted)
- Risks / do-not-redo: do NOT re-create setup-woosoo-env.sh; do NOT add a new parallel deploy
  script; do NOT introduce auto-rollback (forward-only migrations make it unsafe — rollback is
  manual by design)

> **Re-scope note (2026-06-05):** two constraints from the original narrow plan were intentionally
> reversed — `check.sh` is now the informational step 0 of `deploy-all.sh` (was "do NOT call it
> from deploy-all"), and `dev-docker-bootstrap.sh` received the `chmod 600` secure-env fix (was
> "do NOT touch"). The Implementation section above is the authoritative record; the sections below
> "## Problem" are the original investigation kept for context only.

---

## Problem

> _Original investigation (2026-06-05), describing the pre-change state that motivated this case.
> Kept for context; the Implementation section above is the authoritative record of what shipped._

Three issues surfaced during INFRA-CASE-002 Stage B prep:

1. **check.sh was created this session but is not wired into any documented operator flow.**
   It is a standalone script that runs no-sudo preflight checks, but no doc or pipeline references it.
   Operators won't know to run it.

2. **check.sh duplicates checks that doctor.sh already performs.**
   Running both back-to-back means the operator sees the same failure twice — once from check.sh
   and once from doctor.sh inside deploy-all.sh. More importantly, the two scripts could diverge
   (different thresholds, different messages) and confuse operators.

3. **production-docker.md references setup-woosoo-env.sh, which was deleted this session.**
   The replacement is init-woosoo-env.sh. Any operator following the doc gets "command not found".

---

## Overlap Audit: check.sh vs doctor.sh

These checks appear in both scripts (some with different depth):

| Check | check.sh section | doctor.sh section | Verdict |
|---|---|---|---|
| docker/ss/curl available | §3 Required tools | §Required commands | True duplicate — same 3 commands |
| rootCA.crt present | §4 TLS certificates | §Platform-root compose authority | True duplicate |
| CONFIG_FILE existence | §5 Operator config | §Config file | Different depth: check.sh = presence only; doctor.sh = presence + source + value validation |
| compose.yaml validates | §7 Docker compose | §Platform-root compose authority | Different depth: check.sh = `config --quiet`; doctor.sh = same + REVERB_APP_KEY interpolation warning |
| Port conflicts | §10 (80,443,3306,6379,8080) | §Docker-only host runtime ownership (3306,6379,8080) | Partial: check.sh covers 2 more ports |

Checks ONLY in check.sh (unique, no equivalent in doctor.sh):
- Git repo branch + commits-behind origin (platform + app repos)
- TLS certificate expiry via openssl
- APP_KEY presence and format
- Docker image inventory (built vs missing)
- Running container list
- Placeholder credential detection in woosoo.env

Checks ONLY in doctor.sh (unique, no equivalent in check.sh):
- Sources woosoo.env and validates all WOOSOO_* VALUES (not just presence)
- POS host IP: production (192.168.1.32) vs dev (192.168.100.7) enforcement
- Reverb key placeholder detection in woosoo.env values
- systemctl: mariadb, redis-server, php8.4-fpm, supervisor must be disabled
- compose REVERB_APP_KEY interpolation warning detection
- Pi vcgencmd throttle / temperature
- docker system df

---

## Stale Documentation Audit

`docs/deployment/production-docker.md` references the deleted script in three places:

| Line | Current text | Correct text |
|---|---|---|
| 78–80 | `setup-woosoo-env.sh — interactive first-time setup wizard for /etc/woosoo/woosoo.env` | `init-woosoo-env.sh — seeds ./woosoo.env from app .env files; re-runnable` |
| 92 | `Config contract: /etc/woosoo/woosoo.env (root-owned, mode 0640)` | Dual-path: `./woosoo.env` (mode 0600, user-owned) or `/etc/woosoo/woosoo.env` (root-owned, mode 0640) |
| 98–99 | `sudo bash scripts/deployment/setup-woosoo-env.sh` (code block) | `bash scripts/deployment/init-woosoo-env.sh` (no sudo needed) |
| — | check.sh not mentioned anywhere in the deploy scripts table | Add row: `check.sh — no-sudo pre-deploy readiness check; run before init-woosoo-env.sh` |

---

## Scenarios

### Scenario A — First-time, Pi (production)

Machine state: Pi5, Docker, git installed. No repos cloned, no config, no certs.

Required steps and which script serves each:

| Step | Script | Notes |
|---|---|---|
| 1. Clone repos | manual git clone | No script automates this — documented in production-docker.md |
| 2. Readiness check | `check.sh` | No sudo. Reports exactly what is missing with FIX commands |
| 3. Create TLS certs | `docker/certs/generate-dev-certs.sh` | check.sh will show FIX if missing |
| 4. Create config | `init-woosoo-env.sh` | No sudo. Seeds ./woosoo.env from nexus/.env. check.sh shows FIX if missing |
| 5. Deploy | `sudo bash scripts/deployment/deploy-all.sh` | Calls doctor.sh (preflight) → backup → deploy → health |

check.sh covers steps 2–4 diagnostics. If check.sh passes, deploy-all.sh should succeed (doctor.sh will still run as the first step in the pipeline).

### Scenario B — First-time, WSL2 (dev / staging test)

Two paths exist and must not be conflated:

**Path B1 — Dev-only (quick dev loop):**
No woosoo.env required. Uses dev defaults.
```
bash scripts/deployment/dev-docker-bootstrap.sh
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml build
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml up -d
```
dev-docker-bootstrap.sh refuses to run if /etc/woosoo/woosoo.env exists (Pi guard).

**Path B2 — Staging-parity (full deploy pipeline on WSL2):**
Exercises deploy-all.sh the same way the Pi would.
```
bash scripts/deployment/init-woosoo-env.sh           # creates ./woosoo.env
WOOSOO_ALLOW_NON_PI=true sudo -E bash scripts/deployment/deploy-all.sh
```
check.sh detects WSL2 and shows the WOOSOO_ALLOW_NON_PI=true form in the WSL2 notes section.

Currently, there is no doc that tells the operator which path to take. Operators arriving at production-docker.md see only the Pi flow.

### Scenario C — Re-deploy (code update on Pi)

Machine already configured. New commits on dev.
```
git -C woosoo-platform pull origin dev    # update platform repo (out-of-band, per deploy.sh comment)
sudo bash scripts/deployment/deploy-all.sh
```
deploy.sh pulls nexus + tablet-pwa automatically. check.sh is optional here — the operator already knows the machine works.

### Scenario D — Network switch (home ↔ restaurant)

Covered by `switch-network.sh`. check.sh does not know about this scenario and is irrelevant.
check.sh §1 checks git branch/sync — relevant if the operator hasn't pulled latest after a network switch.

### Scenario E — Recovery after failed deploy

```
sudo bash scripts/deployment/rollback-client.sh <backup-dir>
```
check.sh has no role here. deploy-all.sh prints the rollback command when any step fails.

---

## Verification (local gates, 2026-06-05)
- `bash -n` PASS on deploy.sh, deploy-all.sh, apply-woosoo-config.sh, dev-docker-bootstrap.sh,
  check.sh, doctor.sh.
- `retry()` exercised in isolation: first-try success, transient (fail×2 → succeed on 3rd),
  permanent failure (exhausts attempts → non-zero) all behave correctly.
- grep: no `setup-woosoo-env` in `production-docker.md`/`DEPLOYMENT_GUIDE.md`/`scripts`; no
  `check_tool docker|ss|curl` and no `rootCA` *check* left in check.sh; `DEPLOYMENT_GUIDE.md`
  §3.1 uses `init-woosoo-env.sh`.
- `chmod 600`/`700` insertions confirmed in both env-writing scripts.
- `compose.yaml` untouched → no compose regression. `docker compose config` not runnable on this
  Windows dev box (no docker in shell); deferred to the Pi gate.
- **Pi runtime verification (composer hydration on a fresh clone, tablet `--no-cache` freshness,
  doctor gate end-to-end, chmod under real deploy) = Bucket B follow-up — requires Pi hardware,
  cannot run from this host.** Consistent with INFRA-CASE-001/002 treatment.

## Review cycle (2026-06-05)
First pass returned **REJECTED** (independent review). Findings, all fixed:
- [P1] `WOOSOO_SKIP_DOCTOR` made the gate bypassable → flag removed entirely; `deploy.sh` always
  runs doctor (intentional double read-only run via the wrapper).
- [P2] `deploy.sh` summary sourced hardcoded `/etc/woosoo/woosoo.env` → now `source "$CONFIG_FILE"`.
- [P3] `deploy-all.sh` banner stale → now `check -> doctor -> backup -> deploy -> health`.
- [P2] case-file contradictions (stale "do NOT call check.sh"/"do NOT touch dev-docker-bootstrap")
  → marked superseded.
- [P2] false grep claim → scoped with `--exclude-dir=cases` (verified: 0 matches outside docs/cases).
- [Open Q] "every app repo" → clarified to the two deployable Docker app repos.
Re-verified: `bash -n` PASS ×6; `grep WOOSOO_SKIP_DOCTOR scripts/` → none; banner/summary/grep
assertions all pass. Also added (change 7): health grace+retry and a failure diagnosis bundle.

## Executioner Verdict
APPROVED — review blockers fixed and re-verified; local gates green; change set matches the
approved plan; risk contained (no compose/Dockerfile/architecture change; rollback stays manual).
Merge to `dev` after operator review. Pi runtime checks tracked as a Bucket B deploy-gate.

## Remaining Risks
- First-time-on-a-fresh-Pi: `woosoo-backup.sh` (step 2) now **safely no-ops** when the MySQL
  container isn't running yet (exits 0 with a clear message), so `deploy-all.sh` works uniformly
  on a fresh machine — no special first-run path needed. Later deploys back up normally.
- composer hydration runs inside a one-off `app` container; if the image build (step 3) failed the
  hydration can't run — but the deploy already aborts at build in that case. No masking.
- WSL2 path B2 still requires `sudo -E bash` because deploy-all.sh guards on EUID. If the operator runs without sudo they get an error. This is documented in check.sh WSL2 notes and in production-docker.md after Change 3. No code change needed.
