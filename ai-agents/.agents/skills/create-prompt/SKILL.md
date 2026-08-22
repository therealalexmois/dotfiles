---
name: create-prompt
description: Create or refine a self-contained prompt from an abstract request for a web-based language model or a task-oriented coding agent such as Codex or Claude Code. Use when the user asks to write, generate, formulate, structure, improve, or adapt a prompt; turn an idea into a model-ready instruction; or prepare an agent task with explicit scope and success criteria.
---

# Create Prompt

Turn the user's intent into the shortest prompt that reliably solves the stated task. Preserve the user's scope and terminology. Do not add requirements merely to make the prompt look complete.

## 1. Establish the Brief

Require only a clear goal before starting. Infer safe details from the request and supplied artifacts.

Ask one to three focused questions only when missing information would materially change the prompt. Prioritize:

- target surface: web model or task-oriented agent;
- input or source material;
- expected result and format;
- hard constraints and success criteria.

Before drafting, privately identify the failure modes that could prevent a correct result. Check for ambiguous goals, conflicting instructions, missing required inputs, unclear scope, unverifiable success criteria, brittle output contracts, and model- or environment-specific assumptions. Resolve only the failure modes that are plausible for the stated task.

Do not ask for every possible field. Do not couple clarification to a particular interaction tool. If the user requests immediate output, state essential assumptions briefly and continue.

For ambiguous, high-impact requests, first summarize the interpreted goal, constraints, input, and expected result, then obtain confirmation. For narrow requests, proceed directly.

### Select the Active Context

When the source is a conversation, build the prompt from the current effective decision, not from the transcript as a whole. Privately separate:

- active requirements: the latest requested goal, accepted decisions, necessary constraints, and exact targets;
- supporting facts: only context the target model needs to act correctly;
- inactive context: rejected alternatives, superseded decisions, deferred work, exploratory ideas, and incidental discussion.

Include active requirements and only necessary supporting facts. Omit inactive context entirely. Do not convert every rejected or deferred idea into a negative instruction such as “do not add X.” Include a non-goal only when the target model could plausibly reintroduce it while completing the active task and doing so would materially change the result. Mere mention earlier in the conversation is not evidence of relevance.

Do not invent acceptance criteria, quality gates, tests, CI steps, review stages, reports, constraints, or deliverables. Include a success criterion only when the user supplied it, it directly restates the requested end state, or it distinguishes materially different outcomes. A simple task normally needs one concise completion state, not a checklist.

Use a closed-world brief for a complete final request: only explicitly active requirements and indispensable identifiers may appear. Do not enrich the task with normal engineering practice. Repository inspection, tests, documentation, schemas, examples, migrations, CI, reporting, cleanup, error handling, compatibility work, and blocked behavior are absent unless the active request requires them. The target agent may still choose these actions under its own instructions; the prompt must not prescribe or require them.

Before returning the prompt, perform a traceability pass. Every action, constraint, artifact, check, and requested output must map to an explicit active requirement or to one fact without which that requirement is ambiguous. Delete anything justified only by “good practice,” safety theater, completeness, or earlier discussion. Preserve a user phrase such as “сохрани текущее поведение” at its original abstraction level instead of expanding it into guessed invariants.

## 2. Choose the Target Surface

### Web model

Create a prompt intended for a chat interface such as ChatGPT, Claude, or Gemini. Prefer one self-contained user prompt unless the user explicitly needs separate system and user prompts.

Include only the sections needed from:

- task;
- necessary context;
- input or source;
- constraints;
- expected output;
- success criteria.

Adapt to a named model when relevant. Otherwise use clear, model-agnostic Markdown.

### Task-oriented agent

Create an executable task brief for an agent such as Codex or Claude Code. Include, when applicable:

- objective and relevant context;
- artifacts or workspace scope;
- required changes or investigation;
- explicit boundaries and non-goals;
- expected deliverables;
- success criteria and verification.

Treat this list as optional. Do not add a deliverable, success criterion, or verification section merely because the template offers one.

Do not instruct a strong agent to inspect the repository, follow project conventions, choose a minimal implementation, add tests, run checks, or report changes. These are normal agent behaviors, not task requirements, unless the user explicitly made one of them part of the requested result.

Assume a task-oriented coding agent already knows standard shell, Git, testing, and repository-inspection mechanics. Write at the level of the desired outcome, boundaries, and observable completion state. Do not translate ordinary goals into commands, tool names, step-by-step procedures, generic preflight checks, or implementation details.

Specify a mechanism only when at least one of these is true:

- the user explicitly requested it;
- the exact command, tool, algorithm, file format, or sequence is part of the contract;
- multiple plausible approaches have materially different outcomes;
- a fragile or destructive action needs exact targets, ordering, or safety limits.

State verification as an invariant such as “local `main` matches `origin/main` and the worktree is clean,” not as commands that produce the evidence. Preserve exact branch names, paths, PR numbers, and protected scope when they prevent the agent from touching the wrong target.

For example, “Update local `main` to `origin/main` and remove only the worktrees and branches from this task” is normally sufficient. Do not expand it into `git fetch`, `git pull`, `git status`, or `git worktree` commands unless the user asks for commands or the method itself is constrained.

## 3. Select the Minimum Necessary Pattern

Classify the task internally and load [references/prompt-patterns.md](references/prompt-patterns.md) only when the task is non-trivial, works with documents or data, requires a strict output contract, or targets an agent.

Load [references/prompt-evaluation.md](references/prompt-evaluation.md) only when the prompt is reusable, production-facing, being optimized or migrated between models, evaluated against a dataset, or has costly and plausible failure modes.

Use optional prompt elements only when justified:

- Add a role only when a specific expertise or viewpoint changes the result.
- Add examples only when rules alone do not define the expected output reliably.
- Add a schema only when the output must be fixed or machine-readable.
- Add evidence and citation rules for factual review, document analysis, or high-stakes work.
- Add blocked handling when missing data must stop execution rather than invite guessing.
- Add anti-injection rules only for untrusted content or privileged operations.
- Request concise rationale, assumptions, checks, or a verdict when they are useful; never request private chain-of-thought.

Avoid decorative sections, inflated roles, repeated instructions, and platform-specific syntax without a concrete reason.

## 4. Make the Prompt Self-Contained

Ensure the final prompt can be copied into a new chat or agent session without access to this conversation. Self-contained means sufficient for the active task, not a summary of the entire discussion or decision history.

Include all critical context, constraints, definitions, input instructions, expected output, and success criteria. Replace references such as “as discussed above” with the actual information. Use placeholders only for values the user will supply later, and label them clearly.

For prompt templates, define the input contract when it is not obvious: list required and optional placeholders, preserve integration-sensitive names, state missing-value behavior, and separate untrusted content from governing instructions. Do not turn ordinary user instructions into inert data.

For prompts grounded in supplied facts, require the target model to distinguish facts, calculations, interpretations, assumptions, and hypotheses. Require it to identify missing information instead of inventing it.

## 5. Refine Existing Prompts

When improving an existing prompt:

1. Extract the requested changes.
2. Preserve unaffected requirements and terminology.
3. Resolve or surface conflicts between old and new requirements.
4. Rewrite only as much as needed for a coherent final prompt.
5. Return the complete updated prompt unless the user explicitly asks for a diff.

## 6. Return an Adaptive Result

For a simple, well-specified request, return only the ready-to-copy prompt in a code block.

For a task-oriented agent, also return only the ready-to-copy prompt by default. Do not append an assumptions note, rationale, verification checklist, or usage guidance unless the user requests it or a missing decision prevents a correct prompt.

For a standard request, return:

1. a brief assumptions note only if assumptions were necessary;
2. the ready-to-copy prompt;
3. a short verification checklist when mistakes are plausible or costly.

For a complex or strict request, return:

1. a concise brief recap;
2. the ready-to-copy prompt;
3. concrete positive, negative, edge, and relevant regression test cases with pass criteria.

Do not expose internal classification or rejected prompt modules unless the user asks for the design rationale.

Write the response in the language of the user's request. Put the final prompt in a Markdown code block. If the prompt itself contains triple-backtick code blocks, wrap the whole prompt in four backticks.

## 7. Check Before Sending

Verify that:

- the prompt covers every stated goal and constraint;
- no unsupported requirements were added;
- no rejected, superseded, deferred, exploratory, or incidental context was carried into the prompt without material need;
- no invented acceptance criteria, tests, quality gates, reports, or deliverables were added;
- every action, constraint, artifact, check, and requested output is traceable to the active brief;
- the level of detail matches the task's complexity;
- the expected output is unambiguous;
- placeholders and machine-consumed fields have an explicit, non-breaking contract;
- the prompt is self-contained;
- factual tasks handle missing evidence safely;
- verification targets plausible failure modes and uses observable pass criteria;
- agent tasks define boundaries, deliverables, and verification without unnecessary micromanagement.
- task-oriented prompts contain no commands or routine implementation mechanics that a capable agent can choose safely on its own.
- negative instructions address a plausible in-scope failure rather than memorializing discarded discussion.
- ordinary engineering behavior was left to the target agent instead of being promoted into requirements.
