#!/usr/bin/env python3
"""Deterministic storage CLI for the learning-backlog skill.

One entry is one Markdown file with YAML frontmatter in the data directory
(default ~/.local/share/learning-backlog; override with LEARNING_BACKLOG_DIR or
--dir). The files are the only source of truth: list and filters re-read the
directory on every call, there is no index. The data directory is separate from
the skill, so reinstalling the skill never touches stored entries.

Entry layout (the canonical form lives in assets/entry-template.md):

    ---
    id: LB-0001
    title: "..."
    status: open | learned | archived
    created_at: 2026-10-16T16:20:05+03:00
    updated_at: 2026-10-16T16:20:05+03:00
    project: "..."          # optional
    tags: ["...", "..."]    # optional
    ---

    # <title>

    ## Что хочу понять
    ## Контекст
    ## Пример
    ## Решение и альтернативы
    (optional extra sections follow)

Body input for `add` and `update --section` is read from stdin or --body-file.
Exit codes: 0 = success, 1 = data or validation error, 2 = usage error.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import tempfile
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

DIR_ENV = "LEARNING_BACKLOG_DIR"
DEFAULT_DIR = Path.home() / ".local" / "share" / "learning-backlog"
TEMPLATE_PATH = Path(__file__).resolve().parent.parent / "assets" / "entry-template.md"

ID_PREFIX = "LB-"
ID_WIDTH = 4
ENTRY_FILE_RE = re.compile(r"^LB-(\d{4,})\.md$")
ID_ARG_RE = re.compile(r"^(?:lb-?)?(\d+)$", re.IGNORECASE)

STATUSES = ("open", "learned", "archived")
QUESTION = "Что хочу понять"
REQUIRED_SECTIONS = (QUESTION, "Контекст", "Пример", "Решение и альтернативы")
EMPTY_SECTION = "Не зафиксировано."

TAG_RE = re.compile(r"^[\w.+#-]+$")
MAX_TITLE_LENGTH = 200
FENCE_RE = re.compile(r"^\s{0,3}(`{3,}|~{3,})")
HEADING_RE = re.compile(r"^(#{1,6}) ")


class CliError(Exception):
    """A data or validation error reported to the user with exit code 1."""


@dataclass
class Entry:
    """One learning-backlog entry as stored on disk."""

    id: str
    title: str
    status: str
    created_at: str
    updated_at: str
    project: str | None = None
    tags: list[str] = field(default_factory=list)
    sections: list[tuple[str, str]] = field(default_factory=list)
    path: Path | None = None

    def section(self, heading: str) -> str:
        for name, text in self.sections:
            if name == heading:
                return text

        return ""

    def as_dict(self) -> dict[str, object]:
        return {
            "id": self.id,
            "title": self.title,
            "status": self.status,
            "created_at": self.created_at,
            "updated_at": self.updated_at,
            "project": self.project,
            "tags": self.tags,
            "question": self.section(QUESTION),
            "path": str(self.path) if self.path else None,
        }


# --- time and identifiers -------------------------------------------------


def now_iso() -> str:
    return datetime.now().astimezone().replace(microsecond=0).isoformat()


def format_id(number: int) -> str:
    return f"{ID_PREFIX}{number:0{ID_WIDTH}d}"


def resolve_id(raw: str) -> str:
    match = ID_ARG_RE.match(raw.strip())
    if not match:
        raise CliError(f"некорректный ID {raw!r}: ожидается LB-0012, LB-12 или 12")

    return format_id(int(match.group(1)))


# --- field validation -----------------------------------------------------


def clean_title(raw: str) -> str:
    title = raw.strip()
    if not title:
        raise CliError("title не может быть пустым")

    if "\n" in title or "\r" in title:
        raise CliError("title должен быть одной строкой")

    if len(title) > MAX_TITLE_LENGTH:
        raise CliError(f"title длиннее {MAX_TITLE_LENGTH} символов")

    return title


def clean_project(raw: str | None) -> str | None:
    if raw is None:
        return None

    project = raw.strip()
    if not project:
        return None

    if "\n" in project:
        raise CliError("project должен быть одной строкой")

    return project


def clean_tags(raw_tags: list[str]) -> list[str]:
    tags: list[str] = []
    for raw in raw_tags:
        for part in raw.split(","):
            tag = part.strip().lower()
            if not tag:
                continue

            if not TAG_RE.match(tag):
                raise CliError(f"некорректный тег {tag!r}: без пробелов, допустимы буквы, цифры и . + # - _")

            if tag not in tags:
                tags.append(tag)

    return tags


def check_timestamp(value: object, key: str, source: str) -> str:
    if not isinstance(value, str):
        raise CliError(f"{source}: поле {key} должно быть датой ISO 8601")

    try:
        datetime.fromisoformat(value)
    except ValueError as error:
        raise CliError(f"{source}: поле {key} не является датой ISO 8601: {value!r}") from error

    return value


# --- Markdown structure ---------------------------------------------------


def iter_lines_with_fence(text: str) -> list[tuple[str, bool]]:
    """Pairs every line with a flag telling whether it sits inside a code fence."""
    result: list[tuple[str, bool]] = []
    fence: str | None = None

    for line in text.split("\n"):
        match = FENCE_RE.match(line)
        if fence is None and match:
            fence = match.group(1)
            result.append((line, True))
            continue

        if fence is not None:
            marker = match.group(1) if match else ""
            if marker[:1] == fence[0] and len(marker) >= len(fence) and line.strip() == marker:
                fence = None

            result.append((line, True))
            continue

        result.append((line, False))

    return result


def split_sections(body: str, source: str, allow_title: bool) -> list[tuple[str, str]]:
    """Splits a Markdown body into `## ` sections, ignoring headings inside code fences."""
    sections: list[tuple[str, str]] = []
    current: str | None = None
    buffer: list[str] = []

    for line, in_fence in iter_lines_with_fence(body):
        if not in_fence and line.startswith("## "):
            if current is not None:
                sections.append((current, "\n".join(buffer).strip()))

            current = line[3:].strip()
            buffer = []
            if not current:
                raise CliError(f"{source}: пустой заголовок раздела")

            continue

        if current is not None:
            buffer.append(line)
            continue

        if not line.strip():
            continue

        if allow_title and line.startswith("# "):
            continue

        raise CliError(f"{source}: текст до первого раздела `## `: {line.strip()[:60]!r}")

    if current is not None:
        sections.append((current, "\n".join(buffer).strip()))

    return sections


def normalize_sections(sections: list[tuple[str, str]], source: str) -> list[tuple[str, str]]:
    """Puts required sections first in canonical order and fills the empty ones."""
    seen: dict[str, str] = {}
    order: list[str] = []
    for heading, text in sections:
        if heading in seen:
            raise CliError(f"{source}: раздел {heading!r} встречается дважды")

        seen[heading] = text
        order.append(heading)

    question = seen.get(QUESTION, "").strip()
    if not question or question == EMPTY_SECTION:
        raise CliError(f"{source}: раздел «{QUESTION}» обязателен и не может быть пустым")

    normalized = [(heading, seen.get(heading, "").strip() or EMPTY_SECTION) for heading in REQUIRED_SECTIONS]
    extras = [(heading, seen[heading].strip() or EMPTY_SECTION) for heading in order if heading not in REQUIRED_SECTIONS]

    return normalized + extras


def demote_headings(text: str) -> str:
    lines = []
    for line, in_fence in iter_lines_with_fence(text):
        if not in_fence and HEADING_RE.match(line) and not line.startswith("###### "):
            line = "#" + line

        lines.append(line)

    return "\n".join(lines)


# --- frontmatter ----------------------------------------------------------


def parse_scalar(raw: str) -> object:
    value = raw.strip()
    if value in ("", "~", "null"):
        return None

    if value.startswith('"'):
        try:
            return json.loads(value)
        except json.JSONDecodeError as error:
            raise ValueError(f"некорректная строка в кавычках: {value!r}") from error

    if value.startswith("'"):
        if len(value) < 2 or not value.endswith("'"):
            raise ValueError(f"незакрытая строка в кавычках: {value!r}")

        return value[1:-1].replace("''", "'")

    if value.startswith("["):
        if not value.endswith("]"):
            raise ValueError(f"незакрытый список: {value!r}")

        try:
            return json.loads(value)
        except json.JSONDecodeError:
            inner = value[1:-1].strip()
            return [parse_scalar(item) for item in inner.split(",")] if inner else []

    return value


def parse_frontmatter(text: str, source: str) -> tuple[dict[str, object], str]:
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        raise CliError(f"{source}: файл не начинается с YAML frontmatter")

    end = next((index for index in range(1, len(lines)) if lines[index].strip() == "---"), None)
    if end is None:
        raise CliError(f"{source}: frontmatter не закрыт строкой ---")

    meta: dict[str, object] = {}
    list_key: str | None = None
    for raw in lines[1:end]:
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue

        item = re.match(r"^\s*-\s+(.*)$", raw)
        if item and list_key is not None:
            current = meta.get(list_key)
            items = current if isinstance(current, list) else []
            items.append(parse_scalar(item.group(1)))
            meta[list_key] = items
            continue

        pair = re.match(r"^([A-Za-z_][\w-]*):(?:\s+(.*))?$", raw)
        if not pair:
            raise CliError(f"{source}: неподдерживаемая строка frontmatter: {raw!r}")

        key, value = pair.group(1), pair.group(2) or ""
        try:
            meta[key] = parse_scalar(value)
        except ValueError as error:
            raise CliError(f"{source}: поле {key}: {error}") from error

        list_key = key if not value.strip() else None

    return meta, "\n".join(lines[end + 1 :])


def entry_from_text(text: str, path: Path) -> Entry:
    source = str(path)
    meta, body = parse_frontmatter(text, source)

    for key in ("id", "title", "status", "created_at", "updated_at"):
        if meta.get(key) in (None, ""):
            raise CliError(f"{source}: нет обязательного поля {key}")

    entry_id = str(meta["id"])
    if f"{entry_id}.md" != path.name:
        raise CliError(f"{source}: id {entry_id!r} не совпадает с именем файла")

    status = str(meta["status"])
    if status not in STATUSES:
        raise CliError(f"{source}: недопустимый status {status!r}, ожидается один из {', '.join(STATUSES)}")

    tags = meta.get("tags") or []
    if not isinstance(tags, list):
        tags = [tags]

    try:
        title = clean_title(str(meta["title"]))
        project = clean_project(None if meta.get("project") is None else str(meta["project"]))
        clean = clean_tags([str(tag) for tag in tags if tag is not None])
    except CliError as error:
        raise CliError(f"{source}: {error}") from error

    sections = normalize_sections(split_sections(body, source, allow_title=True), source)

    return Entry(
        id=entry_id,
        title=title,
        status=status,
        created_at=check_timestamp(meta["created_at"], "created_at", source),
        updated_at=check_timestamp(meta["updated_at"], "updated_at", source),
        project=project,
        tags=clean,
        sections=sections,
        path=path,
    )


def render_entry(entry: Entry) -> str:
    lines = [
        "---",
        f"id: {entry.id}",
        f"title: {json.dumps(entry.title, ensure_ascii=False)}",
        f"status: {entry.status}",
        f"created_at: {entry.created_at}",
        f"updated_at: {entry.updated_at}",
    ]
    if entry.project:
        lines.append(f"project: {json.dumps(entry.project, ensure_ascii=False)}")

    if entry.tags:
        lines.append(f"tags: {json.dumps(entry.tags, ensure_ascii=False)}")

    lines += ["---", "", f"# {entry.title}", ""]
    for heading, text in entry.sections:
        lines += [f"## {heading}", "", text.strip() or EMPTY_SECTION, ""]

    return "\n".join(lines)


# --- storage --------------------------------------------------------------


def data_dir(override: str | None) -> Path:
    raw = override or os.environ.get(DIR_ENV) or str(DEFAULT_DIR)
    return Path(raw).expanduser()


def write_temp(directory: Path, content: str) -> Path:
    handle = tempfile.NamedTemporaryFile(
        "w", encoding="utf-8", dir=directory, prefix=".tmp-", suffix=".md", delete=False
    )
    with handle:
        handle.write(content)
        handle.flush()
        os.fsync(handle.fileno())

    return Path(handle.name)


def create_entry(directory: Path, entry: Entry) -> Entry:
    """Allocates the next free ID and publishes the file atomically, never overwriting."""
    directory.mkdir(parents=True, exist_ok=True)
    numbers = [int(match.group(1)) for path in directory.iterdir() if (match := ENTRY_FILE_RE.match(path.name))]
    number = max(numbers, default=0) + 1

    while True:
        entry.id = format_id(number)
        target = directory / f"{entry.id}.md"
        temp = write_temp(directory, render_entry(entry))
        try:
            os.link(temp, target)
        except FileExistsError:
            number += 1
            continue
        finally:
            temp.unlink()

        entry.path = target
        return entry


def save_entry(entry: Entry) -> None:
    if entry.path is None:
        raise CliError(f"{entry.id}: путь записи неизвестен")

    temp = write_temp(entry.path.parent, render_entry(entry))
    try:
        os.replace(temp, entry.path)
    except OSError:
        temp.unlink(missing_ok=True)
        raise


def load_entry(directory: Path, raw_id: str) -> Entry:
    entry_id = resolve_id(raw_id)
    path = directory / f"{entry_id}.md"
    if not path.is_file():
        raise CliError(f"запись {entry_id} не найдена в {directory}")

    return entry_from_text(path.read_text(encoding="utf-8"), path)


def load_all(directory: Path) -> tuple[list[Entry], list[str]]:
    if not directory.is_dir():
        return [], []

    entries: list[Entry] = []
    errors: list[str] = []
    for path in sorted(directory.iterdir()):
        if not ENTRY_FILE_RE.match(path.name):
            continue

        try:
            entries.append(entry_from_text(path.read_text(encoding="utf-8"), path))
        except (CliError, OSError, UnicodeDecodeError) as error:
            errors.append(str(error))

    entries.sort(key=lambda entry: int(entry.id[len(ID_PREFIX) :]))
    return entries, errors


def read_body(body_file: str | None) -> str:
    if body_file and body_file != "-":
        return Path(body_file).expanduser().read_text(encoding="utf-8")

    if sys.stdin.isatty():
        raise CliError("текст не передан: подайте Markdown через stdin или --body-file")

    return sys.stdin.read()


# --- commands -------------------------------------------------------------


def cmd_add(args: argparse.Namespace) -> int:
    source = "текст записи"
    sections = normalize_sections(split_sections(read_body(args.body_file), source, allow_title=False), source)
    timestamp = now_iso()
    entry = Entry(
        id="",
        title=clean_title(args.title),
        status="open",
        created_at=timestamp,
        updated_at=timestamp,
        project=clean_project(args.project),
        tags=clean_tags(args.tag),
        sections=sections,
    )

    created = create_entry(data_dir(args.dir), entry)
    print(f"{created.id} {created.title}")
    print(created.path)
    return 0


def matches(entry: Entry, args: argparse.Namespace) -> bool:
    if args.status != "all" and entry.status != args.status:
        return False

    if args.project and (entry.project or "").casefold() != args.project.strip().casefold():
        return False

    if any(tag not in entry.tags for tag in clean_tags(args.tag)):
        return False

    if args.query:
        haystack = "\n".join([entry.title, *(text for _, text in entry.sections)]).casefold()
        if args.query.casefold() not in haystack:
            return False

    return True


def cmd_list(args: argparse.Namespace) -> int:
    directory = data_dir(args.dir)
    entries, errors = load_all(directory)
    selected = [entry for entry in entries if matches(entry, args)]

    if args.format == "json":
        print(json.dumps([entry.as_dict() for entry in selected], ensure_ascii=False, indent=2))
    elif not selected:
        print("Нет записей по заданному фильтру." if entries else f"Записей нет: {directory}")
    else:
        for entry in selected:
            tags = f"[{', '.join(entry.tags)}]" if entry.tags else "-"
            columns = [entry.id, entry.status, entry.updated_at[:10], entry.project or "-", tags, entry.title]
            print("  ".join(columns))

        print(f"Записей: {len(selected)}")

    for error in errors:
        print(f"learning-backlog: пропущен некорректный файл: {error}", file=sys.stderr)

    return 1 if errors else 0


def cmd_show(args: argparse.Namespace) -> int:
    entry = load_entry(data_dir(args.dir), args.id)
    if args.format == "json":
        payload = entry.as_dict()
        payload["sections"] = dict(entry.sections)
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print(f"<!-- {entry.path} -->")
        print(render_entry(entry), end="")

    return 0


def cmd_update(args: argparse.Namespace) -> int:
    entry = load_entry(data_dir(args.dir), args.id)
    changed = False

    if args.title is not None:
        entry.title = clean_title(args.title)
        changed = True

    if args.clear_project:
        entry.project = None
        changed = True
    elif args.project is not None:
        entry.project = clean_project(args.project)
        changed = True

    if args.add_tag:
        entry.tags = clean_tags(entry.tags + args.add_tag)
        changed = True

    if args.remove_tag:
        removed = clean_tags(args.remove_tag)
        entry.tags = [tag for tag in entry.tags if tag not in removed]
        changed = True

    if args.section is not None:
        update_section(entry, args)
        changed = True
    elif args.mode or args.stamp or args.body_file:
        raise CliError("--mode, --stamp и --body-file работают только вместе с --section")

    if not changed:
        raise CliError("нечего обновлять: укажите --title, --project, --add-tag, --remove-tag или --section")

    entry.updated_at = now_iso()
    save_entry(entry)
    print(f"{entry.id} {entry.title}")
    print(entry.path)
    return 0


def update_section(entry: Entry, args: argparse.Namespace) -> None:
    heading = args.section.strip()
    mode = args.mode or "append"
    if not heading or "\n" in heading:
        raise CliError("--section должен быть непустым названием раздела в одну строку")

    if heading == QUESTION and mode == "replace":
        raise CliError(f"раздел «{QUESTION}» хранит исходный вопрос: его можно только дополнять (--mode append)")

    text = read_body(args.body_file).strip()
    if not text:
        raise CliError("текст для раздела пустой")

    if any(not in_fence and line.startswith("## ") for line, in_fence in iter_lines_with_fence(text)):
        raise CliError("текст раздела не должен содержать заголовков `## `; используйте `###` и ниже")

    if args.stamp:
        text = f"### {now_iso()[:10]}\n\n{text}"

    sections = dict(entry.sections)
    current = sections.get(heading, "")
    if mode == "append" and current and current != EMPTY_SECTION:
        sections[heading] = f"{current}\n\n{text}"
    else:
        sections[heading] = text

    order = [name for name, _ in entry.sections]
    if heading not in order:
        order.append(heading)

    entry.sections = normalize_sections([(name, sections[name]) for name in order], entry.id)


def cmd_set_status(args: argparse.Namespace) -> int:
    entry = load_entry(data_dir(args.dir), args.id)
    if args.status == "learned" and not args.user_confirmed:
        raise CliError("status learned ставится только по явному слову пользователя: добавьте --user-confirmed")

    if entry.status == args.status:
        print(f"{entry.id} уже в статусе {entry.status}")
        return 0

    entry.status = args.status
    entry.updated_at = now_iso()
    save_entry(entry)
    print(f"{entry.id} {entry.status} {entry.title}")
    return 0


def cmd_export(args: argparse.Namespace) -> int:
    directory = data_dir(args.dir)
    ids = list(dict.fromkeys(resolve_id(raw) for raw in args.ids))
    entries = [load_entry(directory, entry_id) for entry_id in ids]

    if args.format == "json":
        payload = []
        for entry in entries:
            item = entry.as_dict()
            item["sections"] = dict(entry.sections)
            payload.append(item)

        print(json.dumps(payload, ensure_ascii=False, indent=2))
        return 0

    lines = ["# Темы для плана обучения", ""]
    for entry in entries:
        meta = [f"статус: {entry.status}", f"создано: {entry.created_at[:10]}"]
        if entry.project:
            meta.append(f"проект: {entry.project}")

        if entry.tags:
            meta.append(f"теги: {', '.join(entry.tags)}")

        lines += [f"## {entry.id}. {entry.title}", "", "; ".join(meta), ""]
        for heading, text in entry.sections:
            lines += [f"### {heading}", "", demote_headings(text), ""]

    print("\n".join(lines), end="")
    return 0


def cmd_template(_args: argparse.Namespace) -> int:
    print(TEMPLATE_PATH.read_text(encoding="utf-8"), end="")
    return 0


def cmd_dir(args: argparse.Namespace) -> int:
    print(data_dir(args.dir))
    return 0


# --- argument parsing -----------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="learning_backlog.py",
        description="Бэклог тем для изучения: Markdown-файлы с YAML frontmatter.",
    )
    parser.add_argument("--dir", help=f"каталог данных (по умолчанию ${DIR_ENV} или {DEFAULT_DIR})")
    commands = parser.add_subparsers(dest="command", required=True)

    add = commands.add_parser("add", help="создать запись; разделы `## ` читаются из stdin")
    add.add_argument("--title", required=True)
    add.add_argument("--project")
    add.add_argument("--tag", action="append", default=[], help="можно повторять или перечислить через запятую")
    add.add_argument("--body-file", help="файл с разделами вместо stdin")
    add.set_defaults(handler=cmd_add)

    listing = commands.add_parser("list", help="показать записи с фильтрами")
    listing.add_argument("--status", choices=(*STATUSES, "all"), default="open")
    listing.add_argument("--project")
    listing.add_argument("--tag", action="append", default=[], help="все указанные теги должны совпасть")
    listing.add_argument("--query", help="подстрока в названии или тексте, без учета регистра")
    listing.add_argument("--format", choices=("table", "json"), default="table")
    listing.set_defaults(handler=cmd_list)

    show = commands.add_parser("show", help="показать запись целиком")
    show.add_argument("id")
    show.add_argument("--format", choices=("markdown", "json"), default="markdown")
    show.set_defaults(handler=cmd_show)

    update = commands.add_parser("update", help="изменить метаданные или раздел")
    update.add_argument("id")
    update.add_argument("--title")
    update.add_argument("--project")
    update.add_argument("--clear-project", action="store_true")
    update.add_argument("--add-tag", action="append", default=[])
    update.add_argument("--remove-tag", action="append", default=[])
    update.add_argument("--section", help="название раздела; текст читается из stdin или --body-file")
    update.add_argument("--mode", choices=("append", "replace"), help="по умолчанию append")
    update.add_argument("--stamp", action="store_true", help="начать добавляемый текст заголовком ### с датой")
    update.add_argument("--body-file")
    update.set_defaults(handler=cmd_update)

    status = commands.add_parser("set-status", help="сменить статус")
    status.add_argument("id")
    status.add_argument("status", choices=STATUSES)
    status.add_argument("--user-confirmed", action="store_true", help="обязателен для learned")
    status.set_defaults(handler=cmd_set_status)

    export = commands.add_parser("export", help="выгрузить выбранные записи для плана обучения")
    export.add_argument("ids", nargs="+")
    export.add_argument("--format", choices=("markdown", "json"), default="markdown")
    export.set_defaults(handler=cmd_export)

    template = commands.add_parser("template", help="показать шаблон записи")
    template.set_defaults(handler=cmd_template)

    directory = commands.add_parser("dir", help="показать каталог данных")
    directory.set_defaults(handler=cmd_dir)

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        return args.handler(args)
    except CliError as error:
        print(f"learning-backlog: {error}", file=sys.stderr)
        return 1
    except OSError as error:
        print(f"learning-backlog: ошибка файловой системы: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
