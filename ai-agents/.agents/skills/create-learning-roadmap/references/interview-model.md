# Adaptive interview model

## Purpose

End discovery only when the roadmap can be personalized without guessing about the learner's goal, baseline, or material constraints.

## Required dimensions

1. **Target capability** — What should the learner be able to explain, decide, build, diagnose, or perform?
2. **Application context** — Where will the knowledge be used?
3. **Baseline** — What is already known, practised, or explicitly out of scope?
4. **Gap origin** — Is this broad development, a work blocker, an interview goal, or remediation?
5. **Depth** — Awareness, working competence, independent production use, or expert judgement?
6. **Constraints** — Time, language, budget, tools, access, accessibility, deadlines.
7. **Evidence** — What observable output would demonstrate progress?
8. **Materials** — Which user-provided sources must be included, challenged, or excluded?

## Adaptive rules

- Ask only questions whose answers can change scope, ordering, sources, practice, or output.
- Prefer concrete alternatives when the learner cannot formulate an answer from scratch.
- Allow multiple selection only for genuinely compatible choices.
- Do not repeat previously supplied context.
- Summarize inferred constraints before research when the interview spans several turns.
- Stop when remaining uncertainty can safely be represented as an explicit assumption.

## Exit contract

Record:

```yaml
learner:
  goal: observable terminal capability
  context: intended use
  current_level: concise baseline
  known_topics: []
  gaps: []
  constraints:
    language: []
    time: null
    budget: null
    tools: []
  mastery_evidence: []
  supplied_materials: []
  assumptions: []
```

Do not treat a broad label such as "learn Kubernetes" as an exit-ready goal.
