#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["markdown-it-py>=3"]
# ///
"""Детерминированный линтер (Tier 1) для русского Markdown.

Движок правил: каждое правило - маленький матчер за протоколом `Rule`. Данные,
которые меняются (стоп-лист терминов), лежат в `banned-terms.toml`; логика правил -
в коде. Линтер вырезает из текста код, frontmatter, HTML и URL (там правила не
действуют) и применяет правила только к прозе.

Правила первой волны:
    banned-term - запрещенные основы-кальки из TOML (report-only, замену выбирает
        человек);
    em-dash     - длинное тире U+2014 при политике «только `–`» (fixable);
    whitespace  - двойные пробелы и пробел перед пунктуацией (fixable), не трогает
        markdown hard line break (два пробела в конце строки).

Совпадение печатается как `path:line:col`. Режим `--fix` чинит fixable-правила на
месте и оставляет report-only как findings.

Коды выхода: 0 - чисто, 1 - остались findings, 2 - ошибка конфигурации или
чтения. Ошибка приоритетнее findings: при exit 2 прогон неполный, и его
результату нельзя доверять как полному отчету.

Запуск:
    uv run lint_banned_terms.py FILE [FILE ...]
    uv run lint_banned_terms.py --fix FILE
    uv run lint_banned_terms.py --terms path/to/banned-terms.toml FILE
"""

from __future__ import annotations

import argparse
import re
import sys
import tomllib
from collections.abc import Iterable
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Protocol, TypedDict

from markdown_it import MarkdownIt

DEFAULT_TERMS = Path(__file__).resolve().parent.parent / "references" / "banned-terms.toml"

# Основа якорится по левой границе слова и поглощает русский суффиксальный хвост.
STEM_TEMPLATE = r"(?<![а-яёА-ЯЁ])(?:{stem})[а-яё]*"

# Регионы прозы, где правила не действуют и которые маскируются пробелами.
INLINE_CODE = re.compile(r"`+[^`]*`+")
LINK_TARGET = re.compile(r"\]\([^)]*\)")
BARE_URL = re.compile(r"https?://\S+")
AUTOLINK = re.compile(r"<[^>]+>")
MASK_INLINE: tuple[re.Pattern[str], ...] = (INLINE_CODE, LINK_TARGET, BARE_URL, AUTOLINK)

BLOCK_CODE_TYPES = {"fence", "code_block", "html_block"}
FRONTMATTER_FENCE = {"---", "..."}

# Длинное тире U+2014 задано escape-ом, чтобы не держать его литерал в исходнике
# (политика проекта). Короткое тире U+2013 - разрешенный символ замены.
EM_DASH = re.compile("\u2014")
EN_DASH = "–"

# Внутристрочные прогоны пробелов; хвостовые и ведущие не трогаем (markdown-перенос).
DOUBLE_SPACE = re.compile(r"(?<=\S) {2,}(?=\S)")
SPACE_BEFORE_PUNCT = re.compile(r"(?<=\S)( +)(?=[,.;:!?])")

# Парсер не зависит от файла, поэтому создается один раз на процесс. Таблицы
# включены, чтобы отличать выравнивание ячеек от лишних пробелов в прозе.
_MD = MarkdownIt("commonmark").enable("table")


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
class Hit:
    """Одно срабатывание правила внутри строки.

    Attributes:
        start: Начальная колонка в строке, 0-индекс.
        end: Конечная колонка, 0-индекс, полуинтервал.
        matched: Фактически найденный фрагмент.
        message: Человекочитаемая подсказка или предлагаемая замена.
        replacement: Текст автозамены; None - правило report-only.
    """

    start: int
    end: int
    matched: str
    message: str
    replacement: str | None


@dataclass(frozen=True)
class Line:
    """Строка прозы с предвычисленным контекстом для правил.

    Attributes:
        raw: Исходная строка.
        masked: Строка с вырезанными кодом и URL, длина сохранена.
        spans: Исключенные inline-span (код, URL) как пары `(start, end)`.
        is_table_row: Строка входит в markdown-таблицу, где пробелы выравнивают
            ячейки и не считаются лишними.
    """

    raw: str
    masked: str
    spans: list[tuple[int, int]]
    is_table_row: bool


@dataclass(frozen=True)
class Finding:
    """Одно попадание правила в файле.

    Attributes:
        path: Файл, где найдено попадание.
        line: Номер строки, 1-индекс.
        col: Номер колонки, 1-индекс.
        rule_id: Идентификатор сработавшего правила.
        matched: Фактически найденный фрагмент.
        message: Подсказка или предлагаемая замена.
        fixable: Может ли `--fix` починить это попадание автоматически.
    """

    path: Path
    line: int
    col: int
    rule_id: str
    matched: str
    message: str
    fixable: bool


class Rule(Protocol):
    """Правило Tier 1: находит срабатывания в одной строке прозы."""

    id: str

    def scan_line(self, line: Line) -> Iterable[Hit]:
        """Возвращает срабатывания в строке."""
        ...


class TermRule:
    """R1: запрещенные основы-кальки из стоп-листа. Report-only."""

    id = "banned-term"

    def __init__(self, terms: list[Term]) -> None:
        self.terms = terms

    def scan_line(self, line: Line) -> Iterable[Hit]:
        for term in self.terms:
            for matcher in term.matchers:
                for match in matcher.finditer(line.masked):
                    yield Hit(match.start(), match.end(), match.group(0), term.replacement, None)


class EmDashRule:
    """R2: длинное тире U+2014 при политике «только `–`». Fixable."""

    id = "em-dash"

    def scan_line(self, line: Line) -> Iterable[Hit]:
        for match in EM_DASH.finditer(line.masked):
            yield Hit(match.start(), match.end(), match.group(0), "длинное тире, замените на –", EN_DASH)


class WhitespaceRule:
    """R4: двойные пробелы и пробел перед пунктуацией. Fixable.

    Пропускает строки markdown-таблиц: там пробелы выравнивают ячейки, а не
    засоряют прозу. Запрещенные основы и длинное тире в ячейках ловят другие
    правила, поэтому carve-out локальный, а не исключение всей строки.
    """

    id = "whitespace"

    def scan_line(self, line: Line) -> Iterable[Hit]:
        if line.is_table_row:
            return

        for match in DOUBLE_SPACE.finditer(line.raw):
            if not in_spans(match.start(), line.spans):
                yield Hit(match.start(), match.end(), match.group(0), "лишние пробелы", " ")

        for match in SPACE_BEFORE_PUNCT.finditer(line.raw):
            if not in_spans(match.start(1), line.spans):
                yield Hit(match.start(1), match.end(1), match.group(1), "пробел перед пунктуацией", "")


def load_terms(path: Path) -> list[Term]:
    """Читает и компилирует стоп-лист из TOML.

    Raises:
        ValueError: Если в файле нет ни одной записи `[[term]]`, запись без
            обязательного ключа или с некомпилируемым regex в `patterns`.
            Любой из этих дефектов делает gate ненадежным, поэтому это ошибка
            конфигурации, а не повод молча пропустить запись.
    """
    data: dict[str, Any] = tomllib.loads(path.read_text(encoding="utf-8-sig"))
    entries: list[TermEntry] = data.get("term", [])

    terms: list[Term] = []
    for entry in entries:
        try:
            matchers = tuple(
                re.compile(STEM_TEMPLATE.format(stem=stem), re.IGNORECASE)
                for stem in entry["patterns"]
            )
            terms.append(Term(id=entry["id"], replacement=entry["replacement"], matchers=matchers))
        except KeyError as exc:
            raise ValueError(f"запись [[term]] без обязательного ключа {exc}") from exc
        except re.error as exc:
            raise ValueError(f"[[term]] {entry.get('id', '?')}: битый regex в patterns: {exc}") from exc

    if not terms:
        raise ValueError(f"стоп-лист пуст: {path} не содержит ни одного [[term]]")

    return terms


def build_rules(terms: list[Term]) -> list[Rule]:
    """Собирает включенные правила Tier 1 в порядке применения."""
    return [TermRule(terms), EmDashRule(), WhitespaceRule()]


def prose_spans(line: str) -> list[tuple[int, int]]:
    """Возвращает span inline-кода и URL, где правила не действуют."""
    spans: list[tuple[int, int]] = []
    for pattern in MASK_INLINE:
        spans.extend((match.start(), match.end()) for match in pattern.finditer(line))

    return spans


def blank_spans(line: str, spans: list[tuple[int, int]]) -> str:
    """Заменяет символы в span пробелами, сохраняя длину и колонки."""
    if not spans:
        return line

    chars = list(line)
    for start, end in spans:
        for i in range(start, end):
            chars[i] = " "

    return "".join(chars)


def in_spans(pos: int, spans: list[tuple[int, int]]) -> bool:
    """Истина, если позиция попадает в один из исключенных span."""
    return any(start <= pos < end for start, end in spans)


def line_kinds(text: str) -> tuple[set[int], set[int]]:
    """Классифицирует строки, 0-индекс.

    Returns:
        Пара `(excluded, tables)`. `excluded` - строки кода, HTML и frontmatter,
        где правила не действуют совсем. `tables` - строки markdown-таблиц для
        per-rule carve-out.
    """
    excluded: set[int] = set()
    tables: set[int] = set()

    lines = text.splitlines()
    if lines and lines[0].strip() == "---":
        for i in range(1, len(lines)):
            if lines[i].strip() in FRONTMATTER_FENCE:
                excluded.update(range(0, i + 1))
                break

    for token in _MD.parse(text):
        if not token.map:
            continue

        if token.type in BLOCK_CODE_TYPES:
            excluded.update(range(token.map[0], token.map[1]))
        elif token.type == "table_open":
            tables.update(range(token.map[0], token.map[1]))

    return excluded, tables


def _build_line(raw: str, index: int, tables: set[int]) -> Line:
    """Собирает `Line` с маской и флагом таблицы для одной строки."""
    spans = prose_spans(raw)
    return Line(raw=raw, masked=blank_spans(raw, spans), spans=spans, is_table_row=index in tables)


def scan(path: Path, rules: list[Rule]) -> list[Finding]:
    """Прогоняет все правила по прозе одного Markdown-файла."""
    text = path.read_text(encoding="utf-8-sig")
    skip, tables = line_kinds(text)

    findings: list[Finding] = []
    for index, raw in enumerate(text.splitlines()):
        if index in skip:
            continue

        line = _build_line(raw, index, tables)
        for rule in rules:
            for hit in rule.scan_line(line):
                findings.append(
                    Finding(
                        path=path,
                        line=index + 1,
                        col=hit.start + 1,
                        rule_id=rule.id,
                        matched=hit.matched,
                        message=hit.message,
                        fixable=hit.replacement is not None,
                    )
                )

    return findings


def _fix_line(line: Line, rules: list[Rule]) -> str:
    """Применяет fixable-правила к строке, замены справа-налево без пересечений."""
    hits = [hit for rule in rules for hit in rule.scan_line(line) if hit.replacement is not None]
    hits.sort(key=lambda hit: hit.start, reverse=True)

    result = line.raw
    applied: list[tuple[int, int]] = []
    for hit in hits:
        if any(not (hit.end <= start or hit.start >= end) for start, end in applied):
            continue

        assert hit.replacement is not None
        result = result[: hit.start] + hit.replacement + result[hit.end :]
        applied.append((hit.start, hit.end))

    return result


def fix_file(path: Path, rules: list[Rule]) -> list[Finding]:
    """Чинит fixable-правила в файле и возвращает оставшиеся findings."""
    text = path.read_text(encoding="utf-8-sig")
    had_trailing_nl = text.endswith("\n")
    skip, tables = line_kinds(text)

    fixed: list[str] = []
    for index, raw in enumerate(text.splitlines()):
        fixed.append(raw if index in skip else _fix_line(_build_line(raw, index, tables), rules))

    new_text = "\n".join(fixed) + ("\n" if had_trailing_nl else "")
    if new_text != text:
        path.write_text(new_text, encoding="utf-8")

    return scan(path, rules)


def main(argv: list[str] | None = None) -> int:
    """Разбирает аргументы, прогоняет линтер и возвращает код выхода.

    Коды выхода: 0 - чисто, 1 - остались findings, 2 - ошибка конфигурации или
    чтения файла. Ошибка приоритетнее findings: exit 2 означает неполный прогон.
    """
    parser = argparse.ArgumentParser(description="Детерминированный линтер (Tier 1) для русского Markdown.")
    parser.add_argument("files", nargs="+", type=Path, help="Markdown-файлы для проверки.")
    parser.add_argument(
        "--terms",
        type=Path,
        default=DEFAULT_TERMS,
        help=f"Путь к banned-terms.toml (по умолчанию {DEFAULT_TERMS}).",
    )
    parser.add_argument(
        "--fix",
        action="store_true",
        help="Починить fixable-правила на месте; report-only остается в выводе.",
    )
    args = parser.parse_args(argv)

    try:
        terms = load_terms(args.terms)
    except (OSError, ValueError, tomllib.TOMLDecodeError) as exc:
        print(f"error: не удалось загрузить стоп-лист {args.terms}: {exc}", file=sys.stderr)
        return 2

    rules = build_rules(terms)

    findings: list[Finding] = []
    read_errors = 0
    for path in args.files:
        if path.suffix.lower() not in {".md", ".markdown"}:
            print(f"{path}: skip: не markdown-файл", file=sys.stderr)
            continue

        try:
            findings.extend(fix_file(path, rules) if args.fix else scan(path, rules))
        except (OSError, ValueError) as exc:
            print(f"{path}: error: {exc}", file=sys.stderr)
            read_errors += 1

    for finding in findings:
        print(f"{finding.path}:{finding.line}:{finding.col}: {finding.rule_id}: '{finding.matched}' -> {finding.message}")

    if findings:
        print(f"\nОсталось findings: {len(findings)}", file=sys.stderr)

    # Ошибка чтения приоритетнее findings: прогон неполный, exit 1 создал бы
    # ложное впечатление полного отчета.
    if read_errors:
        return 2

    return 1 if findings else 0


if __name__ == "__main__":
    raise SystemExit(main())
