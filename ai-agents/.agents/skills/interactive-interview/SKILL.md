---
name: interactive-interview
description: Conduct a structured, multi-turn interview through the web interface's interactive user-input widget, with tappable single-select or multi-select answers and an optional free-text response. Use when the user explicitly asks to conduct an interview, questionnaire, assessment, discovery session, or to ask a specified number of questions. Also use when explicitly invoked as $interactive-interview. Do not use for an ordinary one-off clarification, a factual question, or a simple A-versus-B recommendation.
---

# Interactive Interview

Conduct the interview directly. Do not generate a prompt that asks another agent to conduct it.

## Establish the contract

Extract from the request:

- interview purpose and topic;
- exact question count;
- requested final deliverable;
- already known facts that must not be asked again.

Infer missing details when safe. If the question count is absent, ask one preliminary setup question through the interactive widget with several depth choices. Do not count this setup question toward the interview. Ask additional setup questions only when the topic or intended result is genuinely unclear.

## Run the interview

1. Track the target count, questions already presented, answers received, covered dimensions, and unresolved information.
2. Plan the next useful dimensions, but generate only the current batch so later questions can adapt to earlier answers.
3. Present at most three interview questions per widget call. Use `min(3, remaining_questions)` for the batch size.
4. Before each widget, write only a brief progress line such as `Вопросы 4–6 из 15.`
5. Use an interactive user-input widget that the current agent can actually render, preferably `ask_user_input`. Follow the exposed widget schema exactly.
6. End the turn immediately after presenting the widget. Do not add analysis or conclusions after it.
7. On the next turn, incorporate selected options and free-text details, update progress, and present the next batch.
8. Continue until exactly the requested number of interview questions has been presented. Treat an explicitly skipped question as asked and record its answer as unknown.
9. After the final answers arrive, produce the requested deliverable. If none was specified, return a concise synthesis of goals, constraints, preferences, uncertainties, and the most useful next step.

If the user changes the target count during the interview, update the remaining count without repeating or discarding completed questions.

## Design each question

- Ask only questions whose answers can materially change the final result.
- Cover one concrete preference, constraint, fact, or trade-off per question.
- Do not repeat information already supplied by the user or established earlier in the interview.
- Use short, distinct options: normally two to four, and more only when the choice space requires it.
- Use `single_select` only for mutually exclusive answers; otherwise use `multi_select`.
- Keep a specific free-text answer available when the widget supports it.
- Avoid vague umbrella questions, overlapping options, leading wording, and options that merely restate candidate recommendations.
- Do not label an option as recommended unless the user is explicitly choosing an action and a recommendation is necessary.
- Match the language of the user.

## Preserve interaction integrity

- Never replace the widget with a Markdown list, numbered questionnaire, or prose questions.
- Invoke or insert the real widget. Never print its JSON arguments, schema, code block, pseudo-call, or instructions for another agent to invoke it.
- Never present more than three questions in one widget call, even if the interface accepts more.
- Never claim that a widget was used if it was not rendered.
- Never silently reduce the requested question count.
- Do not provide intermediate interpretation unless the user explicitly requests it.

If the current agent cannot render an interactive user-input widget, stop before asking any interview question and say concisely that the interactive widget is unavailable in the current interface. Do not delegate the call, expose a payload for manual execution, or fall back to text questions unless the user explicitly authorizes that fallback.
