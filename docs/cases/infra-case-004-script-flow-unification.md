---
status: queued
last_reviewed: 2026-06-05
scope: woosoo-platform
---

# INFRA-CASE-004: Deployment Script Flow Unification

## Run State
- task_slug: infra-case-004-script-flow-unification
- tier: 2
- branch: agent/infra-004-script-flow-unification
- status: queued
- last_completed_agent: none
- next_agent: contrarian
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-05

## Handoff
- Phase in progress: —
- Done so far: investigation complete (this document)
- Exact next action: contrarian review → specialist:infra implements the four changes listed in Proposed Changes
- Working-tree state: no edits yet — this document is the only new file
- Risks / do-not-redo: do NOT re-create setup-woosoo-env.sh; do NOT add a new script; do NOT call check.sh from deploy-all.sh (it requires no sudo and is a user-run step only)

---

## Problem

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

## Proposed Changes

Four changes. No new scripts. No new logic.

### Change 1 — Remove true duplicates from check.sh (§3 tools)

Remove docker, ss, curl from §3 (they are already in doctor.sh, which runs as step 1 of deploy-all.sh).
Keep git and openssl (unique to check.sh).
Keep the "Docker Engine running" check (separate from tool availability — catches a common setup problem not covered by doctor.sh at the right time).

Current §3:
```
check_tool docker  "Install Docker Engine: ..."
check_tool git     "sudo apt install git"
check_tool openssl "sudo apt install openssl"
check_tool curl    "sudo apt install curl"
check_tool ss      "sudo apt install iproute2"
# Docker must be reachable (not just installed)
if command -v docker ...; docker info ...; fi
```
After:
```
check_tool git     "sudo apt install git"
check_tool openssl "sudo apt install openssl"
# Docker must be installed AND reachable
if ! command -v docker ...; then fail + fix; elif ! docker info ...; then fail + fix; else pass; fi
```

### Change 2 — Remove rootCA.crt existence check from check.sh §4

check.sh §4 checks `fullchain.pem`, `privkey.pem`, `rootCA.crt`. doctor.sh §Platform-root compose authority also checks `rootCA.crt`. Remove `rootCA.crt` from check.sh — it will still be caught by doctor.sh.

Keep `fullchain.pem` and `privkey.pem` in check.sh (unique — TLS cert presence + expiry check).

### Change 3 — Fix production-docker.md (three stale references)

1. Replace `setup-woosoo-env.sh` description (line 78) with `init-woosoo-env.sh`.
2. Replace `sudo bash scripts/deployment/setup-woosoo-env.sh` code block (line 98) with `bash scripts/deployment/init-woosoo-env.sh`.
3. Update "Config contract" line (line 92) to show both paths.
4. Add `check.sh` to the deploy scripts table.
5. Add a "Two dev paths on WSL2" note for Scenario B.

### Change 4 — Add infra-case-004 to QUEUE.md

Track this case in the active queue under Bucket B (deploy readiness infrastructure, non-gating).

---

## What NOT to Change

- Do NOT call check.sh from deploy-all.sh. check.sh is a user-run step; it requires no sudo and is informational. deploy-all.sh → doctor.sh is the pipeline gate.
- Do NOT merge check.sh into doctor.sh. They serve different moments (before-deploy vs inside-deploy-pipeline) and different privilege levels (no sudo vs sudo).
- Do NOT add DEPLOYMENT_GUIDE.md changes until production-docker.md is corrected first — that is the canonical doc.
- Do NOT touch dev-docker-bootstrap.sh. Its guards are correct and it is not related to this issue.
- Do NOT change QUEUE.md row counts, priorities, or order of other rows.

---

## Success Criterion

`production-docker.md` contains no reference to `setup-woosoo-env.sh`; check.sh contains no check that is a true duplicate of doctor.sh; a fresh read of production-docker.md gives an operator the correct first command for each of the two WSL2 paths and for the Pi path.

---

## Tier
2

## Branch
agent/infra-004-script-flow-unification

## Files to Change

| File | Repo | Change |
|---|---|---|
| `scripts/deployment/check.sh` | woosoo-platform | Remove docker/ss/curl from §3; remove rootCA.crt from §4 |
| `docs/deployment/production-docker.md` | woosoo-platform | Fix 3 stale refs + add check.sh row + add WSL2 two-path note |
| `state/QUEUE.md` | woosoo-platform | Add infra-case-004 row under Bucket B |

---

## Verification

1. `grep -r 'setup-woosoo-env' docs/ scripts/` returns no matches
2. `grep -n 'check_tool docker\|check_tool ss\|check_tool curl' scripts/deployment/check.sh` returns no matches
3. `grep -n 'rootCA' scripts/deployment/check.sh` returns no matches (removed from §4)
4. `bash -n scripts/deployment/check.sh` exits 0 (syntax clean)
5. `bash -n scripts/deployment/doctor.sh` exits 0 (syntax clean)
6. `cat docs/deployment/production-docker.md | grep 'setup-woosoo-env'` returns empty

---

## Executioner Verdict
(pending)

## Remaining Risks
- deploy-all.sh prints "Sequence: doctor -> backup -> deploy -> health" in its banner. If the operator has never run check.sh, they may hit doctor.sh failures for things check.sh would have caught and shown FIX commands for (missing TLS certs, missing app .env, expired certs). Mitigation: production-docker.md now explicitly states "run check.sh first."
- WSL2 path B2 still requires `sudo -E bash` because deploy-all.sh guards on EUID. If the operator runs without sudo they get an error. This is documented in check.sh WSL2 notes and in production-docker.md after Change 3. No code change needed.
