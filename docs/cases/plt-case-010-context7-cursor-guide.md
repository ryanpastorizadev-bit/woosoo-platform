---
status: canonical
last_reviewed: 2026-06-06
scope: ecosystem
---

# CASE: plt-case-010-context7-cursor-guide

Document how operators use the Context7 MCP plugin in Cursor for up-to-date library documentation.

## Run State

- task_slug: plt-case-010-context7-cursor-guide
- tier: 1
- branch: agent/plt-case-010-context7-cursor-guide
- status: APPROVED
- last_completed_agent: verifier
- next_agent: executioner
- active_runner: cursor
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-06

## Handoff

- Phase in progress:
- Done so far:
- Exact next action:
- Working-tree state (list edited files explicitly; cross-check with `git status`):
- Risks / do-not-redo:

## Tier

1

## Branch

agent/plt-case-010-context7-cursor-guide

## Contrarian Review

Tier 1 documentation task. No app code changes. Add canonical operator guide for Context7 plugin usage in Cursor; link from USAGE_GUIDE and docs/README.md.

## Specialist Investigation & Implementation

Investigated the installed Context7 MCP server (`plugin-context7-plugin-context7`): tools
`resolve-library-id` and `query-docs`, plus the `context7-mcp` skill and `/docs` command.

Created [docs/CONTEXT7_GUIDE.md](../CONTEXT7_GUIDE.md) with operator-facing guidance covering:

- What Context7 does and when to use / not use it
- How to trigger via natural language and `/docs`
- Agent two-step MCP workflow
- Woosoo stack examples (Nuxt, Laravel, Flutter)
- Security: no secrets in queries

Linked from [docs/USAGE_GUIDE.md](../USAGE_GUIDE.md) § Cursor Hybrid Workflow and
[docs/README.md](../README.md) Boot Layer index. Updated USAGE_GUIDE `last_reviewed` to
2026-06-06.

Verified Context7 MCP responds (resolve-library-id for Nuxt returned valid library IDs).

## Verifier

APPROVED. Tier 1 docs only — no app code changed. Reviewed:
- CONTEXT7_GUIDE.md: accurate two-step MCP workflow (resolve-library-id → query-docs), correct security warning (no secrets in queries), Woosoo stack examples valid.
- USAGE_GUIDE.md diff: date bump to 2026-06-06, Context7 section added under Cursor Hybrid Workflow — consistent with existing style.
- README.md diff: link entry correct, alphabetically placed in Boot Layer index.
- Cross-links between files resolve correctly.

## Executioner

(pending)
