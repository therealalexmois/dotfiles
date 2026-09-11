#!/usr/bin/env zsh
# Unit test for prune_stray_skill_links() in scripts/install-ai-cli-dotfiles.sh.
# Sources the installer (which runs main() only when executed directly) and
# exercises the function against a throwaway skills directory. Touches neither
# the real $HOME nor the repo.
set -euo pipefail

repo_dir="${0:A:h:h}"
source "${repo_dir}/scripts/install-ai-cli-dotfiles.sh"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

backup_dir="${work_dir}/backup"
skills_dir="${work_dir}/skills"
source_dir="${work_dir}/sources"
external_dir="${work_dir}/external"
mkdir -p "$skills_dir" "$source_dir/kept" "$source_dir/dropped" "$external_dir/live" "$skills_dir/.system"

# Managed links point at the source dir the way ~/.codex/skills points at
# ~/.agents/skills; the prefix below matches what main() passes in.
managed_prefix="../sources/"
ln -s "${managed_prefix}kept" "$skills_dir/kept"
ln -s "${managed_prefix}dropped" "$skills_dir/dropped"
ln -s "${managed_prefix}never-existed" "$skills_dir/managed-dangling"
ln -s "${external_dir}/live" "$skills_dir/external-live"
ln -s "${external_dir}/gone" "$skills_dir/external-dangling"
mkdir -p "$skills_dir/real-directory"

skills=(kept)

fail=0
check_gone() {
  if [[ -e "$1" || -L "$1" ]]; then
    printf 'FAIL: %s should have been pruned\n' "$1" >&2
    fail=1
  fi
}
check_kept() {
  if [[ ! -e "$1" && ! -L "$1" ]]; then
    printf 'FAIL: %s should have been left alone\n' "$1" >&2
    fail=1
  fi
}

prune_stray_skill_links "$skills_dir" "$managed_prefix" >/dev/null

check_kept "$skills_dir/kept"
check_kept "$skills_dir/external-live"
check_kept "$skills_dir/real-directory"
check_kept "$skills_dir/.system"
check_gone "$skills_dir/dropped"
check_gone "$skills_dir/managed-dangling"
check_gone "$skills_dir/external-dangling"

# A resolvable link is backed up before removal; a dangling one has nothing to copy.
# The backup label is derived from the skills dir's parent, the way ~/.codex/skills
# yields ".codex-stray-skills".
backup_label="${skills_dir:h:t}-stray-skills"
# The backup copy is the symlink itself, whose relative target no longer
# resolves from the backup location, so test for -L rather than -e.
if [[ ! -L "${backup_dir}/${backup_label}/dropped" ]]; then
  printf 'FAIL: pruned link "dropped" was not backed up under %s\n' "${backup_dir}/${backup_label}" >&2
  fail=1
fi
if [[ -e "${backup_dir}/${backup_label}/external-dangling" || -L "${backup_dir}/${backup_label}/external-dangling" ]]; then
  printf 'FAIL: dangling link "external-dangling" must not be backed up\n' >&2
  fail=1
fi

if (( fail )); then
  echo "prune_stray_skill_links test FAILED" >&2
  exit 1
fi
echo "ok: prune_stray_skill_links keeps tracked and foreign-live links, prunes stray and dangling ones"
