---
name: draft-in-alex-style
description: Draft and edit Russian text in Alex's confirmed writing style. Use for technical messages, RFC and design documents, reviews, Jira tasks, status updates, prompts, and concise professional correspondence when the user asks to write, rewrite, polish, shorten, or adapt text in their style. Do not use for code or exact quotations unless explicitly requested.
---

# Draft in Alex's Style

Write in Russian by default. Produce the requested draft directly without explaining the writing process.

## Choose the Mode

Use polished technical mode by default:

- Write formally, directly, and concisely.
- Start with the requested action, result, problem, or decision.
- State the conclusion first, then the supporting fact and its main consequence.
- Use short paragraphs, compact lists, and only necessary Markdown.

Use conversational reasoning mode only for brainstorming, exploratory dialogue, or when the user asks to preserve spoken phrasing:

- Develop the thought through concrete examples and explicit clarification.
- Allow natural transitions such as «смотри», «то есть» and «например» when they help the reasoning.
- Keep useful self-corrections, but remove excessive repetition and transcript noise.

## Apply the Style

- Keep one root idea per paragraph, comment, or list item.
- Prefer concrete component, artifact, and process names over vague abstractions.
- Preserve established English technical terms when translation would reduce precision or sound artificial.
- Prefer Russian terms for a Russian audience when the English term is unnecessary.
- State disagreement directly and support it with a technical argument.
- Preserve the causal link between the current behavior and its consequence when shortening the text.
- Keep only the consequence needed to justify the requested action. Add an example only when the problem is not obvious.
- Recommend one preferred solution. Mention alternatives only when there is a real choice.
- Use a direct imperative for a confirmed correction: `Добавь`, `Обнови`, `Исправь`, or `Перенеси`.
- Use `Я бы` only for a recommendation when several valid solutions exist.
- Match certainty to evidence. Do not soften a confirmed defect or present an assumption as a fact.
- When requesting verification, describe a reachable scenario and the expected result, not the test implementation.
- Base technical claims on states allowed by the actual contract. Distinguish observed behavior, contractual behavior, assumptions, and defense in depth.
- Use measurable outcomes and verifiable criteria where the context supports them.
- Keep recommendations practical and consistent with KISS and YAGNI.
- For strategic choices, give two to four viable options, risks, and a recommended choice.
- For technical tasks, give the best working option first and alternatives briefly.

## Preserve and Remove

Preserve:

- the user's terminology and explicit distinctions;
- stated constraints, priorities, and scope boundaries;
- factual uncertainty and open questions;
- the intended level of technical precision.

Remove:

- filler, motivational language, empty praise, and bureaucratic phrasing;
- repeated ideas, accidental digressions, and unnecessary introductions;
- spelling errors and artifacts of dictated speech;
- unsupported claims, invented facts, recipients, commitments, or deadlines.

Do not reuse details from past projects unless the user explicitly asks for continuity.

## Structure Common Drafts

- Architecture critique: requested action or conclusion → evidence → main consequence or uncovered risk.
- Task: objective → required scope → success criteria.
- Decision: recommendation → reasons → risks and short alternatives.
- Status update: completed work → remaining risks or blockers → next action.
- Review request: artifact and focus → review priorities → output constraints.
- Prompt: task → necessary context → constraints → expected output.

Ask a question only when a missing choice materially changes the result. Otherwise, make a conservative assumption and deliver the draft.
