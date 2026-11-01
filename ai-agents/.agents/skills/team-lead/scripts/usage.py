#!/usr/bin/env python3
"""Оценивает расход задач по локальным журналам, истории и калибровке квот.

Шкалы Claude и Codex раздельны. Источники только читаются; состояние хранится в
TEAM_LEAD_STATE_DIR либо ${XDG_STATE_HOME:-~/.local/state}/team-lead.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import statistics
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from quota_sources import (
    CLAUDE_WINDOWS,
    STALE_SEC,
    claude_source,
    claude_tier,
    codex_source,
    iso_time,
    json_lines,
    number,
    print_claude,
    print_codex,
    read_json,
    validate_window,
)

# Claude: цены API в долларах за миллион токенов (кэш claude-api, 25.09.2026).
# Codex: отдельная шкала пропорций; масштаб подписки поглощает калибровка.
SCHEMA_VERSION = 1
WEIGHTS_VERSION = 'claude-api-usd-v2'
INPUT_WEIGHT = 1.0
CACHE_READ_WEIGHT = 0.1
OUTPUT_WEIGHT = 5.0
CACHE_CREATION_5M_WEIGHT = 1.25
CACHE_CREATION_1H_WEIGHT = 2.0
CLAUDE_MODEL_PRICES = {
    'claude-fable-5-1': (10.0, 50.0, 0.25),
    'claude-opus-5-5': (4.0, 20.0, 0.20),
    'claude-opus-5': (5.0, 25.0, 0.50),
    'claude-sonnet-5-5': (2.0, 10.0, 0.20),
    'claude-sonnet-5': (2.0, 10.0, 0.20),
    'claude-sonnet-4-6': (3.0, 15.0, 0.30),
    'claude-haiku-4-5': (1.0, 5.0, 0.10),
    # цены нет в каталоге claude-api от 2026-09-25; принята цена haiku 4.5
    'claude-haiku-5-5': (1.0, 5.0, 0.10),
}
CLAUDE_MODEL_ALIASES = {
    'opus': 'claude-opus-5-5', 'sonnet': 'claude-sonnet-5-5',
    'haiku': 'claude-haiku-4-5', 'fable': 'claude-fable-5-1',
}
CLAUDE_CACHE_KEYS = ('ephemeral_5m_input_tokens', 'ephemeral_1h_input_tokens')
TIER_MULTIPLIERS = {
    'claude': {'default_claude_pro': 1, 'default_claude_max_5x': 5, 'default_claude_max_20x': 20},
    # Подтвержден только prolite. Отношения с другими планами Codex неизвестны.
    'codex': {'prolite': 1},
}
CLAUDE_TOKEN_KEYS = ('input_tokens', 'cache_creation_input_tokens', 'cache_read_input_tokens', 'output_tokens')
CODEX_TOKEN_KEYS = ('input_tokens', 'cached_input_tokens', 'output_tokens', 'reasoning_output_tokens')

# usage.py task: серия 43dd21e3-a7f3-43e5-8056-000e8a69e635, 06.10.2026
# 10:19–12:40 UTC; main / 4, медиана двух opus-инженеров, четырех sonnet-ревьюеров
# и четырех haiku-наблюдателей. Research: a59261aaefd4f94ba.
# Codex: медиана #754 (13-30-57) и #755 (13-30-59); high: #757 (15-36-09).
# Точные измерения и селекторы приведены в references/quota.md.
STARTING_UNITS = {
    'codex-medium': 554961.5,
    'codex-high': 2599328.8,
    'codex-high-l': 5198657.6,  # Оценка: high × 2, опорной задачи L нет.
    'claude-engineer-opus': 15.1395902,
    'claude-research-opus': 8.0849978,
    'claude-reviewer-sonnet': 0.3152127,
    'claude-watcher-haiku': 0.053242075,
    'team-lead-per-task': 4.0912762,
}


def now_iso() -> str:
    """Возвращает время записи в UTC."""
    return datetime.now(timezone.utc).isoformat()


def state_dir() -> Path:
    """Возвращает каталог машинного состояния с учетом переменных окружения."""
    override = os.environ.get('TEAM_LEAD_STATE_DIR')
    if override:
        return Path(override).expanduser()

    root = Path(os.environ.get('XDG_STATE_HOME') or Path.home() / '.local' / 'state')
    return root / 'team-lead'


def append_json(path: Path, value: dict[str, Any]) -> None:
    """Дописывает одну запись JSONL, создавая только каталог назначения."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('a', encoding='utf-8') as stream:
        stream.write(json.dumps(value, ensure_ascii=False, allow_nan=False) + '\n')


def calibration() -> dict[str, Any]:
    """Читает образцы калибровки; отсутствие файла означает отсутствие образцов."""
    path = state_dir() / 'calibration.json'
    return read_json(path) if path.exists() else {}


def priced_model(model: str) -> str:
    """Нормализует алиас, суффикс контекста и дату без подмены поколения модели."""
    normalized = re.sub(r'\[[^]]*\]$', '', model.lower())
    normalized = re.sub(r'-\d{8}$', '', normalized)
    return CLAUDE_MODEL_ALIASES.get(normalized, normalized)


def token_counts(usage: dict[str, Any], keys: tuple[str, ...]) -> dict[str, float]:
    """Читает обязательные счетчики и сохраняет разбивку срока записи кэша."""
    counts = {key: number(usage.get(key), f'счетчик {key}') for key in keys}
    if keys == CODEX_TOKEN_KEYS:
        counts.update({key: number(value, f'счетчик {key}') for key, value in usage.items()})
    else:
        cache = usage.get('cache_creation')
        if cache is not None:
            for key in CLAUDE_CACHE_KEYS:
                counts[key] = number(cache.get(key, 0), f'счетчик {key}')
        elif any(key in usage for key in CLAUDE_CACHE_KEYS):
            for key in CLAUDE_CACHE_KEYS:
                counts[key] = number(usage.get(key, 0), f'счетчик {key}')
        if any(key in counts for key in CLAUDE_CACHE_KEYS):
            if sum(counts[key] for key in CLAUDE_CACHE_KEYS) > counts['cache_creation_input_tokens']:
                raise ValueError('разбивка записи кэша больше общего счетчика Claude')

    return counts


def claude_units(model: str, counts: dict[str, float]) -> float | None:
    """Считает API-эквивалент в долларах; неизвестная цена возвращает None."""
    price = CLAUDE_MODEL_PRICES.get(priced_model(model))
    if price is None:
        return None

    incoming, outgoing, cached = price
    one_hour = counts.get('ephemeral_1h_input_tokens', 0)
    # Неизвестный срок оставшейся записи явно считается как 5m.
    creation = (counts['cache_creation_input_tokens'] - one_hour) * CACHE_CREATION_5M_WEIGHT
    creation += one_hour * CACHE_CREATION_1H_WEIGHT
    return (
        counts['input_tokens'] * incoming + counts['output_tokens'] * outgoing
        + counts['cache_read_input_tokens'] * cached + creation * incoming
    ) / 1_000_000


def codex_units(counts: dict[str, float]) -> float:
    """Взвешивает разность счетчиков Codex без повторного учета кэша и reasoning."""
    if counts['cached_input_tokens'] > counts['input_tokens']:
        raise ValueError('кэшированный вход больше общего входа Codex')

    return (
        (counts['input_tokens'] - counts['cached_input_tokens']) * INPUT_WEIGHT
        + counts['cached_input_tokens'] * CACHE_READ_WEIGHT
        + counts['output_tokens'] * OUTPUT_WEIGHT
    )


def claude_usage(
    paths: list[Path],
    since: datetime | None,
    until: datetime | None,
) -> dict[str, Any]:
    """Дедуплицирует API-запросы по (message.id, requestId) до фильтрации времени.

    Последняя строка запроса несет итоговый usage. Пара дедуплицируется и между
    файлами; окно включает правую границу и исключает левую.
    """
    skipped_synthetic = 0
    requests: dict[tuple[str, str | None], tuple[datetime, str, dict[str, float]]] = {}
    for path in sorted(set(paths)):
        if since and path.stat().st_mtime < since.timestamp():
            continue
        for event in json_lines(path):
            message = event.get('message') or {}
            usage = message.get('usage')
            if not usage:
                continue
            stamp = iso_time(event['timestamp'])
            if message.get('model') == '<synthetic>':
                if not ((since and stamp <= since) or (until and stamp > until)):
                    skipped_synthetic += 1
                continue

            identifier = message.get('id')
            if not identifier or not message.get('model'):
                raise ValueError(f'usage без id или модели: {path}')

            stamp = iso_time(event['timestamp'])
            key = (identifier, event.get('requestId'))
            counts = token_counts(usage, CLAUDE_TOKEN_KEYS)
            if key not in requests or stamp >= requests[key][0]:
                requests[key] = (stamp, message['model'], counts)

    models: dict[str, dict[str, float]] = {}
    units = 0.0
    for stamp, model, counts in requests.values():
        if (since and stamp <= since) or (until and stamp > until):
            continue
        total = models.setdefault(model, dict.fromkeys(CLAUDE_TOKEN_KEYS, 0.0))
        for key, value in counts.items():
            total[key] = total.get(key, 0.0) + value

    unpriced_tokens = 0.0
    total_tokens = 0.0
    print(f'Claude: пропущено строк <synthetic>: {skipped_synthetic}')
    for model, counts in sorted(models.items()):
        tokens = sum(counts[key] for key in CLAUDE_TOKEN_KEYS)
        total_tokens += tokens
        cost = claude_units(model, counts)
        if cost is None:
            unpriced_tokens += tokens
            print(f'предупреждение: {model}: без цены, {tokens:.0f} токенов')
            anomaly('model-without-price', {'model': model, 'tokens': counts})
        else:
            units += cost
            if priced_model(model) == 'claude-haiku-5-5':
                print(f'Claude: {model}: цена принята (haiku 4.5); {cost:.6f} ед.')

    return {
        'models': models, 'units': units, 'skipped_synthetic': skipped_synthetic,
        'unpriced_tokens': unpriced_tokens, 'total_tokens': total_tokens,
    }


def codex_usage(paths: list[Path], since: datetime | None, until: datetime | None) -> dict[str, Any]:
    """Считает разность накопительных счетчиков каждого rollout в (since, until].

    Начальный счетчик берется из последнего события до since включительно.
    Если таких событий нет, начало нового rollout равно нулю. Без границ берется
    последнее значение. reasoning_output_tokens уже включен в output_tokens.
    """
    totals = dict.fromkeys(CODEX_TOKEN_KEYS, 0.0)
    units = 0.0
    for path in sorted(set(paths)):
        if since and path.stat().st_mtime < since.timestamp():
            continue
        counters = []
        for event in json_lines(path):
            payload = event.get('payload') or {}
            if payload.get('type') != 'token_count':
                continue
            info = payload.get('info') or {}
            usage = info.get('total_token_usage')
            if usage:
                counters.append((iso_time(event['timestamp']), token_counts(usage, CODEX_TOKEN_KEYS)))

        counters.sort(key=lambda item: item[0])
        before = dict.fromkeys(CODEX_TOKEN_KEYS, 0.0)
        end = before
        previous = before
        for stamp, counts in counters:
            if until and stamp > until:
                break
            if (since is None or stamp > since) and any(counts[key] < previous[key] for key in CODEX_TOKEN_KEYS):
                raise ValueError(f'накопительный счетчик Codex уменьшился: {path}')
            previous = counts
            if since and stamp <= since:
                before = counts
            end = counts

        delta = {key: value - before.get(key, 0.0) for key, value in end.items()}
        if any(value < 0 for value in delta.values()):
            raise ValueError(f'отрицательная разность счетчиков Codex: {path}')
        if delta['cached_input_tokens'] > delta['input_tokens']:
            raise ValueError(f'кэшированный вход больше общего входа Codex: {path}')
        for key, value in delta.items():
            totals[key] = totals.get(key, 0.0) + value
        units += codex_units(delta)

    return {'tokens': totals, 'units': units}


def selected_paths(args: argparse.Namespace) -> tuple[list[Path], list[Path]]:
    """Находит сессию с субагентами или только явно выбранных субагентов."""
    root = Path.home() / '.claude' / 'projects'
    paths: list[Path] = []
    if args.claude_session:
        matches = list(root.rglob(f'{args.claude_session}.jsonl'))
        if len(matches) != 1:
            raise ValueError(f'сессия Claude не найдена однозначно: {args.claude_session}')
        main = matches[0]
        paths.append(main)
        if not args.claude_main_only:
            paths.extend(main.with_suffix('').glob('subagents/agent-*.jsonl'))

    if args.claude_main_only and (not args.claude_session or args.claude_agent):
        raise ValueError('--claude-main-only требует --claude-session и несовместим с --claude-agent')

    for agent in args.claude_agent:
        matches = list(root.rglob(f'agent-{agent}.jsonl'))
        if len(matches) != 1:
            raise ValueError(f'субагент Claude не найден однозначно: {agent}')
        paths.append(matches[0])

    rollouts = [path.expanduser() for path in args.codex_rollout]
    for path in rollouts:
        if not path.is_file():
            raise ValueError(f'rollout не найден: {path}')
    if not paths and not rollouts:
        raise ValueError('нужен селектор сессии, субагента или rollout')

    return paths, rollouts


def bounds(args: argparse.Namespace) -> tuple[datetime | None, datetime | None]:
    """Проверяет порядок и часовые пояса границ окна."""
    since = iso_time(args.since) if args.since else None
    until = iso_time(args.until) if args.until else None
    if since and until and since >= until:
        raise ValueError('--since должен быть раньше --until')

    return since, until


def task_usage(args: argparse.Namespace) -> dict[str, Any]:
    """Считает выбранную задачу и отказывает при отсутствии расхода в выбранном окне."""
    since, until = bounds(args)
    claude_paths, codex_paths = selected_paths(args)
    result: dict[str, Any] = {}
    if claude_paths:
        result['claude'] = claude_usage(claude_paths, since, until)
    if codex_paths:
        result['codex'] = codex_usage(codex_paths, since, until)
    for provider, value in result.items():
        if value['units'] <= 0 and not value.get('unpriced_tokens'):
            raise ValueError(f'{provider}: нет расхода в выбранных журналах и окне')

    return result


def coefficient(samples: list[dict[str, Any]]) -> float:
    """Возвращает сумму дельт процентов / сумму единиц валидных образцов."""
    if not isinstance(samples, list) or not samples:
        raise ValueError('калибровка: пустой или неверный список образцов')
    if any(sample.get('weights_version') != WEIGHTS_VERSION for sample in samples):
        raise ValueError(
            'калибровка: неизвестная или устаревшая версия весов; архивируйте образцы и повторите calibrate'
        )

    units = sum(number(sample.get('units'), 'единицы образца') for sample in samples)
    delta = sum(number(sample.get('delta_percent'), 'дельта образца') for sample in samples)
    if units <= 0 or delta <= 0:
        raise ValueError('калибровка: единицы и дельта должны быть положительными')

    return delta / units


def forecast(
    provider: str,
    tier: str | None,
    units: float,
    saved: dict[str, Any],
    source: str,
) -> dict[str, dict[str, Any]]:
    """Возвращает проценты и действовавшие коэффициенты отдельно для каждого окна."""
    windows = CLAUDE_WINDOWS if provider == 'claude' else (('weekly', 'неделя'),)
    result = {}
    for window, _ in windows:
        detail = {'percent': None, 'key': None, 'coefficient': None, 'source': 'none'}
        result[window] = detail
        if not tier:
            continue
        key = f'{provider}:{tier}:{window}'
        if key in saved:
            rate = coefficient(saved[key])
            detail.update(key=key, coefficient=rate, percent=units * rate, source=source)
            continue

        alternatives = [key for key in saved if key.startswith(f'{provider}:') and key.endswith(f':{window}')]
        if not alternatives:
            continue
        multipliers = TIER_MULTIPLIERS[provider]
        if tier not in multipliers:
            raise ValueError(f'неизвестный тариф для пересчета: {provider}:{tier}')
        usable = [key for key in alternatives if key.split(':')[1] in multipliers]
        if not usable:
            raise ValueError(f'нет явно известного исходного тарифа для {provider}:{window}')
        # Ближайший известный множитель; образцы разных тарифов не смешиваются.
        chosen = min(usable, key=lambda key: abs(multipliers[key.split(':')[1]] - multipliers[tier]))
        old_tier = chosen.split(':')[1]
        rate = coefficient(saved[chosen]) * multipliers[old_tier] / multipliers[tier]
        detail.update(key=chosen, coefficient=rate, percent=units * rate, source=f'rescaled-from:{old_tier}')

    return result


def format_forecast(provider: str, details: dict[str, dict[str, Any]]) -> str:
    """Форматирует проценты с явными пометками отсутствия и переноса калибровки."""
    windows = CLAUDE_WINDOWS if provider == 'claude' else (('weekly', 'неделя'),)
    texts = []
    for window, label in windows:
        detail = details[window]
        if detail['percent'] is None:
            texts.append(f'{label}: калибровки нет, проценты не оценить')
            continue
        note = ''
        if detail['source'].startswith('rescaled-from:'):
            note = f' (грубо: пересчет с {detail["source"].split(":", 1)[1]})'
        texts.append(f'{label}: {detail["percent"]:.2f}%{note}')

    return '; '.join(texts)


def percentages(provider: str, tier: str | None, units: float, saved: dict[str, Any]) -> str:
    """Переводит единицы в проценты для человекочитаемой сводки."""
    if not tier:
        return 'тариф неизвестен, проценты не оценить'

    return format_forecast(provider, forecast(provider, tier, units, saved, 'actual'))


def anomaly(kind: str, details: dict[str, Any]) -> None:
    """Дописывает диагностическую запись только в каталог машинного состояния."""
    append_json(
        state_dir() / 'anomalies.jsonl',
        {
            'schema_version': SCHEMA_VERSION,
            'type': kind,
            'at': now_iso(),
            'details': details,
        },
    )


def current_tiers(providers: list[str]) -> dict[str, str | None]:
    """Читает текущие тарифы только нужных провайдеров."""
    result = {}
    if 'claude' in providers:
        result['claude'] = claude_tier()
    if 'codex' in providers:
        result['codex'] = codex_source()['plan_type']

    return result


def print_task(result: dict[str, Any], tiers: dict[str, str | None]) -> None:
    """Печатает счетчики по моделям и проценты по текущей калибровке."""
    saved = calibration()
    for provider, value in result.items():
        print(f'{provider}; тариф: {tiers[provider] or "неизвестен"}')
        counts_by_model = value['models'] if provider == 'claude' else {'Codex': value['tokens']}
        for model, counts in sorted(counts_by_model.items()):
            note = ' (без цены)' if provider == 'claude' and claude_units(model, counts) is None else ''
            print(f'  {model}{note}: ' + ', '.join(f'{key}={count:.0f}' for key, count in counts.items()))
        print(f'  {value["units"]:.2f} ед.; {percentages(provider, tiers[provider], value["units"], saved)}')


def jump(previous: dict[str, Any], current: dict[str, Any]) -> bool:
    """Выявляет уменьшение 7d или скачок больше 10 п.п. при неизменном сбросе."""
    old = previous.get('claude', {}).get('rate_limits', {}).get('seven_day')
    new = current.get('claude', {}).get('rate_limits', {}).get('seven_day')
    if not old or not new or old.get('resets_at') != new.get('resets_at'):
        return False

    delta = number(new.get('used_percentage'), '7d') - number(old.get('used_percentage'), '7d')
    return delta < 0 or abs(delta) > 10


def take_snapshot(args: argparse.Namespace) -> None:
    """Записывает снимок квот и предупреждает о подозрительном изменении 7d."""
    snapshot = {'at': now_iso(), 'claude': claude_source(), 'codex': codex_source()}
    previous = list(json_lines(args.log)) if args.log.exists() else []
    snapshot['suspect_jump'] = bool(previous and jump(previous[-1], snapshot))
    if snapshot['suspect_jump']:
        print('предупреждение: подозрительный скачок 7d; calibrate требует --accept-jumps')
        anomaly('suspicious-jump', {'log': str(args.log), 'snapshot': snapshot})

    if any(not snapshot['claude']['rate_limits'].get(key) for key, _ in CLAUDE_WINDOWS):
        anomaly('incomplete-snapshot', {'log': str(args.log), 'snapshot': snapshot})

    age = iso_time(snapshot['at']).timestamp() - snapshot['claude']['at']
    if age > STALE_SEC:
        print(f'предупреждение: снимок Claude устарел: {age:.0f} секунд')
        anomaly('stale-snapshot', {'age_seconds': age, 'log': str(args.log)})

    append_json(args.log, snapshot)
    print_claude(snapshot['claude'])
    print_codex(snapshot['codex'])


def stored_window(snapshot: dict[str, Any], provider: str, window: str) -> dict[str, Any] | None:
    """Возвращает окно из записи журнала снимков."""
    source = snapshot[provider]
    return source.get('rate_limits', {}).get(window) if provider == 'claude' else source.get(window)


def source_time(snapshot: dict[str, Any], provider: str) -> datetime:
    """Возвращает время самого значения квоты, а не запуска snapshot."""
    value = snapshot[provider]['at']
    if isinstance(value, str):
        return iso_time(value)

    return datetime.fromtimestamp(number(value, f'время {provider}'), timezone.utc)


def calibration_segments(
    selected: list[dict[str, Any]], provider: str, window: str,
) -> list[list[dict[str, Any]]]:
    """Делит окно при смене сброса, тарифа или отсутствии значения."""
    tier_key = 'tier' if provider == 'claude' else 'plan_type'
    segments: list[list[dict[str, Any]]] = []
    previous_identity = None
    for snapshot in selected:
        value = stored_window(snapshot, provider, window)
        identity = (value.get('resets_at') if value else None, snapshot[provider].get(tier_key))
        if not segments or identity != previous_identity or not value:
            segments.append([])
        segments[-1].append(snapshot)
        previous_identity = identity

    return segments


def calibrate(args: argparse.Namespace) -> None:
    """Сохраняет пригодные отрезки каждого окна независимо от остальных.

    Границы расхода берутся из времени источника. Ненулевой выход означает,
    что не сохранено ни одного образца. Индексы --from/--to начинаются с нуля.
    """
    snapshots = list(json_lines(args.log))
    if len(snapshots) < 2:
        raise ValueError('для калибровки нужны минимум два снимка')
    start_index = args.from_index if args.from_index is not None else 0
    end_index = args.to_index if args.to_index is not None else len(snapshots) - 1
    if not 0 <= start_index < end_index < len(snapshots):
        raise ValueError('индексы снимков должны удовлетворять 0 <= from < to < длина журнала')

    selected = snapshots[start_index : end_index + 1]
    if any(iso_time(left['at']) >= iso_time(right['at']) for left, right in zip(selected, selected[1:])):
        raise ValueError('время снимков в журнале не возрастает')

    saved = calibration()
    paths_by_provider = {
        'claude': list((Path.home() / '.claude' / 'projects').rglob('*.jsonl')),
        'codex': list((Path.home() / '.codex' / 'sessions').rglob('rollout-*.jsonl')),
    }
    totals_cache: dict[tuple[str, datetime, datetime], dict[str, Any]] = {}
    added = 0
    for provider in ('claude', 'codex'):
        tier_key = 'tier' if provider == 'claude' else 'plan_type'
        used_key = 'used_percentage' if provider == 'claude' else 'used_percent'
        windows = CLAUDE_WINDOWS if provider == 'claude' else (('weekly', 'неделя'),)
        for window, label in windows:
            for segment in calibration_segments(selected, provider, window):
                first, last = segment[0], segment[-1]
                try:
                    values = [stored_window(item, provider, window) for item in segment]
                    if any(value is None for value in values):
                        raise ValueError('нет данных окна')
                    if len(segment) < 2:
                        raise ValueError('отрезок содержит только один снимок после смены сброса или тарифа')
                    tier = first[provider].get(tier_key)
                    if tier not in TIER_MULTIPLIERS[provider]:
                        raise ValueError('неизвестный тариф')
                    for value in values:
                        validate_window(value, used_key)
                    since, until = source_time(first, provider), source_time(last, provider)
                    if since >= until or any(
                        source_time(left, provider) > source_time(right, provider)
                        for left, right in zip(segment, segment[1:])
                    ):
                        raise ValueError('время значений источника не возрастает')
                    if values[-1]['resets_at'] <= until.timestamp():
                        raise ValueError('время значения после сброса окна')
                    if provider == 'claude' and window == 'seven_day' and not args.accept_jumps:
                        if any(item.get('suspect_jump') for item in segment) or any(
                            jump(left, right) for left, right in zip(segment, segment[1:])
                        ):
                            raise ValueError('подозрительный скачок: требуется --accept-jumps')
                    delta = values[-1][used_key] - values[0][used_key]
                    if delta < 1:
                        raise ValueError('дельта процента меньше 1 п.п.')
                    key = f'{provider}:{tier}:{window}'
                    samples = saved.get(key, [])
                    # Старые веса требуют явной новой калибровки, смешивать их нельзя.
                    if samples:
                        coefficient(samples)
                    if any(item['since'] == since.isoformat() and item['until'] == until.isoformat() for item in samples):
                        raise ValueError('образец этого окна уже записан')

                    cache_key = (provider, since, until)
                    if cache_key not in totals_cache:
                        reader = claude_usage if provider == 'claude' else codex_usage
                        totals_cache[cache_key] = reader(paths_by_provider[provider], since, until)
                    total = totals_cache[cache_key]
                    if provider == 'claude' and total['unpriced_tokens']:
                        share = total['unpriced_tokens'] / total['total_tokens']
                        if share > 0.01:
                            raise ValueError(f'модели без цены: {share:.2%} токенов окна, больше 1%')
                        print(f'предупреждение: Claude, без цены {share:.2%} токенов; единицы неполные')
                    if total['units'] <= 0:
                        raise ValueError('нет единиц за окно калибровки')
                except (OSError, ValueError, KeyError, TypeError) as error:
                    print(f'предупреждение: {provider} {label}: отрезок пропущен: {error}')
                    anomaly('calibration-skipped', {
                        'provider': provider, 'window': window, 'log': str(args.log),
                        'from_snapshot': first['at'], 'to_snapshot': last['at'], 'reason': str(error),
                    })
                    continue

                if provider == 'codex' and delta < 3:
                    print('предупреждение: Codex, дельта меньше 3 п.п.; грубость из-за целых процентов')
                sample = {
                    'weights_version': WEIGHTS_VERSION, 'since': since.isoformat(), 'until': until.isoformat(),
                    'delta_percent': delta, 'units': total['units'], 'recorded_at': now_iso(),
                }
                saved.setdefault(key, []).append(sample)
                added += 1
                print(f'{key}: {total["units"]:.6f} ед., {delta:g} п.п.; коэффициент {coefficient(saved[key]):.12g} %/ед.')

    if not added:
        raise ValueError('не сохранено ни одного образца калибровки')
    directory = state_dir()
    directory.mkdir(parents=True, exist_ok=True)
    path = directory / 'calibration.json'
    temporary = directory / f'calibration.json.{os.getpid()}.tmp'
    temporary.write_text(json.dumps(saved, ensure_ascii=False, indent=2, allow_nan=False) + '\n', encoding='utf-8')
    temporary.replace(path)


def class_provider(name: str) -> str:
    """Проверяет класс и возвращает его отдельную шкалу провайдера."""
    if name not in STARTING_UNITS:
        raise ValueError(f'неизвестный класс: {name}')

    return 'codex' if name.startswith('codex-') else 'claude'


def history() -> list[dict[str, Any]]:
    """Читает версионированную историю фактов и планов без тихой миграции."""
    path = state_dir() / 'history.jsonl'
    entries = list(json_lines(path)) if path.exists() else []
    for entry in entries:
        provider = class_provider(entry['class'])
        if entry.get('provider') != provider:
            raise ValueError('история: провайдер не соответствует классу')
        if not isinstance(entry.get('id'), str) or not entry['id'].strip():
            raise ValueError('история: пустой или неверный id')
        if entry.get('schema_version') != SCHEMA_VERSION:
            raise ValueError('история: неизвестная версия схемы')
        if entry.get('kind') not in ('estimate', 'actual'):
            raise ValueError('история: неизвестный вид записи')
        if number(entry.get('units'), 'единицы истории') == 0 and entry['kind'] == 'estimate':
            raise ValueError('история: расход должен быть положительным')
        iso_time(entry['at'])

    return entries


def actual_units(entry: dict[str, Any]) -> float | None:
    """Пересчитывает сырой факт; неполный расход не обучает медиану класса."""
    raw = entry['raw_tokens']
    if entry['provider'] == 'codex':
        return codex_units(token_counts(raw, CODEX_TOKEN_KEYS))

    units = 0.0
    for model, usage in raw.items():
        cost = claude_units(model, token_counts(usage, CLAUDE_TOKEN_KEYS))
        if cost is None:
            print(f'предупреждение: факт {entry["id"]}, {model}: без цены, исключен из медианы')
            return None
        units += cost

    return units


def record(args: argparse.Namespace) -> None:
    """Дописывает сырой факт одного класса и отмечает отсутствие соответствующего плана."""
    if not args.id.strip():
        raise ValueError('id задачи не должен быть пустым')

    provider = class_provider(args.task_class)
    result = task_usage(args)
    if set(result) != {provider}:
        raise ValueError('селекторы должны относиться только к провайдеру класса')
    entries = history()
    if any(item['kind'] == 'actual' and item['id'] == args.id and item['class'] == args.task_class for item in entries):
        raise ValueError('этот факт id и класса уже записан в истории')

    tier = current_tiers([provider])[provider]
    value = result[provider]
    details = forecast(provider, tier, value['units'], calibration(), 'actual')
    entry = {
        'schema_version': SCHEMA_VERSION,
        'weights_version': WEIGHTS_VERSION,
        'kind': 'actual',
        'id': args.id,
        'class': args.task_class,
        'units': value['units'],
        'raw_tokens': value['models'] if provider == 'claude' else value['tokens'],
        'price_complete': not bool(value.get('unpriced_tokens')),
        'provider': provider,
        'tier': tier,
        'at': now_iso(),
        'windows': details,
        'selectors': {
            'claude_session': args.claude_session,
            'claude_main_only': args.claude_main_only,
            'claude_agents': args.claude_agent,
            'codex_rollouts': [str(path.expanduser().resolve()) for path in args.codex_rollout],
            'since': args.since,
            'until': args.until,
        },
    }
    if not any(
        item['kind'] == 'estimate' and item['id'] == args.id and item['class'] == args.task_class for item in entries
    ):
        print(f'предупреждение: {args.id}, {args.task_class}: факт без плана')
        anomaly('actual-without-estimate', {'id': args.id, 'class': args.task_class})

    append_json(state_dir() / 'history.jsonl', entry)
    print(f'записано {args.id}, {args.task_class}: {value["units"]:.2f} ед.; тариф {tier or "неизвестен"}')
    print(format_forecast(provider, details))


def estimate(args: argparse.Namespace) -> None:
    """Печатает прогноз и по запросу сохраняет расчет, ручную поправку и калибровку."""
    if args.record is not None and not args.record.strip():
        raise ValueError('id прогноза не должен быть пустым')

    if args.list and (args.record or args.override_units is not None or args.reason):
        raise ValueError('--list несовместим с записью и ручной поправкой')
    if (args.override_units is not None) != bool(args.reason and args.reason.strip()):
        raise ValueError('--override-units и непустой --reason нужны вместе')
    if args.override_units is not None and number(args.override_units, '--override-units') <= 0:
        raise ValueError('--override-units должен быть положительным')
    if args.override_units is not None and len(args.classes) != 1:
        raise ValueError('ручная поправка требует ровно один --class')

    names = list(STARTING_UNITS) if args.list else args.classes
    if not names:
        raise ValueError('нужен --class или --list')
    providers = [class_provider(name) for name in names]
    entries = history()
    saved = calibration()
    tiers = {} if args.list else current_tiers(providers)
    pending = []
    for name in names:
        provider = class_provider(name)
        facts = [actual_units(entry) for entry in entries if entry['kind'] == 'actual' and entry['class'] == name]
        facts = [value for value in facts if value is not None and value > 0]
        calculated = statistics.median(facts) if facts else STARTING_UNITS[name]
        units = args.override_units if args.override_units is not None else calculated
        source = 'history-median' if facts else 'seed'
        label = 'медиана истории' if facts else 'стартовый ориентир'
        if name == 'codex-high-l' and not facts:
            label += ', оценка'
        print(f'{name}: {units:.2f} ед. ({label}; фактов: {len(facts)})')
        if args.override_units is not None:
            print(f'  расчет: {calculated:.2f} ед.; поправка: {args.reason}')
        if args.list:
            print(f'  стартовый ориентир: {STARTING_UNITS[name]:.2f} ед.')
            continue

        tier = tiers[provider]
        details = forecast(provider, tier, units, saved, source)
        print(f'  {provider}, тариф {tier or "неизвестен"}; {format_forecast(provider, details)}')
        for window, detail in details.items():
            if detail['source'] == 'none' or detail['source'].startswith('rescaled-from:'):
                anomaly(
                    'estimate-calibration',
                    {
                        'id': args.record,
                        'class': name,
                        'tier': tier,
                        'window': window,
                        'source': detail['source'],
                    },
                )
        if args.record:
            pending.append(
                {
                    'schema_version': SCHEMA_VERSION,
                    'weights_version': WEIGHTS_VERSION,
                    'kind': 'estimate',
                    'id': args.record,
                    'class': name,
                    'provider': provider,
                    'units': units,
                    'calculated_units': calculated,
                    'override_units': args.override_units,
                    'reason': args.reason,
                    'tier': tier,
                    'at': now_iso(),
                    'source': source,
                    'fact_count': len(facts),
                    'windows': details,
                }
            )

    for entry in pending:
        append_json(state_dir() / 'history.jsonl', entry)


def accuracy(args: argparse.Namespace) -> None:
    """Сравнивает последние планы с фактами и суммы интервалов со снимками квот.

    Отношения задач используют сохраненные при записи веса и коэффициенты.
    Проценты сравниваются только для одинаковых тарифов и окон. --log отдельно
    проверяет калибровку по общему аккаунту, включая посторонние сессии.
    """
    since = iso_time(args.since) if args.since else None
    for name in args.classes:
        class_provider(name)
    entries = [entry for entry in history() if (not args.classes or entry['class'] in args.classes)]
    groups: dict[tuple[str, str], list[dict[str, Any]]] = {}
    for entry in entries:
        groups.setdefault((entry['id'], entry['class']), []).append(entry)

    by_class: dict[str, list[float]] = {}
    unpaired = []
    pairs = []
    for (identifier, name), items in groups.items():
        actuals = [item for item in items if item['kind'] == 'actual']
        plans = [item for item in items if item['kind'] == 'estimate']
        if len(actuals) > 1:
            raise ValueError(f'история: несколько фактов {identifier}, {name}')
        actual = actuals[0] if actuals else None
        eligible = [item for item in plans if not actual or iso_time(item['at']) <= iso_time(actual['at'])]
        plan = max(eligible, key=lambda item: iso_time(item['at'])) if eligible else None
        anchor = actual or plan
        if anchor and since and iso_time(anchor['at']) < since:
            continue
        if not actual or not plan:
            unpaired.append(f'{identifier}, {name}: {"план без факта" if not actual else "факт без плана"}')
            # План, записанный после факта, не является прогнозом этого факта.
            if actual and plans:
                unpaired.append(f'{identifier}, {name}: план после факта')
            continue

        if not actual.get('price_complete', True):
            unpaired.append(f'{identifier}, {name}: пара несопоставима, факт содержит модели без цены')
            continue

        if actual['weights_version'] != plan['weights_version']:
            unpaired.append(f'{identifier}, {name}: пара несопоставима, версии весов различаются')
            continue

        ratio = actual['units'] / plan['units']
        by_class.setdefault(name, []).append(ratio)
        pairs.append((plan, actual))
        print(f'{identifier}, {name}: факт/прогноз {ratio:.3f} по единицам')
        for window, detail in plan['windows'].items():
            actual_percent = actual['windows'].get(window, {}).get('percent')
            predicted = detail['percent']
            if plan['tier'] != actual['tier'] or predicted is None or actual_percent is None or predicted <= 0:
                print(f'  {window}: проценты несопоставимы или калибровки нет')
            else:
                print(f'  {window}: факт/прогноз {actual_percent / predicted:.3f} по процентам')
        if len(plans) > 1:
            print(f'  предыдущих или последующих планов: {len(plans) - 1}, для пары взят последний до факта')

    if not pairs:
        print('пар план/факт нет')
    for name, ratios in sorted(by_class.items()):
        errors = sum(value < 0.5 or value > 2 for value in ratios)
        print(
            f'{name}: пар {len(ratios)}, медиана {statistics.median(ratios):.3f}, '
            f'мин–макс {min(ratios):.3f}–{max(ratios):.3f}, ошибка >2 раз: {errors}'
        )
    print('Без пары:')
    for line in unpaired:
        print(f'  {line}')
    if not unpaired:
        print('  нет')

    if args.log:
        accuracy_windows(args.log, entries, since)


def accuracy_windows(path: Path, entries: list[dict[str, Any]], since: datetime | None) -> None:
    """Сравнивает суммы прогнозов между соседними снимками с дельтами аккаунта."""
    snapshots = list(json_lines(path))
    if len(snapshots) < 2:
        raise ValueError('accuracy --log: нужны минимум два снимка')
    if any(iso_time(left['at']) >= iso_time(right['at']) for left, right in zip(snapshots, snapshots[1:])):
        raise ValueError('accuracy --log: снимки не упорядочены по времени')

    intervals = [('Серия', snapshots[0], snapshots[-1])]
    if len(snapshots) > 2:
        intervals.extend(('Волна', first, last) for first, last in zip(snapshots, snapshots[1:]))
    for title, first, last in intervals:
        start, end = iso_time(first['at']), iso_time(last['at'])
        if start >= end:
            raise ValueError('accuracy --log: снимки не упорядочены по времени')
        if since and end < since:
            continue
        inside = [item for item in snapshots if start <= iso_time(item['at']) <= end]
        has_jump = any(item.get('suspect_jump') for item in inside) or any(
            jump(left, right) for left, right in zip(inside, inside[1:])
        )
        # Прогноз должен быть записан после снимка до волны и до снимка после нее.
        plans: dict[tuple[str, str], dict[str, Any]] = {}
        for item in entries:
            if item['kind'] == 'estimate' and start <= iso_time(item['at']) <= end:
                plans[(item['id'], item['class'])] = item
        print(f'{title} {first["at"]} – {last["at"]} (расход всего аккаунта):')
        if not plans:
            print('  планов в интервале нет, сравнение недоступно')
            continue
        for provider in ('claude', 'codex'):
            selected = [item for item in plans.values() if item['provider'] == provider]
            if not selected:
                continue
            units = sum(item['units'] for item in selected)
            tier_key = 'tier' if provider == 'claude' else 'plan_type'
            tier = first[provider].get(tier_key)
            windows = CLAUDE_WINDOWS if provider == 'claude' else (('weekly', 'неделя'),)
            for window, label in windows:
                old = stored_window(first, provider, window)
                new = stored_window(last, provider, window)
                windows_inside = [stored_window(item, provider, window) for item in inside]
                if (
                    not old
                    or not new
                    or old['resets_at'] != new['resets_at']
                    or new['resets_at'] <= end.timestamp()
                    or tier != last[provider].get(tier_key)
                    or any(item['tier'] != tier or item['windows'][window]['percent'] is None for item in selected)
                    or has_jump
                    or any(item[provider].get(tier_key) != tier for item in inside)
                    or any(item is None for item in windows_inside)
                    or any(item['resets_at'] != old['resets_at'] for item in windows_inside)
                ):
                    print(f'  {provider} {label}: данные несопоставимы')
                    continue
                used_key = 'used_percentage' if provider == 'claude' else 'used_percent'
                delta = new[used_key] - old[used_key]
                predicted = sum(item['windows'][window]['percent'] for item in selected)
                if predicted <= 0 or delta < 0:
                    print(f'  {provider} {label}: отношение недоступно')
                    continue
                print(
                    f'  {provider} {label}: план {units:.2f} ед. / {predicted:.2f}%, '
                    f'дельта аккаунта {delta:g} п.п., факт/прогноз {delta / predicted:.3f}'
                )


def add_selectors(parser: argparse.ArgumentParser) -> None:
    """Добавляет общие селекторы task и record."""
    parser.add_argument('--since', help='начало окна ISO с часовым поясом, не включается')
    parser.add_argument('--until', help='конец окна ISO с часовым поясом, включается')
    parser.add_argument('--claude-session', help='UUID основной сессии вместе со всеми субагентами')
    parser.add_argument(
        '--claude-main-only', action='store_true', help='только основной файл выбранной сессии для накладных Team Lead'
    )
    parser.add_argument('--claude-agent', action='append', default=[], help='ID субагента без agent-, можно повторять')
    parser.add_argument('--codex-rollout', type=Path, action='append', default=[], help='путь rollout, можно повторять')


def main() -> None:
    """Разбирает подкоманды и печатает явные ошибки без содержимого источников."""
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest='command', required=True)
    snapshot_parser = commands.add_parser('snapshot', help='снимок текущих квот и тарифов')
    snapshot_parser.add_argument('--log', type=Path, required=True, help='журнал JSONL в scratchpad')
    task_parser = commands.add_parser('task', help='фактические токены, единицы и проценты')
    add_selectors(task_parser)
    calibrate_parser = commands.add_parser('calibrate', help='калибровка по расходу всего аккаунта')
    calibrate_parser.add_argument('--log', type=Path, required=True)
    calibrate_parser.add_argument('--from', dest='from_index', type=int, help='индекс первого снимка, с нуля')
    calibrate_parser.add_argument('--to', dest='to_index', type=int, help='индекс последнего снимка, с нуля')
    calibrate_parser.add_argument('--accept-jumps', action='store_true', help='принять проверенные скачки 7d')
    record_parser = commands.add_parser('record', help='записать факт задачи в историю')
    record_parser.add_argument('id')
    record_parser.add_argument('--class', dest='task_class', required=True)
    add_selectors(record_parser)
    estimate_parser = commands.add_parser('estimate', help='прогноз по классам задач')
    estimate_parser.add_argument('--class', dest='classes', action='append', default=[])
    estimate_parser.add_argument('--list', action='store_true', help='все классы и число фактов')
    estimate_parser.add_argument('--record', help='id задачи для записи прогноза')
    estimate_parser.add_argument('--override-units', type=float, help='ручной прогноз единиц для выбранных классов')
    estimate_parser.add_argument('--reason', help='обоснование ручной поправки')
    accuracy_parser = commands.add_parser('accuracy', help='диагностика планов против фактов')
    accuracy_parser.add_argument('--since', help='время записи факта или непарного плана, ISO')
    accuracy_parser.add_argument('--class', dest='classes', action='append', default=[])
    accuracy_parser.add_argument('--log', type=Path, help='журнал снимков для проверки сумм волн')
    args = parser.parse_args()

    try:
        if args.command == 'snapshot':
            take_snapshot(args)
        elif args.command == 'task':
            result = task_usage(args)
            print_task(result, current_tiers(list(result)))
        elif args.command == 'calibrate':
            calibrate(args)
        elif args.command == 'record':
            record(args)
        elif args.command == 'estimate':
            estimate(args)
        else:
            accuracy(args)
    except (OSError, ValueError, KeyError, TypeError, AttributeError) as error:
        if args.command == 'calibrate':
            try:
                anomaly('calibration-refused', {'log': str(args.log), 'reason': str(error)})
            except (OSError, ValueError) as log_error:
                print(f'usage: ошибка записи аномалии: {log_error}', file=sys.stderr)
        print(f'usage: ошибка: {error}', file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
