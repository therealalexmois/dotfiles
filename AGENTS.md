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

```
Shell:  ~/.zshenv (Stow) → bootstrap/.zshenv → ZDOTDIR=.dotfiles/zsh → zsh/.zshenv → XDG paths
                                                                                 └→ .zshrc / .zprofile

Neovim: init.lua → lazy_setup.lua → AstroNvim + community.lua + plugins/
                               ├→ CodeCompanion  (NVIM_AI_PROFILE: home | work | claude)
                               └→ claudecode.nvim (claude CLI over IDE protocol, no nvim wiring)

AI CLI: ai-agents/ (Stow) → ~/.agents/skills/  → ~/.claude/skills/
                                               └→ ~/.codex/skills/
        ai-agents/.claude/agents/ (Stow fold)  → ~/.claude/agents/
        ai-agents/.codex/*.config.toml          → ~/.codex/ (child links)
```

- `render-codex-config.py` merges `config.shared.toml` + `~/.codex/config.local.toml` into `~/.codex/config.toml` (local values win, 0600).
- `ai-agents/.claude/settings.json` uses `--skip-worktree`; to edit tracked defaults, temporarily `--no-skip-worktree`.
- CodeCompanion `claude` profile requires the `claude-code-acp` bridge; `claudecode.nvim` needs only the `claude` CLI.
- `~/.codex/skills/.system` is never replaced by the install script.

## Agent Skills: Naming and Layout

Two link layers above the repo; both break silently if a rename is done halfway.

```
ai-agents/.agents/skills/<name>/SKILL.md  ← source of truth

scripts/install-ai-cli-dotfiles.sh creates:
~/.agents/skills/<name>         → .dotfiles/ai-agents/.agents/skills/<name>  (Stow)
    ├── ~/.claude/skills/<name> → ~/.agents/skills/<name>                    (child)
    └── ~/.codex/skills/<name>  → ~/.agents/skills/<name>                    (child)
```

Skills load only at CLI startup. Restart Claude Code and Codex after adding or renaming.

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
skills moved out of this repo to the work vault (`~/Workspace/vault/.claude/skills/`).
Skill-creator eval scratch dirs (`*-workspace/`) are git-ignored and not skills.

### Skill Routing

Active dotfiles skills. "Auto" = auto-triggered by description match; "manual" = explicitly invoked via `/skill-name`.

| Trigger | Skill | Auto |
| --- | --- | --- |
| edit Russian text, убери воду, сократи | `writing-russian-editor` | yes |
| write a plan or design document | `writing-plans` | yes |
| write PRD | `writing-prd-draft` | manual |
| Python code, docstrings, tests | `python-conventions` | yes |
| create, edit, or eval a skill | `skill-creator` | yes |
| audit skill for security | `skill-security-auditor` | yes |
| audit skill for hardcoded values, parameterization | `skill-param-auditor` | yes |
| 2+ independent tasks to parallelize | `dispatching-parallel-agents` | yes |
| isolate work in a git worktree | `using-git-worktrees` | yes |
| design a multi-agent workflow | `agent-workflow-designer` | yes |
| build a Workflow script | `workflow-builder` | manual |
| review API design | `api-design-reviewer` | yes |
| CI/CD pipeline setup | `ci-cd-pipeline-builder` | yes |
| database schema design | `database-schema-designer` | yes |
| observability, SLO, metrics | `observability-designer` | yes |
| improve code architecture | `improve-codebase-architecture` | yes |
| security review | `security-guidance` | yes |
| tech debt audit | `tech-debt-tracker` | yes |
| review before completing a task | `review-before-completion` | yes |
| generate a runbook | `runbook-generator` | yes |
| write technical documentation | `documentation-writer` | yes |
| changelog or release notes | `changelog-generator` | yes |
| TDD, test-first development | `tdd` / `test-driven-development` | yes |
| quick brainstorm | `brainstorm-lite` | yes |
| structured brainstorm | `six-thinking-hats` | yes |
| challenge and stress-test ideas | `grill-me` | yes |
| productivity coaching | `productivity-coach` | yes |
| execute a step-by-step plan | `executing-plans` | yes |
| onboard to a codebase | `codebase-onboarding` | manual |

Vault skills (`~/Workspace/vault/.claude/skills/`) are not listed here; they have their own routing in the vault's CLAUDE.md.

> TODO: Rename the unprefixed first-party skills to follow the convention: `wiki`,
> `daas-k8s-debug`, `incident-triage`, `time-messenger`. (`to-prd` renamed to
> `writing-prd-draft`.)

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

| Extension point | Location | Notes |
| --- | --- | --- |
| Reusable AI prompt | `llm/prompts/<name>.md` | Project overrides in `<repo>/.prompts` |
| Agent skill | `ai-agents/.agents/skills/<name>/SKILL.md` | See "Agent Skills" section |
| Claude subagent | `ai-agents/.claude/agents/<name>.md` | Stow-folded to `~/.claude/agents/` |
| Codex reasoning profile | `ai-agents/.codex/<name>.config.toml` | Symlinked to `~/.codex/` |
| Codex shared settings | `ai-agents/.codex/config.shared.toml` | Machine-local values in `config.local.toml` |
| CodeCompanion AI profile | `nvim/lua/config/ai/codecompanion_profiles.lua` | |
| Neovim plugin | `nvim/lua/plugins/` domain subdir | AstroCommunity in `community.lua` |
| tmux plugin | `tmux/tmux.conf` | `set -g @plugin ...` |
| Homebrew package | `mac-setup/Brewfile` | |
| Shell entrypoint | `bootstrap/.zshenv` / `zsh/bootstrap.zsh` | |
| Starship module | `starship.toml` | |
| Terminal config | `alacritty/` | |

Environment variables are the main feature flags: XDG paths in `zsh/.zshenv`, AI profile variables in CodeCompanion config.

## Further Reading

- [README.md](README.md) - manual macOS setup notes.
- [scripts/install-ai-cli-dotfiles.sh](scripts/install-ai-cli-dotfiles.sh) and
  [scripts/render-codex-config.py](scripts/render-codex-config.py) - AI CLI install chain.
- [llm/PROMPT_POLICY.md](llm/PROMPT_POLICY.md) - prompt-system policy.
- [nvim/lua/config/ai/codecompanion_profiles.lua](nvim/lua/config/ai/codecompanion_profiles.lua) - AI profile selection.

> TODO: Add deeper architecture docs such as `docs/ARCH.md` or ADRs when they exist.
