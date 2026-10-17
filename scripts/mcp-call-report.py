#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Считает отказы MCP-вызовов и работу tool search по транскриптам Claude Code и сессиям Codex.

Отчет отвечает на два вопроса: на чем падают MCP-вызовы агентов и связаны ли отказы
с тем, что схема тула не была загружена до вызова.

Методика:

- Claude: вызовы и результаты дедуплицируются по `tool_use.id`, ход агента – `message.id`.
  Файлы `subagents/*.jsonl` считаются отдельно от основных сессий. Схема считается
  загруженной, если тул вернулся в результате ToolSearch строго в более раннем ходе.
  Вызов после compaction, чья схема загружалась только до нее, идет в `after_compaction`.
- Codex: вызовы и выводы дедуплицируются по `call_id` во всех файлах, поэтому копии
  истории в форках не задваивают счет. MCP-вызовы – `function_call` с namespace `mcp__*`
  и `custom_tool_call` (`exec`), чей JS вызывает `tools.mcp__*`. Выводы прочих `exec`
  не разбираются, чтобы не считать логи, которые сессия сама анализировала.
- Отказ – результат с `is_error` или с текстом `Incorrect Usage` Spirit CLI.

Claude Code удаляет транскрипты старше `cleanupPeriodDays`, поэтому окна данных
у Claude и Codex разные: отчет печатает даты первой и последней сессии.
"""

import argparse
import json
import re
from collections import Counter, defaultdict
from collections.abc import Iterator
from dataclasses import dataclass, field
from pathlib import Path

FLOAT_INT = re.compile(r'invalid value \\*"([0-9.]+(?:e\+\d+)?)\\*" for flag (-[\w-]+)')
UNKNOWN_FLAG = re.compile(r'flag provided but not defined: (-[\w-]+)')
INCORRECT_USAGE = 'Incorrect Usage'


@dataclass
class Report:
    """Агрегаты одного источника."""

    sessions: Counter[str] = field(default_factory=Counter)
    mcp_calls: Counter[str] = field(default_factory=Counter)
    failures: Counter[tuple[str, str]] = field(default_factory=Counter)
    by_tool: Counter[tuple[str, str]] = field(default_factory=Counter)
    unknown_flags: Counter[tuple[str, str]] = field(default_factory=Counter)
    failed_sessions: set[str] = field(default_factory=set)
    tool_search_calls: int = 0
    tool_search_only_turns: int = 0
    dates: list[str] = field(default_factory=list)


def classify(text: str, is_error: bool) -> tuple[str, str] | None:
    """Возвращает класс отказа и деталь или ``None``, если вызов успешен."""
    if match := FLOAT_INT.search(text):
        value, flag = match.groups()
        return ('float_for_int_flag', flag) if 'e+' in value or '.' in value else ('invalid_value', flag)
    if match := UNKNOWN_FLAG.search(text):
        return 'unknown_flag', match.group(1)
    if 'InputValidationError' in text:
        return 'input_validation', ''
    if INCORRECT_USAGE in text:
        return 'other_usage', ''
    return ('other_error', '') if is_error else None


def text_of(content: object) -> str:
    """Собирает текст из строки или списка блоков результата."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = (b.get('text') or text_of(b.get('content')) for b in content if isinstance(b, dict))
        return ' '.join(p for p in parts if p)
    return ''


def records(path: Path) -> Iterator[dict]:
    """Читает JSONL, пропуская битые строки."""
    with path.open(encoding='utf-8', errors='replace') as stream:
        for line in stream:
            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                continue


def analyze_claude(root: Path, report: Report) -> None:
    """Разбирает транскрипты Claude Code."""
    for path in sorted(root.rglob('*.jsonl')):
        kind = 'subagent' if 'subagents' in path.parts else 'main'
        uses: dict[str, tuple[str, int, int]] = {}
        results: dict[str, dict] = {}
        turn_index: dict[str, int] = {}
        turn_tools: defaultdict[int, list[str]] = defaultdict(list)
        compactions: list[int] = []
        loaded: dict[str, int] = {}
        first_ts = ''

        for rec in records(path):
            first_ts = first_ts or rec.get('timestamp', '')
            if rec.get('isCompactSummary'):
                compactions.append(len(turn_index))
            message = rec.get('message') or {}
            content = message.get('content')
            if not isinstance(content, list):
                continue
            for block in content:
                if not isinstance(block, dict):
                    continue
                if block.get('type') == 'tool_use' and block.get('id') not in uses:
                    turn = turn_index.setdefault(message.get('id') or block['id'], len(turn_index))
                    epoch = len(compactions)
                    uses[block['id']] = (block.get('name', ''), turn, epoch)
                    turn_tools[turn].append(block.get('name', ''))
                elif block.get('type') == 'tool_result' and block.get('tool_use_id') not in results:
                    results[block['tool_use_id']] = block

        if not uses:
            continue

        for tid, (name, turn, _) in uses.items():
            if name != 'ToolSearch':
                continue
            report.tool_search_calls += 1
            content = (results.get(tid) or {}).get('content')
            if isinstance(content, list):
                for block in content:
                    if isinstance(block, dict) and block.get('tool_name'):
                        loaded.setdefault(block['tool_name'], turn)
        report.tool_search_only_turns += sum(1 for names in turn_tools.values() if set(names) == {'ToolSearch'})

        session_key = f'claude:{path}'
        has_mcp = False
        for tid, (name, turn, epoch) in uses.items():
            if not name.startswith('mcp__'):
                continue
            has_mcp = True
            if name not in loaded or loaded[name] >= turn:
                state = 'not_loaded'
            elif epoch and loaded[name] < compactions[epoch - 1]:
                state = 'after_compaction'
            else:
                state = 'loaded'
            report.mcp_calls[f'{kind}:{state}'] += 1
            result = results.get(tid) or {}
            verdict = classify(text_of(result.get('content')), bool(result.get('is_error')))
            if verdict is None:
                continue
            klass, detail = verdict
            short = name.split('__')[-1]
            report.failures[(f'{kind}:{state}', klass)] += 1
            report.by_tool[(klass, short)] += 1
            if klass == 'unknown_flag':
                report.unknown_flags[(short, detail)] += 1
            report.failed_sessions.add(session_key)

        if has_mcp:
            report.sessions[kind] += 1
            report.dates.append(first_ts[:10])


def analyze_codex(root: Path, report: Report) -> None:
    """Разбирает сессии Codex с дедупликацией по `call_id`."""
    calls: dict[str, tuple[str, str]] = {}
    outputs: dict[str, str] = {}
    searches: set[str] = set()
    session_of: dict[str, str] = {}
    session_dates: dict[str, str] = {}

    for path in sorted(root.rglob('*.jsonl')):
        for rec in records(path):
            if rec.get('type') == 'session_meta':
                session_dates[str(path)] = (rec.get('payload') or {}).get('timestamp', '')[:10]
            if rec.get('type') != 'response_item':
                continue
            payload = rec.get('payload') or {}
            kind, call_id = payload.get('type'), payload.get('call_id')
            if not call_id:
                continue
            if kind == 'tool_search_call':
                searches.add(call_id)
            elif kind == 'function_call' and (payload.get('namespace') or '').startswith('mcp__'):
                calls.setdefault(call_id, ('direct', payload.get('name', '')))
                session_of.setdefault(call_id, str(path))
            elif kind == 'custom_tool_call' and 'tools.mcp__' in (payload.get('input') or ''):
                names = re.findall(r'tools\.mcp__\w+?__(\w+)\(', payload.get('input') or '')
                calls.setdefault(call_id, ('exec', ','.join(sorted(set(names)))))
                session_of.setdefault(call_id, str(path))
            elif kind in ('function_call_output', 'custom_tool_call_output'):
                outputs.setdefault(call_id, text_of(payload.get('output')))

    report.tool_search_calls = len(searches)
    sessions: set[str] = set()
    for call_id, (mode, names) in calls.items():
        sessions.add(session_of[call_id])
        report.mcp_calls[mode] += 1
        verdict = classify(outputs.get(call_id, ''), is_error=False)
        if verdict is None:
            continue
        klass, detail = verdict
        report.failures[(mode, klass)] += 1
        report.by_tool[(klass, names)] += 1
        if klass == 'unknown_flag':
            report.unknown_flags[(names, detail)] += 1
        report.failed_sessions.add(session_of[call_id])
    report.sessions['main'] = len(sessions)
    report.dates = sorted(session_dates[s] for s in sessions if session_dates.get(s))


def print_report(title: str, report: Report, top: int) -> None:
    """Печатает агрегаты одного источника."""
    dates = sorted(d for d in report.dates if d)
    window = f'{dates[0]} – {dates[-1]}' if dates else 'нет данных'
    total_sessions = sum(report.sessions.values())
    print(f'## {title}  ({window})')
    print(f'сессии с MCP: {dict(report.sessions)}; с отказами: {len(report.failed_sessions)}')
    print(f'tool search: вызовов {report.tool_search_calls}, ходов только из него {report.tool_search_only_turns}')
    print(f'MCP-вызовы: {dict(report.mcp_calls)}')
    print('отказы по состоянию схемы и классу:')
    for (state, klass), count in sorted(report.failures.items()):
        calls = report.mcp_calls.get(state, 0)
        share = f'{count / calls:.1%}' if calls else '–'
        print(f'  {state:<28} {klass:<20} {count:>5}  ({share} вызовов этого состояния)')
    failed = sum(report.failures.values())
    if total_sessions:
        print(f'отказов на сессию с MCP: {failed / total_sessions:.2f}')
    print('топ тулов по классу:', report.by_tool.most_common(top))
    print('выдуманные флаги:', report.unknown_flags.most_common(top))
    print()


def main() -> None:
    """Точка входа CLI."""
    parser = argparse.ArgumentParser(description='Отказы MCP-вызовов и tool search в сессиях Claude Code и Codex.')
    parser.add_argument('--claude-root', type=Path, default=Path.home() / '.claude' / 'projects')
    parser.add_argument('--codex-root', type=Path, default=Path.home() / '.codex' / 'sessions')
    parser.add_argument('--top', type=int, default=10)
    args = parser.parse_args()

    claude, codex = Report(), Report()
    if args.claude_root.is_dir():
        analyze_claude(args.claude_root, claude)
        print_report('Claude Code', claude, args.top)
    if args.codex_root.is_dir():
        analyze_codex(args.codex_root, codex)
        print_report('Codex', codex, args.top)


if __name__ == '__main__':
    main()
