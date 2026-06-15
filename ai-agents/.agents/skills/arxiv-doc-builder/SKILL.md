---
name: arxiv-doc-builder
disable-model-invocation: true
description: Convert a single arXiv paper into a markdown reference note with YAML frontmatter, abstract, and links. Use when the user gives an arXiv ID or URL and asks to "make a note", "save this paper as markdown", "add to my notes", or wants a reference document for an arXiv paper. Pairs with arxiv-search, which finds the paper to convert.
metadata:
  version: "1.0"
---

# arXiv Doc Builder

Turn one arXiv paper into a markdown note. Given an arXiv ID or URL, the bundled
script fetches metadata from the public arXiv API and builds a reference document
with YAML frontmatter, the abstract, authors, categories, and links.

This is a lightweight metadata-to-note converter: it does not download the PDF or
parse full text. Pair it with `arxiv-search` to discover the paper first.

The bundled script uses only the Python standard library (no `pip install` needed).

## When to use

- "Make a note from arxiv.org/abs/2305.12345"
- "Save this paper as markdown: 2305.12345"
- "Add this arXiv paper to my notes"
- Converting a paper chosen from `arxiv-search` results into a note

## Usage

```bash
python .claude/skills/arxiv-doc-builder/scripts/arxiv_doc_builder.py ARXIV_ID
```

The argument accepts any of: `2305.12345`, `2305.12345v2`, `arXiv:2305.12345`,
`https://arxiv.org/abs/2305.12345`, or a `/pdf/` URL.

Write directly to a file with `--out`:

```bash
python .claude/skills/arxiv-doc-builder/scripts/arxiv_doc_builder.py 2305.12345 \
  --out "Notes/arxiv/2305.12345.md"
```

Without `--out`, the note is printed to stdout so you can review or redirect it.

## Output

The generated note contains:

- YAML frontmatter: `title`, `arxiv_id`, `authors`, `primary_category`,
  `categories`, `published`, `updated`, `url`, `pdf`, and `doi` when present.
- An `# Abstract` section.
- A `## Notes` section with an empty bullet for your own annotations.

## Workflow

1. Get an arXiv ID — directly from the user or from `arxiv-search` results.
2. Run the script (use `--out` to save into the user's notes directory).
3. Offer to read the PDF or add annotations; for full-text reading, use a
   PDF-to-markdown skill on the `pdf` URL.

## Notes

- Naming convention for saved notes: use the `arxiv_id` (e.g. `2305.12345.md`) or
  `Author_Year_Title.md` if the user prefers descriptive filenames.
- The arXiv API is public and rate-limited; this skill makes one request per paper.

## Resources

### scripts/

- `arxiv_doc_builder.py` — stdlib-only arXiv metadata fetch + markdown note builder.
