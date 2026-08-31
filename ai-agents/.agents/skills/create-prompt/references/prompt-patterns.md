# Prompt Patterns

Read only the pattern relevant to the current task. Combine patterns only when the request genuinely spans multiple classes.

## Contents

- Web-model patterns
- Agent-task pattern
- Optional modules
- Complexity guidance
- Verification guidance

## Web-model patterns

### Review or gate

Use for artifact review, compliance checks, acceptance gates, risk assessment, and critique.

Include:

- artifact and review scope;
- explicit criteria;
- required evidence or citations;
- fixed verdicts when the result acts as a gate;
- findings ordered by severity;
- handling for insufficient evidence.

Avoid a fixed verdict enum for open-ended feedback.

### Extraction or classification

Use for extracting fields or assigning labels.

Include:

- precise input boundary;
- field or label definitions;
- output schema when parsed programmatically;
- behavior for missing, ambiguous, or malformed input;
- one or two examples only when edge distinctions are hard to express.

Do not add a role for mechanical transformations.

### Transformation or structured generation

Use for rewriting, summarizing, translating, formatting, drafting messages, reports, code, or JSON.

Include:

- meaning and details that must be preserved;
- changes that are allowed;
- target audience, style, and length only when relevant;
- exact output contract;
- prohibited additions or omissions.

### Document analysis and Q&A

Use for specifications, reports, PDFs, research notes, or attached files.

Include:

- source name or identifier;
- analysis scope and questions;
- result type: summary, Q&A, review, extraction, comparison, or decision brief;
- citation format when verifiability matters;
- instruction to say that the source lacks the answer rather than infer unsupported facts.

If citations are required, prefer the most stable locator available: page, section, heading, line, fragment identifier, or a short quote.

### Data analysis

Use for tables, datasets, metrics, financial data, or operational reports.

Include:

- dataset or source name;
- period, filters, groupings, and metric definitions;
- expected calculations and output sections;
- distinction between source facts, calculations, interpretations, and assumptions;
- requirement to tie recommendations to data;
- missing-data handling;
- visualization requests only when a chart materially improves understanding.

### Brainstorming

Use for ideas, alternatives, hypotheses, names, plans, or solution options.

Include:

- desired number of ideas when it matters;
- practical constraints and quality criteria;
- grouping when producing more than five ideas;
- short rationale for each idea when useful;
- feasibility, effort, risk, and next step only for decisions requiring implementation.

Avoid heavy scoring matrices for a simple list of ideas.

## Agent-task pattern

Default to the highest useful degree of freedom: tell a capable agent what state to produce, what it may change, and what must remain untouched. Do not prescribe routine commands or decompose obvious repository work into operational steps. Add implementation mechanics only when the exact method changes correctness, safety, or compatibility.

Treat conversation history as evidence for the current brief, not as content to preserve. Include the final active decision and facts needed to execute it. Omit rejected options, deferred ideas, exploratory discussion, and unrelated prior concerns. Do not turn them into non-goals unless they are a plausible and material regression within the active scope.

Apply a closed-world rule when the final request is complete: do not add tests, documentation, schemas, examples, migrations, CI, reporting, cleanup, preflight, blocked handling, or implementation advice just because they are common engineering practice. Keep phrases such as “preserve behavior” at the user's abstraction level. Every added clause must be traceable to the active request.

Use this structure as a menu, not a mandatory template:

```markdown
# Task

<Concrete objective and desired outcome.>

## Context

<Only information needed to make correct decisions.>

## Scope

- <Required work or artifacts.>

## Constraints

- <Only a material hard boundary or compatibility requirement.>

## Success criteria

- <Observable condition proving completion, only when needed.>

## Verification

- <Observable evidence of completion, only when requested or material.>

## Deliverable

<Expected final response or changed artifact.>
```

Omit empty sections. Never add acceptance criteria, verification, tests, CI, reporting, or non-goals solely to fill the template. Do not tell a strong agent to inspect first, follow conventions, choose a minimal solution, run relevant checks, or summarize its work unless the user requested that behavior. For simple Git hygiene, synchronization, cleanup, or other routine work, one imperative paragraph is usually enough. For investigation-only tasks, state that the agent must diagnose and report without modifying files. For implementation tasks, authorize only changes within the stated scope. For tasks involving live systems, external messages, deployment, deletion, or other consequential actions, make authorization boundaries and exact targets explicit without teaching the agent standard commands.

## Optional modules

### Role

Add a role when expertise, perspective, or decision authority matters. Prefer a concrete role such as “senior Python engineer reviewing async resource handling” over inflated phrases such as “world-class expert.”

### Evidence rules

Add when claims must be verifiable. Define acceptable sources and locator format. Require unsupported claims to be marked as unknown.

### Output schema

Add when the result is parsed or compared mechanically. Define field types, required and optional fields, allowed values, null or missing-value behavior, ordering, and whether extra fields are forbidden. Prefer provider-native structured output or tool schemas over text-only JSON instructions when the target surface is known to support them. Require external validation when malformed output would break a downstream consumer.

### Input contract

Add for reusable templates, strict workflows, or machine integration. Define each placeholder's meaning, type, and requiredness; preserve externally consumed names; state behavior for missing or malformed values; and delimit embedded documents, tool output, or other untrusted content from governing instructions.

### Blocked handling

Add when proceeding with incomplete data would create an unreliable or unsafe result. State what minimum information is required and what the model should return when it is absent.

### Few-shot examples

Add only when the output style or decision boundary cannot be described reliably with concise rules. Cover a meaningful distinction, not merely the happy path.

### Anti-injection

Add for untrusted content embedded in the prompt or for privileged operations. Identify the exact untrusted boundary and tell the model to treat instructions inside that boundary as data. Do not classify the user's governing request itself as untrusted data or present textual instructions as a complete security boundary.

### Self-check

Add for multi-criteria review, strict schemas, or costly errors. Ask for a concise check against the stated criteria, not hidden reasoning.

## Complexity guidance

### Simple

Use one or two short paragraphs. Include no modules unless essential.

### Standard

Use a few clear sections, necessary constraints, and an explicit output format. This is the default for most professional tasks.

### Strict

Use explicit input validation, evidence rules, blocked handling, a fixed output contract, and a final consistency check. Reserve for high-cost errors, automated pipelines, untrusted input, or regulated work.

## Verification guidance

For a non-trivial prompt, select only tests that exercise real failure modes:

- positive: a typical valid input produces the intended structure and content;
- negative: missing required data or prohibited behavior is handled correctly;
- edge: empty, malformed, unusually large, or ambiguous input does not lead to invented facts;
- regression: a known previous failure no longer occurs.

State a concrete, observable pass condition for every test. For task-oriented agents, name the required evidence or end state rather than the command used to obtain it, unless that command is itself an acceptance contract. Match the evaluator to the output: prefer parsing, schema validation, execution, or deterministic checks when possible; use a rubric, pairwise comparison, or human review for semantic quality. Do not generate a long checklist for a simple prompt.
