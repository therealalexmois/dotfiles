# Prompt Design

## What it is

Build a reusable prompt from a brief:

1. Classify the task.
2. Select modules justified by the brief.
3. Write a self-contained prompt.
4. Provide a testing checklist.

Exclude techniques and complexity that the task does not need.

For an explicit review request, assess the supplied prompt without changing its purpose.
Tie findings to verbatim quotes and concrete failure mechanisms.
Return a verdict: `PASS`, `PARTIAL`, `FAIL`, or `BLOCKED`.
For a completed review, include an improved version and changelog.
For `BLOCKED`, return only the verdict, summary, and missing inputs.

## When to use

- You need a reusable prompt, system prompt, or production-model prompt for a specific task and target.
- You have input/output examples and want rules + a prompt extracted from them.
- You want a prompt structured for a class like extraction, gate/review, analysis, or brainstorming.

## How to use

1. Load `SKILL.md` (see the platform adapters).
2. State the GOAL in a sentence or two; answer the 1–3 follow-up questions.
3. Receive the recap, architecture decisions, final prompt, and testing checklist.

## Files

- `SKILL.md` — workflow, contracts, and boundaries.
- `references/module-catalog.md` — prompt classes, complexity levels, the full module catalog with inclusion conditions, platform adaptation notes, and per-class testing items.
- `references/review-mode.md` — review-mode workflow, input/output contracts, and source-of-truth priority.
- `references/review-method.md` — evidence rule, analysis axes A–L, problem taxonomy, severity levels, verdict rules, output structure, and the self-consistency check.

## Notes

- Packaged from the flat `prompt-creator.md` (added frontmatter; lifted platform notes into the catalog reference).
- The review mode was the separate `prompt-review` skill, packaged from the flat `prompt-improver.md`. Use `create-prompt` for one-off task instructions to capable models or coding agents.
