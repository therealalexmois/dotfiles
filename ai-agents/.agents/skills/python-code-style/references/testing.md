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

For pytest projects, use markers as an organization rule and follow the project's marker policy (the set of allowed markers and what they mean is project-specific - see the project's `pyproject.toml`/`AGENTS.md`). Do not mark a test as heavier than necessary.

## Docstrings

Every test module has a module docstring. For test functions, follow the project styleguide, then the neighboring tests. If both are silent, add a docstring when the test name does not state the input conditions and the expected result. A test docstring should describe input conditions, the key action, the expected observable result, and whether it is an error path or regression case. Do not repeat the test name verbatim or describe the implementation line by line.

## Assertions

Assertions must verify the contract. Avoid:

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

Do not introduce a fixture when the object is used in one test, setup is 1-3 clear lines, or it hides key scenario conditions. Fixture names describe the returned object, not the action - avoid vague names like `data`, `obj`, `payload`, `result`, `mocked`. Use the smallest necessary scope; a wider scope that leaks state between tests is a defect. Use a `yield` fixture only when there is real cleanup to run.

## Test doubles

Do not use mocks, stubs, or fakes if the same scenario can be tested more simply with a real typed object. Preference order:

1. real typed object;
2. real object built through a small helper or fixture;
3. `Mock` / `AsyncMock`, through `mocker` if the project uses `pytest-mock`, otherwise from `unittest.mock`;
4. `spy` when interaction with real code must be observed;
5. handwritten `stub` / `fake` only when it is clearly the best option.

Use `Mock` / `AsyncMock` when replacing an external dependency, controlling `return_value`/`side_effect`, or verifying a meaningful interaction. Avoid long fragile mock chains, asserting every internal call, and mock assertions that do not affect the tested contract. Handwritten fakes are allowed only when they are reused, naturally hold state, represent the dependency contract better than mocks, and improve readability and typing.

## Async tests

Use `async def` where appropriate and test the async contract directly; avoid unnecessary sync wrappers. Cover relevant lifecycle behavior: `await`, async context managers, async iterators, shutdown, cleanup, and error paths. Use `AsyncMock` only when a mock is actually needed.

## Parameterization

Use `@pytest.mark.parametrize` when the scenario is the same and only inputs and expected outputs differ, and duplication is reduced without hurting readability. Do not parameterize when cases are conceptually different or the scenario becomes harder to understand.

## Typing in tests

Prefer real typed objects where production code already defines types. Avoid untyped dictionaries when a DTO, schema, settings object, or domain model exists. Avoid `Any` and `cast` unless necessary and localized.

## Logs, metrics, observability

Assert logs or metrics only when they are part of the expected behavior or required to diagnose a meaningful scenario. Use `caplog` for standard logging when appropriate; if `caplog` is flaky due to logging adapters, prefer a patched logger or spy. Do not turn business logic tests into tests of telemetry internals.

## Production defect vs test defect

If a test reveals a production bug, state that explicitly. Separate: test defect, production defect, missing context, mismatch with requirements, mismatch with styleguide. If production code violates the contract, suggest the minimal correction direction without rewriting the module.
