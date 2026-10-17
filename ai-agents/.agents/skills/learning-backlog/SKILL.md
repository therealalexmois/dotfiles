---
name: learning-backlog
description: >-
  Maintains a personal backlog of topics to study later: quickly saves an
  unfamiliar language or library mechanism, architectural decision, engineering
  pattern, or bug-diagnosis case from the current session; lists open topics
  filtered by project and tags, opens a topic for study in dialogue, amends an
  entry, changes its status, and exports selected topics for a study plan. Use
  for "add to backlog: I want to figure this out later", "park this topic for
  study", "what's in my learning backlog", "let's go through LB-12", "amend the
  entry", "mark the topic as learned", "prepare topics for a study plan". Do not
  use for the work task backlog and Planning/Backlog.md, Jira, or building a
  learning roadmap or curriculum.
metadata:
  version: "1.0"
  origin: first-party
---

# Learning Backlog

Save deferred study questions so that an entry is understandable a month later without the original dialogue, and return to them on request.

## Storage and CLI

Perform all entry operations through the CLI only. Do not create, edit, or delete entry files directly.

```sh
python3 <skill-dir>/scripts/learning_backlog.py <command> ...
```

`<skill-dir>` is this skill's directory. The default data directory is `~/.local/share/learning-backlog`; override it with the `LEARNING_BACKLOG_DIR` variable or the global `--dir`. One topic is one `LB-NNNN.md` file; the files are the only source of data, there is no index.

| Command | Purpose |
| --- | --- |
| `add --title T [--project P] [--tag t]...` | Create an entry; `## ` sections are read from stdin. The CLI sets the ID and dates |
| `list [--status open\|learned\|archived\|all] [--project P] [--tag t]... [--query Q] [--format json]` | List entries; `open` by default. Several `--tag` options mean "all at once" |
| `show ID [--format json]` | The whole entry |
| `update ID [--title] [--project \| --clear-project] [--add-tag] [--remove-tag] [--section S [--mode append\|replace] [--stamp]]` | Change metadata or a section; the section text comes from stdin |
| `set-status ID open\|learned\|archived [--user-confirmed]` | Change the status |
| `export ID...` | Markdown export of the selected entries for a study plan |
| `template` | The entry template |

An ID is accepted as `LB-0012`, `LB-12`, or `12`. A non-zero exit code means the operation failed: show the CLI message to the user and do not work around it by editing a file by hand.

## Entry format

The format is fixed in `assets/entry-template.md` (`template` prints it). The CLI builds the frontmatter and the `#` heading itself; only the sections are passed on stdin:

1. `## What I want to understand` – required: a specific question or gap in understanding.
2. `## Context` – what task was being solved and where the question came up.
3. `## Example` – a short illustrative code fragment, error, or sequence of actions.
4. `## Decision and alternatives` – what was chosen, why, and which options were discussed.

The CLI fills an empty or omitted section from 2–4 with the text `Not recorded.`. Extra sections, for example `## Agent assumptions` and `## Analysis results`, go after the required ones. Inside sections use headings no higher than `###`.

## Reliability

- Record only what is in the session, the code, or command output. Do not invent reasons for decisions, alternatives, links to materials, or explanations.
- Put your own guesses in the `## Agent assumptions` section instead of mixing them with confirmed context.
- Preserve the user's original question even if the answer seems known: as a quote `> Original wording: "…"` in the "What I want to understand" section. Do not answer the question inside the entry.
- Add the file path, symbol name, and commit to "Example" as a `Source: …` line, only when they are known. Take the commit from `git rev-parse --short HEAD` if the example comes from committed code. References complement the example but do not replace it: the code may change.

## Save a topic

1. Extract the question and the essential context from the current session. Do not ask questions if the topic can be understood from the context; do not fill in a questionnaire. If even the subject of the topic is unclear, ask one question.
2. Pick an example: a minimal fragment that makes the question clear without the repository, usually up to 20 lines.
3. Determine the metadata: `--project` is the current repository name (basename of `git rev-parse --show-toplevel`) unless the user named another; 1–4 short lowercase tags (`python`, `asyncio`, `architecture`).
4. Check for semantic duplicates: `list --status all --format json` and compare `title` and `question`. With a sizable catalog, narrow the selection through `--project`, `--tag`, or `--query`. If a similar entry exists, offer to extend it (`update --section`) or to create a new one, and wait for the choice. Do not merge automatically.
5. Save:

   ```sh
   python3 <skill-dir>/scripts/learning_backlog.py add \
     --title "Why asyncio.shield here" --project finsight --tag python --tag asyncio <<'EOF'
   ## What I want to understand
   ...
   ## Context
   ...
   ## Example
   ...
   ## Decision and alternatives
   ...
   EOF
   ```

6. Reply with one line: the ID and the title. Do not retell the entry.

The title is a short formulation of the question, understandable outside the project: "Why asyncio.shield around commit in a cancellation handler", not "shield".

## View topics

Run `list` with the filters from the request and show the result compactly. Use status `all` only if the user asks for learned or archived topics.

## Work through a topic

1. Open the entry with `show ID`.
2. Briefly recall the question and context from the entry, then start the explanation in the current dialogue from the original question. If the example refers to code in the current repository, compare it with the current version and mention any discrepancy.
3. If the user wants to learn through guiding questions, suggest `teach-through-dialogue`.
4. Opening an entry and explaining it do not change the status.
5. When the analysis reaches conclusions, offer to save them. After agreement, add a section with `update ID --section "Analysis results" --stamp`. Record the conclusions reached in the dialogue and the materials that were actually used.

## Update an entry

- Extend a section: `update ID --section "<section>"`, text via stdin; by default the text is appended to the section. `--mode replace` replaces the whole section; the CLI allows only appending to the "What I want to understand" section.
- Metadata: `--title`, `--project`, `--clear-project`, `--add-tag`, `--remove-tag`.
- Set `learned` only when the user explicitly says the topic is learned: `set-status ID learned --user-confirmed`. The agent's own judgment or a completed explanation is not such a confirmation.
- `archived` – when the user asks to drop a topic without studying it; `open` – to put a topic back into work.

## Prepare topics for a study plan

Get the IDs of the selected topics (by the user's naming or through `list`) and run `export ID...`. Return the export as is: questions, context, examples, and analysis results. Do not build a curriculum, a study order, or a roadmap; separate tools exist for that if the user asks.
