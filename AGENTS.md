# Project Overview

This repository is an XDG-oriented macOS dotfiles workspace for terminal, shell, editor,
and developer tooling configuration. It centralizes Neovim/AstroNvim setup, reusable AI
prompt workflows, AI CLI agent configuration (Codex and Claude), tmux, Starship, Zsh
bootstrap files, terminal emulator configs, package bootstrap lists, and selected CLI tool
settings so one laptop can reproduce a consistent interactive development environment.

## Repository Structure

- `ai-agents/` - Single Stow package for AI CLI agents. Holds `.codex/` (Codex `AGENTS.md`,
  `config.shared.toml`, `config.local.toml.example`, and `*.config.toml` reasoning/mode
  profiles), `.claude/` (`CLAUDE.md`, `settings.json`, `statusline.sh`, and `agents/`
  tracked Claude Code subagents), and `.agents/skills/` (shared agent skills, the source of
  truth for both CLIs). Runtime state, secrets, and the rendered `config.toml` are
  git-ignored.
- `alacritty/` - Alacritty terminal configuration, key bindings, color script, and themes.
- `bootstrap/` - Stow package for home-level bootstrap files that redirect shell startup
  into repo config.
- `scripts/` - Repo tooling: `install-ai-cli-dotfiles.sh` (Stow + skill/profile symlinks),
  `render-codex-config.py` (merge shared + local Codex TOML into `~/.codex/config.toml`),
  `check-ai-cli.sh` (lint/smoke for the AI CLI tooling), and `audit-skills.sh` (security
  audit of all skills via skill-security-auditor; compares with the committed
  `skills-audit-baseline.json`).
- `lazydocker/` - lazydocker configuration.
- `llm/` - Global AI prompt library and prompt-system policy used by Neovim.
- `mac-setup/` - Homebrew `Brewfile` for macOS package bootstrap.
- `nvim/` - AstroNvim user configuration, plugin specs, Lua helpers, and lockfile.
- `tmux/` - tmux configuration; plugin checkouts are intentionally ignored.
- `zsh/` - Tracked Zsh startup files and bootstrap script.
- `.gitignore` - Ignore rules for machine state, plugin caches, and local-only tools.
- `README.md` - Manual macOS setup notes and installation checklist.
- `starship.toml` - Starship prompt configuration loaded through `STARSHIP_CONFIG`.

## Build & Development Commands

There is no root package manifest, task runner, CI file, or documented test suite. Use
tool-native commands and keep missing workflows behind TODOs.

Install or bootstrap:

```sh
# Install Homebrew packages, applications, and fonts declared by the repo.
brew bundle --file mac-setup/Brewfile

# Create ~/.zshenv as a symlink to bootstrap/.zshenv.
stow --target "$HOME" bootstrap

# Link tracked Zsh startup files and install Oh My Zsh if missing.
zsh zsh/bootstrap.zsh

# Install AI CLI agent dotfiles: backup, Stow `bootstrap`+`ai-agents` (folds
# ~/.claude/agents), render Codex config, and create per-skill / per-profile symlinks for
# Codex and Claude. Idempotent; moves real-file conflicts to a timestamped backup and never
# touches ~/.codex/skills/.system.
scripts/install-ai-cli-dotfiles.sh

# Neovim bootstraps lazy.nvim on first start.
nvim

# tmux/tmux.conf bootstraps TPM if ~/.dotfiles/tmux/plugins/tpm is missing.
tmux source-file ~/.dotfiles/tmux/tmux.conf
```

Test:

```sh
# TODO: Add first-party automated tests for Lua helpers and shell startup behavior.
```

Lint:

```sh
stylua --check nvim
# selene resolves selene.toml from the CWD, so run it from nvim/ (not `selene nvim`,
# which finds no config at the repo root and floods false positives).
(cd nvim && selene .)
zsh -n bootstrap/.zshenv zsh/.zshenv zsh/.zprofile zsh/.zshrc zsh/bootstrap.zsh

# Lint + smoke the AI CLI tooling (zsh -n, shellcheck, py_compile, render --check,
# TOML parse of shared/profile configs). Performs no writes to ~/.codex or ~/.claude.
scripts/check-ai-cli.sh

# Security-audit all agent skills (skips *-workspace scratch dirs) and compare the
# verdicts with scripts/skills-audit-baseline.json; --update-baseline rewrites it.
scripts/audit-skills.sh
```

Type-check:

```sh
# TODO: Add a documented type-check command for first-party Lua.
```

Run:

```sh
nvim
tmux source-file ~/.dotfiles/tmux/tmux.conf
```

Debug:

```sh
nvim --headless "+checkhealth" +qa
NVIM_AI_PROFILE=work nvim
```

Deploy:

```sh
# TODO: Document deployment/bootstrap for a new host beyond README.md notes.
```

## Code Style & Conventions

- Format first-party Lua with `stylua`; `nvim/.stylua.toml` sets Unix line endings,
  two-space indentation, `column_width = 120`, `quote_style = "AutoPreferDouble"`,
  `call_parentheses = "None"`, and `collapse_simple_statement = "Always"`.
- Lint Neovim Lua with `(cd nvim && selene .)`; selene reads `selene.toml` from the CWD,
  so it must run inside `nvim/`. `nvim/selene.toml` uses `std = "neovim"` and
  allows selected rules for this config style.
- Keep `nvim/lua/community.lua` imports enabled-only, alphabetized within sections, and
  ordered as foundation/UI, language packs, editing/search, git/docker, LSP/debugging,
  then workflow/motion.
- Keep plugin specs under `nvim/lua/plugins/` grouped by domain: `ai`, `debugging`,
  `editing`, `ui`, and top-level shared specs.
- Keep reusable prompts in `llm/prompts/` as Markdown files with metadata/frontmatter.
  Use short kebab-case names and one stable logical purpose per prompt.
- Keep project-specific prompts outside this repo in `<repo>/.prompts` unless the prompt
  is reusable across projects.
- Do not mix prompt text, repo rules, backend adapter config, and secrets in one file.
- Commit messages follow Conventional Commits:
  `<type>(<optional scope>): <subject>`, lowercase type and scope, imperative subject,
  and no trailing period.

## Architecture Notes

The shell layer starts from `$HOME/.zshenv`, which is managed by Stow as a symlink to
`bootstrap/.zshenv`. That bootstrap file sets `ZDOTDIR=$HOME/.dotfiles/zsh` and sources
the repo-managed `zsh/.zshenv`; the repo-managed shell layer then sets XDG paths so
application configs resolve from `~/.dotfiles`. Neovim loads `lazy_setup.lua`, which
imports AstroNvim, AstroCommunity packs, and local plugin specs. CodeCompanion reads
reusable prompt Markdown from `llm/prompts` and selects the adapter from `NVIM_AI_PROFILE`:
the local Ollama adapter (`home`), the work proxy adapter (`work`), or the subscription
`claude_code` ACP adapter (`claude`); inline/cmd edits stay on the HTTP adapters while the
`claude` profile only routes chat to ACP. A second, independent surface, `claudecode.nvim`,
drives the `claude` CLI over the official IDE protocol for agentic/research work with native
diffs and inherits the CLI's MCP servers, subagents, skills, and rules with no nvim-side
wiring. tmux uses `tmux.conf` as the source of truth and bootstraps TPM when the plugin
manager is missing. `zsh/bootstrap.zsh` links startup files into `$HOME` and installs Oh My
Zsh into an ignored local checkout when needed.

The AI CLI layer is one Stow package, `ai-agents/`, deliberately consolidated so Codex and
Claude share one skill source of truth. `scripts/install-ai-cli-dotfiles.sh` backs up
existing files, Stows `bootstrap` and `ai-agents`, renders the Codex config, and then
creates child symlinks: each `~/.agents/skills/<skill>` is linked into both
`~/.codex/skills/<skill>` and `~/.claude/skills/<skill>`, and each tracked
`ai-agents/.codex/*.config.toml` profile is linked into `~/.codex/`. Stow also folds
`ai-agents/.claude/agents` into `~/.claude/agents`, so the tracked Claude Code subagents
resolve from the repo. The whole `~/.codex/skills` directory is never replaced, so
`~/.codex/skills/.system` stays intact.
`render-codex-config.py` recursively merges `config.shared.toml` with the local-only
`~/.codex/config.local.toml` (local values win), validates via `tomllib`, and atomically
writes `~/.codex/config.toml` with `0600`. Project trust entries (`[projects."..."]`) and
machine state live only in the local config and are never tracked. The install script also
sets `git update-index --skip-worktree` on `ai-agents/.claude/settings.json` so the runtime
keys Claude rewrites (model, theme, effort) do not churn the tracked defaults.

## Agent Skills: Naming and Layout

Source of truth and symlink chain (two link layers on top of the repo, easy to break):

- Real files live in `ai-agents/.agents/skills/<name>/` with `SKILL.md` at the skill root.
- `~/.agents/skills/<name>` -> `../../.dotfiles/ai-agents/.agents/skills/<name>` (Stow side).
- `~/.claude/skills/<name>` -> `../../.agents/skills/<name>`.
- `~/.codex/skills/<name>` -> `../../.agents/skills/<name>`.
- All three links are created by `scripts/install-ai-cli-dotfiles.sh` (idempotent). Skills
  load only at CLI startup, so new or renamed skills appear after restarting Claude Code
  and Codex.

Naming convention for first-party skills: the directory name and the `name:` field in
`SKILL.md` frontmatter must carry a domain prefix:

| Prefix | Domain |
| --- | --- |
| `work-` | planning, reflection, and work processes |
| `writing-` | text editing |
| `python-` | Python coding conventions |
| `jira-` | Jira workflows |
| `gitlab-` | GitLab workflows |
| `spirit-deploy` | deploy (single-skill domain) |

Third-party imported skills keep their upstream names and are exempt. The `obsidian-*`
skills moved out of this repo to the work vault (`~/projects/work-vault/.claude/skills/`).
Skill-creator eval scratch dirs (`*-workspace/`) are git-ignored and not skills.

> TODO: Rename the unprefixed first-party skills to follow the convention: `to-prd`,
> `wiki`, `daas-k8s-debug`, `incident-triage`, `time-messenger`.

Rename checklist (every step is required, the link layers break silently):

1. Rename the directory under `ai-agents/.agents/skills/`.
2. Update `name:` in the skill's `SKILL.md` frontmatter.
3. Recreate all three symlinks (`~/.agents/skills`, `~/.claude/skills`,
   `~/.codex/skills`) or rerun `scripts/install-ai-cli-dotfiles.sh`.
4. Update cross-references to the old name in other `SKILL.md` files.
5. Restart Claude Code and Codex so the renamed skill is picked up.

## Testing Strategy

- Unit tests: no first-party unit test suite is documented.
  > TODO: Add tests for `nvim/lua/config/ai/docstring/extractor.lua` if its behavior
  > becomes shared or regression-prone.
- Integration checks: run `stylua --check nvim`, `(cd nvim && selene .)`, `zsh -n ...`, and
  `nvim --headless "+checkhealth" +qa` before broad config changes.
- Neovim plugin checks: start `nvim` after editing plugin specs so Lazy can surface
  install, dependency, or lockfile issues.
- tmux checks: run `tmux source-file ~/.dotfiles/tmux/tmux.conf` after tmux changes.
- E2E tests: no automated end-to-end workflow is documented.
  > TODO: Document a manual smoke test for a fresh shell, tmux session, and Neovim launch.
- CI: no CI configuration is present.
  > TODO: Add CI or document why validation remains local-only.

## Security & Compliance

- Do not commit secrets, API keys, tokens, proxy credentials, or machine-specific paths
  beyond the explicit dotfiles contract.
- CodeCompanion work mode requires `NVIM_AI_WORK_URL`, `NVIM_AI_WORK_API_KEY`, and
  `NVIM_AI_WORK_MODEL`. Optional variables are `NVIM_AI_WORK_CHAT_URL`,
  `NVIM_AI_WORK_PROXY`, `NVIM_AI_WORK_ALLOW_INSECURE`, `NVIM_AI_PROFILE`, and
  `NVIM_AI_OLLAMA_MODEL`.
- The Claude surfaces use the subscription, not an API key. The `claude` CodeCompanion
  profile needs the `claude-code-acp` bridge (`npm install -g @zed-industries/claude-code-acp`);
  `claudecode.nvim` needs only the `claude` CLI. `CLAUDE_CODE_OAUTH_TOKEN` (from
  `claude setup-token`) is optional and, if used, is a local-only secret exported from the
  shell env — never commit it. ACP also works without it on an interactive subscription.
- Treat `.pyenv/`, `tmux/plugins/*`, ignored Zsh plugin checkouts, shell history, htop
  config, and local-only CLI configs as machine state unless the user explicitly asks to
  version them.
- Never track Codex/Claude secrets or runtime state: `auth.json`, `*.sqlite*`, `history*`,
  `sessions/`, `cache/`, `logs/`, `~/.claude.json`, the rendered `~/.codex/config.toml`, or
  `~/.codex/config.local.toml`. The `.gitignore` already excludes these under `ai-agents/`.
- Codex project trust entries (`[projects."..."]`) belong only in `~/.codex/config.local.toml`;
  keep them out of `config.shared.toml` and the tracked `*.config.toml` profiles.
- `ai-agents/.claude/settings.json` is held with `git update-index --skip-worktree`; to change
  the tracked defaults, temporarily `--no-skip-worktree`, edit, commit, then re-apply.
- `nvim/lazy-lock.json` pins Neovim plugin revisions; update it only through plugin update
  workflows, not hand edits.
- Vendored upstream plugin directories may carry their own licenses, but they are ignored
  by this repository. This repository has no root license file.
  > TODO: Add or document the first-party repository license.
- Dependency scanning is not configured.
  > TODO: Add a documented check for Neovim plugins, tmux plugins, and shell plugins.

## Agent Guardrails

- Never edit ignored machine state such as `.pyenv/`, `tmux/plugins/*`, shell history, or
  local-only tool configs unless the user explicitly requests it.
- Do not hand-edit vendored upstream plugin internals; change plugin declarations or the
  documented update flow instead.
- Do not rewrite `nvim/lazy-lock.json` unless the task is a plugin update or lockfile
  refresh.
- Be cautious with `nvim/init.lua`; it is a bootstrap file and its own comment says it
  should not usually be touched.
- Changes to `llm/PROMPT_POLICY.md`, CodeCompanion profile selection, shell bootstrap or
  startup files, and tmux bootstrap behavior require focused review because they affect
  every session.
- Prompt workflows that modify code must use a reviewable surface by default; the prompt
  policy explicitly forbids automatic application of destructive output.
- Do not run network-heavy plugin updates, work-proxy AI calls, or broad recursive scans of
  ignored plugin checkouts without user approval.
- Do not run `git add`, `git commit`, `git push`, `git rebase`, `git reset`, or amend
  commits unless explicitly asked.

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

Examples:

```text
chore(zsh): remove zshenv loading echo
docs(agents): add git commit rules
fix(nvim): correct treesitter ensure_installed in astrocore
```

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

## Extensibility Hooks

- Add reusable AI workflows as Markdown prompts in `llm/prompts/`; project overrides live
  in `<repo>/.prompts`.
- Add shared agent skills under `ai-agents/.agents/skills/<skill>/`; see "Agent Skills:
  Naming and Layout" above for the convention, symlink chain, and rename checklist.
- Add Claude Code subagents as `ai-agents/.claude/agents/<name>.md` (frontmatter `name`,
  `description`, `tools`, `model`); they reach `~/.claude/agents` through the Stow fold and
  are auto-discovered by the `claude` CLI and `claudecode.nvim` (`/agents`, Task tool).
- Add Codex reasoning/mode profiles as `ai-agents/.codex/<name>.config.toml`; the install
  script symlinks every `*.config.toml` into `~/.codex/`.
- Adjust shared Codex settings in `ai-agents/.codex/config.shared.toml`; keep machine-specific
  values in `~/.codex/config.local.toml` (see `config.local.toml.example`).
- Add or adjust CodeCompanion profiles in `nvim/lua/config/ai/codecompanion_profiles.lua`.
- Add Neovim plugin specs through `nvim/lua/plugins/init.lua` and domain folders below
  `nvim/lua/plugins/`; AstroCommunity imports go in `nvim/lua/community.lua` (preserve its
  section order), language tooling in `nvim/lua/plugins/mason.lua`, Treesitter parsers in
  `opts.treesitter.ensure_installed` in `nvim/lua/plugins/astrocore.lua`.
- Add tmux plugins with `set -g @plugin` entries in `tmux/tmux.conf`.
- Add Homebrew package bootstrap entries in `mac-setup/Brewfile`.
- Shell entrypoints: home-level behavior in `bootstrap/.zshenv`, symlink/install behavior in
  `zsh/bootstrap.zsh`, startup behavior in tracked Zsh startup files.
- Add prompt modules or display modules in `starship.toml`.
- Add terminal-specific behavior in `alacritty/`.
- Environment variables are the main feature flags: XDG paths in `zsh/.zshenv`, AI profile
  variables in CodeCompanion config, and tool-specific paths for WezTerm.

## Further Reading

- [README.md](README.md) - manual macOS setup notes.
- [scripts/install-ai-cli-dotfiles.sh](scripts/install-ai-cli-dotfiles.sh) and
  [scripts/render-codex-config.py](scripts/render-codex-config.py) - AI CLI install chain.
- [llm/PROMPT_POLICY.md](llm/PROMPT_POLICY.md) - prompt-system policy.
- [nvim/lua/config/ai/codecompanion_profiles.lua](nvim/lua/config/ai/codecompanion_profiles.lua) - AI profile selection.

> TODO: Add deeper architecture docs such as `docs/ARCH.md` or ADRs when they exist.
