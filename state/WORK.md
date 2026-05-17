---
status: canonical
scope: ecosystem
---

# Active Work State

<!-- Consult this file only after the docs/cases resume check. -->
<!-- It is a cache; docs/cases/<task-slug>.md is authoritative. -->
<!-- Rewrite the fields below when task state changes.          -->
<!-- Last updated: 2026-05-17 by specialist:dazai-docs          -->

---

## Current Task

```
task_id:      PLT-CASE-002
status:       needs_verification
tier:         2
app:          woosoo-platform
specialist:   dazai-docs
description:  Complete canonical hook surface.
case_file:    docs/cases/plt-case-002-hook-surface-completion.md
```

## Next Action

```
VERIFY: rerun stale-phrase scans, hook existence checks, chain-order checks, and git status scope review.
Then hand off to: verifier
```

## Blocking Dependencies

```
none
```

## Last Agent

```
role:         specialist:dazai-docs
date:         2026-05-17
left_off:     specialist:dazai-docs completed canonical hook surface implementation; verification is next.
files_open:   docs/cases/plt-case-002-hook-surface-completion.md, AGENTS.md, state/WORK.md, hooks/status.md, hooks/verify.md
```

## On Completion of Next Task

```
→ set:  next_agent: verifier in the case file
→ then: continue Verifier → Executioner from the case file
→ then: pull next from state/QUEUE.md
```

---
<!--
STATUS VALUES:
  queued              Ready, not started
  in_progress         Work underway
  blocked             Waiting on a dependency (see state/DEPS.md)
  needs_verification  Implementation done, not yet verified
  verified            Tested and confirmed
  done                Handover complete — pull next task

TIER VALUES: 1 (Trivial) | 2 (Standard) | 3 (High-risk)

SPECIALIST VALUES: ranpo-backend | chuya-frontend | relay-ops | dazai-docs | infra

CASE FILE PATH: docs/cases/<task-slug>.md
  Recommended task slug prefix: nex-case | tab-case | prn-case | plt-case
  The case file remains the authoritative durable resume point.
-->
