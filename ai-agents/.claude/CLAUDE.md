# Claude Code User Instructions

These are user-level instructions for coding tasks.

## Applicability

- Apply these instructions to coding, code review, repository work, technical documentation for software projects, tests, diffs, commits, and CLI-based software development.
- Apply the Russian Technical Writing rules only when writing, editing, or shortening Russian technical text.
- Apply the Git commit message rule whenever the user provides `git diff` and asks for a commit message.

## Output Style

These rules apply to all output: chat, code, comments, and documentation, in any language.

- Do not use emoji unless the user explicitly asks for them.
- Do not use the em dash `—` (U+2014) in generated text. Use the en dash `–` (U+2013) instead, or a hyphen, comma, colon, or split the sentence.
- In Russian text, always write `е` instead of `ё`.

## Working Style

- Read the relevant files, contracts, and tests before changing behavior.
- Keep changes scoped to the requested task and avoid unrelated rewrites.
- Prefer existing local patterns and abstractions when their contract fits.
- Avoid new dependencies unless they remove meaningful complexity or are explicitly required.
- Keep implementations simple; add abstractions only when they reduce real duplication or clarify a contract.
- Prefer explicit errors over hidden failures, empty fallback results, or warning-only output.
- Do not add retries around side-effecting operations unless an idempotency contract is clear.
- Spawn subagents and run parallel sessions deliberately, not by default: each subagent and each session consumes its own token budget against the shared limit. Prefer one focused session, smaller fan-out, and a cheaper model for simple subagents.

## Code Quality

- Use modern, precise type annotations such as `str | None`, `list[str]`, and `dict[str, Any]`.
- Avoid bare collection annotations when element types are known.
- Do not suppress lint or type-check violations without a narrow reason.
- Add or update tests for behavior changes and important failure cases.

## Python docstrings and tests

When writing or editing Python code, docstrings, or tests, use the `python-conventions` skill. It is the single source of truth for docstring style (Google style, Russian content, English section headers) and all test-writing rules: structure, docstrings, assertions, fixtures, test doubles, async, parameterization, typing, and observability. Do not duplicate those rules here.

Do not write or modify tests unless the user explicitly asks for test-writing help or the requested implementation requires tests as part of the task.

## Russian Technical Writing

Write Russian technical text in Russian: short, direct, factual sentences. Preserve identifiers, API contracts, and established project terms. Avoid filler, bureaucratic wording, and anglicisms that have a precise Russian equivalent. Do not expand scope. These rules do not apply to git commit messages.

For any non-trivial writing, editing, or shortening of Russian technical text — Jira, README, MR / RFC / ADR titles and descriptions, documentation, docstrings — use the `writing-russian-editor` skill. It is the single source of truth: full preserve-list, anglicism handling, compound-modifier and keep-list term policy, genre output formats, glossary, and the safety rule. Do not duplicate those rules here.

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

When the task is ambiguous, underspecified, or has multiple valid implementation paths:

- Do not start editing files immediately.
- First inspect the repository context if needed.
- Use AskUserQuestion to ask 1–4 blocking clarification questions.
- Prefer multiple-choice options.
- Include a recommended/default option when reasonable.
- If a question is non-blocking, state the assumption and continue.
- After answers are received, produce a short plan before implementation.
