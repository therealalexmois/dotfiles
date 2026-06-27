---
description: Craft a Conventional Commits message and commit the in-scope changes
argument-hint: [optional scope or one-line hint]
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*), Bash(git ls-files:*), Bash(git update-index:*), Bash(git restore:*)
---

## Context

- Branch: !`git rev-parse --abbrev-ref HEAD`
- Status: !`git status --short`
- Staged stat: !`git diff --cached --stat`
- Unstaged stat: !`git diff --stat`
- Recent commits (style reference): !`git log --oneline -8`

## Task

Optional user hint/scope: **$ARGUMENTS**

Create exactly one commit for the in-scope change, following the repo rules below.

### Message format

- One line: `<type>(<scope>): <description>`. A body only when the subject genuinely cannot explain the change.
- Allowed types only: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `style`, `build`, `ci`, `chore`.
- Pick the type by the **main meaning** of the diff, not by secondary files.
- Scope: the narrowest useful top-level area, usually a directory (`nvim`, `zsh`, `tmux`, `claude`, `codex`, `scripts`, `docs`, ...). Add it only when obvious from the paths; omit otherwise.
- English, lowercase, short imperative description, no trailing period, no quotes/markdown in the subject.
- If the user hint names a scope or intent, honor it unless the diff contradicts it.

### Staging

- First inspect `git status --short` and `git diff --cached` (shown above) to see what is actually changing.
- If something is already staged, commit exactly that. Do **not** add unstaged files to it.
- If nothing is staged, stage only the files that belong to **one** coherent change. Never sweep unrelated working-tree edits into the commit.
- If the working tree mixes several unrelated changes, stop and ask which one to commit (or propose splitting) instead of guessing.

### Skip-worktree files (settings.json, *.config.toml)

`ai-agents/.claude/settings.json` and `ai-agents/.codex/*.config.toml` are held with `git update-index --skip-worktree`, so their edits stay hidden from `git status`. If the change to commit includes one of them:

1. `git update-index --no-skip-worktree <file>`
2. Review `git diff <file>` and confirm it contains only the intended change, not runtime churn (model, theme, voice, project trust). Drop unintended hunks before staging.
3. Stage and commit.
4. Re-apply `git update-index --skip-worktree <file>` afterwards.

### Guards

- If there is no meaningful change to commit, say so and do nothing. Do not create an empty commit.
- Do **not** push. Committing is the whole job here; pushing happens only when the user asks.
- Report the final commit subject and the files included.
