---
status: under-review
last_reviewed: 2026-06-08
scope: woosoo-platform
---

# Palisade CLI (`pld`) — scaffold spec

> **Design only.** No Go module is committed until Phase 2 is approved.
> Decision record: [docs/architecture/pld-cli-decision.md](../../docs/architecture/pld-cli-decision.md).

## Purpose

Cross-platform entrypoint for Woosoo/Palisade platform orchestration. Phase 2 ships a thin
binary that delegates to existing Bash; Phase 3 ports hot-path recipes natively.

## Layout (proposed)

```
tools/pld/
  README.md           # this file
  go.mod
  cmd/pld/main.go     # Cobra root
  internal/
    root/             # platform root resolution (PLD_ROOT, walk, symlink-safe)
    manifest/         # parse .pld/manifest.yaml
    delegate/         # exec bash scripts/pipeline.sh with mapped args
    recipes/          # Phase 3: sync, net certs, build web
    output/           # human + --json formatters
  .pld/
    manifest.yaml     # at platform root, not under tools/pld
```

## Manifest sketch (platform root: `.pld/manifest.yaml`)

```yaml
version: 1
root: .
brand: palisade
modules:
  nexus:
    path: woosoo-nexus
    default_branch: dev
  tablet:
    path: tablet-ordering-pwa
    default_branch: dev
profiles:
  dev:
    compose_file: compose.yaml
    env_file: woosoo-nexus/.env
  pi:
    config_file: woosoo.env
recipes:
  sync:
    backend: bash
    script: scripts/pipeline.sh
    args: ["sync"]
  sync_full:
    backend: bash
    script: scripts/pipeline.sh
    args: ["dev"]
```

## Command tree (Cobra)

```
pld
├── sync [--full] [--no-pull] [--no-build] [--dry-run]
├── dev          → alias sync --full (deprecated path: woosoo dev)
├── net
│   ├── sync     → pipeline.sh network
│   └── certs    → pipeline.sh network --regen-certs
├── stack
│   ├── up | down | restart | ps | logs
├── build
│   ├── web [--force]
│   └── php
├── watch
│   ├── doctor   → pipeline.sh check
│   ├── health   → pipeline.sh health
│   └── preflight → dev-preflight.sh
├── repo
│   └── pull [module]
├── run exec <service> -- <cmd...>
├── staging | pi | logs   → delegate Phase 2
├── install | version
└── help
```

## Root resolution (must match `run`)

1. If `PLD_ROOT` set and contains `compose.yaml`, use it.
2. Walk parents from CWD for `.pld/manifest.yaml` or pair (`compose.yaml` + `run`).
3. If binary knows its install path, optional embedded default (installer sets registry).

## Phase 2 minimum viable binary

- [ ] `pld sync` → `bash "$ROOT/scripts/pipeline.sh" sync` (after Bash target exists)
- [ ] `pld net certs` → `bash "$ROOT/scripts/pipeline.sh" network --regen-certs`
- [ ] `pld watch doctor` → `bash "$ROOT/scripts/pipeline.sh" check`
- [ ] `pld version` → embed git SHA at build time
- [ ] `pld --json watch health` → parse health script output or reimplement checks

## Build / release

```bash
# Local dev
cd tools/pld && go build -o pld ./cmd/pld

# Matrix (CI)
GOOS=linux GOARCH=amd64 go build -o dist/pld-linux-amd64 ./cmd/pld
GOOS=windows GOARCH=amd64 go build -o dist/pld-windows-amd64.exe ./cmd/pld
GOOS=darwin GOARCH=arm64 go build -o dist/pld-darwin-arm64 ./cmd/pld
```

## Dependencies

- Go 1.22+
- Suggested: `github.com/spf13/cobra` for CLI; stdlib `os/exec` for delegation
- No Docker SDK in v1 — shell out to `docker compose` like Bash today

## Non-goals (Phase 2)

- Rewriting `deploy-all.sh` or Pi systemd integration
- Embedding Docker or Git
- Replacing PowerShell LAN scripts — `pld net sync` calls them on Windows via WSL or documented elevation path
