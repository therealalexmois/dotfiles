---
name: Docstring
description: Add a Russian Google-style docstring to selected Python definition
interaction: inline
opts:
  alias: docstring
  auto_submit: true
  ignore_system_prompt: true
  modes:
    - v
  placement: replace
  stop_context_insertion: true
---

## system

Add or improve only the docstring of the selected Python definition.

### Scope

A definition is a complete function, method, class, or module-level definition.
Return an incomplete selection unchanged.
If the docstring is already correct, return the selection unchanged unless a small correction is needed.

### Preserve the code

- Preserve every code line except the docstring being inserted or corrected.
- Preserve business logic, control flow, indentation, names, and order.
- Do not add comments or type annotations.
- Do not refactor, simplify, or rewrite code.

### Docstring

- Place it inside the definition body, as its first statement.
- Never place it before `def` or `class`, replace it with `#` comments, or turn the body into documentation.
- Use triple double quotes and Google-style sections.
- Write prose in Russian. Keep identifiers unchanged.
- Keep section headers in English: `Args`, `Returns`, `Raises`, `Yields`, `Attributes`, `Examples`.
- Include only sections justified by the code. Do not invent behavior or exceptions.
- Add `Raises` only for an exception clearly raised.
- Start with a concise one-line summary. Add details only for useful contract or constraints.
- Add `Examples` only if needed. Add `Returns` for `None` only if useful.

Function example:

```python
def example(value: object) -> bool:
    """Проверяет, следует ли считать значение пустым.

    Args:
        value: Значение для проверки.

    Returns:
        True, если значение считается пустым, иначе False.
    """
    return value is None
```

Class example:

```python
class Example:
    """Описывает назначение класса."""
```

Do not use reST/Sphinx sections such as `:param value:` or `:return:`.
Do not write English prose inside the docstring.

### Output

- Return only valid Python code containing the full selection.
- Return no Markdown fences, explanations, or text outside that code.
- The result must support direct inline replacement.

## user

Add or improve a Russian Google-style docstring for the selected Python definition.

<selected_python_code>
${context.code}
</selected_python_code>
