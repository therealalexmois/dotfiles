---
name: arxiv-search
disable-model-invocation: true
description: Search arXiv by keywords and return structured results (text, JSON, or JSONL). Use when the user asks to "search arXiv", "find papers about <topic>", "latest preprints on <topic>", monitor fresh LLM/agent research, or needs a structured paper list to feed into a note-building pipeline. Pairs with arxiv-doc-builder for converting a chosen paper into a markdown note.
metadata:
  version: "1.0"
---

# arXiv Search

Search the public arXiv API and emit structured results. Built for the
`terminal → research → markdown note` workflow: use this skill to discover papers,
then hand a chosen `arxiv_id` to the `arxiv-doc-builder` skill to produce a note.

The bundled script uses only the Python standard library (no `pip install` needed).

## When to use

- "Search arXiv for retrieval augmented generation"
- "Find the latest preprints on LLM agents"
- "Give me 5 recent papers about diffusion models as JSON"
- Building a research pipeline that needs a machine-readable paper list

## Usage

Run the bundled script. It accepts a query plus optional flags:

```bash
python .claude/skills/arxiv-search/scripts/arxiv_search.py "QUERY" --max-papers N
```

Flags:

- `--max-papers N` — number of results (default: 10)
- `--format text|json|jsonl` — output shape (default: `text`)
- `--sort-by relevance|submittedDate|lastUpdatedDate` — default: `relevance`
- `--sort-order ascending|descending` — default: `descending`

The query supports arXiv field prefixes: `au:` (author), `ti:` (title),
`abs:` (abstract), `cat:` (category), combined with `AND`/`OR`.

### Examples

Human-readable summary:

```bash
python .claude/skills/arxiv-search/scripts/arxiv_search.py "agentic llm" --max-papers 5
```

Structured JSONL for a pipeline (one paper per line, like `papers_raw.jsonl`):

```bash
python .claude/skills/arxiv-search/scripts/arxiv_search.py \
  "cat:cs.CL AND abs:retrieval augmented generation" \
  --max-papers 20 --sort-by submittedDate --format jsonl > papers_raw.jsonl
```

Each JSON record contains: `arxiv_id`, `title`, `authors`, `summary`,
`categories`, `primary_category`, `published`, `updated`, `pdf_url`, `abs_url`.

## Workflow

1. Run the search with the user's topic and desired count.
2. Present the results (titles, authors, dates, abstracts).
3. If the user picks a paper, pass its `arxiv_id` to `arxiv-doc-builder` to create
   a markdown note.

## Notes

- The arXiv API is public and rate-limited; keep `--max-papers` reasonable.
- `relevance` sorting is best for topic search; `submittedDate` for fresh preprints.

## Resources

### scripts/

- `arxiv_search.py` — stdlib-only arXiv API client with text/JSON/JSONL output.
