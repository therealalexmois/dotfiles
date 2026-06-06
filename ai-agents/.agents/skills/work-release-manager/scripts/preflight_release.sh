#!/usr/bin/env bash
# Phase 0 preflight for dwsai-data-agent release. Read-only. Verifies the release
# can start safely and emits a JSON report. Does not change any state.
#
# Usage:
#   ./preflight_release.sh
# Optional env overrides:
#   REPO EXPECT_REMOTE EXPECT_BRANCH
#
# Exit: 0 = preflight ok (status=ok|warn), 1 = blocking (status=blocked), 2 = usage error.
set -uo pipefail

REPO="${REPO:-.}"
EXPECT_REMOTE="${EXPECT_REMOTE:-dwsai-data-agent}"
EXPECT_BRANCH="${EXPECT_BRANCH:-master}"

command -v jq  >/dev/null || { echo '{"status":"blocked","errors":["jq not found"]}'; exit 2; }

errors=()
warnings=()

# git repo + correct project
if ! git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  errors+=("not a git repository: $REPO")
fi
remote_url="$(git -C "$REPO" remote get-url origin 2>/dev/null || echo '')"
case "$remote_url" in
  *"$EXPECT_REMOTE"*) : ;;
  *) errors+=("origin remote does not look like $EXPECT_REMOTE: ${remote_url:-<none>}") ;;
esac

branch="$(git -C "$REPO" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
head_commit="$(git -C "$REPO" rev-parse --short HEAD 2>/dev/null || echo '')"

# working tree clean?
clean=true
if [ -n "$(git -C "$REPO" status --porcelain 2>/dev/null)" ]; then
  clean=false
  warnings+=("working tree is dirty - needs explicit approval to proceed")
fi

# master reachable
if ! git -C "$REPO" rev-parse --verify "$EXPECT_BRANCH" >/dev/null 2>&1; then
  warnings+=("branch $EXPECT_BRANCH not found locally")
fi
[ "$branch" = "$EXPECT_BRANCH" ] || warnings+=("current branch is $branch, not $EXPECT_BRANCH")

# tools
tools='{}'
for t in git dp jq; do
  if command -v "$t" >/dev/null 2>&1; then ok=true; else ok=false; fi
  tools="$(printf '%s' "$tools" | jq --arg t "$t" --argjson ok "$ok" '. + {($t): $ok}')"
done
command -v dp >/dev/null 2>&1 || warnings+=("dp CLI not found - needed for deploy/kube/sage phases")

# release tag detection
prev_tag="$(git -C "$REPO" tag -l 'release-*' --sort=-version:refname 2>/dev/null | grep -E '^release-[0-9]{6}\.[0-9]{4}$' | head -1)"
[ -n "$prev_tag" ] || errors+=("cannot detect previous release tag (no release-* tags)")
candidate_tag="release-$(date +%y%m%d.%H%M)"
if git -C "$REPO" rev-parse "$candidate_tag" >/dev/null 2>&1; then
  warnings+=("candidate tag $candidate_tag already exists")
fi

status="ok"
[ "${#warnings[@]}" -gt 0 ] && status="warn"
[ "${#errors[@]}" -gt 0 ] && status="blocked"

jq -n \
  --arg status "$status" \
  --arg branch "$branch" \
  --arg head "$head_commit" \
  --argjson clean "$clean" \
  --arg prev "$prev_tag" \
  --arg cand "$candidate_tag" \
  --argjson tools "$tools" \
  --argjson errors "$(printf '%s\n' "${errors[@]:-}" | jq -R . | jq -s 'map(select(length>0))')" \
  --argjson warnings "$(printf '%s\n' "${warnings[@]:-}" | jq -R . | jq -s 'map(select(length>0))')" \
  '{status:$status, branch:$branch, head_commit:$head, working_tree_clean:$clean,
    previous_release_tag:$prev, candidate_release_tag:$cand, tools:$tools,
    errors:$errors, warnings:$warnings}'

[ "$status" = "blocked" ] && exit 1 || exit 0
