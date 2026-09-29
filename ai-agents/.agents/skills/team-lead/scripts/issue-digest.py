#!/usr/bin/env python3
"""Печатает краткую выжимку issues GitHub для оценки объема серии.

Использование: issue-digest.py [--solution-heading <заголовок из профиля>] <номер> [<номер> ...]
Для каждого issue: заголовок, метки, длина описания, открытые пункты чеклиста, начало раздела
решения (или описания) и начало комментариев. Детали – `gh issue view <n> --comments`.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess

SOLUTION_CHARS = 420
COMMENT_CHARS = 200
COMMENTS_TOTAL_CHARS = 300


def digest(number: str, solution_heading: str | None) -> None:
    """Печатает выжимку одного issue."""
    raw = subprocess.run(
        ['gh', 'issue', 'view', number, '--json', 'number,title,body,comments,labels,state'],
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    issue = json.loads(raw)

    body = issue['body']
    checklist = len(re.findall(r'^\s*- \[ \]', body, flags=re.MULTILINE))
    match = None

    if solution_heading:
        pattern = rf'## {re.escape(solution_heading)}\s*(.+?)(?:\n## |\Z)'
        match = re.search(pattern, body, flags=re.DOTALL)

    solution = (match.group(1) if match else body)[:SOLUTION_CHARS].replace('\n', ' ')
    labels = ','.join(label['name'] for label in issue['labels'])
    comments = ' | '.join(comment['body'][:COMMENT_CHARS].replace('\n', ' ') for comment in issue['comments'])

    print(f"#{issue['number']} {issue['title']} [{issue['state']}; {labels}] body={len(body)} open_items={checklist}")
    print(f'  решение: {solution}')

    if comments:
        print(f'  комментарии ({len(issue["comments"])}): {comments[:COMMENTS_TOTAL_CHARS]}')


def main() -> None:
    """Разбирает аргументы и печатает выжимки по порядку."""
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--solution-heading', help='заголовок раздела решения; без него – начало описания')
    parser.add_argument('numbers', nargs='+', help='номера issues')
    args = parser.parse_args()

    for number in args.numbers:
        digest(number.lstrip('#'), args.solution_heading)


if __name__ == '__main__':
    main()
