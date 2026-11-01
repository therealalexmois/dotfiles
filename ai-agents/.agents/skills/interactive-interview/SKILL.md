---
name: interactive-interview
description: Conduct a structured, multi-turn interview with tappable answers through the environment's structured-question tool (ask_user_input_v0 in Claude.ai, AskUserQuestion in Claude Code, request_user_input in Codex), falling back to a compact text mode where no such tool exists. Use when the user explicitly asks to conduct an interview, questionnaire, assessment, or discovery session, asks to be asked a number of questions, or invokes $interactive-interview. Do not use for an ordinary one-off clarification, a factual question, or a simple A-versus-B recommendation.
metadata:
  version: "1.0"
  origin: first-party
---

# Interactive Interview

Conduct the interview yourself; do not write a prompt for another agent to conduct it.

An interview is worth running only while the answers change the result. Treat the question count as a budget, not a quota: padding to reach it tires the user and dilutes the deliverable with noise.

## Set up

Extract the following from the request and context:

- purpose and topic;
- question budget;
- expected deliverable;
- known facts.

Use facts from the request, conversation, available memory, and project context.
Do not ask for facts already known.

If no count is given, choose a budget:

- narrow decision: roughly 5-7 questions;
- discovery: roughly 10-15 questions.

Show the budget in the first progress line. The user can change it.
Do not ask a setup question about depth.
Ask one only if the topic or deliverable is unclear; exclude it from the budget.

## Choose the channel

Use the structured-question tool the environment exposes and follow its actual schema. The notes below help you recognize the tools, but the live schema wins when they disagree.

| Environment | Tool | Limits and free text |
| --- | --- | --- |
| Claude.ai | `ask_user_input_v0` | 1–3 questions per call, 2–4 options; `single_select`, `multi_select`, `rank_priorities`; no free-text field |
| Claude Code | `AskUserQuestion` | 1–4 questions per call, 2–4 options, short `header`; an "Other" free-text answer is added automatically; unavailable in subagents |
| Codex | `request_user_input` | Plan mode only as of early 2026; per-question free text; unavailable in `codex exec` |

If no structured-question tool is available, switch to text mode without asking permission.
This may apply in ChatGPT, Codex outside Plan mode, or a raw API session.
Say once: «Интерактивного виджета здесь нет, веду интервью текстом.»

Keep the same batches and rules. Use:

- numbered questions;
- lettered options;
- one answer instruction: «Ответ: 1б, 2ав, 3 - свой вариант».

Never print tool-call JSON, pseudo-calls, or instructions for someone else to invoke a tool, and never claim a widget was shown when it was not.

If the session cannot receive answers at all (`codex exec`, a background or scheduled run, a subagent), do not start. Say that the interview needs an interactive session.

If a tool call returns empty answers the user never saw (a known Claude Code issue when the tool is called right after a skill loads), do not record them. Retry once, then switch to text mode.

## Run the interview

1. Track the budget, questions asked, answers, covered dimensions, and open information.
2. Ask at most three independent questions per call, even if the tool accepts more.
   Defer questions whose wording or options depend on an unanswered question.
   A batch may contain only one question.
3. Before each batch, write one progress line: «Вопросы 4–6 из 15» (or «из ~10» when you chose the budget).
4. End the turn right after the batch, with no analysis after it.
5. On the next turn, incorporate the answers, update the state, and present the next batch.

Do not interpret answers during the interview except when:

- an answer contradicts an earlier one;
- the next questions depend on your interpretation rather than a direct answer.

In either case, add one line «Понял так: …» before the batch.
This lets the user correct an interpretation before it shapes later questions.

Stop when one of these happens:

- The remaining budget would not change the deliverable. Offer the choice: «Для результата хватает. Осталось N вопросов — продолжить или перейти к итогу?» This question does not count. Never stop silently and never pad to reach the count.
- The budget is exhausted.
- The user asks to stop early («хватит, давай итог»). Go to the deliverable and name the gaps.

If the user changes the budget, update the remaining count without repeating or discarding completed questions. A skipped question counts as asked; record its answer as unknown.

## Design each question

- Ask only questions whose answers can materially change the result, one preference, constraint, fact, or trade-off per question.
- Give 2–4 short, distinct, non-overlapping options without leading wording. Use `single_select` only for mutually exclusive answers and `multi_select` otherwise. For trade-offs («что важнее») use ranking where the tool supports it: with multi-select, users tend to tick everything.
- The option set frames the answer: users pick the nearest option even when the truth lies outside. When the real answer may be outside the options, rely on the tool's built-in free text; where there is none (`ask_user_input_v0`), make the last option «Другое — напишу». If the user picks it without text, ask for the text in one line on the next turn; it is still the same question.
- Ask questions that options would distort («опиши проблему», «приведи пример») in plain text, alone in their turn, counted in the budget. Keep them rare, usually one or two per interview. If most questions need free text, the widget format does not fit this interview; say so.
- Do not mark options as recommended: the interview collects the user's view, not agreement with yours.
- Match the user's language.

## Deliverable

Produce the requested deliverable. If none was specified, return a concise synthesis: goals, constraints, preferences, open questions, and the most useful next step.

Keep provenance visible. Separate what the user chose or wrote from what you inferred, and mark inferences as such. List unknown and skipped answers as gaps; do not fill them with assumptions.
