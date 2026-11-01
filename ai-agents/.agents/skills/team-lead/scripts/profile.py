#!/usr/bin/env python3
"""Показывает пути и объединенный профиль Team Lead вне репозиториев."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from profile_model import load_profile, render_profile, resolve_paths


def main() -> None:
    """Разбирает resolve/show; отсутствие глобального профиля дает код 1."""
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    for command in ('resolve', 'show'):
        subparser = commands.add_parser(command)
        subparser.add_argument('--repo', type=Path, default=Path.cwd(), help='каталог проекта, по умолчанию текущий')
    args = parser.parse_args()

    try:
        if args.command == 'resolve':
            for path in resolve_paths(args.repo):
                print(path)
        else:
            print(render_profile(load_profile(args.repo)), end='')
    except (OSError, ValueError) as error:
        print(f'profile: {error}', file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
