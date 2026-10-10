#!/usr/bin/env python3
"""Печатает окна Claude 5h и 7d, тариф и session_id локального снимка."""

from __future__ import annotations

import sys

from quota_sources import claude_source, print_claude


def main() -> None:
    """Печатает сводку; недоступный или битый источник дает ненулевой код."""
    try:
        print_claude(claude_source())
    except (OSError, ValueError, KeyError, TypeError) as error:
        sys.exit(f'claude-quota: {error}')


if __name__ == '__main__':
    main()
