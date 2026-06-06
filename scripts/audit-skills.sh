#!/usr/bin/env bash
# Security audit of all first-party agent skills via skill-security-auditor.
# Skips *-workspace scratch dirs: they are git-ignored and are not skills.
#
# Usage:
#   scripts/audit-skills.sh                    # audit and compare with baseline
#   scripts/audit-skills.sh --update-baseline  # audit and rewrite the baseline
#
# Exit codes: 0 = clean / matches baseline, 1 = findings or baseline drift.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
skills_dir="$repo_root/ai-agents/.agents/skills"
auditor="$skills_dir/skill-security-auditor/scripts/skill_security_auditor.py"
baseline="$repo_root/scripts/skills-audit-baseline.json"
mode="${1:-check}"

raw="$(mktemp)"
trap 'rm -f "$raw"' EXIT

for skill in "$skills_dir"/*/; do
  case "$skill" in
    *-workspace/) continue ;;
  esac
  python3 "$auditor" "$skill" --json >>"$raw" || true
done

python3 - "$raw" "$baseline" "$mode" <<'PY'
import json
import sys
from pathlib import Path

raw_path, baseline_path, mode = sys.argv[1], Path(sys.argv[2]), sys.argv[3]
content = Path(raw_path).read_text().strip()

decoder = json.JSONDecoder()
reports: list[dict] = []
idx = 0
while idx < len(content):
    while idx < len(content) and content[idx] not in "{[":
        idx += 1
    if idx >= len(content):
        break
    obj, idx = decoder.raw_decode(content, idx)
    reports.append(obj)

summary = sorted(
    (
        {
            "skill": r.get("skill") or r.get("skill_name") or r.get("path"),
            "verdict": r.get("verdict"),
            "counts": r.get("summary") or r.get("counts"),
        }
        for r in reports
    ),
    key=lambda row: row["skill"] or "",
)

non_pass = [row for row in summary if row["verdict"] != "PASS"]
for row in non_pass:
    print(f"{row['verdict']:6} {row['skill']} {row['counts']}")
print(f"audited: {len(summary)}, non-PASS: {len(non_pass)}")

if mode == "--update-baseline":
    baseline_path.write_text(json.dumps(summary, indent=1) + "\n")
    print(f"baseline updated: {baseline_path}")
    sys.exit(1 if non_pass else 0)

if not baseline_path.exists():
    print(f"no baseline at {baseline_path}; run with --update-baseline to create it")
    sys.exit(1)

base = json.loads(baseline_path.read_text())
if base != summary:
    base_by_skill = {row["skill"]: row for row in base}
    cur_by_skill = {row["skill"]: row for row in summary}
    for name in sorted(set(base_by_skill) | set(cur_by_skill)):
        old, new = base_by_skill.get(name), cur_by_skill.get(name)
        if old != new:
            print(f"drift: {name}: {old} -> {new}")
    print("baseline drift detected; review and rerun with --update-baseline if expected")
    sys.exit(1)

print("matches baseline")
sys.exit(1 if non_pass else 0)
PY
