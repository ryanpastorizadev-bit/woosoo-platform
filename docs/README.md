---
status: canonical
last_reviewed: 2026-05-17
scope: ecosystem
---

# Woosoo Documentation Index

This is the canonical entry point for all Woosoo platform documentation. Only docs listed here with `status: canonical` are source of truth.

## Boot layer (read first)

- [AGENTS.md](../AGENTS.md) — AI operating rules for the platform
- [CLAUDE.md](../CLAUDE.md) — Claude Code–specific instructions
- [.github/copilot-instructions.md](../.github/copilot-instructions.md) — GitHub Copilot guardrails
- [AI_CONTEXT.md](AI_CONTEXT.md) — Business and architecture context

## Agent operating system (Lite, 4-agent)

The Lite 4-agent operating system (Contrarian → Specialist → Verifier → Executioner) is defined
in [AGENTS.md](../AGENTS.md). It is vendor-neutral and consumed by Claude Code, OpenAI Codex
CLI, and GitHub Copilot.

- Claude subagents: `.claude/agents/*.md` — agent definitions (single source of truth)
- Claude skills: `.claude/skills/*/SKILL.md` — task playbooks
- Codex per-app entrypoints (thin pointers to each app's `.agents.md`):
  [woosoo-nexus/AGENTS.md](../woosoo-nexus/AGENTS.md),
  [tablet-ordering-pwa/AGENTS.md](../tablet-ordering-pwa/AGENTS.md),
  [woosoo-print-bridge/AGENTS.md](../woosoo-print-bridge/AGENTS.md)
- [RESUME_PROTOCOL.md](RESUME_PROTOCOL.md) — **cross-runner resume & handoff** (rate-limit /
  interruption recovery; case file is the durable state)
- [HANDOVER_PROTOCOL.md](HANDOVER_PROTOCOL.md) — required handover before `APPROVED`
- `docs/cases/<task-slug>.md` — per-task case files, the durable resume point (template:
  `docs/cases/_TEMPLATE.md`)

## Contracts

Authoritative cross-app contracts. Implementation must be verified against actual code.

- [order-state.contract.md](../contracts/order-state.contract.md) — `confirmed → completed | voided | cancelled`
- [tablet-api.contract.md](../contracts/tablet-api.contract.md) — intent-only tablet payload
- [printer-relay.contract.md](../contracts/printer-relay.contract.md) — heartbeat & print idempotency
- [pos-db.contract.md](../contracts/pos-db.contract.md) — POS DB access safety
- [auth-session.contract.md](../contracts/auth-session.contract.md) — Sanctum/device auth boundaries

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
- `tablet-ordering-pwa/docs/` — Tablet detailed docs (see audit doc for canonical pointers)
- `woosoo-print-bridge/docs/` — Print Bridge detailed docs

## Strategic

- [WOOSOO_ROADMAP_REVIEW.md](WOOSOO_ROADMAP_REVIEW.md) — strategic roadmap, reconciled with the four 2026-05-14 audits (Audit reconciliation section is canonical; original analysis preserved)
- [WOOSOO_PRODUCTION_DOCKER_PLAN.md](WOOSOO_PRODUCTION_DOCKER_PLAN.md) — production Docker reference contract for Raspberry Pi deployment

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
  in `docs/cases/<slug>.md` (cross-runner resume helper; see RESUME_PROTOCOL.md)

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
