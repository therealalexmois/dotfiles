#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml"]
# ///
"""Считает реальные активации skills по транскриптам Claude Code и сессиям Codex.

Отчет разделяет пути вызова, потому что `disable-model-invocation` (Claude) и
`policy.allow_implicit_invocation: false` (Codex) влияют на них по-разному:

- slash: пользователь набрал `/name` в Claude или `$name` в Codex; продолжит работать;
- named: модель вызвала скилл, потому что пользователь назвал его в тексте; сломается;
- auto: модель выбрала скилл по description; ради этого описание держат в контексте;
- nested, subagent: вызов из другого скилла или сабагента; сломается.

Named определяется эвристически по имени скилла в тексте запроса, поэтому auto -
оценка сверху. Claude Code удаляет транскрипты старше `cleanupPeriodDays`.
Чтения SKILL.md в сессиях Codex внутри этого репозитория и чтения файлов, которые
в той же сессии правились, считаются шумом: это работа над скиллом, а не его вызов.
"""

from __future__ import annotations

import argparse
import json
import os
import re
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any

import yaml

REPO_DIR = Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_DIR / "ai-agents" / ".agents" / "skills"
CLAUDE_PROJECTS = Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude")) / "projects"
CODEX_SESSIONS = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex")) / "sessions"

FRONTMATTER = re.compile(r"\A---\n(.*?)\n---\n", re.DOTALL)
COMMAND_NAME = re.compile(r"<command-name>/?(.*?)</command-name>")
COMMAND_ARGS = re.compile(r"<command-args>(.*?)</command-args>", re.DOTALL)
SKILL_LOADED_MARKER = "Base directory for this skill"
CODEX_SKILL_BLOCK = re.compile(r"<skill>\s*<name>([^<]+)</name>")
CODEX_SKILL_READ = re.compile(r"\b(?:cat|sed|head|tail|nl|bat|less)\b[^|;&]*?skills/([a-z0-9-]+)/SKILL\.md")
CODEX_SKILL_PATH = re.compile(r"skills/([a-z0-9-]+)/SKILL\.md")
CODEX_MARKERS = ('"session_meta"', '"user_message"', "<skill>", "SKILL.md")

COLUMNS = {
    "claude_slash": "c:/",
    "claude_named": "c:nm",
    "claude_auto": "c:au",
    "claude_nested": "c:ns",
    "claude_subagent": "c:sb",
    "codex_explicit": "x:$",
    "codex_named": "x:nm",
    "codex_auto": "x:au",
    "codex_noise": "x:nz",
}
VERDICT_ORDER = ("mismatch", "candidate", "candidate (named)", "check callers", "keep", "manual", "external")


@dataclass
class Scan:
    """Счетчики активаций одного источника и период, который он покрывает.

    Attributes:
        counts: Счетчики по имени скилла и колонке из COLUMNS.
        first: Самая ранняя учтенная метка времени, ISO 8601.
        last: Самая поздняя учтенная метка времени, ISO 8601.
    """

    counts: defaultdict[str, Counter[str]] = field(default_factory=lambda: defaultdict(Counter))
    first: str = ""
    last: str = ""

    def see(self, timestamp: str) -> None:
        """Расширяет покрытый период меткой времени записи."""
        if timestamp:
            self.first = min(self.first or timestamp, timestamp)
            self.last = max(self.last, timestamp)


@dataclass(frozen=True)
class RepoSkill:
    """Скилл из репозитория и его настройки неявного вызова.

    Attributes:
        name: Имя каталога скилла.
        description_chars: Длина description без лишних пробелов.
        claude_manual: В SKILL.md задан `disable-model-invocation: true`.
        codex_manual: В agents/openai.yaml задан `policy.allow_implicit_invocation: false`.
    """

    name: str
    description_chars: int
    claude_manual: bool
    codex_manual: bool


def mentions(text: str, name: str) -> bool:
    """Проверяет, назван ли скилл в тексте: `name`, `/name`, `$name` или через пробелы вместо дефисов."""
    short_name = name.rsplit(":", 1)[-1]
    variants = {short_name, short_name.replace("-", " ")}

    return any(re.search(rf"(?<![\w-]){re.escape(variant)}(?![\w-])", text, re.IGNORECASE) for variant in variants)


def claude_prompt_text(record: dict[str, Any]) -> str | None:
    """Возвращает текст, набранный пользователем, или None для tool_result и служебных сообщений."""
    if record.get("type") != "user" or record.get("isMeta") or record.get("isCompactSummary"):
        return None
    if record.get("toolUseResult"):
        return None

    content = record.get("message", {}).get("content")
    if isinstance(content, str):
        return content

    blocks = [block for block in content or [] if isinstance(block, dict)]
    if any(block.get("type") == "tool_result" for block in blocks):
        return None

    return " ".join(block.get("text", "") for block in blocks if block.get("type") == "text")


def scan_claude(root: Path, since: str) -> Scan:
    """Разбирает транскрипты Claude Code, включая сабагентов.

    Вызов моделью – это tool_use `Skill`. Slash-вызов – `<command-name>` в сообщении
    пользователя, за которым следует meta-сообщение с текстом скилла; у встроенных
    команд вроде `/compact` его нет. Возобновленные сессии дублируют записи, поэтому
    учет идет по id.
    """
    scan = Scan()
    seen: set[str] = set()

    for path in sorted(root.glob("**/*.jsonl")):
        in_subagent = "subagents" in path.parts
        prompt = ""
        turn_skills: set[str] = set()
        pending_command: tuple[str, str, bool] | None = None

        for line in path.open(encoding="utf-8"):
            if '"type":"user"' not in line and '"name":"Skill"' not in line:
                continue

            record = json.loads(line)
            timestamp = record.get("timestamp", "")
            counted = timestamp >= since
            if counted:
                scan.see(timestamp)

            if record.get("isMeta") and pending_command and SKILL_LOADED_MARKER in line:
                name, uuid, command_counted = pending_command
                pending_command = None
                turn_skills.add(name)

                if command_counted and uuid not in seen:
                    seen.add(uuid)
                    scan.counts[name]["claude_slash"] += 1
                continue

            text = claude_prompt_text(record)
            if text is not None:
                prompt, turn_skills, pending_command = text, set(), None
                command = COMMAND_NAME.search(text)
                if command:
                    args = COMMAND_ARGS.search(text)
                    prompt = args.group(1) if args else ""
                    pending_command = (command.group(1), record.get("uuid", ""), counted)
                continue

            content = record.get("message", {}).get("content")
            if not isinstance(content, list):
                continue

            for block in content:
                if block.get("type") != "tool_use" or block.get("name") != "Skill" or block["id"] in seen:
                    continue
                seen.add(block["id"])
                name = block.get("input", {}).get("skill", "")

                if in_subagent or record.get("isSidechain"):
                    column = "claude_subagent"
                elif mentions(prompt, name):
                    column = "claude_named"
                elif turn_skills:
                    column = "claude_nested"
                else:
                    column = "claude_auto"

                if counted:
                    scan.counts[name][column] += 1
                turn_skills.add(name)

    return scan


def codex_message_text(payload: dict[str, Any]) -> str:
    """Склеивает текстовые части сообщения Codex."""
    return " ".join(part.get("text", "") for part in payload.get("content") or [] if isinstance(part, dict))


def scan_codex(root: Path, since: str) -> Scan:
    """Разбирает сессии Codex.

    Явный вызов – блок `<skill>` в сообщении пользователя. Неявный – первое за ход
    чтение `skills/<name>/SKILL.md` через exec. Форки сессий копируют историю,
    поэтому учет идет по паре (метка времени, скилл).
    """
    scan = Scan()
    seen: set[tuple[str, str, str]] = set()

    for path in sorted(root.glob("**/*.jsonl")):
        cwd = ""
        prompt = ""
        turn_skills: set[str] = set()
        patched: set[str] = set()
        reads: list[tuple[str, str, bool]] = []

        for line in path.open(encoding="utf-8"):
            if not any(marker in line for marker in CODEX_MARKERS):
                continue

            record = json.loads(line)
            payload = record.get("payload", {})
            timestamp = record.get("timestamp", "")
            kind = payload.get("type")
            if timestamp >= since:
                scan.see(timestamp)

            if record.get("type") == "session_meta":
                cwd = payload.get("cwd", "")
            elif kind == "user_message":
                prompt, turn_skills = payload.get("message", ""), set()
            elif kind == "message" and payload.get("role") == "user":
                for name in CODEX_SKILL_BLOCK.findall(codex_message_text(payload)):
                    turn_skills.add(name)
                    key = ("explicit", timestamp, name)
                    if timestamp >= since and key not in seen:
                        seen.add(key)
                        scan.counts[name]["codex_explicit"] += 1
            elif kind in ("function_call", "custom_tool_call"):
                args = str(payload.get("arguments") or payload.get("input") or "")
                if "*** Update File" in args or "*** Add File" in args:
                    patched.update(CODEX_SKILL_PATH.findall(args))
                    continue

                for name in CODEX_SKILL_READ.findall(args):
                    if name not in turn_skills:
                        turn_skills.add(name)
                        reads.append((timestamp, name, mentions(prompt, name)))

        in_repo = bool(cwd) and Path(cwd).is_relative_to(REPO_DIR)
        for timestamp, name, named in reads:
            key = ("read", timestamp, name)
            if timestamp < since or key in seen:
                continue
            seen.add(key)

            if in_repo or name in patched:
                column = "codex_noise"
            elif named:
                column = "codex_named"
            else:
                column = "codex_auto"
            scan.counts[name][column] += 1

    return scan


def load_repo_skills(skills_dir: Path) -> dict[str, RepoSkill]:
    """Читает description и настройки неявного вызова всех скиллов репозитория."""
    skills: dict[str, RepoSkill] = {}

    for skill_md in sorted(skills_dir.glob("*/SKILL.md")):
        match = FRONTMATTER.match(skill_md.read_text(encoding="utf-8"))
        if match is None:
            raise ValueError(f"frontmatter not found: {skill_md}")
        frontmatter = yaml.safe_load(match.group(1)) or {}

        policy_file = skill_md.parent / "agents" / "openai.yaml"
        codex_config = yaml.safe_load(policy_file.read_text(encoding="utf-8")) if policy_file.exists() else None
        policy = (codex_config or {}).get("policy") or {}

        name = skill_md.parent.name
        skills[name] = RepoSkill(
            name=name,
            description_chars=len(" ".join(str(frontmatter.get("description", "")).split())),
            claude_manual=frontmatter.get("disable-model-invocation") is True,
            codex_manual=policy.get("allow_implicit_invocation") is False,
        )

    return skills


def verdict(skill: RepoSkill | None, counts: Counter[str]) -> str:
    """Классифицирует скилл по правилу перевода на ручной вызов.

    Кандидат – скилл без auto-активаций, который не вызывают другие скиллы и
    сабагенты. `candidate (named)` означает, что после перевода придется набирать
    `/name` или `$name` вместо упоминания в тексте.
    """
    if skill is None:
        return "external"
    if skill.claude_manual != skill.codex_manual:
        return "mismatch"
    if skill.claude_manual:
        return "manual"
    if counts["claude_auto"] + counts["codex_auto"]:
        return "keep"
    if counts["claude_nested"] + counts["claude_subagent"]:
        return "check callers"
    if counts["claude_named"] + counts["codex_named"]:
        return "candidate (named)"
    return "candidate"


def build_rows(
    skills: dict[str, RepoSkill],
    claude: Scan,
    codex: Scan,
    *,
    include_all: bool,
    include_external: bool,
) -> list[dict[str, Any]]:
    """Сводит счетчики обоих источников со скиллами репозитория в строки отчета."""
    model_seen = {name for name, counts in claude.counts.items() if counts.total() > counts["claude_slash"]}
    names = set(skills)
    if include_external:
        names |= model_seen | set(codex.counts)

    rows = []
    for name in names:
        counts = claude.counts.get(name, Counter()) + codex.counts.get(name, Counter())
        skill = skills.get(name)
        row_verdict = verdict(skill, counts)
        if row_verdict == "manual" and not include_all and not counts.total():
            continue

        rows.append(
            {
                "skill": name,
                "verdict": row_verdict,
                "description_chars": skill.description_chars if skill else None,
                **{column: counts[column] for column in COLUMNS},
            }
        )

    rows.sort(key=lambda row: (VERDICT_ORDER.index(row["verdict"]), -(row["description_chars"] or 0), row["skill"]))
    return rows


def print_table(rows: list[dict[str, Any]], claude: Scan, codex: Scan, skills: dict[str, RepoSkill]) -> None:
    """Печатает отчет в виде таблицы со сводкой по бюджету описаний."""
    for label, scan in (("Claude Code", claude), ("Codex", codex)):
        period = f"{scan.first[:10]} .. {scan.last[:10]}" if scan.first else "no data"
        print(f"{label:12} {period}")

    auto_skills = [skill for skill in skills.values() if not skill.claude_manual]
    candidates = [row for row in rows if row["verdict"].startswith("candidate")]
    print(
        f"auto skills: {len(auto_skills)} ({sum(s.description_chars for s in auto_skills)} description chars); "
        f"candidates: {len(candidates)} ({sum(row['description_chars'] for row in candidates)} chars)"
    )
    print("c: Claude Code, x: Codex; /: slash, $: explicit, nm: named, au: auto, ns: nested, sb: subagent, nz: noise\n")

    width = max((len(row["skill"]) for row in rows), default=5)
    header = f"{'skill':{width}}  {'verdict':17} {'desc':>5} " + " ".join(f"{h:>4}" for h in COLUMNS.values())
    print(header)
    print("-" * len(header))

    for row in rows:
        cells = " ".join(f"{row[column] or '.':>4}" for column in COLUMNS)
        print(f"{row['skill']:{width}}  {row['verdict']:17} {row['description_chars'] or '-':>5} {cells}")


def main() -> int:
    """Точка входа CLI."""
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--days", type=int, help="count only activations from the last N days")
    parser.add_argument("--all", action="store_true", help="also list manual skills that were never activated")
    parser.add_argument(
        "--include-external",
        action="store_true",
        help="also list skills outside this repository (project-local, plugins)",
    )
    parser.add_argument("--json", action="store_true", help="print rows as JSON")
    args = parser.parse_args()

    if not CLAUDE_PROJECTS.is_dir() and not CODEX_SESSIONS.is_dir():
        parser.error(f"no transcripts found in {CLAUDE_PROJECTS} or {CODEX_SESSIONS}")

    since = ""
    if args.days is not None:
        since = (datetime.now(UTC) - timedelta(days=args.days)).strftime("%Y-%m-%dT%H:%M:%S")

    skills = load_repo_skills(SKILLS_DIR)
    claude = scan_claude(CLAUDE_PROJECTS, since)
    codex = scan_codex(CODEX_SESSIONS, since)
    rows = build_rows(skills, claude, codex, include_all=args.all, include_external=args.include_external)

    if args.json:
        periods = {"claude": [claude.first, claude.last], "codex": [codex.first, codex.last]}
        print(json.dumps({"periods": periods, "rows": rows}, ensure_ascii=False, indent=1))
    else:
        print_table(rows, claude, codex, skills)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
