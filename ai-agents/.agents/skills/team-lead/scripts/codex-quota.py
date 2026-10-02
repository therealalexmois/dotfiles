#!/usr/bin/env python3
"""Печатает потраченную и оставшуюся недельную квоту Codex по журналам сессий.

Источник – последнее событие `token_count` в `~/.codex/sessions/**/*.jsonl`: из `rate_limits`
берется окно с `window_minutes == 10080` (`primary` или `secondary`). Строка состояния pane
показывает контекст сессии, а не квоту.
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

SESSIONS = Path.home() / '.codex' / 'sessions'
RECENT_FILES = 40
WEEK_MINUTES = 10080


def weekly_window(limits: dict[str, Any]) -> dict[str, Any] | None:
    """Возвращает недельное окно из `rate_limits` или None, если его в событии нет."""
    for key in ('primary', 'secondary'):
        window = limits.get(key)

        if isinstance(window, dict) and window.get('window_minutes') == WEEK_MINUTES and 'used_percent' in window:
            return window

    return None


def main() -> None:
    """Находит самое свежее значение недельной квоты и печатает остаток."""
    if not SESSIONS.is_dir():
        sys.exit(f'no Codex sessions directory: {SESSIONS}')

    latest: tuple[str, float, object] | None = None
    files = sorted(SESSIONS.rglob('*.jsonl'), key=lambda p: p.stat().st_mtime)[-RECENT_FILES:]

    for path in files:
        for line in path.read_text(errors='ignore').splitlines():
            if '"token_count"' not in line:
                continue

            # Последняя строка активной сессии может быть дописана не до конца.
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue

            limits = (event.get('payload') or {}).get('rate_limits') or {}
            window = weekly_window(limits)

            if window is not None:
                stamp = event.get('timestamp', '')

                if latest is None or stamp > latest[0]:
                    latest = (stamp, float(window['used_percent']), window.get('resets_at'))

    if latest is None:
        sys.exit(f'no weekly ({WEEK_MINUTES} min) rate limit window in the last {RECENT_FILES} session files')

    stamp, used, resets = latest
    reset_text = datetime.fromtimestamp(resets, timezone.utc).isoformat() if isinstance(resets, (int, float)) else resets
    print(f'Codex на {stamp}: потрачено {used:.0f}%, осталось {100 - used:.0f}% (сброс {reset_text})')


if __name__ == '__main__':
    main()
