# Prompt Review

## What it is

A staff-level prompt-review skill that critiques an existing prompt and returns a strengthened version — without breaking its purpose. Every finding is tied to a verbatim quote and a concrete failure mechanism; the output carries a verdict (PASS / PARTIAL / FAIL / BLOCKED) and a changelog. It resists rationalization and trend-chasing.

## When to use

- You already have a prompt and want an evidence-based review.
- You want it strengthened while preserving its original intent and constraints.
- You want a verdict and a concrete change list, not a rewrite from scratch.

## How to use

1. Load `SKILL.md`.
2. Provide the prompt text plus purpose, audience/interface, target model, hard constraints, and (optionally) known issues and examples. Missing the essentials → you get a `BLOCKED` request for them.
3. Confirm the normalized `GOAL-N` / `CONSTRAINT-N` / `S-N` list, then receive the review, the improved prompt, and the changelog.

## Files

- `SKILL.md` — workflow, input/output contracts, source-of-truth priority, and boundaries.
- `references/review-method.md` — evidence rule, analysis axes A–L, problem taxonomy, severity levels, verdict rules, output structure, and the self-consistency check.

## Notes

- Packaged from the flat `prompt-improver.md` (added frontmatter; lifted the method into the reference).
- Pairs with `prompt-design` (build a new prompt from a brief).
