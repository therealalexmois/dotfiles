---
name: create-prompt
description: Create or refine a compact, self-contained one-off task prompt for a capable model or coding agent. Use when the user asks to formulate a specific task for ChatGPT, Claude, Gemini, Codex or Claude Code, including «сделай промпт для Codex» or a quick rewrite of that task prompt. For a reusable prompt, system prompt, production-model prompt or template with a testing checklist, use prompt-design. For an evidence-based review of an existing prompt, use prompt-design in review mode. For continuing work in a new session, use handoff.
metadata:
  version: "1.0"
  origin: first-party
---

# Create Prompt

Give a capable model the context, goal, and completion criteria it cannot infer.
It already knows how to plan, inspect a repository, follow conventions, test, and report.
Omit routine instructions that distract from the requested result.

Use this skill for one-off task prompts for capable models.
Route other requests as follows:

| Request | Skill |
| --- | --- |
| System prompt, reusable template, or prompt for a weaker or production model | `prompt-design` |
| Diagnosis of an existing prompt with findings and a verdict | `prompt-design`, review mode |
| Quick rewrite of a one-off task prompt | This skill |

The other prompt types may need roles, explicit rules, and guardrails omitted here.

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

Adjust only the last phrase to the task type: «приступай к ревью», «приступай к ответу».
Keep both conditions. The question filter avoids unnecessary clarification.
The model decides whether the task needs a visible plan.

For an unattended run, replace part 4 with:

> Сначала проанализируй задачу и контекст. Неоднозначности решай сам; если пришлось что-то допустить, перечисли допущения в конце.

This applies to background tasks, scheduled or cloud routines, `codex exec`, and CI jobs.
List assumptions only when made. An unconditional list adds noise to messages such as scheduled reminders.
Omit part 4 only at the user's request.

## Optional sections

Add a section only when the request makes it necessary:

- **Ограничения** — a hard boundary the user stated, or exact targets for a destructive or irreversible action (what may be deleted, which environment, what must stay untouched).
- **Формат ответа** — the user specified a format too long for one line in the success criteria, or the output will be parsed by a program (then define it exactly).

Do not add a role, examples, step-by-step procedures, commands, self-check sections, or boilerplate such as «не галлюцинируй» or «думай шаг за шагом» unless the user asked for them or the exact method is part of the contract.

## Filling the parts

### Context: the active state only

Use the conversation's current decision:

- Include accepted decisions, exact identifiers, and required facts.
- Omit rejected alternatives, superseded decisions, deferred work, and exploratory ideas.
- Turn a discarded option into a prohibition only if the target model might reintroduce it in this task.
- Replace "as discussed above" with the actual content. The prompt must work in a fresh session.

A coding agent reads the repository itself, so give it paths, not file contents. A web model sees only the prompt and attachments, so put the source material into the prompt or say explicitly what is attached.

### Task: the outcome, not the procedure

State what should exist or be true afterwards. Keep the user's phrasing at its original level of abstraction: «сохрани текущее поведение» stays as is, not expanded into guessed invariants. Specify a mechanism (command, algorithm, sequence) only when the user requested it, it is part of the contract, or plausible approaches lead to materially different outcomes.

### Success criteria: verifiable, and marked when they are yours

Use the user's criteria as stated. If none are given, propose 1-3 criteria.
Each must describe an observable end state:

- code, repository, or data state;
- behavior that can be triggered;
- presence and format of the requested output.

"The code is clean" and «задача выполнена качественно» are not verifiable criteria.
A criterion may check the requested result, such as "existing tests pass".
It must not add unrequested tests, documentation, CI changes, or reports.
Write criteria as states, not commands.

Mark proposed criteria after the code block so the prompt remains ready to copy:

> Критерии успеха предложены мной - проверь перед отправкой.

If you added criteria to the user's list, name only the additions: «Критерий 3 добавлен мной».

## Before drafting

Start as soon as the goal is clear, and infer the rest from the request and conversation. Ask the user 1–3 questions only when you cannot write the prompt without the answer, for example when source material or the end state is missing. Leave ambiguities the target model can resolve by asking to part 4 instead of resolving them yourself. If the user wants the prompt right away, state the assumption in one line and proceed.

## Refining an existing prompt

Rebuild a task prompt into the four parts. Keep every real requirement and the user's terminology; drop roles, generic rules, routine procedures, and boilerplate. Return the full updated prompt unless the user asked for a diff, followed by one line listing what was removed.

If the prompt is a system prompt or a reusable template, do not restructure it into the four parts. Route the request to `prompt-design`. For an evidence-based review of a supplied prompt, route to the review mode of `prompt-design`.

## Response

Return the prompt in a Markdown code block. Outside the block, add only what applies: a one-line assumption that changes the prompt, the criteria marking, the list of removed items when refining. Use four backticks around the prompt when it contains a code block itself. Write the prompt in the language of the user's request unless they ask for another.

## Final check

Reread the prompt as the target model would, without this conversation:

- It can act on the prompt alone.
- Every line traces to the user's request or to a fact the task needs; delete the rest.
- Every success criterion can be checked by looking at the result, and criteria you wrote are marked.
- The task is stated as an outcome, without routine commands.
- Part 4 matches the run mode: interactive or unattended.
