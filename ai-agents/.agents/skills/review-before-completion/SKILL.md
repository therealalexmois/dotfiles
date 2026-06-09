---
name: review-before-completion
description: Strict engineering self-review of your own diff before you consider the work done. Use whenever the user asks to review a diff, review an MR/PR, check tests, assess implementation quality, OR is about to claim work is complete, that tests pass, that a bug is fixed, or is about to commit or prepare an MR. Reviews by the pyramid (API, Implementation, Docs, Tests, Style) and forbids a Ready verdict without fresh verification evidence (tests, lint, build run now). Do not use to implement code, write tests, write a commit message, or author MR text - this skill only reviews and returns a verdict.
---

# Review Before Completion

Act as a reviewer-partner, not an implementer. This skill reviews a change and returns findings plus a verdict before the work is treated as complete. It never writes the implementation, never authors the MR text, and never invents missing context.

The skill is a thin router. Read only the reference files the diff actually needs, then run a single review pass.

## Routing

```
diff ──► what does it touch?
         ├─ public API / signatures / contracts ──► references/correctness.md + references/api.md
         ├─ any production code ───────────────────► references/correctness.md + references/complexity.md
         ├─ test_* / conftest / fixtures ──────────► references/tests.md
         ├─ docstrings / comments ─────────────────► references/docstrings.md
         ├─ formatting / naming only ──────────────► references/style.md
         └─ ALWAYS ────────────────────────────────► references/review-workflow.md
                                                      └─ before verdict = Ready:
                                                         Evidence Gate (run tests/lint/build,
                                                         read the output, then decide)
```

Decision table - which reference to load:

| Signal in the diff | Load |
|---|---|
| Public function/class signature, return type, error contract changes | `correctness.md`, `api.md` |
| New or changed business/runtime logic | `correctness.md`, `complexity.md` |
| Files under `tests/`, `test_*.py`, `conftest.py` | `tests.md` |
| Docstrings or non-trivial comments change | `docstrings.md` |
| Pure formatting, naming, import order | `style.md` |
| Always (workflow, severity, verdict, evidence gate) | `review-workflow.md` |

For Python specifics, `tests.md` and `docstrings.md` defer to the `python-conventions` skill as the write-time source of truth and only add review-time judgment.

## Hard rules

- Do not write the fix, rewrite modules wholesale, or propose refactors outside the change scope. Micro-examples up to 1-3 lines are allowed only to make a finding clear.
- Do not invent contracts, DTO fields, schemas, signatures, or architecture. If context is missing, ask only for the artifacts that affect this review.
- Do not push personal style over the project styleguide. The team styleguide wins.
- Do not claim a layer passes without the evidence the Evidence Gate requires.

## Required models

Severity: `NO_EVIDENCE`, `Blocker`, `Major`, `Minor`, `Nit`. (`NO_EVIDENCE` outranks `Blocker`: no fresh evidence means the review cannot be trusted.)

Layer: `API`, `Implementation`, `Docs`, `Tests`, `Style`.

Verdict (exactly one): `Needs more context`, `Needs changes`, `Non-blocking comments only`, `Ready`.

See `references/review-workflow.md` for severity definitions, the Evidence Gate, the readiness check, iterative-review behavior, and the full verdict logic.

## Output

Default format - one section per item, scaled to findings:

1. `Verdict`
2. `Evidence` (commands run now and their result, or why none were possible)
3. `Scope checked`
4. `Findings` (each: severity, layer, location, issue, why it matters, risk, minimal correction direction)
5. `Questions / missing context`
6. `Automation candidates` (only when relevant - suggest a JIRA tech-debt task with label `review-improvement`)
7. `What is good`

Compressed format - when the user asks for terse comments (or for inline PR comments), switch each finding to the one-line `caveman-review` style: `<file>:L<line>: <severity>: <problem>. <fix>.` Keep `Verdict` and `Evidence` as normal lines.
