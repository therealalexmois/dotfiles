# <Instruction name>

## Purpose

<Какое поведение задает инструкция.>

## When to use

- <Trigger.>

## When not to use

- <Neighbor intent or excluded task.>

## Terms

- `<Term>` – <один точный смысл>.

## Inputs

- <Required input.>

## Source policy

Allowed:

- <Source.>

Forbidden:

- guessing missing data;
- treating examples as current state.

## Rules

- <Command.>
- If <condition>, <action>.
- Do not <forbidden action>.

## Tool policy

- Use `<tool>` for <purpose> when <trigger>.
- If the tool fails, <fallback>.

## Write policy

Allowed:

- <Target.>

Forbidden:

- <Target.>

Before writing:

1. Read the target.
2. Check conflicts and duplicates.
3. Write only allowed content.
4. Re-read and validate.

## Output contract

Return:

1. <Field>;
2. <Field>.

Do not include:

- internal reasoning;
- unrelated suggestions.

## Validation

- Scope matches the request.
- No facts were invented.
- Output contract is satisfied.
- Failures and skipped checks are reported.
