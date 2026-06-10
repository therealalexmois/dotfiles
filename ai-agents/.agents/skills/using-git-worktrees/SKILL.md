---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace, before executing implementation plans, when running 2+ concurrent branches as isolated local apps, or when cleaning up stale worktrees - ensures isolation via native tools or git fallback, with optional deterministic port allocation, env sync, and safe cleanup
---

# Using Git Worktrees

## Overview

Ensure work happens in an isolated workspace. Prefer your platform's native worktree tools. Fall back to manual git worktrees only when no native tool is available. For sustained parallel development across several branches, manage ports, env, and cleanup with the bundled scripts.

**Core principle:** Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness.

**Two modes:**
- **Mode A - Isolate the current task (default).** You need one clean workspace for the feature or plan in front of you. Follow Step 0 through Step 4. Prefer native tools; the bundled scripts are not needed.
- **Mode B - Run multiple concurrent worktrees as isolated apps.** You need 2+ branches live at once with isolated dev servers, env files, and repeatable cleanup. Use the bundled `scripts/worktree_manager.py` and `scripts/worktree_cleanup.py`. See [Concurrent Worktrees](#concurrent-worktrees-mode-b) and [Lifecycle and Cleanup](#lifecycle-and-cleanup).

Mode B runs `git worktree add` directly, so it does not defer to a native harness worktree tool. Use it only when you specifically need the multi-worktree dev environment management (ports, env sync, cleanup) that native tools do not provide. If your harness has a native worktree tool and you only need task isolation, stay in Mode A.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Step 0: Detect Existing Isolation

**Before creating anything, check if you are already in an isolated workspace.**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside git submodules. Before concluding "already in a worktree," verify you are not in a submodule:

```bash
# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 3 (Project Setup). Do NOT create another worktree.

Report with branch state:
- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

**If `GIT_DIR == GIT_COMMON` (or in a submodule):** You are in a normal repo checkout.

Has the user already indicated their worktree preference in your instructions? If not, ask for consent before creating a worktree:

> "Would you like me to set up an isolated worktree? It protects your current branch from changes."

Honor any existing declared preference without asking. If the user declines consent, work in place and skip to Step 3.

## Step 1: Create Isolated Workspace

**You have two mechanisms. Try them in this order.**

### 1a. Native Worktree Tools (preferred)

The user has asked for an isolated workspace (Step 0 consent). Do you already have a way to create a worktree? It might be a tool with a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag. If you do, use it and skip to Step 3.

Native tools handle directory placement, branch creation, and cleanup automatically. Using `git worktree add` when you have a native tool creates phantom state your harness can't see or manage.

Only proceed to Step 1b if you have no native worktree tool available.

### 1b. Git Worktree Fallback

**Only use this if Step 1a does not apply** — you have no native worktree tool available. Create a worktree manually using git.

#### Directory Selection

Follow this priority order. Explicit user preference always beats observed filesystem state.

1. **Check your instructions for a declared worktree directory preference.** If the user has already specified one, use it without asking.

2. **Check for an existing project-local worktree directory:**
   ```bash
   ls -d .worktrees 2>/dev/null     # Preferred (hidden)
   ls -d worktrees 2>/dev/null      # Alternative
   ```
   If found, use it. If both exist, `.worktrees` wins.

3. **Check for an existing global directory:**
   ```bash
   project=$(basename "$(git rev-parse --show-toplevel)")
   ls -d ~/.config/superpowers/worktrees/$project 2>/dev/null
   ```
   If found, use it (backward compatibility with legacy global path).

4. **If there is no other guidance available**, default to `.worktrees/` at the project root.

#### Safety Verification (project-local directories only)

**MUST verify directory is ignored before creating worktree:**

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**If NOT ignored:** Add to .gitignore, commit the change, then proceed.

**Why critical:** Prevents accidentally committing worktree contents to repository.

Global directories (`~/.config/superpowers/worktrees/`) need no verification.

#### Create the Worktree

```bash
project=$(basename "$(git rev-parse --show-toplevel)")

# Determine path based on chosen location
# For project-local: path="$LOCATION/$BRANCH_NAME"
# For global: path="~/.config/superpowers/worktrees/$project/$BRANCH_NAME"

git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

**Sandbox fallback:** If `git worktree add` fails with a permission error (sandbox denial), tell the user the sandbox blocked worktree creation and you're working in the current directory instead. Then run setup and baseline tests in place.

## Step 3: Project Setup

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

## Step 4: Verify Clean Baseline

Run tests to ensure workspace starts clean:

```bash
# Use project-appropriate command
npm test / cargo test / pytest / go test ./...
```

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### Report

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Concurrent Worktrees (Mode B)

Use this when you need several branches live at once as isolated local apps: parallel features, a hotfix while a feature branch is dirty, PR validation, or multiple agents that must not share a branch.

The bundled `scripts/worktree_manager.py` creates a worktree (new or existing branch), allocates non-conflicting ports, syncs `.env*` files from the main repo, and optionally installs dependencies.

```bash
python scripts/worktree_manager.py \
  --repo . \
  --branch feature/new-auth \
  --name wt-auth \
  --base-branch main \
  --install-deps \
  --format text
```

JSON automation input is also accepted via stdin or `--input`:

```bash
cat config.json | python scripts/worktree_manager.py --format json
python scripts/worktree_manager.py --input config.json --format json
```

**Placement note:** the manager creates the worktree as a sibling of the repo (`<repo-parent>/<name>`), not inside `.worktrees/`. A sibling directory lives outside the repo, so it does not need a `.gitignore` entry, but it does differ from the Mode A `.worktrees/` convention. If you need in-repo placement, use the Step 1b manual flow instead.

**Ports.** Each worktree gets a deterministic, collision-checked port map persisted as `.worktree-ports.json`. Defaults: app `3000`, postgres `5432`, redis `6379`, stride `10`, so slot `n` is `base + n*stride`. The manager reads existing `.worktree-ports.json` files and skips occupied slots. Override bases with `--app-base/--db-base/--redis-base/--stride`. See [references/port-allocation-strategy.md](references/port-allocation-strategy.md).

**Env and deps.** `.env`, `.env.local`, `.env.development`, and `.envrc` are copied from the main repo when present. `--install-deps` runs the first matching lockfile command (pnpm, yarn, npm, bun, pip). Without the flag, install is skipped.

**Docker Compose.** Map the allocated ports into per-worktree overrides or a unique compose project name to avoid container, network, and volume collisions. See [references/docker-compose-patterns.md](references/docker-compose-patterns.md).

**Naming convention.** One branch per worktree, one agent per worktree. Use a deterministic `wt-<topic>` (or `wt-<task-id>-<topic>`) name so the path maps to the task.

## Lifecycle and Cleanup

Keep worktrees short-lived; remove them after merge. Use `scripts/worktree_cleanup.py` instead of ad-hoc `rm -rf`. It reports each worktree's age, dirty state, and merge status, and optionally removes only worktrees that are stale, clean, and merged.

```bash
# Report only (no changes)
python scripts/worktree_cleanup.py --repo . --stale-days 14 --format text

# Remove stale + clean + merged worktrees
python scripts/worktree_cleanup.py --repo . --remove-merged --base-branch main --format text
```

**Safety contract:**
- Merge status is checked with `git merge-base --is-ancestor <branch> <base-branch>`, not assumed.
- The main worktree is never removed.
- Dirty worktrees are never removed unless you pass `--force`. Only force when the changes are intentionally discarded.
- After deleting branches outside the script, run `git worktree prune` to clear stale metadata.

**Before removal, confirm:**
1. The branch is merged when removal is intended (or you accept discarding it).
2. No uncommitted files remain (cleanup reports `dirty`).
3. No running containers or processes still depend on the worktree path.

## Validation Checklist (Mode B)

Before claiming a concurrent-worktree setup complete:

1. `git worktree list` shows the expected path and branch.
2. `.worktree-ports.json` exists and contains unique ports.
3. `.env*` files copied successfully (if present in the source repo).
4. Dependency install exited `0` (if `--install-deps` was used).
5. Cleanup scan reports no unintended stale dirty trees.

## Quick Reference

| Situation | Action |
|-----------|--------|
| Already in linked worktree | Skip creation (Step 0) |
| In a submodule | Treat as normal repo (Step 0 guard) |
| Native worktree tool available | Use it (Step 1a) |
| No native tool, single task | Git worktree fallback (Step 1b) |
| 2+ concurrent branches / isolated servers | Mode B manager script |
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check instruction file, then default `.worktrees/` |
| Global path exists | Use it (backward compat) |
| Directory not ignored | Add to .gitignore + commit |
| Permission error on create | Sandbox fallback, work in place |
| Port collides with external service | Rerun manager with adjusted `--*-base` |
| Stale / merged worktrees pile up | Cleanup script (`--stale-days`, `--remove-merged`) |
| Tests fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Skip dependency install |

## Decision Matrix

- Need a single clean workspace for the current task -> Mode A (Steps 0-4).
- Need isolated dependencies and server ports for several branches -> Mode B, create a worktree per branch.
- Need only a quick local diff review -> stay on the current tree.
- Need a hotfix while the feature branch is dirty -> dedicated hotfix worktree.
- Need an ephemeral reproduction branch for bug triage -> temporary worktree, clean up the same day.

## Common Mistakes

### Fighting the harness

- **Problem:** Using `git worktree add` (or the Mode B scripts) when the platform already provides isolation
- **Fix:** Step 0 detects existing isolation. Step 1a defers to native tools. Reach for Mode B only for genuine multi-worktree dev environment needs.

### Skipping detection

- **Problem:** Creating a nested worktree inside an existing one
- **Fix:** Always run Step 0 before creating anything

### Skipping ignore verification

- **Problem:** Worktree contents get tracked, pollute git status
- **Fix:** Always use `git check-ignore` before creating a project-local worktree

### Assuming directory location

- **Problem:** Creates inconsistency, violates project conventions
- **Fix:** Follow priority: existing > global legacy > instruction file > default

### Port and env collisions (Mode B)

- **Problem:** Reusing `localhost:3000` or one database URL across branches
- **Fix:** Let the manager allocate ports per worktree; isolate DB/cache endpoints and persist `.worktree-ports.json`

### Unsafe cleanup

- **Problem:** Removing a worktree with uncommitted changes, or assuming merged status
- **Fix:** Use the cleanup script; never `--force` over dirty trees unless discarding; verify merge with `merge-base`

### Proceeding with failing tests

- **Problem:** Can't distinguish new bugs from pre-existing issues
- **Fix:** Report failures, get explicit permission to proceed

## Failure Recovery

- `git worktree add` fails on an existing path: inspect the path, do not overwrite.
- Dependency install fails: keep the worktree, mark status, continue manual recovery.
- Env copy fails: continue with a warning and an explicit list of missing files.
- Port allocation collides with an external service: rerun with adjusted `--*-base` ports.

## Red Flags

**Never:**
- Create a worktree when Step 0 detects existing isolation
- Use `git worktree add` (or Mode B scripts) when you have a native worktree tool and only need task isolation. This is the #1 mistake — if you have it, use it.
- Skip Step 1a by jumping straight to Step 1b's git commands
- Create a worktree without verifying it's ignored (project-local)
- Skip baseline test verification
- Proceed with failing tests without asking
- Force-remove a dirty worktree unless the changes are intentionally discarded

**Always:**
- Run Step 0 detection first
- Prefer native tools over git fallback
- Follow directory priority: existing > global legacy > instruction file > default
- Verify directory is ignored for project-local
- Auto-detect and run project setup
- Verify clean test baseline
- For Mode B, allocate ports per worktree and clean up with the cleanup script
