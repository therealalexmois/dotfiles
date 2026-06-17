#!/usr/bin/env python3
"""Поиск по arXiv API без сторонних зависимостей.

Запрашивает публичный arXiv Atom API, разбирает ответ и печатает результаты в
выбранном формате. Используется как источник данных для пайплайна
«терминал → research → markdown-заметка».

Examples:
    python3 arxiv_search.py "retrieval augmented generation" --max-papers 5
    python3 arxiv_search.py "agentic llm" --format jsonl > papers_raw.jsonl
"""

from __future__ import annotations

import argparse
import json
import os
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from dataclasses import asdict, dataclass
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

SORT_BY = {"relevance", "lastUpdatedDate", "submittedDate"}
SORT_ORDER = {"ascending", "descending"}


@dataclass
class Paper:
    """Нормализованная карточка статьи arXiv.

    Attributes:
        arxiv_id: Короткий идентификатор вида `2305.12345` без версии.
        title: Заголовок статьи в одну строку.
        authors: Список имён авторов в порядке публикации.
        summary: Текст абстракта.
        categories: Список тематических категорий arXiv.
        primary_category: Основная категория.
        published: Дата первой публикации в формате ISO 8601.
        updated: Дата последнего обновления в формате ISO 8601.
        pdf_url: Прямая ссылка на PDF.
        abs_url: Ссылка на страницу abstract.
    """

    arxiv_id: str
    title: str
    authors: list[str]
    summary: str
    categories: list[str]
    primary_category: str
    published: str
    updated: str
    pdf_url: str
    abs_url: str


def _text(node: ET.Element | None) -> str:
    """Возвращает очищенный текст узла или пустую строку."""
    if node is None or node.text is None:
        return ""
    return " ".join(node.text.split())


def _short_id(raw_id: str) -> str:
    """Извлекает короткий arXiv ID из полного URL записи без версии."""
    tail = raw_id.rsplit("/abs/", 1)[-1]
    if "v" in tail:
        head, _, ver = tail.rpartition("v")
        if ver.isdigit():
            return head
    return tail


def _parse_entry(entry: ET.Element) -> Paper:
    """Преобразует Atom-элемент `entry` в карточку Paper."""
    raw_id = _text(entry.find(f"{ATOM}id"))
    pdf_url = ""
    abs_url = raw_id
    for link in entry.findall(f"{ATOM}link"):
        if link.get("title") == "pdf":
            pdf_url = link.get("href", "")
        elif link.get("rel") == "alternate":
            abs_url = link.get("href", abs_url)

    primary = entry.find(f"{ARXIV}primary_category")
    primary_category = primary.get("term", "") if primary is not None else ""
    categories = [c.get("term", "") for c in entry.findall(f"{ATOM}category") if c.get("term")]

    authors = [
        _text(a.find(f"{ATOM}name"))
        for a in entry.findall(f"{ATOM}author")
        if _text(a.find(f"{ATOM}name"))
    ]

    if not pdf_url and abs_url:
        pdf_url = abs_url.replace("/abs/", "/pdf/")

    return Paper(
        arxiv_id=_short_id(raw_id),
        title=_text(entry.find(f"{ATOM}title")),
        authors=authors,
        summary=_text(entry.find(f"{ATOM}summary")),
        categories=categories,
        primary_category=primary_category,
        published=_text(entry.find(f"{ATOM}published")),
        updated=_text(entry.find(f"{ATOM}updated")),
        pdf_url=pdf_url,
        abs_url=abs_url,
    )


def search(query: str, max_papers: int, sort_by: str, sort_order: str) -> list[Paper]:
    """Выполняет запрос к arXiv API и возвращает список карточек.

    Args:
        query: Поисковая строка arXiv (поддерживает синтаксис `au:`, `ti:`, `cat:`).
        max_papers: Максимальное число результатов.
        sort_by: Поле сортировки из множества SORT_BY.
        sort_order: Порядок сортировки из множества SORT_ORDER.

    Returns:
        Список Paper в порядке, заданном arXiv.

    Raises:
        SystemExit: Сетевая ошибка или некорректный ответ API.
    """
    params = urllib.parse.urlencode(
        {
            "search_query": query,
            "start": 0,
            "max_results": max_papers,
            "sortBy": sort_by,
            "sortOrder": sort_order,
        }
    )
    url = f"{ARXIV_API}?{params}"
    request = urllib.request.Request(url, headers={"User-Agent": "arxiv-search-skill/1.0"})
    try:
        with urllib.request.urlopen(request, timeout=30, context=_ssl_context()) as response:
            payload = response.read()
    except urllib.error.URLError as exc:  # сеть/таймаут/HTTP
        sys.exit(f"arXiv request failed: {exc}")

    try:
        root = ET.fromstring(payload)
    except ET.ParseError as exc:
        sys.exit(f"arXiv response parse error: {exc}")

    return [_parse_entry(entry) for entry in root.findall(f"{ATOM}entry")]


def _print_jsonl(papers: list[Paper]) -> None:
    """Печатает по одному JSON-объекту на строку (формат `papers_raw.jsonl`)."""
    for paper in papers:
        print(json.dumps(asdict(paper), ensure_ascii=False))


def _print_text(papers: list[Paper]) -> None:
    """Печатает читаемую сводку результатов для человека."""
    if not papers:
        print("No papers found.")
        return
    for index, paper in enumerate(papers, start=1):
        authors = ", ".join(paper.authors[:5])
        if len(paper.authors) > 5:
            authors += " et al."
        print(f"[{index}] {paper.title}")
        print(f"    arXiv:{paper.arxiv_id} | {paper.primary_category} | {paper.published[:10]}")
        print(f"    Authors: {authors}")
        print(f"    PDF: {paper.pdf_url}")
        print(f"    Abstract: {paper.summary[:300]}{'…' if len(paper.summary) > 300 else ''}")
        print()


def main() -> None:
    """Разбирает аргументы CLI и печатает результаты поиска."""
    parser = argparse.ArgumentParser(description="Search arXiv and emit structured results.")
    parser.add_argument("query", help="arXiv search query (supports au:, ti:, cat: prefixes)")
    parser.add_argument("--max-papers", type=int, default=10, help="number of results (default: 10)")
    parser.add_argument("--format", choices=("text", "jsonl", "json"), default="text")
    parser.add_argument("--sort-by", choices=sorted(SORT_BY), default="relevance")
    parser.add_argument("--sort-order", choices=sorted(SORT_ORDER), default="descending")
    args = parser.parse_args()

    if args.max_papers < 1:
        parser.error("--max-papers must be >= 1")

    papers = search(args.query, args.max_papers, args.sort_by, args.sort_order)

    if args.format == "jsonl":
        _print_jsonl(papers)
    elif args.format == "json":
        print(json.dumps([asdict(p) for p in papers], ensure_ascii=False, indent=2))
    else:
        _print_text(papers)


if __name__ == "__main__":
    main()
