---
name: close-my-day
disable-model-invocation: true
description: "Close out the day inside an Obsidian Markdown vault. Reviews today's open tasks, confirms which to mark done with an explicit YES gate, marks them complete in Markdown, carries unfinished work forward, and previews tomorrow's schedule. Use when the user explicitly asks: close my day, end of day, wrap up, close out. Markdown-only, no Notion/Google Calendar. Never writes without explicit confirmation."
---

# Close My Day

Review today's open tasks, confirm what to mark complete, write the changes to the
daily note, and stage tomorrow. **This skill never runs on its own** — the user must
explicitly ask to close their day.

## Backend (vault-agnostic, Markdown-only)

- **Primary:** `obsidian-cli` (`obsidian help`) on the active vault.
- **Fallback:** read/edit vault files directly if the CLI is unavailable.

No Notion, no Google Calendar, no schema creation.

## Conventions / Paths

Named conventions, not hardcoded magic. Edit this table only if the vault layout differs.

| Name | Default | Role |
|---|---|---|
| `DAILY_SRC` | `1_Planning/Daily/<year>/<YYYY-MM-DD>.md` | Today's daily note — task + schedule source |
| `DAILY_NEXT` | `1_Planning/Daily/<year>/<YYYY-MM-DD+1>.md` | Tomorrow's daily note — carry-forward target + schedule preview |
| `TASK_OPEN` | lines matching `- [ ]` | Open tasks |
| `TASK_DONE` | `- [x] … ✅ <YYYY-MM-DD>` | Completion format (matches `daily-note`/`weekly-review`) |
| `CAL_SECTION` | heading `## Schedule` (or `## План дня`) | The day's events inside the daily note |

Derive dates from today. Use today's date for the `✅ <DATE>` stamp.

## Setup (per machine)

When installing on a new machine, configure before first run:

1. **Vault paths** — verify the `Conventions / Paths` table matches this machine's
   active vault. Adjust `DAILY_SRC`, `DAILY_NEXT`, `TASK_DONE`, and `CAL_SECTION` if the
   layout or completion convention differs. This is the only place paths live.
2. **obsidian-cli** — confirm the CLI is installed (`obsidian help`). If absent, the
   skill falls back to direct file edits; no action needed beyond knowing it's slower.
3. **Completion format** — confirm `TASK_DONE` matches how this vault marks done tasks
   (e.g. `- [x] … ✅ <DATE>`) so writes stay consistent with the vault's other tooling.

## What to do

### Step 1: Read today's open tasks
Collect `TASK_OPEN` lines from `DAILY_SRC`. Focus on tasks due today or overdue.

### Step 2: Identify likely-completed work
From the open list, identify which tasks were plausibly worked on today (due today,
overdue, or referenced in today's conversation). Do not guess wildly.

### Step 3: Show the confirmation list
Present a numbered list of the tasks you plan to mark complete:

```
Here's what I'll mark complete:

1. [Task title]
2. [Task title]

Type YES to confirm, or NO to cancel.
```

**Do NOT write anything to the vault yet.** Wait for explicit approval.

### Step 4: Wait for approval
- **YES** → proceed to Step 5.
- **NO** → cancel, modify nothing, say "No changes made."
- Adjustment → let the user add/remove items, show the updated list, ask YES/NO again.

### Step 5: Mark tasks complete
Only after YES: in `DAILY_SRC`, rewrite each confirmed line from `TASK_OPEN` form to
`TASK_DONE` form — flip `- [ ]` to `- [x]` and append `✅ <today's DATE>`. Preserve the
rest of the line verbatim (text, links, tags). Do not touch unconfirmed lines.

### Step 6: Stage tomorrow
After writing, show:
- **Carried forward:** tasks still `- [ ]` in `DAILY_SRC` (not completed today). Offer to
  copy them into `DAILY_NEXT` (only on a further explicit YES — copying is also a write).
- **Tomorrow's schedule:** the `CAL_SECTION` of `DAILY_NEXT` if it exists, else "No schedule recorded for tomorrow."
- **Summary:** "X tasks completed today. Y carry forward. Z events tomorrow."

Close with: "Tomorrow morning, your briefing picks up right where tonight left off."

## Rules
1. **Never write to the vault without an explicit YES.** Most important rule.
2. **Show the list before acting.** The user sees exactly what changes before it happens.
3. **Markdown task edits are easy to misread in bulk** — that is why the confirmation step exists.
4. **One confirmation per action.** Do not re-ask "are you sure?" after a YES (a separate write like carry-forward gets its own YES).
5. **If a write fails partway**, stop immediately and report what was already changed.
6. Preserve frontmatter and unrelated content; edit only the confirmed task lines.
