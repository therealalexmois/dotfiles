# Project Overview

macOS dotfiles for terminal, shell, editor, and developer tools.
The workspace uses XDG paths, GNU Stow, AstroNvim, Codex, and Claude Code.

## Repository Structure

### Stow packages

See README.md, "The role of GNU Stow".

| Package | Contents and loading |
| --- | --- |
| `ai-agents/` | Codex and Claude instructions, settings, profiles, MCP declarations, hooks, subagents, and shared skills. Secrets, runtime state, and rendered `config.toml` are ignored. |
| `alacritty/` | Terminal config, key bindings, color script, and themes. Run `bootstrap/install-alacritty.sh` separately because GUI apps do not inherit shell XDG variables. |
| `bootstrap/` | Home-level shell startup redirect and the Alacritty installer. |

AI CLI source paths:

- `.codex/`: `AGENTS.md`, `config.shared.toml` with `[mcp_servers.*]`,
  `config.local.toml.example`, and `*.config.toml` reasoning/mode profiles.
- `.claude/`: `CLAUDE.md`, `settings.json`, `statusline.sh`, `mcp-servers.json`,
  tracked `agents/`, and `hooks/` wired from `settings.json`.
- `.agents/skills/`: shared source of truth for both CLIs.
- `ai-agents/rules/`: empty legacy directory stowed to `~/rules`.

### XDG configuration

`zsh/.zshenv` sets `XDG_CONFIG_HOME=$HOME/.dotfiles`.
These tools read the repository directly:

| Path | Contract |
| --- | --- |
| `atuin/config.toml` | Tracked config only. Ignored history-sync state lives under `$XDG_DATA_HOME/atuin`. |
| `git/ignore` | Global excludes. Git identity (`user.name`/`email`) is not tracked. |
| `lazydocker/config.yml` | Tracked lazydocker config. |
| `mise/config.toml` | Runtime pins and global `npm:` CLIs, preserved across Node upgrades. |
| `nvim/` | AstroNvim specs, Lua helpers, and lockfile. No `~/.config/nvim` symlink. A launcher without shell XDG variables falls back to an empty directory. |
| `tmux/` | Config loaded through tmux 3.1+ XDG support. TPM checkouts are ignored. |
| `zsh/` | Tracked `.zshrc`, `.zprofile`, `.zshenv`, and `bootstrap.zsh`. Bootstrap also links `.zshrc`/`.zprofile` into `$HOME` for tools such as Oh My Zsh that require literal home paths. |
| `starship.toml` | Loaded through `$STARSHIP_CONFIG`. |

### Local-only state

A fresh clone does not reproduce these ignored paths:

- `gh/`, `glab-cli/`: auth state. Never track `gh/hosts.yml` or `glab-cli/config.yml` tokens.
- `homebrew/`, `htop/`, `k9s/`, `lazygit/`, `openspec/config.json`: runtime,
  telemetry, or preferences.
- `goose/`: empty. No Brewfile entry or documented install step exists.

### Documentation and tooling

| Path | Purpose |
| --- | --- |
| `docs/` | Internal design and plan notes, not runtime config. |
| `llm/` | Global prompt library and policy. `nvim/lua/plugins/ai/codecompanion.lua` hardcodes `~/.dotfiles/llm/prompts/`, so the checkout must be `~/.dotfiles`. |
| `mac-setup/Brewfile` | Homebrew package bootstrap. |
| `.gitignore` | Machine-state, plugin-cache, and local-tool exclusions. |
| `README.md` | Install order, package methods, Stow, and tool setup. |

Scripts and registries under `scripts/`:

| File | Purpose |
| --- | --- |
| `install-ai-cli-dotfiles.sh` | Stow setup and skill/profile links. |
| `render-codex-config.py` | Merge shared and local TOML into `~/.codex/config.toml`. |
| `render-codex-agents.py` | Build untracked `~/.codex/AGENTS.override.md` from the tracked global `AGENTS.md` plus untracked `~/Workspace/AGENTS.md` work rules. Codex reads only the override, so rerun it after editing either file; `--check` reports a stale override. |
| `check-ai-cli.sh` | AI CLI lint and smoke checks. |
| `check-skills.sh` | Check `SKILL.md` presence, matching names, supported Codex products, nested skills, and links in all four installed layers. |
| `claude-project-only-skills.txt` | Exclude names globally and link them into this repo's `.claude/skills/`. |
| `claude-external-project-skills.txt` | Exclude names globally for per-machine linking into another repo. |
| `link-project-skill.sh` | Add or `--remove` one external repo's `.claude/skills/` and `.agents/skills/` links and local `.git/info/exclude` entries. No machine path is tracked here. |
| `test-prune-stray-skill-links.sh` | Test installer link pruning. |
| `test-codex-skill-scope.sh` | Test the Codex global selection. |
| `test-claude-project-only-skills.sh` | Test Claude project-only selection. |
| `test-link-project-skill.sh` | Test the external-repo link helper. |
| `skills-provenance-unresolved.txt` | Allowlist skills with no established upstream. |
| `audit-skills.sh` | Run `skill-security-auditor` and compare with `skills-audit-baseline.json`. |
| `skill-usage-report.py` | Count slash, named, auto, nested, and subagent activations in Claude/Codex sessions. Flag manual-only candidates and policy mismatches. |
| `mcp-call-report.py` | Count MCP call failures by class and schema state, and tool-search usage, in Claude Code transcripts and Codex sessions. |
| `dry-run-install.sh` | Check Stow and Zsh links in a fake `$HOME`. See README.md, "Verifying the install". |

## Build & Development Commands

There is no root package manifest, task runner, or CI file.
Use tool-native commands. Script tests are listed under [Testing Strategy](#testing-strategy).
Keep missing workflows as TODOs.

Install or bootstrap:

```sh
# Install Homebrew packages, applications, and fonts declared by the repo.
brew bundle --file mac-setup/Brewfile

# Create ~/.zshenv as a symlink to bootstrap/.zshenv.
stow --target "$HOME" bootstrap

# Link tracked Zsh startup files and install Oh My Zsh if missing.
zsh zsh/bootstrap.zsh

# Alacritty is a GUI app and never sees $XDG_CONFIG_HOME, so it needs its own
# Stow-backed symlink at ~/.config/alacritty.
bootstrap/install-alacritty.sh

# Install AI CLI agent dotfiles: backup, Stow `bootstrap`+`ai-agents` (folds
# ~/.claude/agents), render Codex config, and link all skills to Claude plus the same set to Codex (minus
# project-only and external-project names). --skills-only changes skill links without syncing MCP or config.
# Idempotent; moves real-file conflicts to a timestamped backup and never touches
# ~/.codex/skills/.system.
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

# Validate the skill layer: sources (SKILL.md, names, provenance) plus the installed
# ~/.agents, ~/.claude and ~/.codex link layers. --repo-only skips host-dependent checks.
scripts/check-skills.sh

# Security-audit all agent skills (skips *-workspace scratch dirs) and compare the
# verdicts with scripts/skills-audit-baseline.json; --update-baseline rewrites it.
scripts/audit-skills.sh

# Validate Stow-package and zsh startup symlinks against a throwaway fake $HOME;
# does not touch the real $HOME or install anything.
scripts/dry-run-install.sh
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

AI CLI: ai-agents/.agents/skills/ → ~/.claude/skills/ (all except claude-project-only and claude-external-project lists)
                                  ├→ ~/.agents/skills/ (Codex global selection)
                                  └→ .claude/skills/ (this repo only; claude-project-only-skills.txt)
        ~/.codex/skills/.system remains untouched
        ai-agents/.claude/agents/ (Stow fold)  → ~/.claude/agents/
        ai-agents/.codex/*.config.toml          → ~/.codex/ (child links)
```

### Codex config

- `render-codex-config.py` merges `config.shared.toml` and `~/.codex/config.local.toml`.
- Local values win, including `[mcp_servers.*]` values.
- Output: `~/.codex/config.toml`, mode `0600`.
- Tracked `ai-agents/.codex/*.config.toml` profiles and
  `ai-agents/.claude/settings.json` use `--skip-worktree` to hide runtime rewrites.
  Temporarily use `--no-skip-worktree` when editing defaults.
- The installer never replaces `~/.codex/skills/.system`.

### MCP sync

`scripts/install-ai-cli-dotfiles.sh` syncs Claude user-scope servers with
`claude mcp remove` and `claude mcp add-json -s user`. Sync is idempotent.
Claude has no declarative MCP config file; this JSON is the tracked source.

| Scope | Claude source | Codex source |
| --- | --- | --- |
| Shared | `ai-agents/.claude/mcp-servers.json` | `[mcp_servers.*]` in `config.shared.toml` |
| Machine-only | Ignored `ai-agents/.claude/mcp-servers.local.json`, same format, synced last | `[mcp_servers.*]` in `~/.codex/config.local.toml` |

Restart `claude` or `codex` after adding or changing an MCP server.

### Claude in Neovim

- CodeCompanion's `claude` profile requires `claude-code-acp`.
- `claudecode.nvim` requires only the `claude` CLI.

## Agent Skills: Naming and Layout

| Selection | Source | Installed location |
| --- | --- | --- |
| Claude global | All source skills except the two Claude exclusion lists | `~/.claude/skills/` |
| Claude, this repo only | `scripts/claude-project-only-skills.txt` | `.claude/skills/` |
| Another repo, per machine | `scripts/claude-external-project-skills.txt` and `link-project-skill.sh` | That repo's `.claude/skills/` and `.agents/skills/` |
| Codex global | `scripts/codex-global-skills.txt`, excluding project-only and external-project names | `~/.agents/skills/` |

- Claude loads project skills for sessions started inside that repository.
- Excluding a name globally hides it from other projects while keeping it available here.
- Do not rely on a project skill to override a personal skill with the same name.
  Claude gives the personal `~/.claude/skills/` copy precedence.
- Codex also reads repository-local `.agents/skills/`.

```
ai-agents/.agents/skills/<name>/SKILL.md  ← source of truth

scripts/install-ai-cli-dotfiles.sh creates:
~/.claude/skills/<name>  → .dotfiles/ai-agents/.agents/skills/<name>  (all except project-only and external-project)
~/.agents/skills/<name>  → .dotfiles/ai-agents/.agents/skills/<name>  (Codex global)
.claude/skills/<name>    → ai-agents/.agents/skills/<name>            (this repo; claude-project-only-skills.txt)
```

After changing skill links:

1. Run the installer to update the links.
2. Restart Claude Code and Codex.

The installer prunes old repository-managed `~/.codex/skills/` links.
It preserves `.system` and unrelated live links.
This repo's `.claude/skills/` is ignored by `/.claude/`, so installed links do not dirty Git.

To scope a skill into another repo, run this on each machine where that repo exists:

```sh
scripts/link-project-skill.sh <skill-name> <path-to-repo>
```

- Add the name to `scripts/claude-external-project-skills.txt` to stop global linking.
- The helper links directly from the source into the target repo's two skill directories.
- Targets are absolute paths into this checkout. The helper excludes links locally through
  the target repo's `.git/info/exclude`; no machine-specific repo path is tracked here.
- Use `--remove` to delete the links and their exclude entries.
- `claude-project-only-skills.txt` applies only to `~/.dotfiles`, whose path is fixed.

`arxiv-doc-builder` and `arxiv-search` are the exception to project-local placement:
they stay here, in the global Codex selection, so every repository under `~/Workspace` sees them.

Current placement decisions:

| Project | Placement |
| --- | --- |
| `.dotfiles` | `claude-automation-recommender`, `skill-param-auditor`, `skill-quality-reviewer`, `skill-security-auditor`, `skill-tester`; enforced for Claude by `scripts/claude-project-only-skills.txt`, not available to Codex here |
| `life-os` | `close-my-day`, `productivity-coach`, `define-goal`, `decision-cartesian-square` moved into that repo's `.agents/skills/`; no longer managed here |
| `knowledge-base` | `defuddle`, `zotero-obsidian-bridge`, `zotero-paper-reader` moved into that repo's `.agents/skills/`; no longer managed here |
| `markova.studio` | `analytics-tracking`, `customer-research`, `seo`, `seo-audit`, `yandex-metrica`; listed in `scripts/claude-external-project-skills.txt`, linked per machine with `link-project-skill.sh` |
| work repository (work machine only) | `build-engineering-self-presentation`; listed in `scripts/claude-external-project-skills.txt`, linked there with `link-project-skill.sh` |
| `finsight` and `finance-copilot` | `api-designer`, `api-design-reviewer`, `api-test-suite-builder`, `fastapi-python` stay global and manual-only, since both repos and any FastAPI project use them |

Run `link-project-skill.sh` for the `markova.studio` and work-repository rows on
each machine where that repository exists. Other specialized skills remain in the source catalog
and can be linked into a project when a concrete workflow calls for them.

Layout follows the [Agent Skills specification](https://agentskills.io/specification):

```
<skill>/
├── SKILL.md        # required; keep under 500 lines
├── references/     # documentation the agent reads on demand
├── scripts/        # executable code
├── assets/         # templates and static resources
└── README.md, LICENSE   # package-level files stay at the root
```

### Frontmatter and invocation

| Field | Constraint |
| --- | --- |
| `name` | Match the directory. Use lowercase letters, digits, and single hyphens. |
| `description` | At most 1024 characters. |
| `license` | Optional. |
| `compatibility` | Optional, at most 500 characters. |
| `metadata` | Optional, string values only. Put non-spec fields here. |
| `allowed-tools` | Optional, space-separated. |

Keep Claude's supported client fields at the top level:
`disable-model-invocation`, `argument-hint`, and `user-invocable`.

Keep the manual-only policies in sync:

- Claude: `disable-model-invocation: true` in `SKILL.md`.
- Codex: `policy.allow_implicit_invocation: false` in `agents/openai.yaml`.
  Codex ignores the Claude field. Its policy also removes the skill from its skill list.
- `scripts/skill-usage-report.py` labels disagreement as `mismatch`.

Link bundled files relative to the skill root, one level deep: `references/tests.md`.
`tessl review` cannot see a reference placed next to `SKILL.md`; it reports that link missing.

Naming convention for first-party skills: the directory name and the `name:` field in
`SKILL.md` frontmatter must carry a domain prefix:

| Prefix | Domain |
| --- | --- |
| `work-` | planning, reflection, and work processes |
| `writing` / `writing-` | Russian writing, text editing, and long-form documents (technical documentation, marketing content, plans) |
| `anthropic-` | skills imported from or based on Anthropic workflows |
| `python-` | Python coding conventions |
| `jira-` | Jira workflows |
| `git-` | Git repository and worktree workflows |
| `gitlab-` | GitLab workflows |
| `spirit-deploy` | deploy (single-skill domain) |
| `team-lead` | leading a task series through Codex and Claude executors (single-skill domain) |
| `hypothesis` | formulating, verifying, and reporting hypotheses (single-skill domain) |
| `excalidraw-diagram` | drawing diagrams on the ExcalidrawZ canvas via MCP (single-skill domain) |

Third-party imported skills keep their upstream names and are exempt unless a provider
prefix is needed to avoid a system-skill collision. The `obsidian-*` skills moved out of
this repo to the work vault (`~/Workspace/vault/.claude/skills/`).
Anthropic skill creator eval scratch dirs (`*-workspace/`) are git-ignored and not skills.

### Skill Routing

Active source skills where installed. "yes" means intended selection by description;
"manual" means intended explicit invocation by name. This table must agree with each
skill's `disable-model-invocation` frontmatter; neither value guarantees runtime selection.

| Trigger | Skill | Auto |
| --- | --- | --- |
| write or edit general Russian text, or make language-only edits to a document fragment | `writing` | yes |
| write in Alex's style when explicitly requested, alongside the task-specific skill | `draft-in-alex-style` | yes |
| distill raw thoughts or a voice-to-text transcript into clear text | `distill-thoughts` | yes |
| write a plan or design document | `writing-plans` | yes |
| Python code, docstrings, tests | `python-code-style` | yes |
| compare Python idioms or consult worked examples, explicitly | `python-patterns` | manual |
| plan a broad Python testing strategy, explicitly | `python-testing-patterns` | manual |
| inspect, create, reuse, sync, or clean up Git worktrees | `git-worktree` | yes |
| create, edit, or behaviorally evaluate a skill | `anthropic-skill-creator` | yes |
| audit skill for security | `skill-security-auditor` | manual |
| audit skill for hardcoded values, parameterization | `skill-param-auditor` | yes |
| review skill for predictability/quality (failure modes) | `skill-quality-reviewer` | manual |
| run bundled skill package/script validators or tier scoring | `skill-tester` | manual |
| 2+ independent tasks to parallelize | `dispatching-parallel-agents` | yes |
| build a Workflow script | `workflow-builder` | manual |
| lead a series of issues as Team Lead: delegate to Codex or Claude executors, review, merge | `team-lead` | yes |
| design a REST/GraphQL API, OpenAPI spec | `api-designer` | manual |
| review API design | `api-design-reviewer` | manual |
| CI/CD pipeline setup | `ci-cd-pipeline-builder` | manual |
| SQL queries, schema exploration, ORM integration | `sql-database-assistant` | manual |
| PostgreSQL-specific design, diagnosis, or optimization | `postgres-engineer` | manual |
| high-risk database, system, or infrastructure migration and rollback | `migration-architect` | manual |
| relational schema or ERD, cross-database architecture, SQL versus NoSQL, or multi-engine physical design | `database-designer` | manual |
| build an MCP server without an OpenAPI contract | `mcp-builder` | manual |
| generate an MCP server from an existing OpenAPI contract | `mcp-server-builder` | manual |
| design one agent tool's schema, description, or error contract | `tool-design` | manual |
| observability, SLO, metrics | `observability-designer` | manual |
| chaos experiments, fault injection, game days, blast radius | `chaos-engineering` | manual |
| improve code architecture | `improve-codebase-architecture` | manual |
| microservices, monolith decomposition, bounded contexts, DDD | `microservices-architect` | manual |
| build a CLI tool: arg parsing, shell completions, terminal UX | `cli-developer` | manual |
| security review | `security-guidance` | yes |
| tech debt audit | `tech-debt-tracker` | manual |
| generate a runbook | `runbook-generator` | manual |
| audit and trim repository docs, AGENTS.md, rules, skills, prompts | `audit-repository-documentation` | yes |
| write, edit, or review technical documentation (tutorial, how-to, reference, API/CLI, troubleshooting, README, runbook) | `writing-technical-documentation` | yes |
| plan, write, edit, or review technical marketing content (blog post, case study, white paper, landing page, announcement) | `writing-technical-marketing-content` | yes |
| create or substantially restructure an RFC or ADR from source material | `rfc-authoring` | yes |
| formulate, verify, or re-assess hypotheses and report on them (reviews, RFC, experiment plans, goals) | `hypothesis` | yes |
| create or quickly refine a one-off task prompt for a capable model | `create-prompt` | yes |
| design a reusable, system, or production-model prompt | `prompt-design` | yes |
| review an existing prompt with findings and a verdict, on explicit request | `prompt-design` (review mode) | yes |
| build, personalize, or research a learning roadmap, study plan, or curriculum | `create-learning-roadmap` | manual |
| learn a concept through Socratic dialogue, graduated hints, or guided discovery | `teach-through-dialogue` | manual |
| save a topic to study later, list, review, update, or export learning-backlog entries | `learning-backlog` | yes |
| create UML diagrams (class, sequence, activity, etc.) via PlantUML, including ASCII/text output | `uml` | yes |
| draw a diagram on the ExcalidrawZ canvas, or any `create_view` call of the excalidrawz MCP | `excalidraw-diagram` | yes |
| changelog or release notes | `changelog-generator` | manual |
| Yandex Metrica API: stats, goals, counters, log export | `yandex-metrica` | manual |
| set up or audit analytics tracking (GA4, GTM, events) | `analytics-tracking` | manual |
| TDD, test-first development, red-green-refactor | `test-driven-development` | yes |
| design a complex or materially uncertain change before implementation | `brainstorming` | yes |
| structured brainstorm | `six-thinking-hats` | manual |
| execute a step-by-step plan | `executing-plans` | yes |
| execute a plan task-by-task via subagents | `subagent-driven-development` | yes |
| onboard to a codebase | `codebase-onboarding` | manual |

Choose the skill-review route:

- Inline: invoke `/skill-quality-reviewer`, also available from Codex.
- Isolated context: dispatch the Claude-only `@skill-reviewer` declared in
  `ai-agents/.claude/agents/skill-reviewer.md`. It reads the review skill's `SKILL.md`
  and `references/GLOSSARY.md`. The doctrine remains in that skill.

Vault skills (`~/Workspace/vault/.claude/skills/`) are not listed here; they have their own routing in the vault's CLAUDE.md.

> TODO: Rename the unprefixed first-party skills to follow the convention: `wiki`,
> `daas-k8s-debug`, `incident-triage`, `time-messenger`.

### Skill Provenance

Every `SKILL.md` declares where its text came from, in the frontmatter `metadata`
block. `scripts/check-skills.sh` enforces it:

```yaml
metadata:
  origin: vendored          # first-party | vendored | derived | unresolved
  upstream: https://github.com/owner/repo/tree/main/skills/name  # required for vendored/derived
  upstream_note: "content-identical copy; the original publisher was not established"
  imported_at: 2026-06-19   # date of the commit that added it here
```

- `first-party` - written in this repository. No upstream.
- `vendored` - copied from upstream; the local text still matches it closely.
- `derived` - based on upstream but reworked here.
- `unresolved` - the upstream was searched for and not found. Accepted only for
  the names in `scripts/skills-provenance-unresolved.txt`; every other skill
  declaring it fails the check, and so does a stale line in that file.

The provenance lives in the skill rather than in a separate registry so a skill
directory stays self-describing. When re-importing an upstream version, re-apply
these keys - they are local additions and upstream will not carry them.

Rename checklist (every step is required, the link layers break silently):

1. Rename the directory under `ai-agents/.agents/skills/`.
2. Update `name:` in the skill's `SKILL.md` frontmatter.
3. Update `scripts/codex-global-skills.txt` if the skill is in Codex's global set,
   `scripts/claude-project-only-skills.txt` if it is project-only for Claude, and
   `scripts/claude-external-project-skills.txt` if it is linked into another repo
   (then relink it there with `link-project-skill.sh`).
4. Rerun `scripts/install-ai-cli-dotfiles.sh --skills-only` to update Claude and
   Codex links.
5. Update cross-references to the old name in other `SKILL.md` files.
6. Run `scripts/check-skills.sh` to confirm source names and installed link scopes.
7. Restart Claude Code and Codex so the renamed skill is picked up.

## Testing Strategy

- Unit tests: `scripts/test-prune-stray-skill-links.sh` covers the installer's link
  pruning (sourcing the installer does not run it; `main` is guarded),
  `scripts/test-codex-skill-scope.sh` the Codex global selection,
  `scripts/test-claude-project-only-skills.sh` the Claude project-only and
  external-project selections and their migration, and `scripts/test-link-project-skill.sh` the external-repo link
  helper. `scripts/check-ai-cli.sh` runs all four. No other first-party unit test
  suite is documented.
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
  shell env – never commit it. ACP also works without it on an interactive subscription.
- Treat `.pyenv/`, `tmux/plugins/*`, ignored Zsh plugin checkouts, shell history, htop
  config, and local-only CLI configs as machine state unless the user explicitly asks to
  version them.
- Keep `wiki@llm-wiki` (marketplace `nvk/llm-wiki`) disabled globally in Claude
  and Codex. Enable it only in `~/Projects/llm-wiki/.claude/settings.local.json`
  and `~/Projects/llm-wiki/.codex/config.toml`.
  Its 0.25.0 Claude build ships no hooks, so the target project's local Claude
  settings wire `ai-agents/.claude/hooks/llm-wiki-session.sh` on the same events
  as the plugin's Codex `hooks.json`. Keep this wiring out of global settings.
  The helper records redacted events into `<HUB>/.sessions/` (HUB from
  `~/.config/llm-wiki/config.json`) and may inject digests as context.
  Turn capture off with the
  helper's `disable` command and per-prompt rehydration with
  `rehydrate.user_prompt` in `<HUB>/.sessions/config.json`; neither lives in this repo.
- `ai-agents/.claude/rules/local/` is gitignored and holds machine- or workspace-specific
  Claude rules, such as a symlink to a rule file that lives in another private repo.
  `~/.claude/rules` is a whole-directory Stow link to `ai-agents/.claude/rules/`, so
  anything placed under `local/` is still loaded by Claude without a machine-specific path
  landing in this shared repo. Do not commit symlinks or machine-specific paths under
  `ai-agents/.claude/rules/` outside of `local/`.
- Never track Codex/Claude secrets or runtime state: `auth.json`, `*.sqlite*`, `history*`,
  `sessions/`, `cache/`, `logs/`, `~/.claude.json`, the rendered `~/.codex/config.toml`, or
  `~/.codex/config.local.toml`. The `.gitignore` already excludes these under `ai-agents/`.
- Codex project trust entries (`[projects."..."]`) belong only in `~/.codex/config.local.toml`;
  keep them out of `config.shared.toml` and the tracked `*.config.toml` profiles.
- `ai-agents/.claude/settings.json` and `ai-agents/.codex/*.config.toml` profiles are held with
  `git update-index --skip-worktree` because Codex and Claude write runtime state (model choices,
  project trust, TUI NUX) back into these files via their symlinks. To change tracked defaults:
  temporarily `--no-skip-worktree`, edit, commit, then re-apply `--skip-worktree`.
- `ai-agents/.agents/skills/yandex-metrica/config/.env` holds a Yandex OAuth token. The
  skill's own `.gitignore` keeps it and `cache/*.json` untracked; never commit either.
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
| Codex global skill selection | `scripts/codex-global-skills.txt` | Claude receives all source skills except project-only and external-project ones |
| Claude project-only skill selection | `scripts/claude-project-only-skills.txt` | Linked instead into this repo's own `.claude/skills/` |
| Skill scoped into another project repo | `scripts/claude-external-project-skills.txt` + `scripts/link-project-skill.sh <skill> <path>` | The list is tracked; the link is machine-local |
| Claude subagent | `ai-agents/.claude/agents/<name>.md` | Stow-folded to `~/.claude/agents/` |
| Codex reasoning profile | `ai-agents/.codex/<name>.config.toml` | Symlinked to `~/.codex/` |
| Codex shared settings | `ai-agents/.codex/config.shared.toml` | Machine-local values in `config.local.toml` |
| Codex MCP server | `ai-agents/.codex/config.shared.toml` `[mcp_servers.<name>]` | Rendered by `render-codex-config.py` |
| Claude MCP server | `ai-agents/.claude/mcp-servers.json` | Synced to user scope by `scripts/install-ai-cli-dotfiles.sh` |
| Machine-local MCP server | `ai-agents/.claude/mcp-servers.local.json` (Claude), `~/.codex/config.local.toml` (Codex) | Gitignored / outside the repo; not present on other machines |
| CodeCompanion AI profile | `nvim/lua/config/ai/codecompanion_profiles.lua` | |
| Neovim plugin | `nvim/lua/plugins/` domain subdir | AstroCommunity in `community.lua` |
| tmux plugin | `tmux/tmux.conf` | `set -g @plugin ...` |
| Homebrew package | `mac-setup/Brewfile` | |
| Shell entrypoint | `bootstrap/.zshenv` / `zsh/bootstrap.zsh` | |
| Starship module | `starship.toml` | |
| Terminal config | `alacritty/` | |
| Skill invariants | `scripts/check-skills.sh` | Names, SKILL.md presence, Codex products, installed link layers |
| Install validation | `scripts/dry-run-install.sh` | Fake-`$HOME` symlink check; full VM run documented in README.md "Verifying the install" |

Environment variables are the main feature flags: XDG paths in `zsh/.zshenv`, AI profile variables in CodeCompanion config.

## Further Reading

- [~/Workspace/vault/WHO_I_AM.md](~/Workspace/vault/WHO_I_AM.md) - who the user is, role,
  and work activities (DWSAI project vs InnerSource). Local-only, not part of this repo.
- [README.md](README.md) - manual macOS setup notes.
- [scripts/install-ai-cli-dotfiles.sh](scripts/install-ai-cli-dotfiles.sh) and
  [scripts/render-codex-config.py](scripts/render-codex-config.py) - AI CLI install chain.
- [llm/PROMPT_POLICY.md](llm/PROMPT_POLICY.md) - prompt-system policy.
- [nvim/lua/config/ai/codecompanion_profiles.lua](nvim/lua/config/ai/codecompanion_profiles.lua) - AI profile selection.

> TODO: Add deeper architecture docs such as `docs/ARCH.md` or ADRs when they exist.
