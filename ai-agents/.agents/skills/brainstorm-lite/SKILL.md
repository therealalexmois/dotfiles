---
name: brainstorm-lite
description: "Lightweight brainstorming for small and medium engineering decisions: clarify a feature idea, compare implementation approaches, or choose a direction before coding. Use brainstorming for large architecture redesigns, security-sensitive changes, database migrations, public API contract changes, and multi-service work."
metadata:
  version: "1.0"
  origin: first-party
---

# brainstorm-lite

A lightweight, pre-implementation brainstorming workflow. Its job is to turn a
small or medium task into a clear direction before implementation.
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

For these, use `brainstorming` and its proportionate design workflow.

## Workflow

1. **Understand** - Summarize the task briefly only when this helps expose a decision or assumption.
2. **Clarify (only if needed)** - If intent, constraints, or success criteria
   are unclear, ask up to 3 focused questions. Ask them in a single batch,
   prefer multiple-choice. If the request is already clear, skip this step.
3. **Compare** - Present meaningful approaches when there is a real choice. For each, note the idea, benefits, risks, and fit. Do not invent a second approach just to fill a template.
4. **Recommend** - Pick a direction and explain why briefly.
5. **Continue** - Implement if the user's request already authorizes it and no material decision remains. Ask only when the answer changes the result or the next action needs separate authorization.

## Output format

When comparison is useful, reply in this shape:

```
Task: <1–3 sentence restatement>

Questions (if any):
1. ...
2. ...
3. ...

Approach A - <name>
- Idea: ...
- Benefits: ...
- Risks: ...
- When to choose: ...

Approach B - <name>
- Idea: ...
- Benefits: ...
- Risks: ...
- When to choose: ...

Recommendation: <A or B> - <why in 1-2 sentences>
```

## Rules

- Do not turn a clear, authorized implementation into a separate approval workflow.
- Do not produce a formal design document unless the user explicitly asks.
- Keep the conversation lightweight; scale depth to the size of the task.
- Prefer one batched round of questions over drip-feeding them.

## Escalation

If the task turns out to involve a large architecture redesign, security-sensitive change, schema migration, public API contract change, or multiple services, switch to `brainstorming`. Carry over context already gathered instead of restarting the conversation.
