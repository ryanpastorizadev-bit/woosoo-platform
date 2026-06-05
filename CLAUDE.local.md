# Woosoo Platform — Session State

**Updated:** 2026-05-31

> This file is a personal working scratchpad. It is **not** authoritative durable state —
> that lives in `docs/cases/<slug>.md`. See `docs/USAGE_GUIDE.md` for how to drive the system.

---

## Recent PRs / Branches

### Platform
| PR | Branch | What |
|---|---|---|
| [#27](https://github.com/ryanpastorizadev-bit/woosoo-platform/pull/27) | `agent/claude-only-consolidation` | merged to `dev` |
| [#28](https://github.com/ryanpastorizadev-bit/woosoo-platform/pull/28) | `chore/platform/tab-case-009-intake` | merged to `dev`; `tab-case-009` schedulable |

### Nexus
| PR | Branch | What |
|---|---|---|
| [#155](https://github.com/tech-artificer/woosoo-nexus/pull/155) | `chore/nexus/claude-only-agents-consistency` | de-Codex AGENTS.md + order-state fix + AI_ONBOARDING + inventory cleanup |

### Tablet
| PR | Branch | What |
|---|---|---|
| [#191](https://github.com/tech-artificer/tablet-ordering-pwa/pull/191) | `chore/tablet/claude-only-agents-consistency` | de-Codex AGENTS.md + AI_ONBOARDING |

---

## App work queue — next actions

### woosoo-nexus (highest priority)
| Case | Status | Next action |
|---|---|---|
| `nex-case-007` | ✅ APPROVED — on remote `dev` | Run `php artisan pos:setup-payment-trigger` on Pi after deploy |
| `nex-case-011` | code-merged (PR #163, 2026-06-04); Pi POS config pending (Bucket B) | Confirm `NEXUS_PRINT_EVENTS_ENABLED=true`; disable Krypton 3rd-party printer; verify BT-only print |
| `nex-case-005` | ✅ CLOSED — OBE (idempotency guard added inline via nex-case-011 PR #163) | — |

### tablet-ordering-pwa
| Case | Status | Next action |
|---|---|---|
| `tab-case-009` | queued | WS silent-death detector — `useBroadcasts.ts`; schedule chuya-frontend when ready |

### woosoo-print-bridge
| Item | Status | Next action |
|---|---|---|
| APK rebuild (`830fdfd`) | pending | Build + install on Pi tablet — `flutter build apk` then scp + install |

---

## Deploy readiness

| Gate | Status |
|---|---|
| nex-case-007 merged + `pos:setup-payment-trigger` run on Pi | ⏳ merged; Pi trigger pending |
| nex-case-011 code (PR #163) | ✅ merged 2026-06-04 |
| nex-case-005 | ✅ closed OBE (merged inline with #163) |
| nex-case-011 POS config (disable Krypton printer on Pi) | ⏳ Bucket B ops pending |
| Print-bridge APK rebuilt + installed | ⏳ pending |
| tab-case-009 WS silent-death fix | ⏳ queued post-stabilization |
| Restaurant smoke test (3 tables, pay 1, verify 1 tablet resets) | ⏳ after above |

---

## Content-accuracy follow-up (filed, not blocking)

- nexus [#156](https://github.com/tech-artificer/woosoo-nexus/issues/156) — `docs/AI_ONBOARDING.md` stale `relay-device/` paths + branch context
