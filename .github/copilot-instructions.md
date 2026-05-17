---
status: canonical
last_reviewed: 2026-05-17
scope: ecosystem
---

# Copilot Instructions — Woosoo Platform

This file is the ecosystem-wide guardrail. Each app has its own `.github/copilot-instructions.md` with detailed onboarding; defer to it for app-specific patterns. Those per-app files are **subordinate to `AGENTS.md`** and the 4-agent operating system below — where they diverge from the canonical ecosystem docs/contracts, the ecosystem docs win.

## Universal Rules

- Suggest minimal, idiomatic changes.
- Never add pricing, tax, or modifier logic to tablet code — the backend owns those.
- Never expose raw errors, stack traces, or exception messages to customer-facing UI.
- Respect existing Pinia store patterns; avoid duplicate fetches.
- Always settle loading flags in `finally`.
- Use existing service/composable layers instead of inlining API calls.
- Do not propose cross-app changes unless explicitly requested.
- Do not hardcode LAN IPs or API/Reverb hosts.

## Order Submission Contract

Tablet → Nexus payload is strictly `{ guest_count, package_id, items: [ { menu_id, quantity } ] }`. Do not add fields client-side.

## Print Bridge

The active production printing path is the Flutter `woosoo-print-bridge`. Do not suggest re-enabling Nexus's feature-flagged native print-event path without explicit approval.

## Agent Operating System & Resume (mandatory)

`AGENTS.md` defines the Lite 4-agent operating system (Contrarian → Specialist → Verifier →
Executioner) with triage tiers. Copilot is a runner of this system, not an exception to it.

If a task was started by another runner (e.g. Claude Code hit a rate limit) you must be able to
**resume it, not restart it**:

- Before any task, derive the task slug and check `docs/cases/<task-slug>.md`.
- If it is `status: IN_PROGRESS` or `BLOCKED`: do **not** restart and do **not** re-run
  completed agents. Read its `## Run State`, `## Handoff`, and completed phase sections; adopt
  the role named in `next_agent` by reading `.claude/agents/<role>.md` as your instruction set;
  continue the chain from there honoring the recorded tier and branch.
- When you finish a phase, checkpoint your output + a refreshed `## Run State` block to the case
  file before handing off. If you are cut off, write a `## Handoff` note and set
  `status: BLOCKED`.
- Full rules: `docs/RESUME_PROTOCOL.md`. The case file is authoritative over chat history.
- A task is complete only when the Executioner records `APPROVED`.

## Before Suggesting

Check the relevant app's `.agents.md` and the four 2026-05-14 audit docs for current contract truth.
