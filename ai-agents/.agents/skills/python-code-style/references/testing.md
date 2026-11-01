# Test writing

## Principles

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

## Structure

Prefer clear test names; follow the existing project style if it differs:

```python
test_<what_is_tested>__<expected_behavior>
```

Separate arrange, act, and assert with one blank line each (see "Vertical spacing" in `SKILL.md`).

- Group tests into `Test<Subject>` classes, one class per unit, behavior, or command.
- Do not use module-level test functions.
- Use plain methods with `self`, without `@staticmethod`.
- Keep classes stateless. Fixtures and helpers remain functions.
- Give each pytest module one test type. Declare it once as `pytestmark = pytest.mark.<type>`.
- Split modules that mix test types.
- Follow the marker policy in `pytest.ini`, `pyproject.toml`, or `AGENTS.md`.
  Common types are `unit`, `integration`, `system`, and `scenario`.
- Use the lightest applicable type. Do not repeat the module marker on classes or tests.

## Docstrings

Every test module has a module docstring. For test functions, follow the project styleguide, then the neighboring tests. If both are silent, add a docstring when the test name does not state the input conditions and the expected result.

When you write a docstring, use this format:

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

## Assertions

- Assert behavior, not snapshots.
Full rendered text, JSON, dict, or golden-file comparisons are snapshots unless the exact output is a published contract.
Keep one contract test per published schema. Elsewhere, assert relevant properties only.

Avoid:

- checking everything blindly;
- overfitting to unstable strings, timestamps, random order, or internal call chains;
- magic numbers that reduce readability (extract a named constant instead);
- full-structure assertions when only a meaningful subset is part of the contract.

For error tests, assert the error type; assert the message only if it is part of the user-facing or integration contract.

## Fixtures

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

## Test doubles

Do not use mocks, stubs, or fakes if the same scenario can be tested more simply with a real typed object. Preference order:

1. real typed object;
2. real object built through a small helper or fixture;
3. `mocker.Mock` / `mocker.AsyncMock` with `spec` (or `mocker.create_autospec`) if the project uses `pytest-mock`, otherwise `Mock` / `AsyncMock` from `unittest.mock` with `spec`;
4. `mocker.spy` (`pytest-mock`) when interaction with real code must be observed;
5. handwritten `stub` / `fake` only when it is clearly the best option.

- If the project uses `pytest-mock`, create doubles through its `mocker` fixture:
`mocker.patch`, `mocker.patch.object`, `mocker.Mock`, and `mocker.spy`.

- With `pytest-mock`, do not import `unittest.mock` in tests.
- Use `spec`/`spec_set` or `autospec=True` to catch renamed methods and wrong signatures.
- Use `MagicMock` only for magic-method support.
- Observe real calls with `mocker.spy`, not `patch(..., wraps=...)`.
- Use `Mock`/`AsyncMock` for external dependencies, controlled results or errors, and meaningful interactions.
- Avoid long mock chains and assertions about irrelevant internal calls.
- Use handwritten fakes only when reused, stateful, clearer than mocks,
  faithful to the dependency contract, and better for readability and typing.

## Async tests

Test async contracts with `async def`. Avoid unnecessary sync wrappers.
Cover relevant `await`, context managers, iterators, shutdown, cleanup, and errors.
Use `AsyncMock` only when a mock is needed.

## Parameterization

Use `@pytest.mark.parametrize` with readable `ids` when:

- the scenario stays the same;
- only inputs and expected outputs differ;
- it reduces duplication without hurting readability.

Keep conceptually different or harder-to-read scenarios separate.

## Typing in tests

Prefer real typed objects where production code already defines types. Avoid untyped dictionaries when a DTO, schema, settings object, or domain model exists. Avoid `Any` and `cast` unless necessary and localized.

## Logs, metrics, observability

- Assert logs or metrics only when they are part of the expected behavior or required to
  diagnose a meaningful scenario.
- Use `caplog` for standard logging when appropriate; if `caplog` is flaky due to logging
  adapters, prefer a patched logger or spy.
- Do not turn business logic tests into tests of telemetry internals.

## Production defect vs test defect

- If a test reveals a production bug, state that explicitly.
- Separate: test defect, production defect, missing context, mismatch with requirements,
  mismatch with styleguide.
- If production code violates the contract, suggest the minimal correction direction without
  rewriting the module.
