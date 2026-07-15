#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["markdown-it-py>=3"]
# ///
"""Детерминированный линтер жесткого стоп-листа для русского Markdown.

Читает список запрещенных основ из `banned-terms.toml`, вырезает из текста код,
frontmatter, HTML и URL (там правило не действует) и ищет запрещенные основы в
прозе. Совпадение печатается как `path:line:col` с предложенной заменой; при
любом попадании код возврата не нулевой.

Единый источник правды - `references/banned-terms.toml`. Скрипт зовут две
поверхности: skill `writing` в сессии и git pre-commit hook как жесткий gate.

Запуск:
    uv run lint_banned_terms.py FILE [FILE ...]
    uv run lint_banned_terms.py --terms path/to/banned-terms.toml FILE
"""

from __future__ import annotations

import argparse
import re
import sys
import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import Any, TypedDict

from markdown_it import MarkdownIt

DEFAULT_TERMS = Path(__file__).resolve().parent.parent / "references" / "banned-terms.toml"

# Основа якорится по левой границе слова и поглощает русский суффиксальный хвост.
STEM_TEMPLATE = r"(?<![а-яёА-ЯЁ])(?:{stem})[а-яё]*"

# Регионы прозы, где стоп-лист не действует и которые маскируются пробелами.
INLINE_CODE = re.compile(r"`+[^`]*`+")
LINK_TARGET = re.compile(r"\]\([^)]*\)")
BARE_URL = re.compile(r"https?://\S+")
AUTOLINK = re.compile(r"<[^>]+>")
MASK_INLINE: tuple[re.Pattern[str], ...] = (INLINE_CODE, LINK_TARGET, BARE_URL, AUTOLINK)

BLOCK_CODE_TYPES = {"fence", "code_block", "html_block"}
FRONTMATTER_FENCE = {"---", "..."}

# Парсер не зависит от файла, поэтому создается один раз на процесс.
_MD = MarkdownIt("commonmark")


class TermEntry(TypedDict):
    """Форма одной записи `[[term]]` в banned-terms.toml."""

    id: str
    replacement: str
    patterns: list[str]


@dataclass(frozen=True)
class Term:
    """Запрещенный термин: набор скомпилированных основ и замена.

    Attributes:
        id: Идентификатор термина из TOML.
        replacement: Что писать вместо запрещенной основы.
        matchers: Скомпилированные regex основ с якорем и русским хвостом.
    """

    id: str
    replacement: str
    matchers: tuple[re.Pattern[str], ...]


@dataclass(frozen=True)
class Finding:
    """Одно попадание стоп-слова в файле.

    Attributes:
        path: Файл, где найдено попадание.
        line: Номер строки, 1-индекс.
        col: Номер колонки, 1-индекс.
        term_id: Идентификатор сработавшего термина.
        matched: Фактически найденная словоформа.
        replacement: Предлагаемая замена.
    """

    path: Path
    line: int
    col: int
    term_id: str
    matched: str
    replacement: str


def load_terms(path: Path) -> list[Term]:
    """Читает и компилирует стоп-лист из TOML.

    Raises:
        ValueError: Если в файле нет ни одной записи `[[term]]` - пустой
            стоп-лист означает, что gate молча пропустит все, поэтому это ошибка.
    """
    data: dict[str, Any] = tomllib.loads(path.read_text(encoding="utf-8-sig"))
    entries: list[TermEntry] = data.get("term", [])

    terms: list[Term] = []
    for entry in entries:
        matchers = tuple(
            re.compile(STEM_TEMPLATE.format(stem=stem), re.IGNORECASE)
            for stem in entry["patterns"]
        )
        terms.append(Term(id=entry["id"], replacement=entry["replacement"], matchers=matchers))

    if not terms:
        raise ValueError(f"стоп-лист пуст: {path} не содержит ни одного [[term]]")

    return terms


def _blank(match: re.Match[str]) -> str:
    """Заменяет совпадение пробелами той же длины, сохраняя колонки."""
    return " " * (match.end() - match.start())


def excluded_lines(text: str) -> set[int]:
    """Возвращает 0-индексные номера строк с кодом, HTML или frontmatter."""
    excluded: set[int] = set()

    lines = text.splitlines()
    if lines and lines[0].strip() == "---":
        for i in range(1, len(lines)):
            if lines[i].strip() in FRONTMATTER_FENCE:
                excluded.update(range(0, i + 1))
                break

    for token in _MD.parse(text):
        if token.type in BLOCK_CODE_TYPES and token.map:
            excluded.update(range(token.map[0], token.map[1]))

    return excluded


def mask_prose(line: str) -> str:
    """Маскирует inline-код и URL в строке прозы, сохраняя длину."""
    for pattern in MASK_INLINE:
        line = pattern.sub(_blank, line)

    return line


def scan(path: Path, terms: list[Term]) -> list[Finding]:
    """Ищет запрещенные основы в одном Markdown-файле."""
    text = path.read_text(encoding="utf-8-sig")
    skip = excluded_lines(text)

    findings: list[Finding] = []
    for index, raw in enumerate(text.splitlines()):
        if index in skip:
            continue

        line = mask_prose(raw)
        for term in terms:
            for matcher in term.matchers:
                for match in matcher.finditer(line):
                    findings.append(
                        Finding(
                            path=path,
                            line=index + 1,
                            col=match.start() + 1,
                            term_id=term.id,
                            matched=match.group(0),
                            replacement=term.replacement,
                        )
                    )

    return findings


def main(argv: list[str] | None = None) -> int:
    """Разбирает аргументы, прогоняет линтер и возвращает код выхода.

    Коды выхода: 0 - чисто, 1 - найдены запрещенные слова, 2 - ошибка
    конфигурации или чтения файла (стоп-лист не загрузился, битая кодировка).
    """
    parser = argparse.ArgumentParser(description="Линтер жесткого стоп-листа для русского Markdown.")
    parser.add_argument("files", nargs="+", type=Path, help="Markdown-файлы для проверки.")
    parser.add_argument(
        "--terms",
        type=Path,
        default=DEFAULT_TERMS,
        help=f"Путь к banned-terms.toml (по умолчанию {DEFAULT_TERMS}).",
    )
    args = parser.parse_args(argv)

    try:
        terms = load_terms(args.terms)
    except (OSError, ValueError, tomllib.TOMLDecodeError) as exc:
        print(f"error: не удалось загрузить стоп-лист {args.terms}: {exc}", file=sys.stderr)
        return 2

    findings: list[Finding] = []
    read_errors = 0
    for path in args.files:
        if path.suffix.lower() not in {".md", ".markdown"}:
            continue

        try:
            findings.extend(scan(path, terms))
        except (OSError, ValueError) as exc:
            print(f"{path}: error: {exc}", file=sys.stderr)
            read_errors += 1

    for f in findings:
        print(f"{f.path}:{f.line}:{f.col}: {f.term_id}: '{f.matched}' -> {f.replacement}")

    if findings:
        print(f"\nНайдено запрещенных слов: {len(findings)}", file=sys.stderr)
        return 1

    return 2 if read_errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
