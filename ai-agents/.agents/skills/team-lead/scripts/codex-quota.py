#!/usr/bin/env python3
"""Печатает недельную квоту и тариф из последнего события token_count Codex."""

from __future__ import annotations

import sys

from quota_sources import codex_source, print_codex


def main() -> None:
    """Печатает сводку; недоступный или битый источник дает ненулевой код."""
    try:
        print_codex(codex_source())
    except (OSError, ValueError, KeyError, TypeError) as error:
        sys.exit(f'codex-quota: {error}')


if __name__ == '__main__':
    main()
