---
status: canonical
last_reviewed: 2026-05-18
scope: ecosystem
---

# Woosoo Documentation Index

This is the canonical entry point for all Woosoo platform documentation. Only docs listed here with `status: canonical` are source of truth.

## Boot Layer

- [AGENTS.md](../AGENTS.md) — AI operating rules for the platform (Claude Code entrypoint)
- [AI_CONTEXT.md](AI_CONTEXT.md) — Business and architecture context

## Agent operating system (Lite, 4-agent)

The Lite 4-agent operating system (Contrarian → Specialist → Verifier → Executioner) is defined
in [AGENTS.md](../AGENTS.md) and runs on Claude Code.

- [USAGE_GUIDE.md](USAGE_GUIDE.md) — **operator runbook**: how to drive the system, common-scenario protocol index, and the anti-degradation loop
- [AGENT_USAGE_GUIDE.md](AGENT_USAGE_GUIDE.md) — **technical reference**: 4-agent chain detail, skill routing, evidence standards, and hook trigger map
- Claude subagents: `.claude/agents/*.md` — agent definitions (single source of truth)
- Claude skills: `.claude/skills/*/SKILL.md` — task playbooks
- [RESUME_PROTOCOL.md](RESUME_PROTOCOL.md) — **resume & handoff** (rate-limit / interruption
  recovery; case file is the durable state)
- [HANDOVER_PROTOCOL.md](HANDOVER_PROTOCOL.md) — required handover before `APPROVED`
- [PROTOCOL.md](../PROTOCOL.md) — concise routing reference for the hook/state system
- `docs/cases/<task-slug>.md` — per-task case files, the durable resume point (template:
  `docs/cases/_TEMPLATE.md`)
- `hooks/` — the 9 installed hooks routed from the AGENTS.md trigger map:
  `work.md`, `status.md`, `intake.md`, `triage.md`, `execute.md`, `verify.md`,
  `review.md`, `unlock.md`, `handover.md`
- `state/` — machine-readable orchestration state: `WORK.md` (active-case convenience cache,
  not authoritative), `QUEUE.md` (priority task queue), `DEPS.md` (cross-app dependency
  ledger), `DONE.md` (append-only verified-completion log)

## Contracts

Authoritative cross-app contracts. Implementation must be verified against actual code.

- [order-state.contract.md](../contracts/order-state.contract.md) — `OrderStatus` enum + transitions (mirrors `woosoo-nexus/app/Enums/OrderStatus.php`)
- [tablet-api.contract.md](../contracts/tablet-api.contract.md) — intent-only tablet payload
- [printer-relay.contract.md](../contracts/printer-relay.contract.md) — heartbeat & print idempotency
- [pos-db.contract.md](../contracts/pos-db.contract.md) — POS DB access safety
- [auth-session.contract.md](../contracts/auth-session.contract.md) — Sanctum/device auth boundaries

## Business Requirements Documents

- [Woosoo Platform BRD Supplement](business/WOOSOO_PLATFORM_BRD_SUPPLEMENT.md) — Platform role as 4th system component (orchestration, contracts, AI agent OS, governance); complements the Nexus BRD
- [Woosoo Origin Specification (Archived)](business/WOOSOO_ORIGIN_SPECIFICATION.md) — Original May 20XX signed specification for the Woosoo KBBQ table ordering system project; historical reference only (KDS component later replaced by Woosoo Print Bridge)
- [Specification Delta & Cost Analysis](business/WOOSOO_SPEC_DELTA.md) — Feature-by-feature comparison of origin spec vs. current system; project cost breakdown (legacy ₱350k / current est. ₱875k / delta ₱525k)

## Canonical audit documents (2026-05-14)

These four documents are the authoritative system-state references. Restructured against a unified template; read the relevant one for any non-trivial task.

- [Ecosystem Engineering Review](WOOSOO_ECOSYSTEM_ENGINEERING_REVIEW_2026-05-14.md) — cross-app system review
- [Nexus Stabilization & Hardening Audit](../woosoo-nexus/docs/WOOSOO_NEXUS_STABILIZATION_AND_HARDENING_AUDIT_2026-05-14.md) — Laravel backend
- [Tablet PWA Production Stability Audit](../tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md) — Nuxt tablet client
- [Print Bridge Production Reliability Audit](../woosoo-print-bridge/docs/WOOSOO_PRINT_BRIDGE_PRODUCTION_RELIABILITY_AUDIT_2026-05-14.md) — Flutter print relay

## Per-app scope rules

- [woosoo-nexus/.agents.md](../woosoo-nexus/.agents.md)
- [tablet-ordering-pwa/.agents.md](../tablet-ordering-pwa/.agents.md)
- [woosoo-print-bridge/.agents.md](../woosoo-print-bridge/.agents.md)

## Per-app documentation indexes

- [woosoo-nexus/docs/INDEX.md](../woosoo-nexus/docs/INDEX.md) — Nexus-side detailed docs
- [woosoo-nexus/docs/software-development/](../woosoo-nexus/docs/software-development/) — software development documentation package: process, product, and user documentation
- `tablet-ordering-pwa/docs/` — Tablet detailed docs (see audit doc for canonical pointers)
- `woosoo-print-bridge/docs/` — Print Bridge detailed docs

## Deployment

Docker orchestration authority is the **platform repo root** (3-repo sibling model).

- [deployment/DEPLOYMENT_GUIDE.md](deployment/DEPLOYMENT_GUIDE.md) — **operator guide**: Pi vs dev path, first-time setup, update flow, recovery, rollback, troubleshooting
- [deployment/production-docker.md](deployment/production-docker.md) — canonical platform-root Docker deployment, topology, deploy scripts, verification + transition state
- `deployment/examples/woosoo.env.example` — `/etc/woosoo/woosoo.env` template (incl. `WOOSOO_PLATFORM_PATH`, per-repo deploy branches)
- `scripts/deployment/README.md` — per-script migration status

## Strategic

- [WOOSOO_ROADMAP_REVIEW.md](WOOSOO_ROADMAP_REVIEW.md) — strategic roadmap, reconciled with the four 2026-05-14 audits (Audit reconciliation section is canonical; original analysis preserved)

## Audit trail

- [docs/audits/DOCS_AUDIT_2026-05-14.md](audits/DOCS_AUDIT_2026-05-14.md) — full inventory and classification of all markdown files

## Archives

Documents in `docs/archive/` and per-app `docs/archive/` directories are historical only. Each archived file has a `superseded_by` pointer to the canonical replacement. Do not treat archived docs as source of truth.

- `docs/archive/2026-05/` — platform-level archives
- `woosoo-nexus/docs/archive/2026-05/` — Nexus archives
- `tablet-ordering-pwa/docs/archive/2026-05/` — Tablet archives
- `woosoo-print-bridge/docs/archive/2026-05/` — Print Bridge archives

## Tooling

- `scripts/pre-merge-check.sh` — Bash pre-merge validation
- `scripts/pre-merge-check.ps1` — PowerShell wrapper for Windows
- `scripts/case-status.sh` / `scripts/case-status.ps1` — print/update the `## Run State` block
  in `docs/cases/<slug>.md` (resume helper; see RESUME_PROTOCOL.md)

## Frontmatter convention

Every canonical doc starts with:

```yaml
---
status: canonical
last_reviewed: YYYY-MM-DD
scope: <ecosystem | app-name>
---
```

Archived docs use:

```yaml
---
status: archived
archived_reason: <one sentence>
superseded_by: <path to canonical replacement>
archived_on: YYYY-MM-DD
---
```
