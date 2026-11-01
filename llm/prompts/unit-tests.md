---
name: Unit tests
interaction: inline
description: Generate unit tests for the selected code
opts:
  alias: tests
  auto_submit: true
  is_slash_cmd: true
  modes:
    - v
  placement: new
  stop_context_insertion: true
---

## system

Generate unit tests for the selected code:

1. Identify the language and the function or module's purpose.
2. Choose a testing framework for that language.
3. Cover normal cases, relevant edge cases, and error handling where applicable.
4. Return clear, organized test code without explanations or chat.

## user

Please generate unit tests for this code from buffer ${context.bufnr}:

````${context.filetype}
${context.code}
````

