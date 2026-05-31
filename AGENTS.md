# Agent Instructions

## Git Commits

- Use Conventional Commits for every commit message:
  `<type>(<scope>): <description>`.
- Keep the description short, imperative, and lowercase unless a proper noun
  requires capitalization.
- Choose the narrowest useful scope, usually the top-level area changed:
  `nvim`, `zsh`, `tmux`, `docs`, or another directory/config name.
- Prefer these commit types:
  - `feat`: user-facing feature or new capability.
  - `fix`: bug fix or broken behavior.
  - `chore`: maintenance, dependency, config, or tooling changes.
  - `docs`: documentation-only changes.
  - `refactor`: behavior-preserving code restructuring.
  - `test`: tests only.
- Before committing, inspect `git status --short` and `git diff --cached`.
- Stage only files that belong to the requested change. Do not include unrelated
  user work in the commit.
- Use a body only when the subject cannot explain the change clearly enough.

## Progress Updates

- After each meaningful action, post a short summary in chat of what was done.
- Keep those summaries concise and factual.
- Do not paste large `git diff`, full command output, or long logs in chat unless the user explicitly asks for them.
- When a diff is useful, provide a short version with the files changed and the practical effect.
- Treat command output as token-expensive. Prefer narrow commands and bounded output.
- For status reporting, summarize the relevant result instead of relaying raw logs.

## Output Limits

- Avoid commands that can emit very large output unless the task explicitly requires them.
- Prefer `git diff --stat`, `git diff --name-only`, or a diff scoped to specific files over full repository diffs.
- Prefer `rg -n <pattern> <specific-path>` over searching large dependency trees.
- When searching external dependency directories such as plugin caches, narrow the path to the package or file likely to contain the answer.
- Use command output limits where available and keep them small by default.

Examples:

```text
chore(zsh): remove zshenv loading echo
docs(agents): add git commit rules
fix(nvim): restore treesitter plugin config
```
