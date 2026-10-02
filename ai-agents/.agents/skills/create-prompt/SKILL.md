---
name: create-prompt
description: Create or refine a compact, self-contained one-off task prompt for a capable model or coding agent. Use when the user asks to formulate a specific task for ChatGPT, Claude, Gemini, Codex or Claude Code, including «сделай промпт для Codex» or a quick rewrite of that task prompt. For a reusable prompt, system prompt, production-model prompt or template with a testing checklist, use prompt-design. For an evidence-based review of an existing prompt, use prompt-review. For continuing work in a new session, use handoff.
metadata:
  version: "1.0"
  origin: first-party
---

# Create Prompt

Target models are strong. They already know how to plan, inspect a repository, follow conventions, test, and report. A prompt only has to give them what they cannot know on their own: the context, the goal, and how to tell the job is done. Everything else is overhead: it dilutes the signal and pushes the model to optimize for things the user never asked for.

This skill covers one-off task prompts for such models. System prompts, prompts for weaker or production models, and reusable templates need roles, explicit rules, and guardrails that this skill deliberately strips. Use `prompt-design` for those. If the user wants a diagnosis of an existing prompt with findings and a verdict, use `prompt-review`; a quick rewrite of a one-off task prompt stays here.

## Default structure

Use exactly these four parts, in this order:

1. **Контекст** — facts the target model needs and cannot infer: project, current state, decisions already made, exact identifiers (paths, branches, tickets, names), source material.
2. **Задача** — what to do, in 2–5 sentences. The outcome, not the procedure.
3. **Критерии успеха** — 1–4 verifiable end states that show the job is done.
4. **Порядок работы** — the analyze-then-ask instruction below.

Name the sections in the language of the prompt (English: Context / Task / Success criteria / How to proceed). If there is nothing to say in the context beyond what the task already states, omit the section instead of restating the task.

Canonical wording for part 4:

- RU: «Сначала проанализируй задачу и контекст. Показывать ли план, реши по сложности задачи. Если есть вопросы, от ответов на которые зависит результат, задай их и дождись ответа. Если вопросов нет, приступай к реализации.»
- EN: "First, analyze the task and context; decide from its complexity whether to show a plan. If you have questions whose answers would change the result, ask them and wait for my reply. If you have none, proceed with the implementation."

Adjust only the last phrase to the task type («приступай к ревью», «приступай к ответу»). Both conditions earn their place: the filter stops the model asking what it could decide itself, and leaving plan visibility to the model keeps that overhead out of the answer.

If nobody will answer questions during the run — a background task, a scheduled or cloud routine, `codex exec`, a CI job — replace part 4 with: «Сначала проанализируй задачу и контекст. Неоднозначности решай сам; если пришлось что-то допустить, перечисли допущения в конце.» Keep that list conditional: when the output goes to a person, such as a scheduled reminder, an unconditional one is noise in every run. Omit part 4 only when the user asks.

## Optional sections

Add a section only when the request makes it necessary:

- **Ограничения** — a hard boundary the user stated, or exact targets for a destructive or irreversible action (what may be deleted, which environment, what must stay untouched).
- **Формат ответа** — the user specified a format too long for one line in the success criteria, or the output will be parsed by a program (then define it exactly).

Do not add a role, examples, step-by-step procedures, commands, self-check sections, or boilerplate such as «не галлюцинируй» or «думай шаг за шагом» unless the user asked for them or the exact method is part of the contract.

## Filling the parts

### Context: the active state only

When the source is a conversation, use the current decision, not the transcript. Include accepted decisions, exact identifiers, and facts the task depends on. Omit rejected alternatives, superseded decisions, deferred work, and exploratory ideas. Do not turn discarded options into "don't do X" lines unless the target model would plausibly reintroduce them within this task. Replace references like "as discussed above" with the actual content, because the prompt will be pasted into a fresh session.

A coding agent reads the repository itself, so give it paths, not file contents. A web model sees only the prompt and attachments, so put the source material into the prompt or say explicitly what is attached.

### Task: the outcome, not the procedure

State what should exist or be true afterwards. Keep the user's phrasing at its original level of abstraction: «сохрани текущее поведение» stays as is, not expanded into guessed invariants. Specify a mechanism (command, algorithm, sequence) only when the user requested it, it is part of the contract, or plausible approaches lead to materially different outcomes.

### Success criteria: verifiable, and marked when they are yours

If the user gave criteria, use them as stated. If not, write 1–3 criteria yourself. Each must be checkable by looking at the result: a state of the code, repository, or data, a behavior that can be triggered, the presence and shape of a requested output. "The code is clean" or «задача выполнена качественно» is not a criterion. A criterion may name a check of the requested result, such as "existing tests pass", but must not add new work the user did not ask for: writing tests, documentation, CI changes, reports. Phrase criteria as states, not as commands.

Criteria you wrote are proposals, and the user should see that before sending the prompt. Mark them after the code block, not inside the prompt, so the prompt stays ready to copy: «Критерии успеха предложены мной — проверь перед отправкой.» If the user gave some criteria and you added others, name the added ones: «Критерий 3 добавлен мной».

## Before drafting

Start as soon as the goal is clear, and infer the rest from the request and conversation. Ask the user 1–3 questions only when you cannot write the prompt without the answer, for example when source material or the end state is missing. Leave ambiguities the target model can resolve by asking to part 4 instead of resolving them yourself. If the user wants the prompt right away, state the assumption in one line and proceed.

## Refining an existing prompt

Rebuild a task prompt into the four parts. Keep every real requirement and the user's terminology; drop roles, generic rules, routine procedures, and boilerplate. Return the full updated prompt unless the user asked for a diff, followed by one line listing what was removed.

If the prompt is a system prompt or a reusable template, do not restructure it into the four parts. Route the request to `prompt-design`. For an evidence-based review of a supplied prompt, route to `prompt-review`.

## Response

Return the prompt in a Markdown code block. Outside the block, add only what applies: a one-line assumption that changes the prompt, the criteria marking, the list of removed items when refining. Use four backticks around the prompt when it contains a code block itself. Write the prompt in the language of the user's request unless they ask for another.

## Final check

Reread the prompt as the target model would, without this conversation:

- It can act on the prompt alone.
- Every line traces to the user's request or to a fact the task needs; delete the rest.
- Every success criterion can be checked by looking at the result, and criteria you wrote are marked.
- The task is stated as an outcome, without routine commands.
- Part 4 matches the run mode: interactive or unattended.
