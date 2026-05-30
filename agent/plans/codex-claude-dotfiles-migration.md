# Codex and Claude Dotfiles Migration Plan

## Current state

- `.dotfiles` already serves as the main dotfiles repository.
- `~/.zshenv` is a symlink to `.dotfiles/bootstrap/.zshenv`.
- `bootstrap/.zshenv` sets `ZDOTDIR="$HOME/.dotfiles/zsh"` and sources `.dotfiles/zsh/.zshenv`.
- That zsh model should stay unchanged.
- `~/.codex/config.toml` mixes shared settings and local project-trust entries.
- `~/.codex/AGENTS.md` exists as a regular file and contains user-level Codex instructions.
- `~/.claude/settings.json` contains safe UI/plugin settings.
- `~/.claude/CLAUDE.md` exists as a separate file and differs from `~/.codex/AGENTS.md`.
- `~/.codex/skills` and `~/.claude/skills` are real directories, not symlinks.
- `~/.codex/skills/.system` exists, so the whole Codex skills tree must not be replaced by one symlink.
- `.codex` and `.claude` contain runtime state: auth, sessions, history, cache, logs, sqlite, snapshots, and plugin cache.
- `stow` is installed.
- `skills` and `skills.sh` are not in the current `PATH`, so the migration should not depend on those commands being globally available.

## Recommended structure

```text
~/.dotfiles/
  codex/
    .codex/
      AGENTS.md
      config.shared.toml
      config.local.toml.example

  claude/
    .claude/
      CLAUDE.md
      settings.json

  skills/
    shared/
      engineering-review/
      prd/
      russian-technical-editor/
      to-jira-issues/

    codex-only/
      cli-creator/
      define-goal/

    claude-only/
      codebase-onboarding/
      find-skills/
      python-docstring-editor/
      skill-creator/
      to-prd/

  scripts/
    render-codex-config.py
    install-ai-cli-dotfiles.sh

  docs/
    plans/
      codex-claude-dotfiles-migration.md
```

## Files to track

Track only durable config and reusable skills:

- `codex/.codex/AGENTS.md`
- `codex/.codex/config.shared.toml`
- `codex/.codex/config.local.toml.example`
- `claude/.claude/CLAUDE.md`
- `claude/.claude/settings.json`
- `skills/shared/**`
- `skills/codex-only/**`
- `skills/claude-only/**`
- `scripts/render-codex-config.py`
- `scripts/install-ai-cli-dotfiles.sh`
- `docs/plans/codex-claude-dotfiles-migration.md`

`config.shared.toml` should contain:

- `model = "gpt-5.5"`
- `model_reasoning_effort = "medium"`
- `plan_mode_reasoning_effort = "high"`
- `approval_policy = "on-request"`
- `sandbox_mode = "workspace-write"`
- `web_search = "cached"`
- `[sandbox_workspace_write] network_access = false`
- `[tui]` settings
- curated plugins:
  - `atlassian-rovo@openai-curated`
  - `google-calendar@openai-curated`
  - `google-drive@openai-curated`
- `[mcp_servers.context7]`

Do not track `[projects."/Users/..."]` in shared config.

## Files to keep local

Keep these outside Git:

- `~/.codex/auth.json`
- `~/.codex/sessions/`
- `~/.codex/history*`
- `~/.codex/cache/`
- `~/.codex/logs*`
- `~/.codex/*.sqlite*`
- `~/.codex/state_*`
- `~/.codex/goals_*`
- `~/.codex/memories*`
- `~/.codex/plugins/cache/`
- `~/.codex/.tmp/`
- `~/.codex/tmp/`
- `~/.codex/shell_snapshots/`
- `~/.codex/packages/`
- `~/.codex/models_cache.json`
- `~/.codex/installation_id`
- `~/.codex/version.json`
- `~/.codex/config.local.toml`
- generated `~/.codex/config.toml`
- `~/.claude.json`
- `~/.claude/projects/`
- `~/.claude/sessions/`
- `~/.claude/session-env/`
- `~/.claude/cache/`
- `~/.claude/paste-cache/`
- `~/.claude/shell-snapshots/`
- `~/.claude/telemetry/`
- `~/.claude/history*`
- `~/.claude/file-history/`
- `~/.claude/downloads/`
- `~/.claude/backups/`
- `~/.claude/stats-cache.json`
- `~/.claude/.last-*`
- `~/.claude/plugins/cache/`
- `~/.claude/plugins/data/`
- `~/.claude/plugins/marketplaces/`

## Gitignore additions

Add these patterns to `.dotfiles/.gitignore`:

```gitignore
# Codex local/runtime state
codex/.codex/config.toml
codex/.codex/config.local.toml
codex/.codex/auth.json
codex/.codex/history*
codex/.codex/sessions/
codex/.codex/cache/
codex/.codex/logs*/
codex/.codex/*.sqlite*
codex/.codex/state_*
codex/.codex/goals_*
codex/.codex/memories*
codex/.codex/plugins/cache/
codex/.codex/.tmp/
codex/.codex/tmp/
codex/.codex/shell_snapshots/
codex/.codex/packages/
codex/.codex/models_cache.json
codex/.codex/installation_id
codex/.codex/version.json

# Claude local/runtime state
.claude.json
claude/.claude/history*
claude/.claude/cache/
claude/.claude/projects/
claude/.claude/sessions/
claude/.claude/session-env/
claude/.claude/paste-cache/
claude/.claude/shell-snapshots/
claude/.claude/telemetry/
claude/.claude/file-history/
claude/.claude/downloads/
claude/.claude/backups/
claude/.claude/stats-cache.json
claude/.claude/.last-*
claude/.claude/plugins/cache/
claude/.claude/plugins/data/
claude/.claude/plugins/marketplaces/

# Skill manager/runtime state
skills/**/.system/
```

## GNU Stow model

Use Stow for stable file locations:

```sh
cd ~/.dotfiles
stow --target "$HOME" bootstrap codex claude
```

Use separate Stow commands for skill child directories:

```sh
stow --dir "$HOME/.dotfiles/skills" --target "$HOME/.codex/skills" shared codex-only
stow --dir "$HOME/.dotfiles/skills" --target "$HOME/.claude/skills" shared claude-only
```

Do not symlink:

- all of `~/.codex`;
- all of `~/.claude`;
- all of `~/.codex/skills`.

This keeps Codex runtime state and `.system` skills local.

## Shared skills

Use `.dotfiles/skills/shared` as the shared source of truth.

Recommended initial classification:

- shared:
  - `engineering-review`
  - `prd`
  - `russian-technical-editor`
  - `to-jira-issues`
- Codex-only:
  - `cli-creator`
  - `define-goal`
- Claude-only:
  - `codebase-onboarding`
  - `find-skills`
  - `python-docstring-editor`
  - `skill-creator`
  - `to-prd`

Before replacing existing skill directories, create backups. Then remove only migrated skill directories from `~/.codex/skills` and `~/.claude/skills`, and let Stow create symlinks for those child directories.

## Codex config render

`~/.codex/config.toml` should be generated, not tracked.

Inputs:

- shared: `~/.codex/config.shared.toml`
- local: `~/.codex/config.local.toml`

Local file example:

```toml
[projects."/Users/al.a.moiseenko/work/dwsai-data-agent"]
trust_level = "trusted"

[projects."/Users/al.a.moiseenko/projects/work-vault"]
trust_level = "trusted"

[projects."/Users/al.a.moiseenko/.codex"]
trust_level = "trusted"

[projects."/Users/al.a.moiseenko"]
trust_level = "trusted"
```

`render-codex-config.py` should:

- use Python stdlib only;
- parse TOML with `tomllib`;
- merge shared and local tables recursively;
- let local scalar/list values override shared values;
- write `~/.codex/config.toml` atomically;
- set output permissions to `0600`;
- fail loudly on invalid TOML.

## Migration plan

1. Create timestamped backups of:
   - `~/.codex/config.toml`
   - `~/.codex/AGENTS.md`
   - `~/.codex/skills`
   - `~/.claude/settings.json`
   - `~/.claude/CLAUDE.md`
   - `~/.claude/skills`
2. Create the proposed `.dotfiles` directories.
3. Copy `~/.codex/AGENTS.md` to `codex/.codex/AGENTS.md`.
4. Split `~/.codex/config.toml`:
   - shared settings into `codex/.codex/config.shared.toml`;
   - project trust entries into local `~/.codex/config.local.toml`.
5. Copy `~/.claude/CLAUDE.md` to `claude/.claude/CLAUDE.md`.
6. Copy `~/.claude/settings.json` to `claude/.claude/settings.json`.
7. Move selected skills into `skills/shared`, `skills/codex-only`, and `skills/claude-only`.
8. Add `.gitignore` rules for runtime state and local config.
9. Add `render-codex-config.py`.
10. Add `install-ai-cli-dotfiles.sh` as an idempotent wrapper around:
    - Stow dry-run;
    - Stow apply;
    - Codex config render;
    - basic validation.
11. Run Stow dry-run.
12. Resolve conflicts manually if Stow reports existing real files.
13. Run Stow apply.
14. Render `~/.codex/config.toml`.
15. Validate links, generated TOML, skills, and Git tracking.
16. Repeat on the second laptop:
    - pull `.dotfiles`;
    - create local `~/.codex/config.local.toml`;
    - run Stow and render script.

## Validation commands

Run from `~/.dotfiles`:

```sh
stow -n -v --target "$HOME" bootstrap codex claude
stow -n -v --dir "$HOME/.dotfiles/skills" --target "$HOME/.codex/skills" shared codex-only
stow -n -v --dir "$HOME/.dotfiles/skills" --target "$HOME/.claude/skills" shared claude-only
```

Validate generated Codex config:

```sh
python3 -c 'import tomllib, pathlib; tomllib.load(open(pathlib.Path.home()/".codex/config.toml","rb")); print("codex toml ok")'
```

Validate symlinks:

```sh
test -L ~/.codex/AGENTS.md && readlink ~/.codex/AGENTS.md
test -L ~/.claude/CLAUDE.md && readlink ~/.claude/CLAUDE.md
find ~/.codex/skills -maxdepth 1 -type l -print
find ~/.claude/skills -maxdepth 1 -type l -print
```

Check that secrets and runtime state are not tracked:

```sh
git -C ~/.dotfiles ls-files | rg '(^|/)(auth\.json|history|sessions|cache|logs|\.claude\.json|config\.local\.toml|.*\.sqlite)'
git -C ~/.dotfiles status --short
```

Expected result:

- TOML parses successfully.
- `AGENTS.md` and `CLAUDE.md` are symlinks into `.dotfiles`.
- Migrated skills are symlinks.
- Sensitive search prints nothing.
- Git status contains only intended files.

## Risks and rollback

Risks:

- Stow can conflict with existing real files.
- Replacing the whole `~/.codex/skills` would hide `.system`; avoid this.
- Some skills may be agent-specific even if their format looks shared.
- Claude plugin settings may require separate plugin installation on each laptop.
- Local project trust entries can accidentally leak if copied into shared config.

Rollback:

```sh
cd ~/.dotfiles
stow -D --target "$HOME" codex claude
stow -D --dir "$HOME/.dotfiles/skills" --target "$HOME/.codex/skills" shared codex-only
stow -D --dir "$HOME/.dotfiles/skills" --target "$HOME/.claude/skills" shared claude-only
```

Then restore backed-up files and directories:

- `~/.codex/config.toml`
- `~/.codex/AGENTS.md`
- `~/.codex/skills`
- `~/.claude/settings.json`
- `~/.claude/CLAUDE.md`
- `~/.claude/skills`

Do not roll back `bootstrap` unless zsh bootstrap itself becomes part of the failure.
