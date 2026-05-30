---
status: canonical
last_reviewed: 2026-05-27
scope: woosoo-nexus
---

# CASE: public-user-manual-product-spec-look

## Run State
- task_slug: public-user-manual-product-spec-look
- tier: 1
- branch: n/a
- status: IN_PROGRESS
- last_completed_agent: specialist:dazai-docs
- next_agent: verifier
- active_runner: codex
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-27

## Handoff
- Phase in progress: verifier
- Done so far: Restyled the public `/user-manual` Blade view into the product-spec visual system with fixed desktop rail, mobile navigation, editorial typography, metadata strip, restrained panels, and formal inline figures.
- Exact next action: Run Blade, route, asset, sensitive-text, and visual viewport checks.
- Working-tree state (list edited files explicitly; cross-check with `git status`): `woosoo-nexus/resources/views/manual/user.blade.php`, `docs/cases/public-user-manual-product-spec-look.md`.
- Risks / do-not-redo: Do not include unrelated root certificate files or app-code changes. Do not publish private network values, credentials, database details, deployment commands, or troubleshooting internals.

## Tier
1

## Branch
n/a

## Problem

The public user manual had the correct content and safe screenshots, but its page styling still felt like a general help page rather than the product-spec aesthetic requested by the user.

## Contrarian Review

The change should be visual and documentation-only. It must not touch routes, APIs, tablet behavior, deployment behavior, authenticated manuals, or screenshot safety boundaries.

## Investigation

- The public manual is rendered from `woosoo-nexus/resources/views/manual/user.blade.php`.
- The existing screenshot assets already include redacted Nexus and tablet images under `woosoo-nexus/public/docs/user-manual/screenshots/`.
- The pasted reference uses a fixed document rail, warm dark canvas, amber labels, large editorial heading, compact metadata row, thin dividers, and restrained document panels.

## Root Cause

The prior manual structure used a top-nav and card-heavy help-guide layout. It did not match the desired internal product-spec look and feel.

## Proposed Fix

Restyle the public user manual as a single-page product-spec document while preserving the existing safe content and inline screenshots.

## Files Changed

- `woosoo-nexus/resources/views/manual/user.blade.php`
- `docs/cases/public-user-manual-product-spec-look.md`

## Verification

Pending verifier pass.

## Executioner Verdict

Pending.

## Remaining Risks

Pending verifier pass.
