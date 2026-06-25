---
name: python-code-style
description: Generic Python conventions - naming, imports, type annotations, formatting, vertical spacing, Google-style docstrings, and pytest test-writing rules. Use whenever writing, editing, or reviewing Python code, adding or improving docstrings, or writing, modifying, or reviewing Python tests, even if the user does not mention conventions explicitly. Project AGENTS.md/CLAUDE.md and pyproject.toml override these defaults.
---

# Python Code Style

Generic, language-agnostic defaults for writing Python. The goal is code that reads like prose and stays maintainable across projects.

## Precedence

These are project-independent defaults. Anything project-specific wins over them, in this order:

1. The project's `AGENTS.md` / `CLAUDE.md` / styleguide (conventions, documentation language, test marker policy).
2. The project's `pyproject.toml` (line length, target version, lint rule selection, type-checker strictness).
3. The existing style of the surrounding code.

So this skill never hardcodes concrete config values or a fixed documentation language - it carries the principles, and the project supplies the specifics. When a project file and this skill disagree, follow the project.

## When to use

- Writing or editing Python code.
- Reviewing code for style consistency.
- Writing or improving docstrings.
- Writing, modifying, or reviewing pytest tests.
- Setting up or configuring linting, formatting, and type checking.

## Naming

Follow PEP 8 with clarity over brevity.

- Modules and files: descriptive `snake_case` (`user_repository.py`, not `usr_repo.py`).
- Classes: `PascalCase`; keep acronyms uppercase (`HTTPClientFactory`).
- Functions and variables: `snake_case`.
- Module-level constants: `SCREAMING_SNAKE_CASE`.

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

Use absolute imports; avoid relative imports (`from ..utils import x`) - they are harder to move and read.

## Type annotations

Use modern, precise syntax: `str | None`, `list[str]`, `dict[str, Any]`, `tuple[str, ...]`.

- Annotate public APIs (parameters and return types).
- Avoid bare collection annotations when the element type is known.
- Avoid `Any` and `cast` unless they are necessary and localized.
- Add or change annotations only when the type is obvious and the change is safe, or when explicitly requested - do not change runtime behavior for the sake of typing.

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

Inside a function or method body, separate logical blocks with a single blank line. Read code like prose: a wall of statements packed line-to-line forces the reader to parse every line to find where one idea ends and the next begins. Blank lines turn a body into paragraphs of intent - setup, the core step, the result - so the structure is visible at a glance.

Formatters normalize blank lines *around* functions and classes, but they do not insert semantic blank lines *inside* a body. This is a judgment call you make by hand.

Group by intent, not by line count: a tight block that forms one idea stays together; a blank line goes between distinct steps (guard checks, the main computation, logging, the return). Avoid double blank lines inside a body and a blank line right after the `def`/docstring - one separator between ideas is enough.

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
```

## Tooling

Use `ruff` as the all-in-one linter and formatter (it replaces flake8, isort, black) and a type checker (`mypy` or `pyright`).

```bash
ruff check --fix .   # lint and auto-fix
ruff format .        # format
mypy .               # type check
```

Concrete configuration - line length, target version, the selected lint rule set, type-checker strictness - lives in the project's `pyproject.toml`, not here. Follow the project's values. For a new project with no config, enable strict type checking and a sensible rule set, then record the choice in `pyproject.toml` so it becomes project-owned.

## Docstrings

When editing Python code, improve docstrings without changing runtime behavior.

- Use Google Python Style docstrings.
- Keep section headers in English: `Args`, `Returns`, `Raises`, `Yields`, `Attributes`, `Examples`.
- Write docstring content in the project's documentation language (declared in its `AGENTS.md`/`CLAUDE.md`); match the surrounding code when it is not declared. Do not impose a language the project does not use.
- Add module, class, function, and method docstrings when they are missing or weak.
- Keep docstrings concise: explain purpose, contract, important constraints, and non-obvious behavior. Do not restate the name or obvious implementation details.
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

## Test writing

Use these rules when writing, modifying, or reviewing tests. Do not write or modify tests unless the user explicitly asks for test-writing help or the requested implementation requires tests as part of the task.

### Principles

A test must verify observable behavior, not incidental implementation details. A good test:

- fixes a real contract;
- is isolated and reproducible;
- covers one scenario or one clear behavior branch;
- uses meaningful assertions only;
- makes important input conditions visible;
- does not mask production defects;
- does not add unnecessary test-layer complexity;
- can be understood on review without opening many helper layers.

First inspect the real source code and existing test style. Use real imports, real types, and real signatures.

### Structure

Prefer clear test names; follow the existing project style if it differs:

```python
test_<what_is_tested>__<expected_behavior>
```

For pytest projects, use markers as an organization rule and follow the project's marker policy (the set of allowed markers and what they mean is project-specific - see the project's `pyproject.toml`/`AGENTS.md`). Do not mark a test as heavier than necessary.

### Docstrings

Every test module has a module docstring. Every test has a docstring unless the project styleguide says otherwise. A test docstring should describe input conditions, the key action, the expected observable result, and whether it is an error path or regression case. Do not repeat the test name verbatim or describe the implementation line by line.

### Assertions

Assertions must verify the contract. Avoid:

- checking everything blindly;
- overfitting to unstable strings, timestamps, random order, or internal call chains;
- magic numbers that reduce readability (extract a named constant instead);
- full-structure assertions when only a meaningful subset is part of the contract.

For error tests, assert the error type; assert the message only if it is part of the user-facing or integration contract.

### Fixtures

Use fixtures only when they make the test clearer or reduce meaningful duplication. Preference order:

1. explicit inline setup;
2. local helper function;
3. local fixture in the test module;
4. local `conftest.py` fixture for neighboring modules;
5. shared `conftest.py` fixture only for stable, genuinely shared setup.

Do not introduce a fixture when the object is used in one test, setup is 1-3 clear lines, or it hides key scenario conditions. Fixture names describe the returned object, not the action - avoid vague names like `data`, `obj`, `payload`, `result`, `mocked`. Use the smallest necessary scope; a wider scope that leaks state between tests is a defect. Use a `yield` fixture only when there is real cleanup to run.

### Test doubles

Do not use mocks, stubs, or fakes if the same scenario can be tested more simply with a real typed object. Preference order:

1. real typed object;
2. real object built through a small helper or fixture;
3. `mocker.Mock` / `mocker.AsyncMock`;
4. `spy` when interaction with real code must be observed;
5. handwritten `stub` / `fake` only when it is clearly the best option.

Use `Mock` / `AsyncMock` when replacing an external dependency, controlling `return_value`/`side_effect`, or verifying a meaningful interaction. Avoid long fragile mock chains, asserting every internal call, and mock assertions that do not affect the tested contract. Handwritten fakes are allowed only when they are reused, naturally hold state, represent the dependency contract better than mocks, and improve readability and typing.

### Async tests

Use `async def` where appropriate and test the async contract directly; avoid unnecessary sync wrappers. Cover relevant lifecycle behavior: `await`, async context managers, async iterators, shutdown, cleanup, and error paths. Use `AsyncMock` only when a mock is actually needed.

### Parameterization

Use `@pytest.mark.parametrize` when the scenario is the same and only inputs and expected outputs differ, and duplication is reduced without hurting readability. Do not parameterize when cases are conceptually different or the scenario becomes harder to understand.

### Typing in tests

Prefer real typed objects where production code already defines types. Avoid untyped dictionaries when a DTO, schema, settings object, or domain model exists. Avoid `Any` and `cast` unless necessary and localized.

### Logs, metrics, observability

Assert logs or metrics only when they are part of the expected behavior or required to diagnose a meaningful scenario. Use `caplog` for standard logging when appropriate; if `caplog` is flaky due to logging adapters, prefer a patched logger or spy. Do not turn business logic tests into tests of telemetry internals.

### Production defect vs test defect

If a test reveals a production bug, state that explicitly. Separate: test defect, production defect, missing context, mismatch with requirements, mismatch with styleguide. If production code violates the contract, suggest the minimal correction direction without rewriting the module.
