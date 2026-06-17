#!/usr/bin/env python3
"""Сборка markdown-заметки из одной статьи arXiv.

Запрашивает метаданные по arXiv ID через публичный API и формирует
reference-документ с frontmatter, абстрактом и ссылками. Не скачивает PDF и не
парсит полный текст — это лёгкий конвертер метаданных в заметку.

Examples:
    python3 arxiv_doc_builder.py 2305.12345
    python3 arxiv_doc_builder.py 2305.12345 --out Notes/arxiv/2305.12345.md
"""

from __future__ import annotations

import argparse
import os
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

ARXIV_API = "http://export.arxiv.org/api/query"
ATOM = "{http://www.w3.org/2005/Atom}"
ARXIV = "{http://arxiv.org/schemas/atom}"


def _ssl_context() -> ssl.SSLContext:
    """Создаёт SSL-контекст с полной проверкой и локальными корпоративными CA.

    Доверяет стандартным CA плюс любым `.pem` из каталога `ARXIV_EXTRA_CA_DIR`
    (по умолчанию `~/.claude/certs`). Это нужно в сетях с MITM-прокси, который
    переподписывает TLS своей цепочкой: достаточно положить корневой CA в этот
    каталог. Проверка цепочки и hostname остаётся включённой
    (`verify_mode=CERT_REQUIRED`). Если корпоративные CA подгружены, снимается
    только строгая проверка расширений RFC 5280 (`VERIFY_X509_STRICT`), которую
    не проходят некоторые корпоративные CA и которую не применяют curl и браузеры.

    Returns:
        Готовый к использованию `ssl.SSLContext`.
    """
    ctx = ssl.create_default_context()
    ca_dir = Path(os.environ.get("ARXIV_EXTRA_CA_DIR", Path.home() / ".claude" / "certs"))
    loaded = 0
    if ca_dir.is_dir():
        for pem in sorted(ca_dir.glob("*.pem")):
            try:
                ctx.load_verify_locations(cafile=str(pem))
                loaded += 1
            except ssl.SSLError:
                continue
    if loaded:
        ctx.verify_flags &= ~ssl.VerifyFlags.VERIFY_X509_STRICT
    return ctx


def _text(node: ET.Element | None) -> str:
    """Возвращает очищенный текст узла или пустую строку."""
    if node is None or node.text is None:
        return ""
    return " ".join(node.text.split())


def _normalize_id(value: str) -> str:
    """Приводит вход к чистому arXiv ID, отбрасывая URL и префикс `arXiv:`."""
    value = value.strip()
    value = value.rsplit("/abs/", 1)[-1]
    value = value.rsplit("/pdf/", 1)[-1]
    if value.lower().startswith("arxiv:"):
        value = value[len("arxiv:") :]
    return value.removesuffix(".pdf")


def fetch_entry(arxiv_id: str) -> ET.Element:
    """Запрашивает одну запись arXiv по идентификатору.

    Args:
        arxiv_id: Идентификатор статьи, например `2305.12345` или `2305.12345v2`.

    Returns:
        Atom-элемент `entry` с метаданными статьи.

    Raises:
        SystemExit: Сетевая ошибка, некорректный ответ или статья не найдена.
    """
    params = urllib.parse.urlencode({"id_list": arxiv_id, "max_results": 1})
    url = f"{ARXIV_API}?{params}"
    request = urllib.request.Request(url, headers={"User-Agent": "arxiv-doc-builder-skill/1.0"})
    try:
        with urllib.request.urlopen(request, timeout=30, context=_ssl_context()) as response:
            payload = response.read()
    except urllib.error.URLError as exc:
        sys.exit(f"arXiv request failed: {exc}")

    try:
        root = ET.fromstring(payload)
    except ET.ParseError as exc:
        sys.exit(f"arXiv response parse error: {exc}")

    entry = root.find(f"{ATOM}entry")
    if entry is None or not _text(entry.find(f"{ATOM}title")):
        sys.exit(f"arXiv paper not found: {arxiv_id}")
    return entry


def build_markdown(entry: ET.Element, arxiv_id: str) -> str:
    """Формирует markdown-документ из Atom-записи.

    Args:
        entry: Atom-элемент `entry`, полученный из arXiv API.
        arxiv_id: Нормализованный идентификатор для заголовка и ссылок.

    Returns:
        Полный текст markdown-заметки с YAML frontmatter.
    """
    title = _text(entry.find(f"{ATOM}title"))
    summary = _text(entry.find(f"{ATOM}summary"))
    published = _text(entry.find(f"{ATOM}published"))
    updated = _text(entry.find(f"{ATOM}updated"))
    authors = [
        _text(a.find(f"{ATOM}name"))
        for a in entry.findall(f"{ATOM}author")
        if _text(a.find(f"{ATOM}name"))
    ]
    categories = [c.get("term", "") for c in entry.findall(f"{ATOM}category") if c.get("term")]
    primary = entry.find(f"{ARXIV}primary_category")
    primary_category = primary.get("term", "") if primary is not None else ""
    doi = _text(entry.find(f"{ARXIV}doi"))
    comment = _text(entry.find(f"{ARXIV}comment"))

    abs_url = f"https://arxiv.org/abs/{arxiv_id}"
    pdf_url = f"https://arxiv.org/pdf/{arxiv_id}"

    authors_yaml = "\n".join(f"  - {name}" for name in authors) or "  []"
    tags_yaml = "\n".join(f"  - {cat}" for cat in categories) or "  []"

    lines = [
        "---",
        f'title: "{title}"',
        f"arxiv_id: {arxiv_id}",
        "authors:",
        authors_yaml,
        f"primary_category: {primary_category}",
        "categories:",
        tags_yaml,
        f"published: {published[:10]}",
        f"updated: {updated[:10]}",
        f"url: {abs_url}",
        f"pdf: {pdf_url}",
    ]
    if doi:
        lines.append(f"doi: {doi}")
    lines.append("---")
    lines.append("")
    lines.append(f"# {title}")
    lines.append("")
    lines.append(f"**Authors:** {', '.join(authors)}")
    lines.append("")
    lines.append(f"**arXiv:** [{arxiv_id}]({abs_url}) · [PDF]({pdf_url}) · {primary_category}")
    if comment:
        lines.append("")
        lines.append(f"**Comment:** {comment}")
    lines.append("")
    lines.append("## Abstract")
    lines.append("")
    lines.append(summary)
    lines.append("")
    lines.append("## Notes")
    lines.append("")
    lines.append("- ")
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    """Разбирает аргументы CLI, строит заметку и печатает её или пишет в файл."""
    parser = argparse.ArgumentParser(description="Build a markdown note from an arXiv paper.")
    parser.add_argument("arxiv_id", help="arXiv ID or URL (e.g. 2305.12345 or arxiv.org/abs/2305.12345)")
    parser.add_argument("--out", type=Path, help="write note to this path instead of stdout")
    args = parser.parse_args()

    arxiv_id = _normalize_id(args.arxiv_id)
    entry = fetch_entry(arxiv_id)
    document = build_markdown(entry, arxiv_id)

    if args.out is None:
        print(document)
        return

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(document, encoding="utf-8")
    print(f"Wrote {args.out}")


if __name__ == "__main__":
    main()
