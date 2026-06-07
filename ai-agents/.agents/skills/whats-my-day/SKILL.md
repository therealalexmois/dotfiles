---
name: whats-my-day
disable-model-invocation: true
description: "Show today's open tasks and schedule from an Obsidian Markdown vault as a quick self-contained HTML view. Reads the daily note's open tasks and schedule section — no news, no app-hopping. Use when the user explicitly asks: what's my day, today's tasks, my schedule, daily overview. Markdown-only, no Notion/Google Calendar. Explicit invocation only to avoid colliding with daily-log/daily-note routers."
---

# What's My Day

Show today's open tasks and the day's schedule from the active Obsidian vault in one
quick view. A lighter sibling of `morning-briefing` — same task/schedule source, no
news. **Runs only when the user explicitly asks** ("what's my day", "today's tasks").

## Backend (vault-agnostic, Markdown-only)

- **Primary:** `obsidian-cli` (`obsidian help`) on the active vault.
- **Fallback:** read/glob vault files directly if the CLI is unavailable.

No Notion, no Google Calendar.

## Conventions / Paths

Named conventions, not hardcoded magic. Edit this table only if the vault layout differs.

| Name | Default | Role |
|---|---|---|
| `DAILY_SRC` | `1_Planning/Daily/<year>/<YYYY-MM-DD>.md` | Today's daily note — task + schedule source |
| `WEEKLY_SRC` | `2_Reports/Weekly/<year>/_workspace/<YYYY-Www>/02_weekly_log.md` | Current weekly log (extra open tasks) |
| `TASK_OPEN` | lines matching `- [ ]` | Open tasks |
| `CAL_SECTION` | heading `## Schedule` (or `## План дня`) | The day's events inside the daily note |
| `OUT_DIR` | vault root (or an `_briefings/` folder if present) | Where `whats-my-day.html` is written |

Derive `<year>`, `<YYYY-MM-DD>`, `<YYYY-Www>` from today's date (ISO week).

## What to do

1. **Tasks** — collect `TASK_OPEN` lines from `DAILY_SRC` and `WEEKLY_SRC`. Preserve any
   priority/due markers already in the line. Sort by priority if markers exist, else
   keep source order. Do not invent priorities or due dates.
2. **Schedule** — read the `CAL_SECTION` block from `DAILY_SRC`: time + title (+
   location/attendees if written), chronological. If absent/empty, show "No schedule
   recorded today" — do not fabricate.
3. **Render** a lighter version of the `morning-briefing` self-contained HTML (same
   design system: deep-navy cards, accent #4a9eff, priority dots, time pills) with two
   cards only — **Schedule** and **Tasks**. No news card. All CSS inline, no external
   dependencies.
4. **Save and open** `OUT_DIR/whats-my-day.html` in the browser. On the Claude mobile
   app, output as formatted text in the conversation instead.

## Summary line
End with one line: how many tasks are due today/overdue, how many schedule entries, and
the next upcoming event (from `CAL_SECTION`).

## Rules
- Scannable, no filler, no motivational language — just the data, organized clearly.
- Read-only: this skill never edits the vault.
- If a source is missing, note it and continue with the rest.
