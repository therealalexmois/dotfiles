---
name: <skill-name>
description: >
  <What the skill does>. Use when <real trigger cases>. Do not use for
  <neighbor intent or important exclusion>.
---

# <Skill Name>

## Purpose

<One bounded context and one primary user intent.>

## When to use

- <Trigger phrase or context.>

## When not to use

- <Neighbor task.>

## Inputs

- <Required input.>

## Source policy

Allowed:

- explicit user input;
- attached files;
- tool output from the current run.

Forbidden:

- guessing missing data;
- treating examples as current state;
- reading unrelated sources.

## Workflow

1. <Observable step.>
2. <Observable step.>
3. <Validation step.>

## Decision rules

- If <condition>, <decision>.

## Guardrails

- Do not <concrete forbidden behavior>.

## Tool policy

- Use `<tool>` for <purpose> when <trigger>.
- If the tool fails, <fallback>.

## Write policy

Allowed:

- <Target or `none`>.

Forbidden:

- <Target>.

## Output contract

Return:

1. <Required field>;
2. <Required field>.

## Validation checklist

- Workflow completed.
- No forbidden side effect occurred.
- Output contract is satisfied.

## References

- Read `<reference>` when <trigger>.
