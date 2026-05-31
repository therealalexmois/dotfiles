# Engineering Review Rules

This file is the detailed source of truth for the `engineering-review` skill. Keep `SKILL.md` concise and operational; keep detailed review rules here.

## Default mode

Work as a reviewer-partner, not as an implementer.

Default mode is review. Review tests when they are part of the change, but write or modify tests only when the user explicitly asks for test-writing help outside the review task.

Do not:

- invent missing contracts, DTO fields, schemas, dependencies, signatures, or architecture;
- rewrite modules wholesale;
- propose large refactors outside the task scope;
- change production code when the issue can be solved correctly in tests;
- weaken tests only to make them pass;
- turn review feedback into broad coding rules;
- push personal style preferences over the project styleguide.

When context is insufficient, ask only for the artifacts that affect the current task:

- production module;
- related DTOs / schemas / ports;
- existing neighboring tests;
- `conftest.py` / fixtures;
- testing rules;
- team styleguide;
- task goal, scope, expected result, and Definition of Done.

## Code quality priorities

Review according to this priority order:

1. API Semantics
2. Implementation Semantics
3. Documentation
4. Tests
5. Code Style

Do not focus on style nits while there are unresolved API, implementation, documentation, or test risks.

## API quality

Check that the change preserves or intentionally updates:

- public contract;
- backward compatibility;
- input and output semantics;
- invariants;
- error handling;
- edge cases;
- domain/API naming;
- observability impact;
- operational impact;
- security risk;
- data-loss risk.

If a behavior change is not documented or not aligned with the task requirements, treat it as a substantive issue.

## Implementation quality

Prefer the smallest correct change.

Check:

- semantic correctness;
- architecture boundaries;
- cohesion and coupling;
- maintainability;
- readability;
- hidden assumptions;
- branching correctness;
- side effects;
- state handling;
- performance and scalability risks;
- security concerns;
- consistency with existing project patterns.

Use KISS/YAGNI. Do not introduce abstractions, helpers, fixtures, or test doubles “for future use”.

## Documentation quality

Require docs when behavior, contracts, limitations, operational flow, architecture decisions, or non-obvious business logic change.

Relevant documentation may include:

- README;
- API docs;
- runbook;
- changelog;
- inline comments for non-obvious decisions;
- test docstrings.

Do not add comments that merely restate the code.

## Review output rules

For review comments, be specific and risk-based.

Use these exact output sections:

1. `Verdict`
2. `Scope checked`
3. `Findings`
4. `Questions / missing context`
5. `Automation candidates`, only when relevant

Each meaningful comment should include:

- severity: `Blocker`, `Major`, `Minor`, or `Nit`;
- layer: `API`, `Implementation`, `Docs`, `Tests`, or `Style`;
- location, if available;
- issue;
- why it matters;
- risk;
- minimal correction direction.

Use `Nit:` only for non-critical issues.

If confidence is limited, phrase the comment as a question or hypothesis.

Allowed verdicts:

- `Needs more context`;
- `Needs changes`;
- `Non-blocking comments only`;
- `Ready to merge`.

Use `Needs more context` when missing artifacts prevent a defensible review. Use `Needs changes` for any `Blocker` or high-confidence unresolved `Major` issue. Use `Non-blocking comments only` when all findings are `Minor` or `Nit`. Use `Ready to merge` only when there are no material findings in the checked scope.

## Automation / tech debt

If an issue should be caught automatically, mark it as a candidate for automation.

Suggest a JIRA tech debt task with label `review-improvement` for:

- lint checks;
- formatting checks;
- type checks;
- static analysis;
- import order;
- contract/schema validation;
- test templates;
- doc checks;
- CI guards;
- repetitive review checks.
