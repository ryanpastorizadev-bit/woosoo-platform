---
status: canonical
last_reviewed: 2026-06-06
scope: woosoo-platform
---

# CASE: infra-case-005-local-pipeline-runner

## Run State
- task_slug: infra-case-005-local-pipeline-runner
- tier: 2
- branch: dev
- status: IN_PROGRESS
- last_completed_agent: specialist:infra
- next_agent: verifier
- active_runner: cursor
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-06

## Specialist Investigation & Implementation

**Bug (WSL operator report):** `woosoo dev` failed with
`bash: /usr/local/bin/scripts/pipeline.sh: No such file or directory` when invoked via the
`/usr/local/bin/woosoo` symlink from `scripts/install.sh`.

**Root cause:** `run` used `dirname "${BASH_SOURCE[0]}"` without resolving symlinks. When `$0` is
`/usr/local/bin/woosoo`, `PLATFORM_ROOT` became `/usr/local/bin` instead of the platform repo.

**Fix:** Added `_resolve_platform_root()` in `run` — walks symlink chain with `readlink` before
`exec` to `scripts/pipeline.sh`. `./run` from repo root unchanged.

**Separate runtime issue (not fixed here):** `woosoo-nexus-reverb-1` unhealthy blocks nginx.
Operator should run `docker compose logs reverb --tail=80` and fix Reverb boot before re-running
`woosoo dev --no-pull --no-build --from-step 4`.

## Handoff
- Phase in progress: symlink fix landed; operator verify pending.
- Done so far: pipeline runner shipped (a756deb); symlink fix in `run` (uncommitted).
- Exact next action: operator `git pull` after commit; `woosoo dev --no-pull --no-build`; triage reverb if still unhealthy.
- Working-tree state: `run` modified; case file updated.
- Risks / do-not-redo: Do not duplicate `deploy-all.sh` or `dev-docker-bootstrap.sh`.

## Tier
2 — operator tooling / dev experience. No app code changes.

## Branch
agent/infra-005-local-pipeline-runner (off `dev`)

## Problem

No single command exists for a dev test deploy. After `dev-docker-bootstrap.sh` completes, the
operator must chain 4–6 manual `docker compose` / `artisan` commands from memory
(`DEPLOYMENT_GUIDE.md` §4.1). First-time runs require ~10-minute builds with no progress feedback.
The operator also had no way to install a globally-recognized command — everything required typing
the full `bash scripts/deployment/...` path from the platform root.

## Solution

Three new files + one install script:

| File | Purpose |
|---|---|
| `scripts/lib/pipeline-ui.sh` | Shared step engine: colored `[N/T]` steps, timers, skip/warn/fail |
| `scripts/pipeline.sh` | Pipeline runner: `dev`, `staging`, `pi`, `health`, `logs`, `check` targets |
| `run` | Root entry point: `exec bash scripts/pipeline.sh "$@"` |
| `scripts/install.sh` | Creates `/usr/local/bin/woosoo -> ./run`; works on WSL + Pi |

No existing scripts modified. `pipeline.sh` orchestrates; `deploy-all.sh` and
`dev-docker-bootstrap.sh` own their respective behaviors.

## dev target step sequence

```
[1/7] Pull repos          git pull all 3 repos; print SHA table
[2/7] Bootstrap .env      call dev-docker-bootstrap.sh OR smart-skip
[3/7] Build images        compose build with retry x3
[4/7] Start + migrate     up -d → key:generate if needed → migrate --force
[5/7] Warm caches         optimize:clear + config/route/view cache
[6/7] POS triggers        SKIP (v1) — pointer to RELEASE_RUNBOOK
[7/7] Health check        8 services + HTTP endpoints (no woosoo-health.sh / no root needed)
```

Smart-skip for step 2: skips bootstrap if `.env` has `APP_ENV=local`, `APP_KEY` set, and
`SESSION_DOMAIN` is empty.

## Fast-iteration flags

| Flag | Effect |
|---|---|
| `--no-pull` | Skip step 1 |
| `--no-build` | Skip step 3 |
| `--from-step N` | Start from step N |
| `--dry-run` | Print without executing |

## Success Criterion
`woosoo dev` runs end-to-end with exit 0; 8 services show running/healthy; admin URL reachable.
`woosoo dev --no-pull --no-build` completes in under 30s on an already-built stack.

## Files Changed
- `scripts/lib/pipeline-ui.sh` — created
- `scripts/pipeline.sh` — created
- `run` — created; symlink resolution fix (2026-06-06)
- `scripts/install.sh` — created
- `docs/cases/infra-case-005-local-pipeline-runner.md` — this file
- `docs/deployment/DEPLOYMENT_GUIDE.md` §4.1 — `./run dev` as primary dev path

## Verification
```bash
bash -n scripts/pipeline.sh scripts/lib/pipeline-ui.sh   # syntax check
bash scripts/install.sh                                    # installs woosoo command
woosoo dev                                                 # full dev deploy
woosoo dev --no-pull --no-build                           # fast path (already built)
woosoo health                                              # standalone health check
woosoo check                                               # preflight only
pld sync                                                   # Phase 0 post-push (2026-06-08)
bash scripts/install.sh && pld help                        # Phase 1 alias (2026-06-08)
```

## Palisade `pld` extension (2026-06-08)

Phase 0–1 shipped per [pld-cli-decision.md](../architecture/pld-cli-decision.md):

- **Phase 0:** `sync`, `rebuild`, `certs` targets; bootstrap no longer wipes `.env` for missing APP_KEY alone.
- **Phase 1:** `pld` + `woosoo` symlinks via `install.sh`; `.pld/manifest.yaml`; Windows `pld.ps1`/`pld.cmd`; `woosoo` deprecation notice in pipeline.

Canonical operator flow: `pld sync` from `~/projects/woosoo-platform` after Windows push.
