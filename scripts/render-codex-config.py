#!/usr/bin/env python3
"""Render Codex config from shared and local TOML fragments."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import tempfile
import tomllib
from typing import Any


HOME = Path.home()
CODEX_DIR = HOME / ".codex"
SHARED_CONFIG = CODEX_DIR / "config.shared.toml"
LOCAL_CONFIG = CODEX_DIR / "config.local.toml"
OUTPUT_CONFIG = CODEX_DIR / "config.toml"


TomlTable = dict[str, Any]


def load_toml(path: Path, *, required: bool) -> TomlTable:
    """Загружает TOML-файл и явно сообщает об отсутствующем обязательном входе."""
    if not path.exists():
        if required:
            raise FileNotFoundError(f"required config not found: {path}")
        return {}
    with path.open("rb") as file_obj:
        data = tomllib.load(file_obj)
    if not isinstance(data, dict):
        raise TypeError(f"top-level TOML value must be a table: {path}")
    return data


def merge_tables(base: TomlTable, override: TomlTable) -> TomlTable:
    """Рекурсивно объединяет таблицы, оставляя приоритет локального фрагмента."""
    result: TomlTable = dict(base)
    for key, value in override.items():
        current = result.get(key)
        if isinstance(current, dict) and isinstance(value, dict):
            result[key] = merge_tables(current, value)
        else:
            result[key] = value
    return result


def extract_projects(config: TomlTable) -> TomlTable:
    """Возвращает только локальные project trust entries из существующего конфига."""
    projects = config.get("projects")
    if not isinstance(projects, dict) or not projects:
        return {}
    return {"projects": projects}


def init_local_from_current(local_path: Path, output_path: Path) -> bool:
    """Создает локальный фрагмент из текущего config.toml, если он еще отсутствует."""
    if local_path.exists() or not output_path.exists():
        return False
    current = load_toml(output_path, required=True)
    local_data = extract_projects(current)
    if not local_data:
        return False
    write_toml(local_path, local_data, mode=0o600)
    return True


def toml_quote(value: str) -> str:
    """Экранирует строку для TOML basic string."""
    replacements = {
        "\\": "\\\\",
        '"': '\\"',
        "\b": "\\b",
        "\t": "\\t",
        "\n": "\\n",
        "\f": "\\f",
        "\r": "\\r",
    }
    return '"' + "".join(replacements.get(char, char) for char in value) + '"'


def format_value(value: Any) -> str:
    """Форматирует поддерживаемые скалярные значения и списки для TOML."""
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        return toml_quote(value)
    if isinstance(value, int | float):
        return str(value)
    if isinstance(value, list):
        if not value:
            return "[]"
        if all(not isinstance(item, dict) for item in value) and len(value) <= 3:
            return "[" + ", ".join(format_value(item) for item in value) + "]"
        lines = ["["]
        lines.extend(f"  {format_value(item)}," for item in value)
        lines.append("]")
        return "\n".join(lines)
    raise TypeError(f"unsupported TOML value: {value!r}")


def table_items(table: TomlTable) -> tuple[list[tuple[str, Any]], list[tuple[str, TomlTable]]]:
    """Разделяет простые ключи и вложенные таблицы с сохранением порядка."""
    scalars: list[tuple[str, Any]] = []
    tables: list[tuple[str, TomlTable]] = []
    for key, value in table.items():
        if isinstance(value, dict):
            tables.append((key, value))
        else:
            scalars.append((key, value))
    return scalars, tables


def format_key(key: str) -> str:
    """Форматирует ключ TOML, цитируя сегменты со спецсимволами."""
    if key.replace("_", "").replace("-", "").isalnum() and not key[:1].isdigit():
        return key
    return toml_quote(key)


def format_table_path(path: tuple[str, ...]) -> str:
    """Форматирует путь вложенной TOML-таблицы."""
    return ".".join(format_key(part) for part in path)


def render_table(table: TomlTable, path: tuple[str, ...] = ()) -> list[str]:
    """Рендерит TOML-таблицу в строки."""
    lines: list[str] = []
    scalars, tables = table_items(table)
    if path:
        lines.append(f"[{format_table_path(path)}]")
    for key, value in scalars:
        lines.append(f"{format_key(key)} = {format_value(value)}")
    for key, child in tables:
        if lines:
            lines.append("")
        lines.extend(render_table(child, (*path, key)))
    return lines


def dumps_toml(table: TomlTable) -> str:
    """Сериализует поддерживаемое подмножество TOML."""
    return "\n".join(render_table(table)).rstrip() + "\n"


def write_toml(path: Path, data: TomlTable, *, mode: int) -> None:
    """Атомарно записывает TOML и проверяет, что результат читается tomllib."""
    content = dumps_toml(data)
    tomllib.loads(content)
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    tmp_path = Path(tmp_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as file_obj:
            file_obj.write(content)
            file_obj.flush()
            os.fsync(file_obj.fileno())
        os.chmod(tmp_path, mode)
        os.replace(tmp_path, path)
    except Exception:
        try:
            tmp_path.unlink()
        except FileNotFoundError:
            pass
        raise


def main() -> int:
    """Точка входа CLI."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--init-local-from-current",
        action="store_true",
        help="create ~/.codex/config.local.toml from existing ~/.codex/config.toml projects if missing",
    )
    parser.add_argument(
        "--init-local-only",
        action="store_true",
        help="create ~/.codex/config.local.toml from current config and exit without rendering",
    )
    args = parser.parse_args()

    if args.init_local_from_current or args.init_local_only:
        created = init_local_from_current(LOCAL_CONFIG, OUTPUT_CONFIG)
        if created:
            print(f"created local config: {LOCAL_CONFIG}")
    if args.init_local_only:
        return 0

    shared = load_toml(SHARED_CONFIG, required=True)
    local = load_toml(LOCAL_CONFIG, required=False)
    merged = merge_tables(shared, local)
    write_toml(OUTPUT_CONFIG, merged, mode=0o600)
    print(f"rendered codex config: {OUTPUT_CONFIG}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
