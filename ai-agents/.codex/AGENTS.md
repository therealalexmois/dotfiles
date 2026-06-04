# Codex User Instructions

These are user-level instructions.

## Applicability

- Apply these instructions to coding, code review, repository work, technical documentation for software projects, tests, diffs, commits, and CLI-based software development.
- Do not apply coding-specific rules to personal planning, Obsidian notes, journaling, knowledge management, or non-code writing unless explicitly requested.
- For Obsidian and planning tasks, prefer the user's requested structure, vault conventions, and planning workflow over coding workflow rules.
- Apply the Russian Technical Writing rules only when writing, editing, or shortening Russian technical text.
- Apply the Git commit message rule whenever the user provides `git diff` and asks for a commit message.

## Output Style

These rules apply to all output: chat, code, comments, and documentation, in any language.

- Do not use emoji unless the user explicitly asks for them.
- Do not use the em dash `—` in generated text. Use a hyphen, comma, colon, or split the sentence instead.
- In Russian text, always write `е` instead of `ё`.

## Working Style

- Read the relevant files, contracts, and tests before changing behavior.
- Keep changes scoped to the requested task and avoid unrelated rewrites.
- Prefer existing local patterns and abstractions when their contract fits.
- Avoid new dependencies unless they remove meaningful complexity or are explicitly required.
- Keep implementations simple; add abstractions only when they reduce real duplication or clarify a contract.
- Prefer explicit errors over hidden failures, empty fallback results, or warning-only output.
- Do not add retries around side-effecting operations unless an idempotency contract is clear.

## External documentation lookup

Use the `context7` MCP server before answering questions about current library APIs, framework configuration, dependency setup, migration guides, or version-specific behavior.

Do not use `context7` for generic programming concepts, local code review, repository-local behavior, or tasks fully answerable from the repository files.

## Code Quality

- Use modern, precise type annotations such as `str | None`, `list[str]`, and `dict[str, Any]`.
- Avoid bare collection annotations when element types are known.
- Do not suppress lint or type-check violations without a narrow reason.
- Add or update tests for behavior changes and important failure cases.

## Python docstrings

When editing Python code, improve docstrings without changing runtime behavior.

Rules:

- Use Google Python Style docstrings.
- Write docstring content in Russian.
- Keep section headers in English: `Args`, `Returns`, `Raises`, `Yields`, `Attributes`, `Examples`.
- Add module, class, function and method docstrings when they are missing or weak.
- Keep docstrings concise: explain purpose, contract, important constraints and non-obvious behavior.
- Do not restate the function name or obvious implementation details.
- Add `Attributes` for dataclasses, Pydantic models, DTOs and classes with meaningful public fields.
- Add `Args`, `Returns` and `Raises` only when they add useful information.
- Do not document exceptions that are not visible from code or explicit contract.
- Preserve technical identifiers, API names, field names, enum values, file names and established project terms.
- Avoid unnecessary English words in Russian text when a precise Russian equivalent exists.
- Do not create Russian-English hybrids with endings; use a Russian generic word instead, for example: `компонент Router`, `сервис builder`, `контекст runtime preflight`.
- Add or adjust type annotations only when explicitly requested or when the type is obvious and the change is safe.
- Do not change business logic, control flow, constants, public API, log event names, error messages or tests unless explicitly requested.

## Test Writing

Use these rules when writing, modifying, or reviewing tests.

### Test-writing principles

A test must verify observable behavior, not incidental implementation details.

A good test:

- fixes a real contract;
- is isolated and reproducible;
- covers one scenario or one clear behavior branch;
- uses meaningful assertions only;
- makes important input conditions visible;
- does not mask production defects;
- does not add unnecessary test-layer complexity;
- can be understood on review without opening many helper layers.

When writing tests, first inspect the real source code and existing test style. Use real imports, real types, and real signatures.

Do not write or modify tests unless the user explicitly asks for test-writing help or the requested implementation requires tests as part of the task.

### Test structure

Prefer clear test names:

```python
test_<what_is_tested>__<expected_behavior>
```

Follow the existing project style if it differs.

For pytest projects, use markers as an organization rule. Adapt to the project marker policy when it exists. Common markers:

- `unit`;
- `integration`;
- `api_integration`;
- `infra_integration`;
- `system`;
- `e2e`;
- `manual`;
- `slow`.

Do not mark a test as heavier than necessary.

### Test docstrings

Every test module must have a module docstring.

Every test must have a docstring unless the project styleguide explicitly says otherwise.

A test docstring should describe:

- input conditions;
- key action;
- expected observable result;
- whether the case is an error path or regression case, if relevant.

Do not repeat the test name verbatim. Do not describe implementation line by line.

### Assertions

Assertions must verify the contract.

Avoid:

- checking everything blindly;
- overfitting to unstable strings, timestamps, random order, or internal call chains;
- magic numbers that reduce readability;
- full-structure assertions when only a meaningful subset is part of the contract.

For error tests:

- assert the error type;
- assert the important part of the message only if the message is part of the user-facing or integration contract.

### Fixtures

Use fixtures only when they make the test clearer or reduce meaningful duplication.

Preference order:

1. explicit inline setup;
2. local helper function;
3. local fixture in the test module;
4. local `conftest.py` fixture for neighboring modules;
5. shared `conftest.py` fixture only for stable, genuinely shared setup.

Do not introduce a fixture when:

- the object is used in only one test;
- setup is 1–3 clear lines;
- the fixture hides key scenario conditions;
- the fixture is created “for later”;
- the fixture makes the test harder to read.

Fixture names should describe the returned object, not the action. Avoid vague names like `data`, `obj`, `payload`, `result`, `mocked`.

### Test doubles

Do not use mocks, stubs, or fakes if the same scenario can be tested more simply with a real typed object.

Preference order:

1. real typed object;
2. real object built through a small helper or fixture;
3. `mocker.Mock` / `mocker.AsyncMock`;
4. `spy` when interaction with real code must be observed;
5. handwritten `stub` / `fake` only when it is clearly the best option.

Use `Mock` / `AsyncMock` when:

- replacing an external dependency;
- controlling `return_value` or `side_effect`;
- verifying a meaningful interaction.

Avoid:

- long fragile mock chains;
- asserting every internal call;
- mock assertions that do not affect the tested contract.

Handwritten fakes are allowed only when they:

- are reused;
- naturally hold state;
- represent the dependency contract better than mocks;
- improve readability and typing.

### Async tests

For async behavior:

- use `async def` where appropriate;
- test the async contract directly;
- avoid unnecessary sync wrappers;
- cover relevant lifecycle behavior: `await`, async context managers, async iterators, shutdown, cleanup, and error paths.

Use `AsyncMock` only when a mock is actually needed.

### Parameterization

Use `@pytest.mark.parametrize` when:

- the scenario is the same;
- only inputs and expected outputs differ;
- duplication is reduced without hurting readability.

Do not parameterize when cases are conceptually different or the scenario becomes harder to understand.

### Typing in tests

Prefer real typed objects where production code already defines types.

Avoid untyped dictionaries when a DTO, schema, settings object, or domain model exists.

Avoid `Any` and `cast` unless they are necessary and localized.

### Logs, metrics, and observability

Assert logs or metrics only when they are part of the expected behavior or required for diagnosing a meaningful scenario.

Use `caplog` for standard logging when appropriate. If `caplog` makes the test flaky due to logging adapters or configuration, prefer a patched logger or spy.

Do not turn business logic tests into tests of telemetry internals.

### Production defect vs test defect

If a test reveals a production bug, state that explicitly.

Separate:

- test defect;
- production defect;
- missing context;
- mismatch with requirements;
- mismatch with styleguide.

If the production code violates the contract, suggest the minimal correction direction without rewriting the module.

## Russian Technical Writing

Use these rules when writing, editing, or shortening Russian technical text. These rules do not apply to git commit messages.

### Core behavior

- Write in Russian by default.
- Prefer short, direct, factual sentences.
- Keep the user’s meaning, requirements, constraints, and technical contracts unchanged.
- Do not expand scope or add new requirements unless explicitly asked.
- Return ready-to-use text, not a long explanation of edits.

### Preserve technical precision

Do not translate or rewrite:

- file and directory names;
- class, function, method, field, variable, enum, and package names;
- API endpoints, HTTP methods, JSON/YAML keys, CLI commands;
- metric names, log events, feature flags, environment variables;
- project-specific terms when a Russian replacement would reduce precision.

### Remove weak writing

Remove or rewrite:

- filler phrases;
- repeated ideas;
- vague conclusions;
- empty evaluations;
- bureaucratic wording;
- passive constructions where an active subject is clearer;
- long chains of abstract nouns.

Bad:

- «осуществляется проверка»
- «в рамках данной задачи»
- «является важным аспектом»
- «позволяет повысить эффективность»

Better:

- «компонент проверяет»
- «в задаче»
- объяснить фактический эффект
- назвать измеримый результат или конкретное поведение

### English terms

Use Russian words when they are precise enough.

Keep English only when it is:

- an identifier;
- a product, library, API, protocol, or technology name;
- a project term;
- an AI/ML term where Russian is less precise;
- explicitly requested by the user.

Allowed AI/ML terms include:

- `AI`
- `LLM`
- `prompt`
- `system prompt`
- `skill`
- `token`
- `context window`
- `embedding`
- `RAG`
- `benchmark`
- `evaluation`
- `inference`

Do not attach Russian endings to English terms through hyphens.

Bad:

- `router-ом`
- `resolver-ом`
- `runtime-ом`
- `skill-реализация`
- `workflow-ом`

Better:

- «компонент Router»
- «компонент Resolver»
- «runtime-среда»
- «реализация skill»
- «сценарий» или `workflow`, если это проектный термин

### Editing workflow

When editing text:

1. Identify the genre: Jira description, README, MR description, RFC, docstring, UI text, or plain technical note.
2. Keep the original format unless the user asks to change it.
3. Preserve identifiers and contracts.
4. Remove repetition and filler.
5. Replace vague wording with concrete behavior.
6. Shorten without losing meaning.
7. Return the final version in a copy-ready form.

### Output format

- For a short phrase, return only the improved phrase.
- For a docstring, return a valid code block in the target language.
- For Jira text, preserve Jira markup, panels, checkboxes, and numbering.
- For Markdown documents, preserve headings, lists, tables, and code blocks.
- If the text contains nested code blocks, wrap the outer Markdown block with four backticks.
- Do not add a final summary if the edited text already completes the task.

### Safety rule

If the source text contains a contradiction, missing condition, or misleading statement, do not silently polish it. State the problem briefly, then provide the safest corrected version.

## Delivery

- Do not include secrets or local-only values in committed files.
- Do not run `git add`, `git commit`, `git push`, `git rebase`, `git reset`, or amend commits unless explicitly asked.
- When asked to commit, include only files in scope.

## Git commit message rule

When the user provides `git diff` and asks for a commit message, return exactly one line in Conventional Commits format:

`<type>(optional-scope): <description>`

Rules:

- Use only these types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `style`, `build`, `ci`, `chore`.
- Pick the type by the main meaning of the diff, not by secondary files.
- Add scope only when it is obvious from file paths or code context.
- Write in English.
- Use lowercase, short imperative description.
- Do not add explanations, quotes, bullets, body, footer, or markdown.
- If the diff has no meaningful change, return exactly: `chore: no significant changes detected`.

## Clarification protocol

When the task is ambiguous, underspecified, or depends on missing user intent:

- Do not edit files immediately.
- First inspect available repository context.
- Ask blocking clarification questions before implementation.
- Ask no more than 5 questions.
- Prefer short multiple-choice questions with a recommended default.
- If a question is not blocking, state the assumption and continue.
- For complex or unclear tasks, use plan-first workflow before making changes.
