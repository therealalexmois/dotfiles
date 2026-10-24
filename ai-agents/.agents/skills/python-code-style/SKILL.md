---
name: python-code-style
description: Generic Python conventions - naming, imports, type annotations, enums, data class invariants and Pydantic constrained types, duplication, formatting, vertical spacing, Google-style docstrings, and pytest test-writing rules (test classes, markers, Given/When/Then docstrings, pytest-mock doubles). Use whenever writing, editing, or reviewing Python code, adding or improving docstrings, or writing, modifying, or reviewing Python tests, even if the user does not mention conventions explicitly. Project AGENTS.md/CLAUDE.md and pyproject.toml override these defaults.
metadata:
  version: "1.1"
  origin: first-party
---

# Python Code Style

Project-independent Python conventions.

## Precedence

Follow project-specific conventions in this order:

1. `AGENTS.md`, `CLAUDE.md`, or the project style guide.
2. `pyproject.toml` settings: line length, Python version, lint rules, and type checks.
3. The surrounding code's style.

These sources define documentation language, test markers, and configuration values.
When they conflict with this skill, follow the project.

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

- Separate logical blocks inside functions and methods with one blank line.
- Keep one idea together. Separate guards, computation, logging, and return steps when their intent differs.
- Do not add double blank lines inside a body or a blank line immediately after `def`/the docstring.
- Apply these boundaries by hand. Formatters normalize spacing around definitions,
  but do not insert semantic spacing inside them.

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

- Use the project's `pyproject.toml` for line length, target version, lint rules, and type-checker strictness.
For a new project without configuration, choose strict type checks and a suitable lint rule set.
Record those choices in `pyproject.toml`.

## Docstrings

When editing Python code, improve docstrings without changing runtime behavior.

- Use Google Python Style docstrings.
- Keep section headers in English: `Args`, `Returns`, `Raises`, `Yields`, `Attributes`, `Examples`.
- Write docstring content in the project's documentation language (declared in its `AGENTS.md`/`CLAUDE.md`); match the surrounding code when it is not declared. Do not impose a language the project does not use.
- Add module, class, function, and method docstrings when they are missing or weak.
- Follow the [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html#38-comments-and-docstrings).
- Start with a one-line summary within the line limit, ending with a period.
- Add a blank line and details only for useful contract, constraints, or non-obvious behavior.
- Do not restate names, signatures, or obvious implementation details.
  Recheck a docstring longer than its code for unnecessary text.
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

- Group tests into `Test<Subject>` classes, one class per unit, behavior, or command.
- Do not use module-level test functions.
- Use plain methods with `self`, without `@staticmethod`.
- Keep classes stateless. Fixtures and helpers remain functions.
- Give each pytest module one test type. Declare it once as `pytestmark = pytest.mark.<type>`.
- Split modules that mix test types.
- Follow the marker policy in `pytest.ini`, `pyproject.toml`, or `AGENTS.md`.
  Common types are `unit`, `integration`, `system`, and `scenario`.
- Use the lightest applicable type. Do not repeat the module marker on classes or tests.

### Docstrings

For each test module, write:

1. A one-line summary.
2. An unnumbered list of checks, one short line per check or per class for large modules.

For each test, write:

1. A one-line scenario summary.
2. A blank line.
3. Three short lines: `Given:`, `When:`, and `Then:`, translated into the project's language.

`Given` names important input conditions. `When` names the action.
`Then` names the observable result.
Mark error paths or regressions (`Regression: #123`) in the summary or `Then`.
Do not repeat the test name or describe implementation steps.

```python
"""Bond limit checks for a single issuer.

- rejects a purchase above the issuer cap;
- allows a purchase exactly at the cap.
"""

pytestmark = pytest.mark.unit


class TestIssuerLimit:
    def test_check__rejects_purchase_over_cap(self) -> None:
        """Purchase above the issuer cap is rejected.

        Given: cap 100 000, current position 90 000.
        When: a purchase of 20 000 is checked.
        Then: LimitExceededError is raised and the position is unchanged.
        """
```

### Assertions

- Assert behavior, not snapshots.
Full rendered text, JSON, dict, or golden-file comparisons are snapshots unless the exact output is a published contract.
Keep one contract test per published schema. Elsewhere, assert relevant properties only.

Avoid:

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

- Avoid fixtures when the object appears in one test, setup takes 1-3 clear lines,
or the fixture hides important input conditions.

- Name the returned object, not the action. Avoid `data`, `obj`, `payload`, `result`, and `mocked`.
- Use the smallest scope. Wider scopes must not leak state between tests.
- Use `yield` only for real cleanup.

### Test doubles

Do not use mocks, stubs, or fakes if the same scenario can be tested more simply with a real typed object. Preference order:

1. real typed object;
2. real object built through a small helper or fixture;
3. `mocker.Mock` / `mocker.AsyncMock` with `spec` (or `mocker.create_autospec`);
4. `mocker.spy` when interaction with real code must be observed;
5. handwritten `stub` / `fake` only when it is clearly the best option.

- Create doubles through pytest-mock's `mocker` fixture:
`mocker.patch`, `mocker.patch.object`, `mocker.Mock`, and `mocker.spy`.

- Do not import `unittest.mock` in tests.
- Use `spec`/`spec_set` or `autospec=True` to catch renamed methods and wrong signatures.
- Use `MagicMock` only for magic-method support.
- Observe real calls with `mocker.spy`, not `patch(..., wraps=...)`.
- Use `Mock`/`AsyncMock` for external dependencies, controlled results or errors, and meaningful interactions.
- Avoid long mock chains and assertions about irrelevant internal calls.
- Use handwritten fakes only when reused, stateful, clearer than mocks,
  faithful to the dependency contract, and better for readability and typing.

### Async tests

Test async contracts with `async def`. Avoid unnecessary sync wrappers.
Cover relevant `await`, context managers, iterators, shutdown, cleanup, and errors.
Use `AsyncMock` only when a mock is needed.

### Parameterization

Use `@pytest.mark.parametrize` with readable `ids` when:

- the scenario stays the same;
- only inputs and expected outputs differ;
- it reduces duplication without hurting readability.

Keep conceptually different or harder-to-read scenarios separate.

### Typing in tests

Prefer real typed objects where production code already defines types. Avoid untyped dictionaries when a DTO, schema, settings object, or domain model exists. Avoid `Any` and `cast` unless necessary and localized.

### Logs, metrics, observability

- Assert logs or metrics only when they are part of the expected behavior or required to
  diagnose a meaningful scenario.
- Use `caplog` for standard logging when appropriate; if `caplog` is flaky due to logging
  adapters, prefer a patched logger or spy.
- Do not turn business logic tests into tests of telemetry internals.

### Production defect vs test defect

- If a test reveals a production bug, state that explicitly.
- Separate: test defect, production defect, missing context, mismatch with requirements,
  mismatch with styleguide.
- If production code violates the contract, suggest the minimal correction direction without
  rewriting the module.
