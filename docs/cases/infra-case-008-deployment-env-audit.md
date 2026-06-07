---
status: canonical
last_reviewed: 2026-06-07
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
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: cursor
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-07

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

Committed on `dev` as `9ec1502` (11 files):

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

## Verifier Result

**PASS** — 2026-06-07

- `bash -n` clean on all 7 shell scripts: `switch-network.sh`, `init-woosoo-env.sh`,
  `host-network.sh`, `dev-preflight.sh`, `check.sh`, `pipeline.sh`, `dev-docker-bootstrap.sh`
- All 8 implementation claims (3a–3h) cross-checked against code at specific line refs
- App-scoped `pre-merge-check` correctly N/A (platform scripts/docs only; no app-repo changes)

## Executioner Verdict

**APPROVED** — 2026-06-07

Independent line-level re-verification of all 8 claims; scope, correctness, and security
boundaries pass (chmod 600 secrets, password redaction in `init-woosoo-env.sh`, no auth
weakening). Docs honest — `PUBLIC_HOST` tension between `apply` and `switch-network` documented,
not over-claimed as automated.

## Handoff

- Platform scripts/docs only; no app-repo changes
- Pi `PUBLIC_HOST` policy (apply hostname vs switch-network LAN IP) documented — not automated
- Nexus Tier 3 follow-up: queue/scheduler `system_settings` POS alignment (out of scope)

### Non-blocking follow-ups (do not gate this case)

- Operator: populate `HOME_DB_POS_PASSWORD` / `RESTO_DB_POS_PASSWORD` in live `woosoo.env`
  before `switch-network.sh` on Pi (empty placeholders in example → `require_secret` abort)
- Pi ops carry-forward: clear `SESSION_DOMAIN` + set `WOOSOO_ENV=production` in live `.env`
  (nex-case-014); nexus Tier-3 queue/scheduler `system_settings` POS alignment

## Run State (checkpoint)

- last_completed_agent: executioner
- next_agent: done
- active_runner: cursor
- status: COMPLETE
- updated: 2026-06-07
