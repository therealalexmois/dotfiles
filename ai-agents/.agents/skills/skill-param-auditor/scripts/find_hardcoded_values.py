#!/usr/bin/env python3
"""Regex-пресканер кандидатов на захардкоженные значения в agent skills.

Назначение скрипта - быстро подсветить строки, которые *похожи* на mutable runtime
data (ID, URL, namespace, абсолютные пути, секреты), чтобы аудит не вычитывал каждую
строку вручную. Это вспомогательный инструмент, а не самостоятельный аудит: regex
переусердствует (любой URL, любой `/abs/path`) и недоусердствует (голый числовой
thread ID неотличим от обычного числа). Финальное решение stable-vs-mutable
принимает skill skill-param-auditor, а не этот скрипт.

Скрипт читает файлы, ничего не изменяет и не делает сетевых вызовов.

Примеры:
    python3 find_hardcoded_values.py path/to/skill/
    python3 find_hardcoded_values.py path/to/SKILL.md --json
    python3 find_hardcoded_values.py path/to/skills-folder/ --json
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

# Расширения файлов, которые имеет смысл сканировать внутри скилла.
SCANNED_SUFFIXES: frozenset[str] = frozenset(
    {".md", ".py", ".sh", ".bash", ".js", ".ts", ".toml", ".yaml", ".yml", ".json", ".env"}
)

# Каталоги, которые пропускаем, чтобы не шуметь на чужом коде и кэшах.
SKIPPED_DIR_NAMES: frozenset[str] = frozenset(
    {".git", "node_modules", "__pycache__", ".venv", "venv", ".mypy_cache", ".ruff_cache"}
)

# Максимальный размер файла для построчного скана (защита от бинарей и дампов).
MAX_FILE_BYTES: int = 512 * 1024


@dataclass(frozen=True, slots=True)
class Rule:
    """Правило-детектор для одной категории кандидатов.

    Attributes:
        category: Человекочитаемая категория значения.
        risk: Базовый уровень риска - `critical`, `major` или `minor`.
        pattern: Скомпилированное регулярное выражение для поиска кандидата.
    """

    category: str
    risk: str
    pattern: re.Pattern[str]


@dataclass(frozen=True, slots=True)
class Finding:
    """Один кандидат, найденный пресканером.

    Attributes:
        file: Путь к файлу относительно цели сканирования.
        line: Номер строки (с единицы).
        category: Категория из сработавшего правила.
        risk: Базовый уровень риска из правила.
        match: Фрагмент строки, который совпал с шаблоном.
    """

    file: str
    line: int
    category: str
    risk: str
    match: str


def _compile_rules() -> list[Rule]:
    """Собирает список правил-детекторов.

    Шаблоны намеренно широкие: цель - не пропустить кандидата, а не вынести вердикт.
    Любое совпадение нужно перепроверять по эвристике example-vs-real.

    Returns:
        Список правил в порядке убывания строгости.
    """
    return [
        Rule(
            "secret",
            "critical",
            re.compile(
                r"(?i)(api[_-]?key|secret|token|password|passwd|bearer\s+[a-z0-9._-]+"
                r"|AKIA[0-9A-Z]{16}|xox[baprs]-[0-9a-zA-Z-]+|gh[pousr]_[0-9a-zA-Z]{20,})"
            ),
        ),
        Rule(
            "messenger-id",
            "major",
            re.compile(r"\b(bot[_-][0-9a-zA-Z]{4,}|[CUDG][0-9A-Z]{8,}|\d{10}\.\d{4,})\b"),
        ),
        Rule(
            "k8s-namespace-or-context",
            "major",
            re.compile(r"(?i)(--namespace[=\s]+\S+|\s-n\s+[a-z0-9-]+|--context[=\s]+\S+|namespace:\s*\S+)"),
        ),
        Rule(
            "url-or-host",
            "major",
            re.compile(r"https?://[^\s\"'`)>]+"),
        ),
        Rule(
            "absolute-path",
            "major",
            re.compile(r"(?<![\w./])(/Users/|/home/|/opt/|/var/|/srv/|[A-Z]:\\)[^\s\"'`)>]+"),
        ),
        Rule(
            "jira-or-project-key",
            "minor",
            re.compile(r"\b[A-Z][A-Z0-9]{1,9}-\d{1,6}\b"),
        ),
        Rule(
            "env-name",
            "minor",
            re.compile(r"(?i)\b(prod|production|stage|staging|preprod|qa)\b"),
        ),
    ]


def _iter_files(target: Path) -> list[Path]:
    """Возвращает файлы для сканирования внутри цели.

    Args:
        target: Путь к файлу `SKILL.md`, каталогу скилла или папке со скиллами.

    Returns:
        Отсортированный список путей к файлам подходящих расширений.
    """
    if target.is_file():
        return [target]

    files: list[Path] = []
    for path in sorted(target.rglob("*")):
        if any(part in SKIPPED_DIR_NAMES for part in path.parts):
            continue
        if not path.is_file():
            continue
        if path.suffix.lower() in SCANNED_SUFFIXES or path.name.startswith(".env"):
            files.append(path)
    return files


def _scan_file(path: Path, rules: list[Rule], root: Path) -> list[Finding]:
    """Сканирует один файл всеми правилами.

    Args:
        path: Путь к сканируемому файлу.
        rules: Список правил-детекторов.
        root: База для вычисления относительного пути в выводе.

    Returns:
        Список находок; пустой, если файл слишком большой, бинарный или чистый.
    """
    try:
        if path.stat().st_size > MAX_FILE_BYTES:
            return []
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return []

    try:
        rel = str(path.relative_to(root))
    except ValueError:
        rel = str(path)

    findings: list[Finding] = []
    for line_number, line in enumerate(text.splitlines(), start=1):
        for rule in rules:
            match = rule.pattern.search(line)
            if match is None:
                continue
            snippet = match.group(0).strip()[:160]
            findings.append(Finding(rel, line_number, rule.category, rule.risk, snippet))
    return findings


def _render_text(findings: list[Finding]) -> str:
    """Формирует человекочитаемый отчет.

    Args:
        findings: Список находок пресканера.

    Returns:
        Готовый к печати текст с группировкой по уровню риска.
    """
    if not findings:
        return "No candidate hardcoded values found (regex pre-scan only)."

    order = {"critical": 0, "major": 1, "minor": 2}
    findings_sorted = sorted(findings, key=lambda f: (order.get(f.risk, 9), f.file, f.line))

    lines = [f"Candidate hardcoded values: {len(findings_sorted)} (regex pre-scan, verify each)"]
    for f in findings_sorted:
        lines.append(f"[{f.risk.upper():8}] {f.category:26} {f.file}:{f.line}  {f.match}")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    """Точка входа CLI.

    Args:
        argv: Аргументы командной строки; `None` означает `sys.argv`.

    Returns:
        Код возврата процесса: `0` при успешном сканировании, `2` если цель не найдена.
    """
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("target", type=Path, help="SKILL.md, каталог скилла или папка со скиллами")
    parser.add_argument("--json", action="store_true", help="вывести находки в формате JSON")
    args = parser.parse_args(argv)

    target: Path = args.target
    if not target.exists():
        print(f"error: target not found: {target}", file=sys.stderr)
        return 2

    root = target.parent if target.is_file() else target
    rules = _compile_rules()

    findings: list[Finding] = []
    for path in _iter_files(target):
        findings.extend(_scan_file(path, rules, root))

    if args.json:
        print(json.dumps([asdict(f) for f in findings], ensure_ascii=False, indent=2))
    else:
        print(_render_text(findings))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
