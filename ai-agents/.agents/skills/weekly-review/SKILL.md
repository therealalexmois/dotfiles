---
name: weekly-review
description: Manage a weekly planning-and-review workflow inside an Obsidian vault for a Staff/Staff-candidate engineer. Use whenever the user wants to start a work week, keep a weekly log, generate a daily status message for their team, consolidate daily notes into a weekly log, draft a weekly review, check whether quarterly goals/OKR are attainable, collect Staff promotion evidence, or carry unfinished work forward. Trigger on phrases like "начать неделю", "weekly review", "weekly log", "подведи итоги недели", "daily status", "консолидируй daily", "собери evidence", "start week", or when the user references a weekly workspace folder, a `YYYY-Www` week, or quarterly goal attainability. This skill is markdown-only, evidence-first, and never invents impact, metrics, or Staff coverage.
---

# Weekly Review

A markdown-only workflow skill for an Obsidian vault. It helps a Staff/Staff-candidate engineer run a weekly loop: start a week, keep one weekly log, produce a daily team status, consolidate daily notes, draft a weekly review, check quarterly goal attainability, and collect Staff promotion evidence — without inventing anything.

This skill writes Markdown only. It does not run code, call APIs (Jira/GitLab/etc.), spawn subagents, or rewrite the vault in bulk. Keep every action minimal (KISS) and build nothing ahead of need (YAGNI).

## Core principles (always)

- **Evidence-first.** Conclusions come only from notes/links/artifacts actually read. Never invent impact, metrics, outcomes, scope, feedback, or Staff coverage. If something is missing, write `TBD` / `missing data` — do not reconstruct facts.
- **Activity ≠ output ≠ outcome.** Separate them explicitly. A finished task is activity; a shipped/merged result with effect is outcome. Only outcomes with evidence back achievement claims.
- **Product scale ≠ personal influence.** A big product does not equal the user's impact; state what the user personally did and how it affected others.
- **Do not edit source daily notes.** Treat `1_Planning/Daily/**` as read-only raw source. Consolidation reads them and writes elsewhere.
- **No silent destructive action.** Never delete or bulk-move files without an explicit, confirmed request (see `consolidate-delete`).
- **Stay in lane.** Vault restructuring, Inbox setup, `AGENTS.md` edits, and historical migration are out of scope. If asked, decline the bulk action and offer per-week `consolidate` instead.
- **Output in Russian**, concise business style. No motivational framing. Mobile-friendly formatting (short lines, light structure).
- **Respect existing Obsidian frontmatter.** A note has YAML frontmatter only at the very top. Never add a second frontmatter block; never duplicate `created`, `updated`, `tags`, `template-type`, `template-version`.

## Conventions / Paths

These are named conventions, not hardcoded magic. If the vault layout changes, update them here only.

| Name | Path | Role |
|---|---|---|
| `DAILY_SRC` | `1_Planning/Daily/<year>/<YYYY-MM-DD>.md` | Raw daily notes. Read-only source. |
| `WORKSPACE` | `2_Reports/Weekly/<year>/_workspace/<YYYY-Www>/` | Weekly working folder (4 files below). |
| `WEEKLY_OUT` | `2_Reports/Weekly/<year>/<YYYY-Www>.md` | Final weekly review (one per week). |
| `QUARTERLY` | `2_Reports/Quarterly/<year>/<year>-Qn.md` | Quarterly goals / OKR (source of truth for attainability). |
| `MATRIX` | `4_Areas/Career/Staff Competency Matrix.md` | Staff 17 competency source of truth. |
| `MAPPING` | `2_Reports/Promotion/<year>/Staff Matrix Mapping.md` | Weekly achievement → competency → evidence log. |

Workspace files: `01_goals.md`, `02_weekly_log.md`, `03_backlog.md`. Skeletons are in `assets/`.

**Week id.** Use the ISO week (`YYYY-Www`, e.g. `2026-W22`). The week runs Monday–Sunday, but the **working week is Monday–Friday**. If the user gives a date, derive its ISO week. If they say "this week" / "next week", derive from today's date.

**Working days.** Expect daily notes only for **Mon–Fri**. Saturday and Sunday are non-working by default — their absence is normal and must **not** be reported as missing. Include a weekend day only if a daily note actually exists for it (rare overtime); when one exists, treat it as a normal day.

## Operations

Pick the operation from the user's intent. If intent is unclear, ask **one** scoping question (which week? which operation?) before acting. Do not guess scope on destructive or write-heavy operations.

### 1. `start-week`
Goal: open a week and agree goals.
1. Resolve `<YYYY-Www>`. Create `WORKSPACE` if absent; populate the three files (`01_goals.md`, `02_weekly_log.md`, `03_backlog.md`) from `assets/` skeletons.
2. Read `QUARTERLY` for the current quarter. In dialogue with the user, draft 1–5 week goals in `01_goals.md`, each linked to a quarterly goal/OKR: `Supports: [[<year>-Qn#Goals / OKR]]`.
3. If `QUARTERLY` is missing or has no goals section, **do not invent goals** — write `gap: no quarterly goals found for <quarter>` in `01_goals.md` and continue with the user's stated goals only.
4. Mark any week goal not linked to a quarterly goal as `orphan` (candidate to drop or to connect later).

### 2. `log-update`
Goal: record a day in the single weekly log.
- Append/update the day's entry in `02_weekly_log.md` under a `### <YYYY-MM-DD>` heading, using the day fields: `Done / Planned / Blockers / Jira / Artifacts / Learn / Research / Attention`.
- Keep Jira keys as `DWSAI-<n>` with their URL. Keep artifact links verbatim. Do not rewrite task meaning. Do not mark unchecked items done.

### 3. `daily-status`
Goal: short team-chat message from the weekly log.
- Read the relevant day(s) in `02_weekly_log.md` and emit a short Russian message in exactly three blocks: **Вчера / Сегодня / Блокеры**.
- Keep it short (not a report, not a performance review). Do not invent status. If a block has no source data, write `— нужно добавить: <что именно>` instead of guessing.

### 4. `consolidate`
Goal: turn a week's daily notes into the single weekly log. On-demand and idempotent (safe to re-run).
1. Resolve `<YYYY-Www>`. The expected days are **Mon–Fri**; also include Sat/Sun only if a `DAILY_SRC` file exists for them. List the existing `DAILY_SRC` files in range.
2. For each existing day, read it and write a normalized `### <YYYY-MM-DD>` block into `02_weekly_log.md`:
   - Strip the source note's YAML frontmatter from the embedded content; keep source metadata separately under a `Source metadata` line (path + created/updated).
   - Keep headings, task lines (preserve `[ ]`/`[x]` state and `✅ DATE`), and non-empty Back Matter (Questions/Study/Backlog/Reference/Knowledge). Omit empty Back Matter subsections.
   - Extract Jira keys (`DWSAI-\d+`) into the day's `Jira` field. Put artifact links in the day's `Artifacts` field **with inline status** where known: `<link> — <status>` (`draft / in-review / merged / shipped / abandoned / unknown`). Classify type when useful (MR / RFC / ADR / doc / note / dashboard / chat / incident / Jira issue / other).
3. **Missing days:** flag only missing **working days** (a Mon–Fri with no note) under a `Missing / unclear` note in `02_weekly_log.md` (e.g. "no daily note for 2026-05-18"). Do **not** flag absent Sat/Sun. Never fabricate a day.
4. **Never modify the source daily notes.**

### 5. `review`
Goal: draft the weekly review. Read `02_weekly_log.md`, `QUARTERLY`, and `MATRIX`. Aggregate Jira keys, artifacts+status, learning gaps, and missing/unclear from the log in-context (no separate input file). Write to `WEEKLY_OUT`. Then update `MAPPING` **only per the gated rule below**. Use the review structure below. Do **not** write to promotion aggregates (`Artifacts Register.md`, `Staff Packet.md`) — those stay manual.

### 6. `consolidate-delete` (gated, optional)
Only on an explicit user request to delete daily notes. Steps, in order:
1. Run/confirm `consolidate` for the week.
2. Verify `02_weekly_log.md` exists and contains a block for each existing source day.
3. Ask for explicit confirmation, naming the exact files to delete (only that week's `DAILY_SRC`).
4. Only after confirmation, delete those files. Never delete other weeks, 2025 notes, or non-daily notes. If verification fails, stop and report.

## Weekly review structure (`WEEKLY_OUT`)

Keep it lean. Use these headings only:

1. **Summary** — 3–7 lines: why the week mattered, overall direction. Facts only.
2. **Achievements** — 2–6 items, each as `problem → action → result`, not a task list. For each:
   - `Evidence:` ≥1 link, or `TBD: add evidence`.
   - `Status:` activity / output / outcome (+ artifact status if relevant).
   - `Scope:` who/what it affected (state personal influence; don't claim product scale as personal).
3. **Staff check** — see Staff mapping rules. Conservative: map only items with real evidence; otherwise `candidate` / `weak` / `missing`.
4. **Goal attainability** — for each quarterly goal touched this week: `on track / at risk / blocked / stalled / unclear (insufficient evidence)`. List tasks **not linked to any goal** as `orphan`. Note what to change next week to keep goals attainable.
5. **Carry-forward** — unfinished items (e.g. open MR / `in-progress` Jira) with stable refs, to seed next week's `01_goals.md`. These are pending evidence, not achievements.
6. **1:1 talking points** — 2–6 items: gaps, risks, requests, decisions needed.
7. **Mapping update** — one line stating exactly what was appended to `MAPPING` this week, or `строка не добавлена — нет evidenced coverage за неделю (кандидаты см. Staff check)`. This must match what was actually written (see MAPPING rule); never claim a row that wasn't written, never write a row not mirrored here.

Separate **facts / inference / recommendations / TBD** throughout. Do not produce a final review from incomplete evidence — mark gaps instead.

## Staff mapping rules (read `MATRIX` first)

The matrix is the source of truth. Use **lowercase block anchors** in links: `[[Staff Competency Matrix#^impact-01]]`. The matrix defines each anchor in both lowercase and UPPERCASE (`^impact-01` and `^IMPACT-01` both resolve); prefer lowercase for new links. **Only use an anchor that actually exists in `MATRIX` — never invent a competency ID.** If unsure an ID exists, read the matrix and confirm; if no fitting competency exists, say so rather than inventing one.

- **Official coverage = `[PDF]` items only** (blocks ELIGIBILITY, SCOPE, IMPACT, IMPACT-EXTRA, COMPLEXITY, LEADERSHIP, IMPROVEMENT, CORE).
- `[OP]` items are **quality/evidence signals only**, not coverage.
- `[REF]`, `[TBD]`, `NON-17-*`, deprecated aliases, and roles are **never** coverage.
- Do **not** map an achievement to a competency ID **without evidence**. No evidence → `candidate` or `weak`, with a note on what artifact would close it.
- For `IMPACT-EXTRA-*`, remember the PDF gate: at least two of five, with required confirmations.
- An un-merged MR / unfinished task is **pending evidence** — log it, carry it forward, but do not map it as an achievement until it lands.

### `MAPPING` update (gated — write only real coverage)
- **Write a row only for an achievement that has a real competency link backed by evidence** — i.e. an `outcome`/`output` whose evidence supports a specific `[PDF]` competency. **One row per such achievement** (the file's rule is "один ряд = один STAR-пункт"). Do **not** cram several achievements into one row.
- **If the week yields no qualifying achievement (everything is `candidate`/`weak`/`pending`), do NOT edit `MAPPING` at all** — do not append a `TBD` row and do not bump the `updated` timestamp. Surface the candidates in the review's **Staff check** instead.
- **Never** log a carry-forward / pending item (e.g. un-merged MR, unfinished task) or a signal-only item (e.g. a single interview) as an achievement row.
- Row format: `Week | Achievement | Competencies (2–5 lowercase anchors) | Evidence (≥1 link) | Notes / TBD`. Append to the `Log (weekly)` table only. Never touch the Coverage or Weak/Missing sections, and never edit existing rows.
- Always mirror the outcome in the review's **Mapping update** line (what was appended, or that nothing was).

## Examples

**Daily status (operation 3):**
```
Вчера: завершил DWSAI-742; добавил smoke checks для MCPHub (tools/list).
Сегодня: продолжаю DWSAI-745 (skill-creator endpoint + frontend).
Блокеры: — нужно добавить: статус по innersource-заезду в SaaS.
```

**Artifact status (operation 4/6):** open MR for a feature →
`Artifact: MR <url> — status: in-review` → goes to **Carry-forward**, not **Achievements**; maps to a competency only after `merged/shipped`.

**Conservative Staff mapping (operation 6):** task done but no production/effect evidence →
`Staff check: candidate — [[Staff Competency Matrix#^impact-01]] (weak: no release/effect evidence; TBD: add MR + deploy proof)`. Do not assert IMPACT coverage.

## What not to do

- Don't fetch or invent Jira descriptions/status (no MCP) — mark `missing data`.
- Don't write to `Artifacts Register.md` / `Staff Packet.md` automatically.
- Don't write a `MAPPING` row (or bump its timestamp) when the week has no evidenced coverage — leave the file untouched.
- Don't invent competency anchors — use only IDs that exist in `MATRIX`.
- Don't migrate the whole vault or all of `1_Planning/` — only per-week `consolidate`.
- Don't edit `MATRIX`, templates, historical daily notes, or `AGENTS.md`.
- Don't produce dataview-heavy or motivational output. Keep the review short.
