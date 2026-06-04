#!/usr/bin/env python3
"""Детерминированная механика daily-log: создание дейли-заметки и idempotent-апсерт блока.

Скрипт делает только хрупкую работу с файлом, чтобы не воспроизводить ее в каждом запуске
модели и не повредить заметку:

- ``prepare``: гарантирует, что заметка за дату существует (создает из шаблона при отсутствии),
  и печатает JSON с путем, текущим содержимым блока daily-log (если он уже есть) и сырым телом
  заметки. Модель использует это, чтобы смержить новый блок с уже записанным.
- ``write``: вставляет или заменяет блок daily-log между маркерами, обновляет ``updated`` во
  frontmatter и сохраняет все остальное без изменений.

Блок ограничен HTML-комментариями ``<!-- daily-log:start -->`` / ``<!-- daily-log:end -->`` и
ставится перед ``# Back Matter``. Внутри блока живут обычные заголовки схемы work-daily-note
(``## Done``, ``## Decisions`` и т.д.), поэтому ``work-weekly-review consolidate`` читает их как
поля дня. Полная замена блока делает повторный запуск idempotent: модель отдает смерженный
суперсет, скрипт переписывает регион целиком.

Зависимостей нет, только стандартная библиотека.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import json
import sys
from pathlib import Path

DEFAULT_VAULT = Path.home() / "projects" / "work-vault"
DAILY_SUBPATH = "1_Planning/Daily"
TEMPLATE_SUBPATH = "Templates/1_Daily Planning.md"

START_MARKER = "<!-- daily-log:start -->"
END_MARKER = "<!-- daily-log:end -->"
BACK_MATTER_HEADING = "# Back Matter"

TS_FORMAT = "%Y-%m-%dT%H:%M"


def _now_ts() -> str:
    """Возвращает локальную метку времени в формате заметок (``YYYY-MM-DDTHH:MM``)."""
    return _dt.datetime.now().strftime(TS_FORMAT)


def _resolve_date(raw: str | None) -> _dt.date:
    """Парсит дату ``YYYY-MM-DD`` или ``today``; по умолчанию сегодня."""
    if raw is None or raw == "today":
        return _dt.date.today()
    return _dt.datetime.strptime(raw, "%Y-%m-%d").date()


def _note_path(vault: Path, day: _dt.date) -> Path:
    """Строит путь к дейли-заметке: ``<vault>/1_Planning/Daily/<year>/<YYYY-MM-DD>.md``."""
    return vault / DAILY_SUBPATH / str(day.year) / f"{day.isoformat()}.md"


def _split_frontmatter(text: str) -> tuple[str, str]:
    """Делит текст на frontmatter (с разделителями) и тело.

    Returns:
        Кортеж ``(frontmatter, body)``. Если frontmatter нет, первый элемент пустой.
    """
    if not text.startswith("---\n"):
        return "", text
    end = text.find("\n---\n", 4)
    if end == -1:
        return "", text
    return text[: end + len("\n---\n")], text[end + len("\n---\n") :]


def _bump_updated(frontmatter: str, ts: str) -> str:
    """Обновляет поле ``updated`` во frontmatter, не трогая остальные строки."""
    if not frontmatter:
        return frontmatter
    out: list[str] = []
    replaced = False
    for line in frontmatter.splitlines():
        if line.startswith("updated:"):
            out.append(f"updated: {ts}")
            replaced = True
        else:
            out.append(line)
    if not replaced:
        # Поля updated не было: вставляем перед закрывающим разделителем.
        insert_at = len(out) - 1 if out and out[-1] == "---" else len(out)
        out.insert(insert_at, f"updated: {ts}")
    return "\n".join(out) + ("\n" if frontmatter.endswith("\n") else "")


def _extract_block(body: str) -> str | None:
    """Возвращает содержимое блока daily-log между маркерами или ``None``, если блока нет."""
    start = body.find(START_MARKER)
    if start == -1:
        return None
    end = body.find(END_MARKER, start)
    if end == -1:
        return None
    inner = body[start + len(START_MARKER) : end]
    return inner.strip("\n")


def _create_from_template(vault: Path, path: Path) -> None:
    """Создает дейли-заметку из шаблона, заполняя ``created``/``updated``."""
    template_path = vault / TEMPLATE_SUBPATH
    if template_path.exists():
        text = template_path.read_text(encoding="utf-8")
    else:
        text = (
            "---\ntags:\n  - type/planning\n  - theme/work\n"
            'created: ""\nupdated: ""\ntemplate-type: Planning\n'
            "template-version: 0.1.0\n---\n# Daily plan\n\n## Meetings\n\n- [ ] \n\n"
            "## Tasks\n\n- [ ] \n\n---\n# Back Matter\n\n## Questions\n- \n"
        )
    ts = _now_ts()
    text = text.replace('created: ""', f"created: {ts}").replace('updated: ""', f"updated: {ts}")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def cmd_prepare(args: argparse.Namespace) -> int:
    """Гарантирует наличие заметки и печатает JSON с путем, текущим блоком и телом."""
    vault = Path(args.vault).expanduser()
    day = _resolve_date(args.date)
    path = _note_path(vault, day)
    created = False
    if not path.exists():
        _create_from_template(vault, path)
        created = True
    text = path.read_text(encoding="utf-8")
    _, body = _split_frontmatter(text)
    result = {
        "path": str(path),
        "date": day.isoformat(),
        "created_now": created,
        "existing_block": _extract_block(body),
        "note_body": body,
    }
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    sys.stdout.write("\n")
    return 0


def _insert_block(body: str, block: str) -> str:
    """Вставляет или заменяет блок daily-log в теле заметки.

    Если блок уже есть, заменяет его содержимое. Иначе ставит блок перед ``# Back Matter``
    (или в конец тела, если заголовка нет), отделяя пустыми строками.
    """
    wrapped = f"{START_MARKER}\n{block.strip()}\n{END_MARKER}"
    start = body.find(START_MARKER)
    if start != -1:
        end = body.find(END_MARKER, start)
        if end != -1:
            end += len(END_MARKER)
            return body[:start] + wrapped + body[end:]
    # Блока нет: ставим перед Back Matter.
    bm = body.find(BACK_MATTER_HEADING)
    if bm != -1:
        # Откатываемся к началу возможного разделителя ``---`` перед заголовком.
        prefix = body[:bm].rstrip("\n")
        sep = ""
        if prefix.endswith("---"):
            prefix = prefix[: -len("---")].rstrip("\n")
            sep = "---\n"
        suffix = body[bm:]
        return f"{prefix}\n\n{wrapped}\n\n{sep}{suffix}"
    return body.rstrip("\n") + f"\n\n{wrapped}\n"


def cmd_write(args: argparse.Namespace) -> int:
    """Записывает блок daily-log в заметку и обновляет ``updated``."""
    vault = Path(args.vault).expanduser()
    day = _resolve_date(args.date)
    path = _note_path(vault, day)
    if not path.exists():
        _create_from_template(vault, path)
    block = Path(args.file).read_text(encoding="utf-8") if args.file else sys.stdin.read()
    if not block.strip():
        sys.stderr.write("daily_log: пустой блок, нечего записывать\n")
        return 2
    text = path.read_text(encoding="utf-8")
    frontmatter, body = _split_frontmatter(text)
    new_body = _insert_block(body, block)
    frontmatter = _bump_updated(frontmatter, _now_ts())
    path.write_text(frontmatter + new_body, encoding="utf-8")
    sys.stdout.write(f"{path}\n")
    return 0


def main(argv: list[str] | None = None) -> int:
    # Общие аргументы вынесены в parent-парсер, чтобы --vault/--date работали
    # после подкоманды (`prepare --date today`), как в примерах SKILL.md.
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--vault", default=str(DEFAULT_VAULT), help="Путь к Obsidian vault")
    common.add_argument("--date", default=None, help="Дата YYYY-MM-DD или 'today'")

    parser = argparse.ArgumentParser(description="Механика daily-log заметки")
    sub = parser.add_subparsers(dest="command", required=True)

    p_prepare = sub.add_parser(
        "prepare", parents=[common], help="Создать заметку при отсутствии и вернуть контекст"
    )
    p_prepare.set_defaults(func=cmd_prepare)

    p_write = sub.add_parser("write", parents=[common], help="Вставить/заменить блок daily-log")
    p_write.add_argument("--file", default=None, help="Файл с блоком; иначе stdin")
    p_write.set_defaults(func=cmd_write)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
