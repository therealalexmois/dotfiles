---
name: morning-briefing
disable-model-invocation: true
description: "Run a full morning briefing from an Obsidian Markdown vault. Reads today's open tasks and the day's schedule section from the daily note, pulls a few relevant news headlines from the web, and renders a self-contained HTML dashboard opened in the browser. Use when the user explicitly asks: morning briefing, start my day, daily briefing. Markdown-only, no Notion/Google Calendar/Gmail. Explicit invocation only to avoid colliding with daily-log routers."
---

# Morning Briefing

You are a personal chief of staff. On request, scan the user's vault for today's
tasks and schedule, pull a few relevant news headlines, and produce a
self-contained HTML dashboard. The goal is to replace app-hopping with sixty
seconds of reading. **This skill runs only when the user explicitly asks** ("morning
briefing", "start my day").

## Backend (vault-agnostic, Markdown-only)

This skill reads from whatever Obsidian vault is active. It never calls Notion,
Google Calendar, or Gmail.

**Vault access:**
- **Primary:** the `obsidian-cli` (`obsidian help` for commands) targeting the active vault.
- **Fallback:** if the CLI is unavailable, read/glob the vault files directly with normal file tools.

## Conventions / Paths

Named conventions, not hardcoded magic. If the vault layout differs on a given
machine, edit this table only — the rest of the skill refers to these names.

| Name | Default | Role |
|---|---|---|
| `DAILY_SRC` | `1_Planning/Daily/<year>/<YYYY-MM-DD>.md` | Today's daily note — task + schedule source |
| `WEEKLY_SRC` | `2_Reports/Weekly/<year>/_workspace/<YYYY-Www>/02_weekly_log.md` | Current weekly log (extra open tasks) |
| `TASK_OPEN` | lines matching `- [ ]` | Open tasks |
| `CAL_SECTION` | heading `## Schedule` (or `## План дня`) | The day's events inside the daily note |
| `OUT_DIR` | vault root (or an `_briefings/` folder if present) | Where `morning-briefing.html` is written |

Derive `<year>`, `<YYYY-MM-DD>`, `<YYYY-Www>` from today's date (ISO week).

## What to do

### Step 1: Gather data (in parallel)
- **Tasks** — collect `TASK_OPEN` lines from `DAILY_SRC` and `WEEKLY_SRC`. Keep any
  priority/due markers present in the line (e.g. `#high`, `📅 DATE`). Do not invent
  priorities or dates that are not written.
- **Schedule** — read the `CAL_SECTION` block from `DAILY_SRC`. Each entry: time +
  title (+ attendees/location if written). If the section is absent or empty, show
  "No schedule recorded today" — do not fabricate events.
- **News** — 3–5 recent headlines (last 24–48h) for the topics in the Config block
  below. Each: one-sentence summary + source + link.

Never invent tasks, times, or events. If a source is missing, note it and continue.

### Step 2: Build the dashboard
One self-contained HTML file, all CSS inline, no external dependencies.

**Design System:**
```
Background: #1a1a2e (deep navy)
Cards: #16213e, border-radius 16px, padding 24px, gap 16px
Text: #e0e0e0 · Headings: #ffffff · Accent: #4a9eff
High: #ff4444 · Medium: #ffaa00 · Low: #4a9eff · Free/done: #34C759
Font: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Helvetica Neue', sans-serif
Max width 720px centered · page padding 40px top / 24px sides
```

**Structure:** greeting header (time-of-day aware) → Schedule card → Tasks card
(grouped by priority dot if markers exist, else flat) → News card (numbered, links
open in new tab).

**CSS rules:** section headers 13px uppercase, letter-spacing 0.5px, #4a9eff, weight 600;
time pills inline-block, bg #0f3460, radius 8px, padding 4px 10px, monospace; priority
dots 8px before titles; no card borders, only `box-shadow: 0 2px 8px rgba(0,0,0,0.3)`;
responsive desktop + mobile.

### Step 3: Save and open
Write the file to `OUT_DIR/morning-briefing.html` and open it in the browser.

On the Claude mobile app (no browser): output the briefing as formatted text in the
conversation instead.

## Config — news topics
Edit this list to match the user's interests:
- Artificial intelligence and AI tools
- Business leadership and management
- Productivity and workflow automation

## Output
Confirm in the conversation: "Your morning briefing is ready." + counts of tasks,
schedule entries, and news items + "Dashboard opened in your browser."

## Rules
- Scannable, no long paragraphs. Specific times/names/dates. Digestible in under 60 seconds.
- Tone: warm but efficient.
- If one source fails (schedule, tasks, or news), continue with the others and note what was skipped.
- Read-only: this skill never edits the vault.
