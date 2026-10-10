"""Общие источники квот и тарифов Claude и Codex, без сетевых запросов."""

from __future__ import annotations

import json
import math
import os
import time
from collections.abc import Iterator
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

STALE_SEC = 600
WEEK_MINUTES = 10080
RECENT_FILES = 40
CLAUDE_WINDOWS = (('five_hour', '5h'), ('seven_day', '7d'))


def iso_time(value: str) -> datetime:
    """Разбирает ISO-время с обязательным часовым поясом."""
    moment = datetime.fromisoformat(value.replace('Z', '+00:00'))
    if moment.tzinfo is None:
        raise ValueError('время ISO должно содержать часовой пояс')

    return moment.astimezone(timezone.utc)


def number(value: object, label: str) -> float:
    """Проверяет конечное неотрицательное число из внешнего источника."""
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError(f'{label}: нет числового значения')
    if not math.isfinite(value) or value < 0:
        raise ValueError(f'{label}: недопустимое значение')

    return float(value)


def read_json(path: Path) -> dict[str, Any]:
    """Читает объект JSON, не раскрывая содержимое при ошибке."""
    try:
        value = json.loads(path.read_text(encoding='utf-8'))
    except json.JSONDecodeError as error:
        raise ValueError(f'битый JSON: {path}, строка {error.lineno}') from None
    if not isinstance(value, dict):
        raise ValueError(f'ожидался объект JSON: {path}')

    return value


def json_lines(path: Path) -> Iterator[dict[str, Any]]:
    """Читает журнал построчно; битая, в том числе незавершенная, строка дает ошибку."""
    with path.open(encoding='utf-8') as stream:
        for index, line in enumerate(stream, 1):
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                raise ValueError(f'битый журнал: {path}, строка {index}') from None
            if not isinstance(event, dict):
                raise ValueError(f'ожидался объект: {path}, строка {index}')

            yield event


def snapshot_path() -> Path:
    """Возвращает путь снимка статусной строки Claude."""
    cache = os.environ.get('XDG_CACHE_HOME') or str(Path.home() / '.cache')
    return Path(cache) / 'claude-code' / 'rate-limits.json'


def claude_tier() -> str | None:
    """Читает только идентификатор тарифа из локальной учетной записи."""
    path = Path.home() / '.claude.json'
    if not path.exists():
        return None

    account = read_json(path).get('oauthAccount') or {}
    tier = account.get('organizationRateLimitTier')
    return tier if isinstance(tier, str) and tier else None


def claude_source() -> dict[str, Any]:
    """Читает снимок Claude и дополняет его текущим тарифом."""
    path = snapshot_path()
    if not path.exists():
        raise ValueError(f'нет снимка Claude: {path}; статусная строка еще не записала его')

    snapshot = read_json(path)
    number(snapshot.get('at'), 'время снимка Claude')
    limits = snapshot.get('rate_limits')
    if not isinstance(limits, dict):
        raise ValueError('снимок Claude: нет объекта rate_limits')
    for key, _ in CLAUDE_WINDOWS:
        if limits.get(key) is not None:
            validate_window(limits[key], 'used_percentage')

    return {**snapshot, 'tier': claude_tier()}


def validate_window(window: dict[str, Any], used_key: str) -> None:
    """Проверяет процент и время сброса доступного окна."""
    if not isinstance(window, dict):
        raise ValueError('окно квоты: ожидался объект')
    used = number(window.get(used_key), 'процент квоты')
    if used > 100:
        raise ValueError('процент квоты больше 100')
    number(window.get('resets_at'), 'время сброса квоты')


def weekly_window(limits: dict[str, Any]) -> dict[str, Any] | None:
    """Находит недельное окно Codex независимо от его позиции."""
    for key in ('primary', 'secondary'):
        window = limits.get(key)
        if isinstance(window, dict) and window.get('window_minutes') == WEEK_MINUTES:
            validate_window(window, 'used_percent')
            return window

    return None


def codex_source() -> dict[str, Any]:
    """Находит последнее событие недельной квоты в 40 недавно измененных rollout."""
    root = Path.home() / '.codex' / 'sessions'
    if not root.is_dir():
        raise ValueError(f'нет каталога сессий Codex: {root}')

    latest: dict[str, Any] | None = None
    latest_time: datetime | None = None
    # Сохраняем область поиска прежнего codex-quota.py; калибровка читает все файлы.
    paths = sorted(root.rglob('rollout-*.jsonl'), key=lambda path: path.stat().st_mtime)[-RECENT_FILES:]
    for path in paths:
        for event in json_lines(path):
            payload = event.get('payload') or {}
            if payload.get('type') != 'token_count':
                continue
            limits = payload.get('rate_limits') or {}
            window = weekly_window(limits)
            if window is None:
                continue

            stamp = iso_time(event['timestamp'])
            if latest_time is None or stamp >= latest_time:
                latest_time = stamp
                latest = {
                    'at': event['timestamp'],
                    'weekly': window,
                    'plan_type': limits.get('plan_type'),
                }

    if latest is None:
        raise ValueError(f'нет недельного окна Codex в {RECENT_FILES} недавно измененных rollout')

    return latest


def format_reset(epoch: object) -> str:
    """Форматирует время сброса окна и оставшееся время."""
    if not isinstance(epoch, (int, float)):
        return 'сброс неизвестен'

    left = int(epoch - time.time())
    moment = datetime.fromtimestamp(epoch, timezone.utc).strftime('%Y-%m-%d %H:%M UTC')
    return f'сброс {moment}, через {left // 3600} ч {left % 3600 // 60} мин' if left > 0 else f'сброс {moment}'


def print_claude(source: dict[str, Any]) -> None:
    """Печатает прежнюю сводку Claude, тариф и идентификатор снимка."""
    age = int(time.time() - source['at'])
    suffix = ' – устарел: статусная строка давно не обновлялась' if age > STALE_SEC else ''
    print(f'снимок {age // 60} мин назад{suffix}')
    print(f'тариф: {source.get("tier") or "неизвестен"}; session_id: {source.get("session_id") or "нет данных"}')
    limits = source['rate_limits']
    if any(not limits.get(key) for key, _ in CLAUDE_WINDOWS):
        print('предупреждение: неполный снимок Claude')

    for key, label in CLAUDE_WINDOWS:
        window = limits.get(key)
        if not window:
            print(f'{label}: нет данных')
            continue

        used = float(window['used_percentage'])
        print(f'{label}: потрачено {used:.0f}%, осталось {100 - used:.0f}% ({format_reset(window.get("resets_at"))})')


def print_codex(source: dict[str, Any]) -> None:
    """Печатает прежнюю сводку Codex и тариф."""
    window = source['weekly']
    used = float(window['used_percent'])
    reset = datetime.fromtimestamp(window['resets_at'], timezone.utc).isoformat()
    print(f'Codex на {source["at"]}: потрачено {used:.0f}%, осталось {100 - used:.0f}% (сброс {reset})')
    print(f'тариф: {source.get("plan_type") or "неизвестен"}')
