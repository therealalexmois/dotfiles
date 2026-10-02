# Anki card design

## Selection policy

Create cards for mechanisms and causal models, meaningful distinctions, decision criteria and constraints, common misconceptions, stable interfaces or formulas that must be recalled, and predictions derived from a model.

Do not create cards for navigation, transient versions, long lists, tutorial steps, or facts better retrieved from documentation.

## Card types

- `basic`: focused question and concise answer.
- `cloze`: one meaningful omission with enough context.
- `comparison`: distinguish two easily confused concepts.
- `mechanism`: explain why or how an effect occurs.
- `scenario`: choose and justify an action in context.
- `misconception`: correct a plausible false belief.
- `prediction`: predict code, system, or model behaviour.

## Atomicity checks

Each card must test one retrievable unit, have an unambiguous prompt, avoid yes/no wording when explanation matters, keep the answer short enough to grade consistently, contain the minimum standalone context, cite a source, and include roadmap and node tags.

Split cards that contain "and" when each clause can be independently right or wrong.

## Source fidelity

Do not turn an inference into a factual card unless the prompt identifies it as an inference or decision heuristic. Never cite a source that merely mentions the topic.

## Export

TSV columns:

```text
front\tback\ttype\ttags\tsource
```

Escape newlines as spaces, join tags with spaces, and preserve UTF-8. Advanced deck management and `.apkg` packaging may be delegated to a separate Anki skill.
