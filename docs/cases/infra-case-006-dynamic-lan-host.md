---
status: canonical
last_reviewed: 2026-06-06
scope: ecosystem
---

# CASE: infra-case-006-dynamic-lan-host

Unified Pi + WSL `PUBLIC_HOST` / LAN access via `scripts/lib/host-network.sh` and
`woosoo network` operator command.

## Run State

- task_slug: infra-case-006-dynamic-lan-host
- tier: 2
- branch: dev
- status: IN_PROGRESS
- last_completed_agent: specialist:infra
- next_agent: verifier
- active_runner: cursor
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-06

## Problem

WSL dev stack used hardcoded `192.168.100.7` for `PUBLIC_HOST`. LAN tablets could not
reach the stack without manual portproxy setup, and network changes silently broke
configured tablets if `.env` drifted.

## Success Criterion

`woosoo network` detects LAN IP, syncs `PUBLIC_HOST`, bridges WSL portproxy, and
verifies `https://<PUBLIC_HOST>:4443/build-info.json`. `woosoo dev` WARNs on drift
without auto-writing `.env`.

## Specialist Investigation & Implementation

### Investigation

- Confirmed `pipeline.sh` `_dev_health` fell back to `192.168.100.7`
- Confirmed `dev-docker-bootstrap.sh` hardcoded `192.168.100.7`
- Confirmed `docker/nginx/default.conf` map hardcoded three IPs
- Existing `scripts/windows/setup-wsl-lan-access.ps1` already dynamic for portproxy;
  only display strings were hardcoded
- Pi prod path isolated (`apply-woosoo-config.sh` WSL guard)

### Implementation

1. **`scripts/lib/host-network.sh`** — shared library:
   - `woosoo_detect_runtime` (vcgencmd for Pi)
   - `woosoo_detect_lan_ip` (WSL → `get-windows-lan-ip.ps1`)
   - `woosoo_check_public_host_drift` / `woosoo_check_tls_san` (warn only)
   - `woosoo_sync_public_host` (opt-in)
   - `woosoo_ensure_lan_access` (WSL delegates to `.ps1`)
   - `woosoo_verify_lan_reachability` / `woosoo_regen_dev_certs`

2. **`scripts/windows/get-windows-lan-ip.ps1`** — default-route RFC1918 IP

3. **`woosoo network`** target in `pipeline.sh` with `--dry-run` / `--regen-certs`

4. **`dev-preflight.sh` step 0 hook** — drift + TLS WARN; `WOOSOO_AUTO_SYNC=1` sync

5. **`_dev_health`** — localhost baseline + LAN WARN (no `192.168.100.7` fallback)

6. **`dev-docker-bootstrap.sh`** — detect LAN IP on first bootstrap write

7. **`docker/nginx/default.conf`** — regex IP catch-all in `map $canonical_host`

8. **`DEPLOYMENT_GUIDE.md` §4.1.1** — operator workflow

## Files Changed

- `scripts/lib/host-network.sh` (new)
- `scripts/windows/get-windows-lan-ip.ps1` (new)
- `scripts/windows/setup-wsl-lan-access.ps1`
- `scripts/windows/teardown-wsl-lan-access.ps1`
- `scripts/pipeline.sh`
- `scripts/deployment/dev-preflight.sh`
- `scripts/deployment/dev-docker-bootstrap.sh`
- `docker/nginx/default.conf`
- `docs/deployment/DEPLOYMENT_GUIDE.md`
- `docs/cases/infra-case-006-dynamic-lan-host.md` (this file)

## Verification

Pending Verifier gate:

```powershell
.\scripts\pre-merge-check.ps1 -App woosoo-platform
```

Operator smoke (WSL):

```bash
woosoo network --dry-run
woosoo network
curl -ksf "https://$(grep ^PUBLIC_HOST woosoo-nexus/.env | cut -d= -f2 | tr -d '\"'):4443/build-info.json"
```

## Contract impact

No — platform scripts and nginx dev config only. Pi prod path unchanged.

## Rollback

Revert merge; run `teardown-wsl-lan-access.ps1`; restore `woosoo-nexus/.env` from `.env.bak.*`
