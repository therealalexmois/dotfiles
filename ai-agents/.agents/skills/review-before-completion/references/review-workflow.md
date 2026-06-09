# Review Workflow

Detailed source of truth for `review-before-completion`. Keep `SKILL.md` thin; keep the rules here.

## Default mode

Work as a reviewer-partner, not an implementer. Default mode is review. Review tests when they are part of the change, but write or modify tests only when the user explicitly asks for test-writing help outside the review task.

Do not:

- invent missing contracts, DTO fields, schemas, dependencies, signatures, or architecture;
- rewrite modules wholesale or propose large refactors outside the task scope;
- change production code when the issue can be solved correctly in tests;
- weaken tests only to make them pass;
- turn review feedback into broad coding rules;
- push personal style over the project styleguide.

## Readiness check

Before a full review, confirm there is enough context. Required signals:

- task goal, scope, constraints, expected result, Definition of Done;
- changed files and the diff;
- MR description, Jira task, RFC / design doc, when they exist;
- architectural context, styleguide, testing rules, related docs.

If context is insufficient, do not produce a full review. Respond in this order and stop:

1. What is already clear
2. What is missing
3. Clarifying questions
4. What to send next

Ask only for artifacts that affect this review. Set the verdict to `Needs more context`.

## Review pyramid

Review bottom-up. The lower the layer, the more expensive the mistake.

1. API Semantics
2. Implementation Semantics
3. Documentation
4. Tests
5. Code Style

Do not spend attention on style nits while there are unresolved API, implementation, docs, or test risks. Per-layer rules live in `correctness.md`, `complexity.md`, `docstrings.md`, `tests.md`, and `style.md`.

## Step 0: Evidence Gate

Before assigning a `Ready` verdict, or before stating that any layer passes, collect fresh evidence. Reviewing the code by eye is not evidence that it runs.

Gate procedure:

1. IDENTIFY: which command proves this claim (test command, linter, type-checker, build).
2. RUN: execute the full command now, in this review.
3. READ: full output, exit code, failure count.
4. VERIFY: does the output confirm the claim? If not, report the actual state with the output.
5. ONLY THEN: state the result, with the evidence attached.

If the command cannot be run in this environment (no access, missing deps, out of scope), say so explicitly. Do not substitute confidence for evidence.

Evidence criteria - what each claim actually requires:

| Claim | Requires | Not sufficient |
|---|---|---|
| Tests pass | Test command output: 0 failures, this run | A previous run, "should pass", reading the test |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Type-check clean | Type-checker output: 0 errors | Linter passing |
| Build succeeds | Build command: exit 0 | Linter or type-check passing |
| Bug fixed | A test that reproduces the original symptom now passes | Code changed, assumed fixed |
| Regression test works | Red-green verified: it fails without the fix, passes with it | The test passes once |

Do not put a `Ready` on the board on any of these rationalizations: "should work now", "I'm confident", "linter passed so it compiles", "it passed earlier", "a partial check is enough". Each one means: run the command.

## Severity

`NO_EVIDENCE` - the Evidence Gate could not confirm a claim a verdict depends on (tests not run, build not run, a "fixed" bug never reproduced). Outranks everything: the review cannot be trusted until evidence exists. Forces the verdict to `Needs more context`.

`Blocker` - blocks completion: breaks the public contract, risks data loss, creates a security risk, breaks backward compatibility without an explicit decision, makes the change incorrect against requirements, or breaks a key scenario.

`Major` - substantial but not always blocking: an important uncovered scenario, an unhandled error path, an in-scope architecture violation, a real test gap, a flaky-behavior risk, a notable performance or scalability risk, or missing docs for a changed contract.

`Minor` - local improvement: readability, maintainability, incomplete-but-non-critical coverage, small docs gaps, a local simplification with no architecture change.

`Nit` - non-critical: naming, formatting, a small consistency issue. Must not distract from substantive findings.

## Finding format

Each meaningful finding includes: severity; layer; location, if available; the issue; why it matters; the risk; the minimal correction direction. Be specific and risk-based. If confidence is limited, phrase the finding as a question or hypothesis rather than an assertion.

## Verdict logic

- `Needs more context` - missing artifacts prevent a defensible review, OR any `NO_EVIDENCE` is open.
- `Needs changes` - any `Blocker`, or a high-confidence unresolved `Major`.
- `Non-blocking comments only` - all findings are `Minor` or `Nit`, and the Evidence Gate passed.
- `Ready` - no material findings in the checked scope AND the Evidence Gate passed with attached evidence.

A `Ready` verdict is only honest with the `Evidence` section filled in. If you did not run the commands, the verdict is at best `Non-blocking comments only` with a `NO_EVIDENCE` note, not `Ready`.

## Iterative review

The user may send the diff in chunks.

- Review only the supplied chunk; do not pretend to see the whole MR.
- Flag likely cross-file risks explicitly.
- Request a neighboring module, test, contract, or doc only when a precise conclusion is impossible without it.
- Keep findings consistent across iterations; after fixes, follow up only on the changed spots.

## Automation / tech debt

If a finding should be caught automatically rather than by hand, mark it as an automation candidate and suggest a JIRA tech-debt task with label `review-improvement`. Typical candidates: lint, format, type checks, static analysis, import order, contract/schema validation, test templates, doc checks, CI guards, repetitive review checks. State briefly: what is caught by hand now, why automate it, which check to add.
