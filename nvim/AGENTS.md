# Agent Instructions for `nvim`

## Scope

- These rules apply to everything under `nvim/`.

## Editing

- Keep changes tightly scoped to the requested Neovim task.
- Prefer existing AstroNvim and AstroCommunity patterns over inventing new ones.
- Do not modify unrelated plugin specs, lockfiles, or generated files unless the task explicitly requires it.

## Verification

- Prefer targeted checks over broad output dumps.
- For Neovim work, use concise verification summaries in chat instead of pasting large `git diff` or healthcheck logs.
- If a check produces a lot of output, summarize only the relevant warnings, errors, or behavioral changes.
- Prefer focused Neovim checks such as `:checkhealth <plugin>` or a small headless reproduction over full `:checkhealth`.
- Do not paste full `:checkhealth` output in chat. Extract and summarize only failing sections, warnings, and the relevant OK checks.
- Save long healthcheck output to `/private/tmp` when needed, then inspect it with targeted `rg`/`sed` ranges.
- Avoid running broad `:checkhealth` repeatedly. Re-run only the affected provider or plugin after a change.
- For `git diff`, prefer `git diff --stat`, `git diff --name-only`, or file-scoped diffs. Do not paste full diffs unless explicitly requested.
- Avoid broad searches through `~/.local/share/nvim/lazy` unless necessary. If needed, search the specific plugin directory.
- For `nvim --headless` verification, make the command print only the exact values needed, such as active LSP client names or a specific plugin option.

## Communication

- After each meaningful action, send a short summary of what changed or what was verified.
- Keep updates concise and factual.
