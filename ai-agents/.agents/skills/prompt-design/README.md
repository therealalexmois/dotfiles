# Prompt Design

## What it is

A staff-level prompt-engineering skill that builds a new prompt from a brief: it classifies the task, selects only justified modules, writes a self-contained final prompt, and supplies a testing checklist. It resists trend-chasing and over-engineering.

On explicit request it switches to a review mode: it critiques a supplied prompt with findings tied to verbatim quotes and concrete failure mechanisms, returns a verdict (PASS / PARTIAL / FAIL / BLOCKED), an improved version and a changelog, without breaking the prompt's purpose.

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
