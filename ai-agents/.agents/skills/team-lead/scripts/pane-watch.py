#!/usr/bin/env python3
"""Наблюдает за сессиями инженеров в tmux и печатает по строке на событие.

Режим наблюдения (для Monitor):
  pane-watch.py <метка>=<pane_id>=<файл отчета>=<файл описания PR>[=codex|claude] ...
  События: отчет обновлен, описание PR записано, вопрос или запрос разрешения, простой, pane закрыт.

Режим проверки простоя (перед коммитом Team Lead):
  pane-watch.py --check-idle <pane_id> [--kind codex|claude]
  Код 0 – простой в двух замерах подряд с паузой; код 1 – инженер работает; код 2 – pane закрыт.

Режим одного замера (для tmux-send.sh):
  pane-watch.py --is-busy <pane_id> [--kind codex|claude]
  Код 0 – есть признак работы; код 1 – нет; код 2 – pane закрыт.

Регулярки PROFILES – единственный источник признаков работы и вопросов; статус профиля `claude` –
в references/claude-cli.md.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

POLL_SEC = 3
IDLE_SEC = 150
IDLE_CHECK_PAUSE_SEC = 15
TAIL_LINES = 25

PROFILES: dict[str, dict[str, re.Pattern[str]]] = {
    'codex': {
        'busy': re.compile(r'Working|esc to interrupt|Waiting for background terminal'),
        'question': re.compile(
            r'Would you like to|Yes, proceed|don.t ask again|tell Codex what to do|\d+ questions?\b|to answer'
        ),
    },
    'claude': {
        'busy': re.compile(r'esc to interrupt'),
        'question': re.compile(r'Do you want to|Would you like to|\d+ questions?\b'),
    },
}


def capture(pane: str) -> str | None:
    """Возвращает хвост видимого текста pane или None, если pane закрыт."""
    result = subprocess.run(['tmux', 'capture-pane', '-p', '-t', pane], capture_output=True, text=True)

    if result.returncode != 0:
        return None

    return '\n'.join(result.stdout.rstrip().splitlines()[-TAIL_LINES:])


def mtime(path: Path) -> float:
    """Возвращает время изменения файла или 0, если файла нет."""
    return path.stat().st_mtime if path.exists() else 0.0


def check_idle(pane: str, kind: str) -> int:
    """Проверяет устойчивый простой: два замера без признака работы с паузой между ними."""
    busy = PROFILES[kind]['busy']

    for attempt in range(2):
        text = capture(pane)

        if text is None:
            print(f'{pane}: pane закрыт')
            return 2

        if busy.search(text):
            print(f'{pane}: работает')
            return 1

        if attempt == 0:
            time.sleep(IDLE_CHECK_PAUSE_SEC)

    print(f'{pane}: устойчивый простой')
    return 0


def is_busy(pane: str, kind: str) -> int:
    """Один замер: есть ли в pane признак работы."""
    text = capture(pane)

    if text is None:
        return 2

    return 0 if PROFILES[kind]['busy'].search(text) else 1


def parse_spec(spec: str) -> dict[str, Any]:
    """Разбирает описание сессии `метка=pane=отчет=описание PR[=вид]`."""
    parts = spec.split('=')

    if len(parts) not in (4, 5):
        raise SystemExit(f'bad session spec (expected label=pane=report=prbody[=kind]): {spec}')

    label, pane, report, pr_body = parts[:4]
    kind = parts[4] if len(parts) == 5 else 'codex'

    if kind not in PROFILES:
        raise SystemExit(f'unknown kind {kind!r} in spec: {spec}')

    return {
        'label': label,
        'pane': pane,
        'kind': kind,
        'report': Path(report),
        'pr_body': Path(pr_body),
        'report_m': mtime(Path(report)),
        'pr_body_m': mtime(Path(pr_body)),
        'last_busy': time.monotonic(),
        'idle_sent': False,
        'question_sent': False,
    }


def watch(specs: list[str]) -> None:
    """Опрашивает pane и файлы сессий, печатает события, пока открыт хотя бы один pane."""
    sessions = [parse_spec(spec) for spec in specs]

    while sessions:
        for s in list(sessions):
            text = capture(s['pane'])

            if text is None:
                print(f"{s['label']}: pane закрыт", flush=True)
                sessions.remove(s)
                continue

            if mtime(s['report']) != s['report_m']:
                s['report_m'] = mtime(s['report'])
                print(f"{s['label']}: отчет обновлен {s['report'].name}", flush=True)

            if mtime(s['pr_body']) != s['pr_body_m']:
                s['pr_body_m'] = mtime(s['pr_body'])
                print(f"{s['label']}: описание PR записано {s['pr_body'].name}", flush=True)

            profile = PROFILES[s['kind']]

            if profile['question'].search(text):
                if not s['question_sent']:
                    print(f"{s['label']}: вопрос или запрос разрешения в pane {s['pane']}", flush=True)
                    s['question_sent'] = True
            else:
                s['question_sent'] = False

            if profile['busy'].search(text):
                s['last_busy'] = time.monotonic()
                s['idle_sent'] = False
            elif not s['idle_sent'] and time.monotonic() - s['last_busy'] > IDLE_SEC:
                print(f"{s['label']}: простой больше {IDLE_SEC} с, возможно вопрос или готово", flush=True)
                s['idle_sent'] = True

        time.sleep(POLL_SEC)


def main() -> None:
    """Разбирает аргументы и запускает нужный режим."""
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--check-idle', metavar='PANE', help='проверить устойчивый простой pane')
    mode.add_argument('--is-busy', metavar='PANE', help='один замер признака работы')
    parser.add_argument('--kind', choices=sorted(PROFILES), default='codex', help='вид сессии для проверок')
    parser.add_argument('specs', nargs='*', help='метка=pane=отчет=описание PR[=вид]')
    args = parser.parse_args()

    if args.check_idle:
        sys.exit(check_idle(args.check_idle, args.kind))

    if args.is_busy:
        sys.exit(is_busy(args.is_busy, args.kind))

    if not args.specs:
        parser.error('no sessions to watch')

    watch(args.specs)


if __name__ == '__main__':
    main()
