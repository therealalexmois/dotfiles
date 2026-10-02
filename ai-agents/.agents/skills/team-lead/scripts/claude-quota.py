#!/usr/bin/env python3
"""Печатает потраченные и оставшиеся лимиты Claude (5 часов и 7 дней).

Источник – снимок `rate_limits`, который статусная строка Claude Code пишет в
`${XDG_CACHE_HOME:-~/.cache}/claude-code/rate-limits.json` при каждом обновлении. Лимиты общие
для этой сессии, ее субагентов, сессий `claude` в tmux и агентов Workflow.
"""

from __future__ import annotations

import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

STALE_SEC = 600
WINDOWS = (('five_hour', '5h'), ('seven_day', '7d'))


def snapshot_path() -> Path:
    """Возвращает путь снимка лимитов."""
    cache = os.environ.get('XDG_CACHE_HOME') or str(Path.home() / '.cache')
    return Path(cache) / 'claude-code' / 'rate-limits.json'


def format_reset(epoch: object) -> str:
    """Форматирует время сброса окна."""
    if not isinstance(epoch, (int, float)):
        return 'сброс неизвестен'

    left = int(epoch - time.time())
    moment = datetime.fromtimestamp(epoch, timezone.utc).strftime('%Y-%m-%d %H:%M UTC')

    return f'сброс {moment}, через {left // 3600} ч {left % 3600 // 60} мин' if left > 0 else f'сброс {moment}'


def main() -> None:
    """Читает снимок и печатает остаток по каждому окну."""
    path = snapshot_path()

    if not path.exists():
        sys.exit(f'no rate limit snapshot at {path}: the Claude Code status line has not written one yet')

    snapshot = json.loads(path.read_text())
    age = int(time.time() - snapshot.get('at', 0))
    limits = snapshot.get('rate_limits') or {}

    print(f'снимок {age // 60} мин назад' + (' – устарел: статусная строка давно не обновлялась' if age > STALE_SEC else ''))

    for key, label in WINDOWS:
        window = limits.get(key)

        if not window or 'used_percentage' not in window:
            print(f'{label}: нет данных')
            continue

        used = float(window['used_percentage'])
        print(f"{label}: потрачено {used:.0f}%, осталось {100 - used:.0f}% ({format_reset(window.get('resets_at'))})")


if __name__ == '__main__':
    main()
