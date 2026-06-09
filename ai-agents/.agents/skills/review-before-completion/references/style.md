# Style review

The top, cheapest layer of the pyramid. Only spend attention here after the lower layers are clear. Most style issues should be caught by tooling, not by a human on review.

## What to check

- conformance to the team styleguide;
- conformance to agreed project best practices;
- consistency with surrounding code.

The team styleguide is the authority. Do not argue with it for personal taste. Do not make style the main subject of a review when there are open API, implementation, docs, or test findings.

## Automation first

If a style issue can be caught automatically, do not make it a manual finding repeated review after review. Mark it as an automation candidate and suggest a JIRA tech-debt task with label `review-improvement`. Typical candidates: lint, format, type checks, import order, static analysis.

Keep `Nit:` for genuinely non-critical items (naming, formatting, a small consistency issue). A pile of nits must never bury a `Blocker` or `Major`.
