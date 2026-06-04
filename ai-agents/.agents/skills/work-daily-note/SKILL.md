---
name: work-daily-note
description: Normalize, clean, or structure a single daily note in a Markdown file while preserving frontmatter, links, block references, tags, embeds, and plugin-managed metadata. Use when tidying one daily note into clear sections without changing its meaning or inventing work. Pairs with the work-weekly-review skill — work-daily-note is the write side for one daily note; work-weekly-review reads daily notes read-only and consolidates them. Do not use for coding tasks, broad multi-file rewrites, weekly logs, or weekly review generation. Part of the work-* planning skill set (work-daily-log, work-weekly-review, future work-okr).
---

# Daily Note

Use this skill to clean and structure a single daily note (a Markdown file) without changing its meaning.

## Scope (operate on one daily note only)

- Operate on a **single daily note** — a `DAILY_SRC` file such as `1_Planning/Daily/<year>/<YYYY-MM-DD>.md`.
- **Never edit work-weekly-review files:** the weekly log `02_weekly_log.md`, anything under a weekly `_workspace/*`, `MATRIX`, `MAPPING`, quarterly notes, or templates. Those have their own structure; restructuring them here corrupts the work-weekly-review workflow.
- Do not do a broad multi-file pass. "Tidy all of this week's dailies" is not this skill — clean one note per invocation, or hand the week to work-weekly-review.

## Rules

- Preserve YAML frontmatter exactly unless explicitly asked to edit it. Do not add a second frontmatter block; do not touch `created` / `updated` / `tags`.
- Preserve Markdown links, wikilinks, block references, tags, and embeds.
- Preserve task lines verbatim, including `[ ]` / `[x]` state and `✅ DATE`. Do not mark unchecked items done.
- Do not remove ambiguous information; move it to a clear section if needed.
- Do not invent completed work, outcomes, metrics, or links.
- Do not modify templates or plugin-managed metadata unless explicitly requested.

## Preferred sections

When structure is requested, use these headings (named to match work-weekly-review day fields so consolidation maps cleanly):

```md
## Planned

## Done

## In progress

## Blockers

## Decisions

## Jira

## Artifacts

## Learn

## Research

## Attention

## Questions
```

- **Jira** — keys as `DWSAI-<n>` with their URL.
- **Artifacts** — one link per line as `<link> — <status>`, where status ∈ `draft / in-review / merged / shipped / abandoned / unknown`. Add the type when useful (MR / RFC / ADR / doc / dashboard / chat / incident / Jira issue).
- Omit a section if it has no content; do not pad with empty headings.

### How these map into work-weekly-review

- `Planned / Done / Blockers / Decisions / Jira / Artifacts / Learn / Research / Attention` → same-named work-weekly-review **day fields** (1:1).
- `In progress` → unchecked tasks; work-weekly-review carries these forward (Carry-forward), not as achievements.
- `Decisions` → work-weekly-review surfaces these in **1:1 talking points** / Staff signal — keep them, they are high-value for Staff evidence.
- `Questions` → work-weekly-review Back Matter.

## Pairing with work-weekly-review (ordering)

- work-daily-note is the **write side** for one daily note; work-weekly-review treats daily notes as **read-only** and consolidates them into the weekly log.
- Structure a daily note **before** `consolidate`. Once a day has been consolidated into `02_weekly_log.md`, do **not** re-edit that day's note here — it would desync the weekly log, break consolidate idempotency, and bump `updated` away from the real work day (weakening evidence). If a consolidated day must change, re-run work-weekly-review `consolidate` afterwards.
- Never edit a source daily note as part of a work-weekly-review flow — that is this skill's job, run separately and first.
