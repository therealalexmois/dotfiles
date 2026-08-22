# Prompt Evaluation

Read this reference only for reusable, production-facing, optimized, model-migrated, dataset-evaluated, or high-cost prompts. Do not impose this workflow on a simple one-off prompt.

## 1. Establish the Baseline

Record only what is needed to reproduce the comparison:

- current prompt or prompt version;
- target model and relevant runtime configuration, when known;
- representative inputs;
- observed outputs;
- task-specific success criteria and current results.

Do not invent a universal quality threshold. Derive pass criteria from the task, downstream contract, and cost of false positives and false negatives.

## 2. Diagnose Failures

Classify observed or plausible failures before changing the prompt:

- ambiguous or competing instructions;
- missing, irrelevant, stale, or excessive context;
- missing preconditions or undefined terms;
- inadequate examples or examples unlike the target distribution;
- invalid, unstable, or underspecified output structure;
- unsupported claims or fabricated evidence;
- incorrect blocked or missing-data behavior;
- model-, provider-, tool-, or environment-specific assumptions;
- excessive tokens, latency, or repeated instructions.

Tie each proposed change to a specific failure. Do not add techniques because they are fashionable.

## 3. Build a Small Representative Test Set

Select cases that exercise actual risk:

- **typical:** normal valid input;
- **negative:** missing required data or prohibited behavior;
- **edge:** empty, malformed, unusually large, multilingual, or ambiguous input when relevant;
- **adversarial:** conflicting or untrusted embedded instructions when relevant;
- **regression:** a previously observed failure.

Keep the set small unless the user explicitly asks for an evaluation suite. For each case, define an observable pass criterion before running it.

## 4. Match Evaluation to the Output

Prefer the most deterministic useful evaluator:

| Output | Preferred evaluation |
| --- | --- |
| JSON or structured data | Parse and validate the schema and invariants |
| Classification | Accuracy, precision, recall, F1, or cost-weighted errors as appropriate |
| Extraction | Exact match plus field-level precision and recall |
| Code, SQL, or commands | Execute safe tests, compile, lint, or inspect required structure |
| Review or gate | Evidence-backed rubric with fixed verdicts when gating |
| Open-ended text | Task-specific rubric, pairwise comparison, or human review |
| Agent task | Inspect resulting artifacts, tool actions, boundaries, and verification evidence |

Use lexical similarity metrics only when surface overlap is genuinely the target. Do not use BLEU, ROUGE, or a generic LLM score as a default proxy for correctness.

## 5. Use Semantic Judges Carefully

Use an LLM judge only for criteria that deterministic checks cannot express. Provide a task-specific rubric and require a concise evidence-based rationale. When comparison matters:

- compare against the same inputs and criteria;
- randomize or reverse answer order to detect position bias;
- tell the judge not to reward verbosity;
- separate correctness from style;
- use human review for subjective or high-stakes decisions when needed.

## 6. Iterate Without Confounding Changes

1. Form a hypothesis from a failure.
2. Change one significant prompt element at a time when diagnosing.
3. Run the same representative cases against baseline and candidate.
4. Check quality, regressions, token cost, and latency only when they matter.
5. Keep the candidate only when it improves the target criteria without unacceptable regressions.

When migrating between models or providers, recheck instruction following, structured output, tool use, context handling, and failure behavior. Consult current official documentation only when model-specific behavior materially affects the design.

## 7. Return Only the Needed Evaluation Artifacts

Depending on the request, provide only the applicable subset:

- final prompt;
- input and output contracts;
- evaluation cases with pass criteria;
- baseline-versus-candidate comparison;
- known limitations and runtime assumptions.

Do not add deployment notes, model parameters, metrics, or a large test suite unless the user's task requires them.

## 8. Regression Set for Task-oriented Prompts

Use these cases when changing context selection, prompt length, agent autonomy, or acceptance-criteria behavior. Score each output against the active request, not against the amount of conversation it repeats.

### Case A: Routine repository cleanup

Context mentions merged PRs, CI, acceptance tests, a scheduled job, and earlier coverage problems. The final request asks only to update local `main` and remove the branches and worktrees created for the completed task.

Pass when the prompt states those two outcomes, identifies exact deletion targets when supplied, and preserves unrelated work. Fail when it includes Git commands, CI, tests, the scheduled job, coverage, PR review, or an extended report.

### Case B: Rejected and deferred alternatives

The discussion considered a circuit breaker, whole-run retry, and explicit gRPC deadlines. The final decision selects only bounded per-call retries with a supplied policy.

Pass when the prompt contains the selected retry behavior and necessary policy. Fail when it mentions the discarded alternatives, including as “do not implement” instructions, unless the active task would otherwise plausibly reintroduce them.

### Case C: Small implementation request

The final request asks to rename one configuration key while preserving behavior. Earlier messages discussed broader refactoring, CI, documentation, and release work, but none was selected.

Pass when the prompt asks for the rename and preserved behavior. Fail when it adds architecture work, documentation, tests, CI, release steps, worktree rules, or reporting that the user did not request.

### Rubric

Each case must satisfy all four dimensions:

1. **Fidelity:** every active requirement is present and unchanged.
2. **Restraint:** no inactive conversation context or invented requirement appears.
3. **Autonomy:** no routine command or implementation recipe is prescribed.
4. **Proportionality:** structure and length match the task rather than the history behind it.

Any added command, discarded option, unrelated context, or invented acceptance gate is a regression even when the resulting prompt would still be executable.
