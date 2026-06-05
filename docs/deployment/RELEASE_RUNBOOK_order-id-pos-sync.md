---
status: canonical
last_reviewed: 2026-06-02
scope: ecosystem
---

# Release Runbook — Order-ID Canonicalization + POS Live-Sync (Bucket B rollout)

**Release contents (now on `main` across all repos, 2026-06-02):**
NEX-CASE-013 (canonical `order_id` channels, broadcast layer, POS order-detail outbox/consumer,
`order.details.updated`) + PR #160 (refresh POS values before broadcast) · TAB-CASE-010 (tablet
canonical `order_id` + `order.details.updated` handler + `preparing`→`in_progress`) · TAB-CASE-009
(WS silent-death watchdog) · INFRA-CASE-003 (`npm ci` WiFi hardening).

This runbook is the **Bucket B (deploy-readiness) sequence** for the restaurant Pi. It wraps the
generic deploy in `docs/deployment/DEPLOYMENT_GUIDE.md`; do not duplicate that — follow the steps
below in order. Pi: static IP `192.168.1.31`, root `/opt/woosoo/woosoo-platform`. Run on the Pi.

> Each step is independently verifiable. **Stop and do not proceed** if a step's verification fails.

---

## Step 0 — Pre-flight
- Confirm the Pi is on `main` for all app repos and reachable: `cd /opt/woosoo/woosoo-platform && git -C . status`.
- `deploy-all.sh` runs `doctor.sh` (preflight) + `woosoo-backup.sh` (DB backup) automatically — no separate action.

## Step 1 — Core deploy (pulls `main`, builds, health-checks)
```bash
# deploy.sh defaults NEXUS_BRANCH and TABLET_BRANCH to `dev` — must override for a main release
export WOOSOO_DEPLOY_BRANCH=main
echo "Deploy branch: $WOOSOO_DEPLOY_BRANCH"   # verify before proceeding
sudo -E bash scripts/deployment/deploy-all.sh
```
`-E` passes the exported variable into the sudo environment.
Runs doctor → backup → deploy (pull repos, apply config, build + `up`, warm cache) → health.
**Verify:** the wrapper exits `0` and `woosoo-health.sh` reports the stack healthy.
**Rollback if it fails:** `sudo bash scripts/deployment/rollback-client.sh <backup-dir>` (the wrapper prints the exact snapshot path on failure).

## Step 2 — POS triggers + schedulers (NEX-CASE-007 + NEX-CASE-013)
Install/refresh the POS-local outbox tables + triggers (payment, session-close, **and the new
order-detail trigger from 013**), then confirm the consumers are scheduled. Run **inside the nexus
app container** (service name is `app` per `compose.yaml`):
```bash
docker compose exec app php artisan pos:setup-payment-trigger
docker compose exec app php artisan schedule:list | grep -E "pos:consume-payment-status-events|pos:consume-order-detail-events"
```
**Verify:** the command reports the outbox tables + triggers created; `schedule:list` shows **both**
`pos:consume-payment-status-events` (every 5s) and `pos:consume-order-detail-events` (every 5s).
Idempotent — safe to re-run.

## Step 3 — POS printer config — BT-only (NEX-CASE-011)
Root cause (docs/cases/nex-case-011): the 3rd-party POS prints autonomously from `create_ordered_menu`
while the Nexus BT path also prints → duplicate. Intended behavior is **BT thermal only**.

**Code gate (cleared):** PR #163 (`fix/nex-011-duplicate-print`) merged to dev 2026-06-04 — removes
`PrintOrder::dispatch()` from all `markPrinted` ack paths and adds `is_printed` idempotency guard.
Confirm this commit is on the deployed branch (Step 1 pulls it when deploying from dev or a branch that includes it).

- **Disable the 3rd-party POS printer (or set its no-print flag) in the Krypton/POS configuration.**
  This is a POS-side/vendor setting — not Nexus code. Confirm `NEXUS_PRINT_EVENTS_ENABLED=true` so the
  BT path (print bridge) keeps printing.
**Verify:** in Step 5, exactly one ticket prints (BT), POS receives the order but prints nothing.

## Step 4 — Print-bridge APK (PRN-REBUILD-APK)
Rebuild the Flutter release APK from current `main` and install on the Pi-connected tablet:
```bash
# on a build host with Flutter:
cd woosoo-print-bridge && flutter build apk --release
# then SCP + install on the Pi tablet (adb install -r <apk>)
```
**Verify:** the bridge connects (heartbeat green), prints a test ticket on the BT printer.

## Step 5 — Acceptance smoke test (the go-live gate)
On 3 tables with real tablets + the POS:
1. **Per-order terminal scoping:** place orders on 3 tablets; pay/close **one** order on the POS →
   **only that one tablet** returns to the welcome screen; the other two stay in-session.
2. **BT-only printing:** that order prints **exactly one** ticket, on the **BT** printer (no POS print).
3. **Live POS detail sync (new):** on an active order, **add a guest / change items on the POS** →
   that tablet's **guest count + total update live** (no refresh, no client recompute) via
   `order.details.updated`.
4. **WS resilience (TAB-CASE-009):** leave a tablet idle; confirm it recovers from a dropped socket
   (watchdog) rather than going stale.

**All four pass → release accepted.** Any failure → diagnose before opening to customers; rollback via Step 1.

---

## References
- Generic deploy / env / rollback: `docs/deployment/DEPLOYMENT_GUIDE.md`
- Wrapper + scripts: `scripts/deployment/{deploy-all,doctor,woosoo-backup,deploy,woosoo-health,rollback-client}.sh`
- Cases: `docs/cases/{nex-case-007,nex-case-011,nex-case-013,tab-case-010,tab-case-009,infra-case-001,infra-case-002,prn-rebuild-apk-scp-pi}.md`
- Event contract: `contracts/websocket-events.contract.md` (`order.details.updated`, channels, scalability for ≤20 tablets)
