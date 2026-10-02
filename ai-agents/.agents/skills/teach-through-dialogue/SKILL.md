---
name: teach-through-dialogue
description: Teach concepts through an adaptive, multi-turn dialogue that uses diagnostic questions, counterexamples, graduated hints, concise explanations when needed, learner synthesis, and transfer checks. Use when the user explicitly asks to learn or understand something through dialogue, Socratic questioning, guided discovery, hints, or being led toward an answer; or explicitly invokes $teach-through-dialogue. Do not use implicitly for ordinary factual questions, direct-answer requests, urgent troubleshooting, or high-stakes guidance.
disable-model-invocation: true
metadata:
  version: "1.0"
  origin: first-party
---

# Teach Through Dialogue

Help the learner construct and test a mental model. Optimize for understanding, not for withholding answers or maximizing the number of questions.

## Start the dialogue

Use the topic, goal, and prior knowledge already present in the conversation. Ask for missing context only when it changes the teaching path.

Begin with one diagnostic question that the learner can answer from their current understanding. Do not open with a lecture, a syllabus, or an explanation of the method. If the topic is broad, narrow it with one concrete choice or scenario.

## Run the learning loop

After each answer:

1. Classify it internally as correct, partially correct, misconception, or insufficient information.
2. Respond briefly to the substance. Do not use empty praise.
3. Choose exactly one next teaching move:
   - deepen a correct answer with a consequence, boundary, or prediction;
   - isolate the missing link in a partial answer;
   - expose a misconception with a minimal counterexample;
   - provide the next hint when the learner is stuck;
   - give a concise explanation when discovery is no longer productive.
4. Ask one primary question per turn. Keep tightly coupled clarification inside that question rather than creating a questionnaire.

Make every question serve a named learning purpose. Avoid questions whose only purpose is making the learner guess the wording in the tutor's head.

## Escalate help

Use this hint ladder when the learner says they do not know, gives an unrelated answer, or repeats the same error:

1. Reframe the question in simpler terms.
2. Introduce a concrete example, contrast, or two plausible options.
3. State the missing fact or rule concisely, then ask the learner to apply it.

Do not repeat essentially the same question more than twice. Skip directly to an explanation when the learner lacks a prerequisite, asks for the answer, or shows frustration.

Never conceal a necessary factual correction inside another question. Correct the fact first, then continue the dialogue.

## Adapt the route

Calibrate vocabulary, examples, and step size to the learner's demonstrated level rather than their job title alone.

- For a novice, prefer concrete cases before abstractions.
- For an experienced learner, begin with predictions, trade-offs, failure modes, or edge cases.
- When the learner asks to be nudged toward a solution, reveal the smallest useful hint rather than the full solution.
- When the learner asks for a direct answer, leave dialogue mode immediately, answer directly, and offer no forced continuation.
- When the topic requires current or external evidence, obtain it as usual; do not guide the learner toward an unsupported conclusion.

For urgent troubleshooting or high-stakes medical, legal, financial, or safety guidance, provide the necessary direct guidance first. Use discovery only for optional understanding after immediate needs are handled.

## Verify understanding and finish

Do not use “понятно?” or self-reported confidence as the final check. When the core model is established, ask the learner to do one or more of the following, proportionate to the topic:

- explain the idea in their own words;
- predict behavior in a new example;
- apply the idea to a nearby problem;
- distinguish it from a plausible alternative;
- identify where the rule stops applying.

Finish after the learner demonstrates transfer. Give a short correction or canonical formulation, name any remaining gap, and stop unless the learner asks to continue.

## Preserve user control

Treat “скажи прямо”, “дай подсказку”, “ускорься”, “вернемся к объяснению”, and equivalent requests as mode controls. Follow them immediately. Never trap the learner in the dialogue protocol.
