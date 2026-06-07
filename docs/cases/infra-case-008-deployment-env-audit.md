---
status: canonical
last_reviewed: 2026-06-06
scope: ecosystem
---

# CASE: infra-case-008-deployment-env-audit

Read-only deployment audit remediation: unify operator config paths, document three POS/Reverb
config surfaces, and harden WSL/Pi preflight messaging so `.env` changes are applied with
`force-recreate` + `optimize:clear`.

## Run State

- task_slug: infra-case-008-deployment-env-audit
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

### Investigation

- Mapped three deployment entry paths: WSL `woosoo dev`, Pi `deploy-all.sh`, Pi
  `switch-network.sh` — each writes or reads different config surfaces.
- `switch-network.sh` read only `/etc/woosoo/woosoo.env` while `apply-woosoo-config.sh` and
  `doctor.sh` prefer `./woosoo.env` first — operator failure when secrets live in repo root.
- `init-woosoo-env.sh` did not seed `HOME_DB_POS_*` / `RESTO_DB_POS_*` required by network flip.
- `woosoo.env.example` defaulted resto POS to port 3308; resto uses **2121**.
- `.env.docker` overlay on queue/scheduler can drift from `.env` for `SESSION_DOMAIN` and
  `REVERB_BROADCAST_HOST`.
- `check.sh` false-FAIL on missing `APP_KEY` before first `woosoo dev`; WSL hints pointed at
  `deploy-all.sh` instead of `woosoo dev`.
- `dev-preflight` auto-fixed `.env` but did not consistently mandate `optimize:clear` after edits.

### Implementation

1. **`switch-network.sh`** — resolve `./woosoo.env` then `/etc/woosoo/woosoo.env` (match apply)
2. **`init-woosoo-env.sh`** — prompt/write `HOME_DB_POS_*` and `RESTO_DB_POS_*`
3. **`woosoo.env.example`** — document resto port 2121 vs home 3308
4. **`scripts/lib/host-network.sh`** — `woosoo_print_nexus_env_reload_steps()`; POS + PUBLIC_HOST
   sync print recreate + `optimize:clear`
5. **`dev-preflight.sh`** — use reload steps after POS fix; `.env.docker` drift WARN; summary
   reminder when auto-fixed
6. **`check.sh`** — WSL + `APP_ENV=local`: missing APP_KEY → WARN; WSL notes → `woosoo dev`
7. **`pipeline.sh`** — `_dev_bootstrap_needed` re-runs bootstrap when `DB_POS_HOST=host.docker.internal` on WSL
8. **`DEPLOYMENT_GUIDE.md`** — §3.6 network switch; §4.1.2 recreate+clear; §4.1.3 three surfaces;
   §3.2 HOME_/RESTO_ vars and resto port 2121

Bundled with infra-case-007 POS host fixes (bootstrap, preflight probe, §4.1.2 initial doc).

## Handoff

- Platform scripts/docs only; no app-repo changes
- Pi `PUBLIC_HOST` policy (apply hostname vs switch-network LAN IP) documented — not automated
- Nexus Tier 3 follow-up: queue/scheduler `system_settings` POS alignment (out of scope)

## Run State (checkpoint)

- last_completed_agent: specialist:infra
- next_agent: verifier
- active_runner: cursor
- status: IN_PROGRESS
- updated: 2026-06-06
