#!/usr/bin/env python3
"""Run deterministic structural and safety checks for postgres-engineer."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def main() -> int:
    skill_dir = Path(__file__).resolve().parents[1]
    errors: list[str] = []
    skill_path = skill_dir / "SKILL.md"
    text = skill_path.read_text(encoding="utf-8")

    match = re.match(r"\A---\n(.*?)\n---\n", text, re.DOTALL)
    if not match:
        fail(errors, "SKILL.md has no valid YAML frontmatter block")
    else:
        keys = {
            line.split(":", 1)[0].strip()
            for line in match.group(1).splitlines()
            if ":" in line and not line.startswith(" ")
        }
        if keys != {"name", "description"}:
            fail(errors, f"frontmatter keys must be name,description; got {sorted(keys)}")

    linked = set(re.findall(r"`(references/[^`]+\.md)`", text))
    existing = {
        str(path.relative_to(skill_dir))
        for path in (skill_dir / "references").glob("*.md")
    }
    if linked != existing:
        fail(errors, f"reference routing mismatch: missing={sorted(existing-linked)}, stale={sorted(linked-existing)}")

    scan_files = [skill_path, *sorted((skill_dir / "references").glob("*.md"))]
    for path in scan_files:
        body = path.read_text(encoding="utf-8")
        relative = path.relative_to(skill_dir)
        if relative.as_posix() != "references/sources.md" and re.search(r"PlanetScale|pscale\b", body, re.I):
            fail(errors, f"provider-specific content outside sources: {relative}")
        if re.search(r"\brm\s+-rf\b", body):
            fail(errors, f"broad recursive delete found: {relative}")
        if re.search(r"(?i)(password|token|private_key)\s*=\s*['\"][^$<{]", body):
            fail(errors, f"possible plaintext secret example: {relative}")

    cases_path = skill_dir / "evals" / "cases.json"
    try:
        cases = json.loads(cases_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(errors, f"invalid eval cases: {exc}")
        cases = []
    if len(cases) < 12:
        fail(errors, f"expected at least 12 behavioral cases, got {len(cases)}")
    ids = [case.get("id") for case in cases]
    if len(ids) != len(set(ids)):
        fail(errors, "eval case ids are not unique")
    for case in cases:
        for field in ("id", "category", "prompt", "expected", "critical_failures", "references"):
            if not case.get(field):
                fail(errors, f"case {case.get('id', '<unknown>')} lacks {field}")
        for reference in case.get("references", []):
            if not (skill_dir / "references" / reference).is_file():
                fail(errors, f"case {case.get('id')} references missing file {reference}")

    baseline_path = skill_dir / "evals" / "baseline-results.json"
    try:
        baseline = json.loads(baseline_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(errors, f"invalid baseline results: {exc}")
        baseline = {}
    final_results = baseline.get("final_results", [])
    result_ids = {result.get("id") for result in final_results}
    if result_ids != set(ids):
        fail(errors, "baseline result ids do not match behavioral cases")
    if any(result.get("status") != "passed" for result in final_results):
        fail(errors, "baseline contains a non-passing final result")
    if baseline.get("summary", {}).get("critical_failures_final") != 0:
        fail(errors, "baseline reports final critical failures")

    metadata = (skill_dir / "agents" / "openai.yaml").read_text(encoding="utf-8")
    if "$postgres-engineer" not in metadata:
        fail(errors, "agents/openai.yaml default_prompt does not mention $postgres-engineer")

    result = {
        "status": "failed" if errors else "passed",
        "checks": {
            "references": len(existing),
            "behavioral_cases": len(cases),
            "baseline_results": len(final_results),
            "files_scanned": len(scan_files),
        },
        "errors": errors,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
