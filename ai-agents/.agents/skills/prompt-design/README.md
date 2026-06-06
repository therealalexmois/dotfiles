# Prompt Design

## What it is

A staff-level prompt-engineering skill that builds a new prompt from a brief: it classifies the task, selects only justified modules, writes a self-contained final prompt, and supplies a testing checklist. It resists trend-chasing and over-engineering.

## When to use

- You need a prompt for a specific task and target model.
- You have input/output examples and want rules + a prompt extracted from them.
- You want a prompt structured for a class like extraction, gate/review, analysis, or brainstorming.

## How to use

1. Load `SKILL.md` (see the platform adapters).
2. State the GOAL in a sentence or two; answer the 1–3 follow-up questions.
3. Receive the recap, architecture decisions, final prompt, and testing checklist.

## Files

- `SKILL.md` — workflow, contracts, and boundaries.
- `references/module-catalog.md` — prompt classes, complexity levels, the full module catalog with inclusion conditions, platform adaptation notes, and per-class testing items.

## Notes

- Packaged from the flat `prompt-creator.md` (added frontmatter; lifted platform notes into the catalog reference).
- Pairs with `prompt-review` (critique/improve an existing prompt).
