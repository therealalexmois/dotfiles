---
name: python-code-style
description: Generic Python conventions - naming, imports, type annotations, enums, data class invariants and Pydantic constrained types, duplication, formatting, vertical spacing, comments, control flow, common idioms, Google-style docstrings, and pytest test-writing rules. Use whenever writing, editing, or reviewing Python code, adding or improving docstrings, or writing, modifying, or reviewing Python tests, even if the user does not mention conventions explicitly. Do not use for architecture, packaging, configuration, resilience, or async design, which have focused python-* skills. Project AGENTS.md/CLAUDE.md and pyproject.toml override these defaults.
metadata:
  version: "2.1"
  origin: first-party
---

# Python Code Style

Generic, project-independent defaults for writing Python. The goal is code that reads like prose and stays maintainable across projects.

Apply these rules to the code you write or change. Do not restyle untouched code unless the user asks for it.

## Precedence

Follow project-specific conventions in this order:

1. The project's `AGENTS.md` / `CLAUDE.md` / styleguide (conventions, documentation language, test marker policy).
2. The project's `pyproject.toml` (line length, target version, lint rule selection, type-checker strictness).
3. The existing style of the surrounding code, except for vertical spacing (see "Vertical spacing").

So this skill carries the principles and default tool choices, and the project supplies config values and the documentation language. When a project file and this skill disagree, follow the project.

## When to use

- Writing or editing Python code.
- Reviewing code for style consistency.
- Writing or improving docstrings.
- Writing, modifying, or reviewing pytest tests.
- Setting up or configuring linting, formatting, and type checking.

## When not to use

Use the focused skill instead:

| Task | Skill |
| --- | --- |
| Layering, abstractions, composition | `python-design-patterns` |
| Module layout, public API, `__all__` | `python-project-structure` |
| Generics, protocols, strict type-checker setup | `python-type-safety` |
| Exception hierarchies, validation, partial failures | `python-error-handling` |
| Retries, backoff, timeouts | `python-resilience` |
| Context managers, cleanup, streaming | `python-resource-management` |
| Logging, metrics, and tracing design | `python-observability` |
| Settings and environment variables | `python-configuration` |
| Packaging and publishing | `python-packaging` |
| Profiling and optimization | `python-performance-optimization` |
| asyncio architecture and concurrency | `async-python-patterns` |
| Anti-pattern checklist for a review | `python-anti-patterns` |
| Test-first development | `test-driven-development` |

Two more skills run only on explicit request: `python-patterns` (worked examples of idioms) and `python-testing-patterns` (broad testing strategy).

## Naming

Follow PEP 8 with clarity over brevity.

- Modules and files: descriptive `snake_case` (`user_repository.py`, not `usr_repo.py`).
- Classes: `PascalCase`; keep acronyms uppercase (`HTTPClientFactory`).
- Functions and variables: `snake_case`.
- Module-level constants: `SCREAMING_SNAKE_CASE`.
- Internal names: a leading underscore (`_parse_row`).
- Booleans: a predicate form (`is_active`, `has_access`, `should_retry`).
- Exceptions: the `Error` suffix (`PaymentError`).
- Quantities: the unit in the name when the type does not carry it (`timeout_seconds`, `size_bytes`).

Prefer a slightly longer descriptive name over an abbreviation a reader has to decode.

## Imports

Group in a consistent order with a blank line between groups: standard library, third-party, local.

```python
import os
from collections.abc import Callable
from typing import Any

import httpx
from pydantic import BaseModel

from myproject.models import User
from myproject.services import UserService
```

Use absolute imports by default. If the package already uses explicit relative imports (`from .utils import x`), follow it. Do not use wildcard imports.

## Type annotations

Use modern, precise syntax: `str | None`, `list[str]`, `dict[str, Any]`, `tuple[str, ...]`.

- Check the project's `requires-python` first. `X | None` needs Python 3.10 at runtime. If the project supports an older version, use `Optional[X]` unless the module has `from __future__ import annotations` and nothing evaluates its annotations at runtime (Pydantic does).
- Annotate parameters and return types of code you add and of public APIs you change.
- Accept the narrowest abstract type the function needs (`Iterable[str]`, `Sequence[str]`, `Mapping[str, int]` from `collections.abc`). Return a concrete type (`list[str]`).
- Avoid bare collection annotations when the element type is known.
- Avoid `Any` and `cast` unless they are necessary and localized.
- Put an import used only in annotations under `if TYPE_CHECKING:` when it breaks an import cycle and nothing evaluates the annotation at runtime.
- In existing code, add or change annotations only when the type is obvious and the change is safe, or when explicitly requested. Do not change runtime behavior for the sake of typing.

## Enums, data classes, and models

- Decorate every `Enum` subclass (including `StrEnum`, `IntEnum`, `Flag`) with `@enum.unique`. An intentional alias is the rare exception and needs a comment.
- A data class that carries domain meaning enforces its invariants in `__post_init__` and raises a precise error: amounts that cannot be negative, non-empty identifiers, ordered date ranges, values from a closed set. Derive each invariant from how the data is produced, not from wishful thinking: a quantity that can be negative (a short position) gets no "positive" check. Plain transport records without rules need no checks.
- Pydantic fields use the built-in constrained types instead of bare primitives plus manual validators: `PositiveInt`, `NonNegativeInt`, `PositiveFloat`, `NonNegativeFloat`, `conint`/`Field(gt=..., le=...)`, `constr`/`Field(min_length=...)`, `AnyUrl`/`HttpUrl`, `SecretStr`, `FilePath`/`DirectoryPath`. Tightening a field of a public schema changes its contract, so treat it as an API change.
- Every invariant and every constrained field has a test for the rejected value at the boundary.

## Duplication

- Keep each concept in one module. Avoid duplicate helpers, constants, mappings, and calculations.
- Search before adding a helper.
- If two copies exist, keep the lower-layer copy and import it.
- Keep one module's responsibility together.
- Move repeated test helpers to the nearest shared `conftest.py` or test support module.

## Formatting and line length

Let the formatter settle whitespace debates; spend judgment on readability the formatter cannot reach.

Follow the project's configured line length (commonly 88 or 120). Within that budget, break lines for readability:

```python
# Trailing-comma argument lists wrap cleanly
def create_user(
    email: str,
    name: str,
    role: UserRole = UserRole.MEMBER,
    notify: bool = True,
) -> User:
    ...

# Chained calls: one step per line
result = (
    db.query(User)
    .filter(User.active.is_(True))
    .order_by(User.created_at.desc())
    .limit(10)
    .all()
)

# Long strings: implicit concatenation across lines
error_message = (
    f"Failed to process user {user_id}: "
    f"received status {response.status_code}"
)
```

## Vertical spacing (logical paragraphs)

Write every function, method, test, and script body as paragraphs: groups of consecutive statements that perform one step, separated by one blank line. A wall of statements forces the reader to parse every line to find where one step ends and the next begins.

Apply these rules by hand. `ruff format` never inserts a blank line inside a body, and no linter requires one.

**Scope**

- Write new functions in paragraphs even when the surrounding code is packed wall-to-wall. Dense neighbors are not a style to match. Only an explicit project rule overrides this section.
- If you rewrite most of a function, put the whole function in paragraphs.
- If you only patch a function, apply the rules to the changed statements and the statement directly before and after them. Leave the rest as is.
- Do not reformat functions the task does not touch.
- In a review, report packed code only on changed lines.

**Add one blank line**

If a rule here and a "Keep together" case both apply, this list wins.

1. Before `if`, `for`, `while`, `with`, `try`, or `match` when statements precede it at the same level.
2. After a compound statement ends when code follows at the same level. Consecutive guard clauses therefore stand apart.
3. Before the final `return`, `raise`, or `yield` of a function, unless "Keep together" covers the whole body.
4. Between simple statements when the purpose changes, for example from validating to computing or from computing to persisting. Decide with the naming test in "Check". If still unsure, add no blank line.
5. Before a comment that introduces a paragraph. Keep the comment attached to the code below it.
6. Between arrange, act, and assert in a test, even in a three-statement test.

**Keep together, no blank line**

- A simple statement and the simple statement that consumes its result for the same step (`result = fetch()` then `log_if_error(result)`).
- Runs of the same shape: related assignments, repeated `parser.add_argument(...)` calls.
- The body of a short branch: a log call and the `return` that follows it inside an `if`.
- A body of up to three simple statements that form one step.

**Never**

- Put a blank line right after a line that opens a block (`def`, `if`, `for`, `with`, `try`) or after a function docstring. Do not rely on `ruff format`: it leaves the blank line after `def` and after a docstring.
- Put a blank line before `elif`, `else`, `except`, or `finally`. Do not rely on `ruff format`: it leaves this blank line too.
- Put two blank lines in a row inside a body.
- Put a blank line inside a multi-line call, literal, or comprehension.
- Separate every statement. If every paragraph is one line, you split by line instead of by step: regroup.

**Check**

Before finishing, reread each function you wrote or changed:

1. Confirm rules 1-3 hold for every compound statement and final `return`.
2. Name each paragraph in two to four words. If a name needs "and", split the paragraph. If two neighbors share a name, merge them.
3. Confirm none of the "Never" cases appear.

If a paragraph needs a header comment to be understood, the function may do too much. Extract it when the task allows it; otherwise mention it in your report instead of expanding the scope.

```python
# Avoid: statements packed wall-to-wall - hard to scan
def resolve(self, key: str) -> Value:
    status = self._status()
    if status is not Status.READY:
        self._log_not_ready(key)
        return self._default(key)
    result = self._client.get(key)
    self._log_if_error(result)
    return result.value

# Good: blank lines mark paragraphs of intent
def resolve(self, key: str) -> Value:
    status = self._status()

    if status is not Status.READY:  # not warmed up yet -> code default
        self._log_not_ready(key)
        return self._default(key)

    result = self._client.get(key)
    self._log_if_error(result)

    return result.value

# Good: each step is a paragraph, and a one-idea run stays together
def export_orders(client: Client, path: Path, since: date) -> int:
    orders = client.fetch_orders(since=since)

    if not orders:
        logger.info("no orders since %s", since)
        return 0

    rows = [order.to_row() for order in orders]
    rows.sort()

    # Write to a temp file first so a crash never leaves a partial export.
    tmp_path = path.with_suffix(".tmp")

    with tmp_path.open("w") as output:
        csv.writer(output).writerows(rows)

    tmp_path.replace(path)

    return len(rows)

# Good: arrange, act, assert
def test_export_orders__returns_row_count(tmp_path: Path) -> None:
    client = FakeClient(orders=[make_order(), make_order()])
    target = tmp_path / "orders.csv"

    exported = export_orders(client, target, since=date(2026, 1, 1))

    assert exported == 2
    assert target.exists()

# Avoid: a blank line after every statement is noise, not paragraphs
def load_endpoint(settings: Settings) -> Endpoint:
    host = settings.host

    port = settings.port

    return Endpoint(host, port)

# Good: three simple statements, one step
def load_endpoint(settings: Settings) -> Endpoint:
    host = settings.host
    port = settings.port
    return Endpoint(host, port)
```

## Comments

- Explain why: a constraint, a workaround, a non-obvious decision. Do not restate what the code does.
- Update or delete a comment when you change the code it describes.
- Do not leave commented-out code. Version control keeps it.
- Link a `TODO` to a ticket or state its condition.

## Control flow

Apply these to code you write. In a patch, do not restructure existing code for them; mention the problem in your report instead.

- Handle invalid and edge cases first with guard clauses, then write the main path without `else`.
- Keep nesting to three levels inside a function body. Past that, invert a condition or extract a function.
- Write a comprehension for one loop with at most one condition. Otherwise write a plain loop.

## Idioms

- Compare with `is None` and `is not None`. Do not compare with `== True`.
- Do not use a mutable default argument. Default to `None` and create the object in the body.
- Use `pathlib.Path` for paths in new code.
- Use `Enum` or `Literal` instead of magic strings for a closed set of values.
- Use `dataclass` or a Pydantic model instead of a dict with a fixed set of keys.
- Open resources with `with`.
- Catch the narrowest exception you can handle. Do not write a bare `except:`.
- Use `raise NewError(...) from error` when translating an exception.
- Pass log arguments lazily: `logger.info("user %s", user_id)`, not an f-string.

## Tooling

The default tools are `ruff` as linter and formatter (it replaces flake8, isort, black) and a type checker (`mypy` or `pyright`).

1. Find how the project runs its checks: `AGENTS.md`/`CLAUDE.md`, `Makefile` or task runner, CI config, `pyproject.toml`.
2. Run those checks through the project's runner (`uv run`, `poetry run`). If the project has a lint task, use it.
3. If you run the tools directly, limit them to the Python files you changed:

```bash
uv run ruff check --fix path/to/changed.py
uv run ruff format path/to/changed.py
uv run mypy path/to/changed.py
```

- Do not run `ruff format .` or `ruff check --fix .` in an existing project: they rewrite files outside the task.
- If a check fails on lines you did not change, report it and leave those lines alone.
- If a tool is not available, report the check as skipped. Do not add a tool or a dependency to the project without a request.

Concrete configuration (line length, target version, the selected lint rule set, type-checker strictness) lives in the project's `pyproject.toml`. If the user asks to set up a new project with no config, enable strict type checking and record the rule set in `pyproject.toml` so it becomes project-owned.

## Docstrings

Add or update docstrings for code you add and for code whose contract you change. Improve other docstrings only when the user asks. Do not change runtime behavior while editing a docstring.

- Use Google Python Style docstrings.
- Keep section headers in English: `Args`, `Returns`, `Raises`, `Yields`, `Attributes`, `Examples`.
- Write docstring content in the project's documentation language (declared in its `AGENTS.md`/`CLAUDE.md`); match the surrounding code when it is not declared. Do not impose a language the project does not use.
- Within that scope, add module, class, function, and method docstrings when they are missing or weak.
- Follow the [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html#38-comments-and-docstrings).
- Start with a one-line summary within the line limit, ending with a period.
- Add a blank line and details only for useful contract, constraints, or non-obvious behavior.
- Keep docstrings concise: explain purpose, contract, important constraints, and non-obvious behavior. Do not restate the name, signature, or obvious implementation details. Recheck a docstring longer than its code for unnecessary text.
- Add `Attributes` for dataclasses, Pydantic models, DTOs, and classes with meaningful public fields.
- Add `Args`, `Returns`, and `Raises` only when they add useful information. Do not document exceptions that are not visible from the code or an explicit contract.
- Preserve technical identifiers, API names, field names, enum values, and established project terms.
- When writing in a non-English language, do not create hybrids with foreign endings; use a native generic word plus the identifier (for example `компонент Router`, `сервис builder`).

**Simple function:**

```python
def get_user(user_id: str) -> User:
    """Return the user with the given identifier."""
    ...
```

**Complex function:**

```python
def process_batch(
    items: list[Item],
    max_workers: int = 4,
    on_progress: Callable[[int, int], None] | None = None,
) -> BatchResult:
    """Process items concurrently using a worker pool.

    Args:
        items: The items to process. Must not be empty.
        max_workers: Maximum concurrent workers.
        on_progress: Optional callback receiving (completed, total) counts.

    Returns:
        BatchResult with succeeded items and any failures with their exceptions.

    Raises:
        ValueError: If items is empty.
    """
    ...
```

## Tests

Do not write or modify tests unless the user explicitly asks for test-writing help or the requested implementation requires tests as part of the task.

Before writing, modifying, or reviewing tests, read [references/testing.md](references/testing.md).

## Final check

Before finishing a code change:

1. Confirm the diff contains only lines the task needs, with no restyled neighbors.
2. Run the "Check" steps of "Vertical spacing" on each function you wrote or changed.
3. Run the project's checks as described in "Tooling". Report each one as passed, failed, or skipped.

When reviewing code, report each finding as `file:line`, the rule, and the fix, most severe first. Limit findings to changed lines. If nothing violates these rules, say so.
