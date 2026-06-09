# Tests: review-time rules

This is the review lens for tests. The `python-conventions` skill is the write-time source of truth for how pytest tests are structured, named, typed, and documented; this file only adds the judgment a reviewer applies and does not restate it. When the change writes Python tests, defer mechanics to `python-conventions`.

## What a test must do

A test fixes a real, observable contract. A good test:

- verifies behavior, not incidental implementation details;
- is isolated and reproducible;
- covers one scenario or one clear behavior branch;
- carries only meaningful assertions;
- keeps important input conditions visible;
- does not mask production defects;
- reads on review without opening many helper layers.

## Leave a finding when

- the test asserts implementation details instead of the contract;
- the test is fragile or flaky (bound to unstable strings, timestamps, random order, or global state without need);
- a fixture hides the scenario - key inputs are buried so the test reads as magic;
- a poor test double is chosen (a mock where a real typed object is simpler and honest);
- an important scenario, error path, or regression guard is missing;
- parameterization hurts readability, or is obviously missing where duplicated tests beg for it;
- assertions are excessive or insufficient;
- a test or test module lacks a docstring that explains the contract;
- typing degrades (untyped dicts where a DTO/schema already exists);
- the test masks a production defect.

Do not leave taste-only findings when the test is correct, readable, consistent with project style, and does not hurt maintenance.

## Test doubles - the order to expect

1. real typed object;
2. real object via a small helper or fixture;
3. `mocker.Mock` / `mocker.AsyncMock`;
4. `spy` when interaction with real code must be observed;
5. handwritten `stub` / `fake` only when it is clearly best.

Flag long fragile mock chains and assertions on every internal call that the contract does not depend on.

## Production defect vs test defect

If a test reveals a production bug, say so explicitly and separate: test defect, production defect, missing context, mismatch with requirements, mismatch with styleguide. If the issue is solvable in the test, do not ask to change production code. If production truly violates the contract, give the minimal correction direction without rewriting the module.

## Evidence

Per the Evidence Gate in `review-workflow.md`: do not assert that tests pass, or that a regression test works, without running them now. A regression test that has not been seen to fail without the fix is a `NO_EVIDENCE` finding.
