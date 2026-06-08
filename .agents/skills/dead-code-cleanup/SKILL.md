---
name: dead-code-cleanup
description: Pre-completion hygiene sweep — remove unused imports/components, temp files, debug logs, commented-out code, stale helpers, orphaned docs, abandoned scripts.
---

# Dead Code Cleanup

Final sub-step of the `code-simplifier` agent, immediately before the Verifier. Also loaded by
Specialists for incremental hygiene during implementation.

Check and remove:

- Unused imports and unused components introduced by this change.
- Temporary files and scratch files created during investigation.
- Duplicate files and abandoned scripts.
- Debug logs and `console.log` / `dd()` / `dump()` left in.
- Commented-out code blocks.
- Stale test helpers no longer referenced.
- Orphaned docs created and then obsoleted by this task.

**Rule:** if a file was created temporarily, remove it before completion. The working tree must
contain only the intended change.
