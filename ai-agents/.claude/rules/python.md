---
paths:
  - "**/*.py"
---

When writing or editing Python code, docstrings, or tests, invoke the user-level `python-code-style` skill first, unless its content is already loaded in this session. It is the single source of truth for code style (naming, imports, formatting, vertical spacing), Google-style docstrings, and test-writing rules. Linters do not enforce vertical spacing (blank lines between logical blocks inside a function body), so apply it by hand.
