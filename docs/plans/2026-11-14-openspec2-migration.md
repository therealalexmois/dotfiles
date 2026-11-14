# OpenSpec 2 Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate existing OpenSpec integrations to CLI 2.0 without changing authored specifications or unrelated work.

**Architecture:** Generate canonical skills in `.agents/skills` and Claude links with `openspec update`. Adapt each repository's existing synchronization path to retain that layout. Run actual updates sequentially because OpenSpec shares global configuration.

**Tech Stack:** OpenSpec 2.0.0, Git worktrees, existing Python and shell synchronization tools.

**Spec:** The user's migration request in this session and https://openspec.dev/docs/upgrade-to-2.

## Global Constraints

- Work only in wrapper-created `chore/openspec2-migration` worktrees.
- Preserve the 11 configured workflows and authored config, schemas, specs and archives.
- Preserve main checkouts, unrelated changes and existing worktrees.
- Do not call financial services or change databases. Delivery commits/PRs/merge were separately authorized after implementation; FinSight remains open by owner decision.
- Skip life-os: its OpenSpec integration was intentionally removed in commit `3ac7cc4`.

## Review Focus

- Local edits inside canonical generated skills: check dry-run notes and retain a recovery copy before generation.
- Claude links: verify they resolve to this project's canonical skills, including from a worktree.
- Old command synchronization: prove a subsequent sync does not recreate `/opsx` commands or remove OpenSpec links.
- Workflow profile: verify all 11 selected workflows remain installed.
- Existing validation warnings: compare with baseline instead of rewriting authored specifications.

## Task 1: finance-copilot

- [x] Create isolated worktree and resolve setup failure using cached dependencies.
- [x] Inspect dry-run: 12 updates, 11 links, 11 old skill-copy removals; no conflicts.
- [x] Run update in `.worktrees/chore-openspec2-migration`.
- [x] Update the required tooling changelog; existing integration documentation remains accurate.
- [x] Check generated links/workflows, authored-file preservation, skill contracts and OpenSpec validation against baseline.

## Task 2: FinSight

- [x] Create isolated worktree; inspect dry-run and legacy synchronization assumptions.
- [x] Add a failing regression to `tests/test_skills_sync.py` for the OpenSpec 2 Claude skill layout.
- [x] Update `packages/finsight-devtools/finsight_devtools/skills_sync.py`, the OpenSpec recipe and their existing tests/docs.
- [x] Run update; remove only obsolete generated command artifacts from the reviewed migration scope.
- [x] Run focused sync tests, sync checks, OpenSpec validation and applicable source/docs checks.

## Task 3: markova.studio

- [x] Create isolated worktree and inspect generated integration paths.
- [x] Adapt the scoped instruction and `scripts/sync-agent-skills.sh` contract to canonical OpenSpec skills with Claude links.
- [x] Cover changed synchronization behavior with an offline regression test.
- [x] Run update and verify sync preserves the new layout and all workflows.
- [x] Check authored-file preservation, idempotence and applicable repository checks.

## Delivery

- [x] Report each worktree, changed integration files, validation and remaining limitations.
- [x] Leave all commits and main checkouts untouched unless the user separately requests delivery.

Validated: finance-copilot and markova.studio independently reviewed; FinSight integration reviewed by the controller. Repeated dry-runs are empty in all three worktrees. Strict validator warnings remain documented; authored specifications were preserved.

## Delivery status

- User authorized commits, PRs and merge after successful checks.
- markova.studio PR #148 merged as `501e7ef46a9eddcdea3b70eab1e42e4b3bdfd4b6`; main synchronized, exact clean task worktree and local branch removed.
- FinSight PR #863 remains open by user decision: manual CI reproduces 18 baseline PLR0917 failures in 15 unchanged files. No suppression or unrelated API edits.
- finance-copilot: user approved the reviewed exact-11 OpenSpec symlink exception in `scripts/privacy_check.py`; existing Claude privacy hook remains untouched. Delivery resumes with normal hooks.

Final delivery: finance-copilot PR #145 merged as `d49042da89c3214773d5e99e8e4f2051bf6caf0d` after all three CI checks passed. Post-main-update validation passed 1832 tests. The owner-approved narrow symlink policy has eight regression cases; the general symlink ban and content scanning remain active. Finance main is synchronized and clean; the exact task worktree/local branch were removed after explicit owner approval. FinSight PR #863 intentionally remains open for the separate baseline lint task.
