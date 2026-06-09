# Docs review

The Documentation layer of the pyramid. Covers code docstrings/comments and the wider docs a change should update. The `python-conventions` skill is the write-time source of truth for Python docstring style (Google style, Russian content, English section headers); this file is the review lens.

## When docs are required

Require docs when the change touches behavior, contracts, limitations, operational flow, architecture decisions, or non-obvious business logic. Relevant surfaces: README, API docs, runbook, changelog, inline comments for non-obvious decisions, and test docstrings.

A minimal doc written now is cheaper than the communication cost later. Missing docs for a changed contract is a `Major` finding, not a nit.

## Docstring review

- Module, class, public function, and method docstrings present where they carry weight (dataclasses, Pydantic models, DTOs, public APIs).
- The docstring explains purpose, contract, and non-obvious behavior - it does not restate the name or narrate the implementation.
- Russian content, English section headers (`Args`, `Returns`, `Raises`, `Yields`, `Attributes`, `Examples`), `е` instead of `ё`.
- Do not flag a missing `Args`/`Returns`/`Raises` when it would add nothing.
- Do not approve a comment that merely restates the code.

## Test docstrings

Every test module and every test should carry a docstring describing input conditions, the key action, and the expected observable result, plus whether it is an error path or regression case when relevant. Do not accept formal noise that repeats the test name.

## Defer

For exact docstring formatting and content rules, defer to `python-conventions`. Here, judge only whether the documentation that the change needed actually exists and is honest.
