#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["tomli-w"]
# ///
"""Render Codex config from shared and local TOML fragments."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import tempfile
import tomllib
from typing import Any

import tomli_w


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


def write_toml(path: Path, data: TomlTable, *, mode: int) -> None:
    """Атомарно записывает TOML и проверяет, что результат читается tomllib."""
    content = tomli_w.dumps(data)
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
    parser.add_argument(
        "--check",
        action="store_true",
        help="validate shared and local configs merge and serialize without writing output",
    )
    args = parser.parse_args()

    if args.check:
        shared = load_toml(SHARED_CONFIG, required=True)
        local = load_toml(LOCAL_CONFIG, required=False)
        merged = merge_tables(shared, local)
        tomllib.loads(tomli_w.dumps(merged))
        print(f"codex config check ok: {SHARED_CONFIG}")
        return 0

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
