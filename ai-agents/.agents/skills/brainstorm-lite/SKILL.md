---
name: brainstorm-lite
description: Lightweight brainstorming workflow for small and medium engineering tasks. Use before implementation to clarify a feature idea, compare 2 approaches, plan a small or medium code change, or decide between options instead of jumping straight into code. Not for large architecture redesigns, security-sensitive changes, database schema migrations, public API contract changes, or multi-service work.
---

# brainstorm-lite

A lightweight, pre-implementation brainstorming workflow. Its job is to turn a
small or medium task into a clear, agreed direction before any code is written.
It keeps just enough structure to make a good decision and nothing more.

## When to use

Use this skill before implementation when the user wants to:

- clarify a feature idea;
- compare possible implementation approaches;
- plan a small or medium code change;
- decide between 2–3 options;
- avoid jumping directly into coding.

## When not to use (non-goals)

Do not use this skill for:

- large architecture redesigns;
- security-sensitive changes;
- database schema migrations;
- public API contract changes;
- multi-service changes;
- tasks that require a formal design document.

For any of these, stop and recommend a heavier spec/design workflow instead
(see "Escalation").

## Workflow

1. **Restate** — Summarize the task in 1–3 sentences so the user can confirm
   you understood it.
2. **Clarify (only if needed)** — If intent, constraints, or success criteria
   are unclear, ask up to 3 focused questions. Ask them in a single batch,
   prefer multiple-choice. If the request is already clear, skip this step.
3. **Propose** — Present exactly 2 implementation approaches. For each:
   - **Idea** — what it is, in a short paragraph;
   - **Benefits** — main upsides;
   - **Risks** — main downsides or unknowns;
   - **When to choose it** — the situation it fits best.
4. **Recommend** — Pick one approach and say why in one or two sentences.
5. **Get approval** — Ask for explicit approval before any implementation.
6. **Stop** — Do not write code, scaffold files, or take implementation action
   until the user approves a direction.

## Output format

Reply in this shape:

```
Task: <1–3 sentence restatement>

Questions (if any):
1. ...
2. ...
3. ...

Approach A — <name>
- Idea: ...
- Benefits: ...
- Risks: ...
- When to choose: ...

Approach B — <name>
- Idea: ...
- Benefits: ...
- Risks: ...
- When to choose: ...

Recommendation: <A or B> — <why in 1–2 sentences>

Approve this direction before I start implementing?
```

## Rules

- Do not write code or create files before the user approves a direction.
- Do not produce a formal design document unless the user explicitly asks.
- Keep the conversation lightweight; scale depth to the size of the task.
- Prefer one batched round of questions over drip-feeding them.

## Escalation

If, while restating or clarifying, the task turns out to be a non-goal
(large architecture redesign, security-sensitive change, schema migration,
public API contract change, or multi-service change), do not continue this
lightweight flow. Tell the user the task needs a heavier spec/design workflow
and recommend switching to it.
