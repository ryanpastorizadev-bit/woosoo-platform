# Woosoo Platform

Governance, deployment orchestration, and cross-app contracts for the **Woosoo** restaurant
operations ecosystem — a local-first, multi-app system for dine-in ordering, kitchen printing,
and manager operations.

This repository is **not** a customer-facing app. It is the operating layer that holds the
sibling app repos together: Docker Compose, deployment scripts, AI agent workflow, and canonical
documentation.

---

## Ecosystem components

| Repo | Role | Status |
| --- | --- | --- |
| **woosoo-platform** (this repo) | Docker, contracts, deploy scripts, docs, agent OS | Production |
| [**woosoo-nexus**](https://github.com/tech-artificer/woosoo-nexus) | Laravel API + manager admin + Reverb + POS | Production |
| [**tablet-ordering-pwa**](https://github.com/tech-artificer/tablet-ordering-pwa) | Nuxt 3 customer tablet PWA | Production |
| [**woosoo-print-bridge**](https://github.com/tech-artificer/woosoo-print-bridge) | Flutter Android kitchen print relay | Production |
| [**woosoo-portal**](https://github.com/ryanpastorizadev-bit/woosoo-portal) | Owner cloud reporting (Laravel/Inertia UI prototype) | Prototype |

Full architecture, flows, and delivery status:
[**docs/WOOSOO_ECOSYSTEM_OVERVIEW.md**](docs/WOOSOO_ECOSYSTEM_OVERVIEW.md)

---

## Workspace setup

Open the multi-root workspace so platform docs and sibling apps stay in scope:

`woosoo-platform.code-workspace`

Sibling app directories (`woosoo-nexus/`, `tablet-ordering-pwa/`, `woosoo-print-bridge/`) are
pulled beside this repo by the deploy scripts — not submodules of this repo.

---

## Quick start (operators)

1. Clone this repo and sibling apps into the same parent directory.
2. Copy env templates from [`docs/deployment/examples/woosoo.env.example`](docs/deployment/examples/woosoo.env.example).
3. Run deployment from **this repo root** — see
   [`docs/deployment/DEPLOYMENT_GUIDE.md`](docs/deployment/DEPLOYMENT_GUIDE.md).

```powershell
# Example: health check after deploy
.\scripts\deployment\woosoo-health.sh
```

---

## Documentation

Canonical index: [**docs/README.md**](docs/README.md)

| Entry | Use when |
| --- | --- |
| [AGENTS.md](AGENTS.md) | AI agent operating rules |
| [docs/AI_CONTEXT.md](docs/AI_CONTEXT.md) | Business/architecture context for agents |
| [contracts/](contracts/) | Cross-app API/event contracts |
| [docs/cases/](docs/cases/) | Per-task durable state / resume |

---

## Validation

```powershell
.\scripts\pre-merge-check.ps1 -App woosoo-nexus
.\scripts\pre-merge-check.ps1 -App tablet-ordering-pwa
.\scripts\pre-merge-check.ps1 -App woosoo-print-bridge
```

---

## Key rules

- **One app per branch/commit** unless explicitly integration-scoped.
- **Backend owns truth** — tablet sends order intent only.
- **Print Bridge** is the production print executor.
- **Manager admin** lives inside `woosoo-nexus`, not a separate deployable app.
- **Cloud owner portal** (`woosoo-portal`) is a separate repo; Nexus→portal sync is planned, not shipped.
