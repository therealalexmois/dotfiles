# Correctness: API and Implementation Semantics

The two lowest, most expensive layers of the pyramid. Review these before docs, tests, or style.

## API Semantics

Check that the change preserves or intentionally updates:

- the public contract;
- backward compatibility;
- input and output semantics;
- invariants;
- error handling;
- edge cases;
- domain and API naming;
- alignment with requirements, MR description, Jira, and RFC;
- observability impact;
- operational impact;
- security risk;
- data-loss risk.

If behavior changes in a way that is not documented or not aligned with the task requirements, treat it as a substantive issue (`Major` or `Blocker`, depending on blast radius). An unexpected, undocumented behavior change is a finding, not a detail.

## Implementation Semantics

Prefer the smallest correct change. Check:

- semantic correctness against the chosen API;
- architecture boundaries;
- cohesion and coupling;
- maintainability and readability;
- hidden assumptions;
- branching correctness, side effects, state handling;
- performance, scalability, and security concerns;
- consistency with existing project patterns - does the change break an established pattern without reason.

Apply KISS and YAGNI. Do not bless abstractions, helpers, fixtures, or test doubles introduced "for the future". Deep complexity belongs in `complexity.md`.

## What is not your job here

Do not propose the implementation. Name the risk and the minimal correction direction. A micro-example of 1-3 lines is allowed only when the finding cannot be made clear otherwise.
