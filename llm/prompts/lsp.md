---
name: Explain LSP diagnostics
interaction: chat
description: Explain the LSP diagnostics for the selected code
opts:
  alias: lsp
  auto_submit: true
  is_slash_cmd: true
  modes:
    - v
  stop_context_insertion: true
---

## system

Explain code diagnostics, including warnings and errors.
When useful, suggest fixes with code snippets.
Use fenced code blocks with a language identifier for syntax highlighting.

## user

The programming language is ${context.filetype}. This is a list of the diagnostic messages:

${lsp.diagnostics}
