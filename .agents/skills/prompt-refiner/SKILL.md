---
name: prompt-refiner
description: Turn a rough idea into a clear, scoped, unambiguous prompt. Analyses the message, asks targeted questions (never assumes), then outputs a refined prompt with no gaps. Invoke with /prompt-refiner followed by your rough idea.
---

# Prompt Refiner

Turn a rough idea into a prompt that a reader can act on with zero guesswork.

**Never assume. Never fill gaps silently. Ask first, produce second.**

---

## Phase 1 — Silent analysis (do not output this)

Read the raw message. Score each dimension as CLEAR or UNCLEAR:

| Dimension | What to check |
|-----------|--------------|
| **Subject** | Exactly what thing is this about? (which app / file / feature / agent / endpoint / component) |
| **Action** | What specifically must happen? ("fix", "improve", "check", "make it work" are not actions — what is the precise change?) |
| **Trigger** | What caused this need? (bug observed, user complaint, new requirement, performance issue, design decision?) |
| **Scope — in** | What is explicitly included? |
| **Scope — out** | What is explicitly excluded? (what must not change?) |
| **Constraints** | Hard limits: do not break X, do not touch Y, must stay within Z |
| **Success** | How does the reader know the task is done? What is the testable end state? |
| **Output format** | What artifact is expected? (code change, new file, explanation, plan, doc, config value, command to run) |
| **Audience** | Who will act on the refined prompt? (Claude Code agent, Cursor, the operator, another human?) |

---

## Phase 2 — Ask (before producing anything)

Rules:
- Ask only about UNCLEAR dimensions.
- Maximum **4 questions per round** — pick the ones most likely to change the answer.
- Each question must be specific and answerable. Not open-ended.
- One thing per question — no compound "and/or" questions.
- Do not ask what you can confidently infer from context already given.
- Use **AskUserQuestion** (structured UI), not plain text questions.

If all dimensions are CLEAR, skip to Phase 3 immediately.

---

## Phase 3 — Refined prompt output

Only after receiving answers (or if Phase 2 was skipped):

Produce the refined prompt in this exact format, inside a code block so it is easy to copy:

```
CONTEXT
[1–3 sentences. What situation or problem led to this? Why does it matter? What is the current state?]

GOAL
[One sentence. Exactly what must be done — specific verb, specific target, specific result.]

SCOPE
  In:  [bullet list — what is included]
  Out: [bullet list — what is explicitly excluded; if nothing, write "none stated"]

CONSTRAINTS
[Bullet list — what must not break, change, or be assumed. Include any immutable rules relevant to this domain.]

SUCCESS CRITERIA
[Numbered list — specific, testable conditions. The reader should be able to verify each one without asking a follow-up question.]

EXPECTED OUTPUT
[Exactly what artifact or result is produced: file path, command, explanation format, doc section, PR description, etc.]

AUDIENCE
[Who runs this? e.g. "Claude Code Specialist (ranpo-backend)", "Cursor in Tier 1", "operator running a Pi command"]
```

---

## Quality check before outputting

Before finalising, verify:
- [ ] A reader with no prior context can act on this without asking a single question
- [ ] No dimension was filled by assumption — every value came from the user
- [ ] "Success Criteria" is testable, not subjective ("works correctly" is not a criterion)
- [ ] Scope-Out prevents the most obvious drift (over-engineering, touching wrong app, etc.)
- [ ] The goal contains a specific verb — not "fix", "improve", "check", "handle"

If any check fails, revise before outputting.
