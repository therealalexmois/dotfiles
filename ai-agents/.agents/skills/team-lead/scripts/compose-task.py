#!/usr/bin/env python3
"""Собирает задание из черновика, объединенного профиля и шаблонов assets/.

Черновик содержит только сведения задачи: разделы `## Контекст`, `## Задача`,
`## Критерии успеха` и необязательный `## Ограничения`.
Общие части берутся из парных блоков профиля:
`<!-- team-lead:<блок> -->` ... `<!-- /team-lead:<блок> -->`.
Пустой обязательный раздел или блок вызывает ошибку.
Вывод: путь `<scratchpad>/<id>-task.md`.

Examples:
    compose-task.py [--repo <путь>] --draft <черновик.md> --id <id>
                   --worktree <путь> --branch <ветка> --scratchpad <каталог> [--closes <строка>]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import NoReturn

from profile_model import TASK_BLOCKS, load_profile, split_sections

TEMPLATES = Path(__file__).resolve().parent.parent / 'assets'
REQUIRED_SECTIONS = ('Контекст', 'Задача', 'Критерии успеха')
KNOWN_SECTIONS = (*REQUIRED_SECTIONS, 'Ограничения')
REQUIRED_BLOCKS = ('task-context',)


def fail(message: str) -> NoReturn:
    """Печатает ошибку и завершает работу с кодом 1."""
    print(f'compose-task: {message}', file=sys.stderr)
    raise SystemExit(1)


def draft_sections(text: str) -> dict[str, str]:
    """Делит черновик на разделы второго уровня и проверяет их состав."""
    preamble, sections = split_sections(text, KNOWN_SECTIONS)

    if preamble:
        fail('draft has text before the first `## ` section; move it into a section')

    missing = [title for title in REQUIRED_SECTIONS if not sections.get(title)]

    if missing:
        fail(f'empty or missing draft sections: {missing}')

    return sections


def profile_blocks(repo: Path) -> dict[str, str]:
    """Проверяет обязательные блоки после слияния обоих профилей."""
    profile = load_profile(repo)
    blocks = {name: profile.blocks[name].text if name in profile.blocks else '' for name in TASK_BLOCKS}

    missing = [name for name in REQUIRED_BLOCKS if not blocks[name]]

    if missing:
        fail(f'profile has no blocks {missing}; see references/profile-format.md')

    return blocks


def substitute(text: str, values: dict[str, str]) -> str:
    """Подставляет известные плейсхолдеры за один проход.

    Прочие скобки, например `{{DUMPS}}` из justfile, сохраняются.
    Подставленный текст повторно не разбирается.
    """
    return re.sub(r'\{(\w+)\}', lambda match: values.get(match.group(1), match.group(0)), text)


def joined(*parts: str) -> str:
    """Склеивает непустые части списка пунктов."""
    return '\n'.join(part for part in parts if part)


def main() -> None:
    """Собирает задание и печатает путь к нему."""
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--repo', type=Path, default=Path.cwd(), help='каталог проекта, по умолчанию текущий')
    parser.add_argument('--draft', type=Path, required=True)
    parser.add_argument('--id', required=True, help='идентификатор задачи, обычно номер issue')
    parser.add_argument('--worktree', required=True)
    parser.add_argument('--branch', required=True)
    parser.add_argument('--scratchpad', type=Path, required=True)
    parser.add_argument('--closes', help='последняя строка описания PR; по умолчанию `Closes #<id>`')
    args = parser.parse_args()

    if args.closes is None and not args.id.isdigit():
        fail('--closes is required when --id is not an issue number')

    try:
        sections = draft_sections(args.draft.read_text(encoding='utf-8'))
        blocks = profile_blocks(args.repo)
    except (OSError, ValueError) as error:
        fail(str(error))
    scratchpad = args.scratchpad.resolve()

    values = {
        'id': args.id,
        'worktree': args.worktree,
        'branch': args.branch,
        'scratchpad': str(scratchpad),
        'closes': args.closes or f'Closes #{args.id}',
    }
    values['report_extra'] = substitute(blocks['report-extra'], values)
    report_template = substitute((TEMPLATES / 'report.md').read_text(encoding='utf-8'), values).strip()
    pr_body_template = substitute((TEMPLATES / 'pr-body.md').read_text(encoding='utf-8'), values).strip()

    values |= {
        'profile_context': substitute(blocks['task-context'], values),
        'context': sections['Контекст'],
        'task': sections['Задача'],
        'criteria': joined(sections['Критерии успеха'], substitute(blocks['task-criteria'], values)),
        'constraints': joined(sections.get('Ограничения', ''), substitute(blocks['task-constraints'], values)),
        'report_path': str(scratchpad / f'{args.id}-report.md'),
        'pr_body_path': str(scratchpad / f'{args.id}-pr-body.md'),
        'report_template': report_template,
        'pr_body_template': pr_body_template,
    }
    task = substitute((TEMPLATES / 'task.md').read_text(encoding='utf-8'), values)

    out = scratchpad / f'{args.id}-task.md'
    out.write_text(task, encoding='utf-8')
    print(out)


if __name__ == '__main__':
    main()
