---
name: select-reasoning-effort
description: Recommend the reasoning-effort level for the next phase of software-development work and define when to reassess it. Use when the user asks which effort or intelligence level to choose, whether to raise or lower it, or how much reasoning a coding agent needs before or during implementation, debugging, review, research, architecture, brainstorming, migration, security, or other agentic work. Analyze context already available from any source, including tickets, code, documents, conversation, memory, or prior investigation.
---

# Select Reasoning Effort

Recommend effort for the **next substantive phase**, not one fixed level for an entire ticket. Keep the skill advisory: explain the choice, but do not change settings or continue the underlying task unless the user asks.

## Workflow

1. Use the task context already available, regardless of its source. Treat Jira, code, documents, memory, and prior research as evidence, not separate workflows.
2. Identify the next phase: lookup, exploration, brainstorming/design, implementation, debugging, review, or validation.
3. Identify the target product, model, supported levels, and current effort when known. Do not assume that the same level name has equivalent capability across models.
4. Evaluate:
   - uncertainty: whether the solution or root cause is known;
   - coupling: how many components, contracts, or systems interact;
   - validation difficulty: how easily correctness can be demonstrated;
   - cost of error: impact, reversibility, security, and compatibility;
   - work horizon: short local action versus extended tool-driven investigation;
   - execution state: new work, phase transition, contradiction, or stalled attempt.
5. Select the lowest level that adequately covers the strongest material signal.
6. State concrete conditions for raising or lowering effort later.

Do not infer difficulty from ticket length, number of files, or labels such as `architecture` and `brainstorm` alone. Do not retrieve missing source material unless the user asks or the recommendation would otherwise be materially unreliable.

## Decision Guide

| Level | Select when the next phase is |
|---|---|
| `low` | A short, tightly scoped, latency-sensitive action that is not intelligence-sensitive: locating a file, listing items, or making an obvious mechanical edit. |
| `medium` | A clear local implementation with a known approach, limited blast radius, conventional tests, and easy rollback. Use as the general fallback when no stronger signal exists. |
| `high` | Diagnosis with an unknown cause, multi-layer logic, meaningful edge cases, careful review, competing hypotheses, or correctness that requires tracing and validation. |
| `xhigh` | A difficult architecture or design choice, cross-system or public contracts, migration, security-sensitive work, long-horizon agentic exploration, or several interacting sources of uncertainty. |
| `max` | The task requires the target model's maximum available capability, token cost is secondary, and there is a concrete reason `xhigh` may be insufficient. Never use it merely as a safe default; account for diminishing returns and overthinking. |

If the target exposes `ultra`, treat it as a platform-specific maximum or orchestration mode rather than a portable level. Recommend it only when supported and when both deepest reasoning and autonomous decomposition or delegation materially help.

When model-specific official guidance or an environment default is already available, use it to calibrate this table. If exact support is unknown, state the assumption and recommend a semantic band without inventing a setting.

## Reassessment Triggers

Recommend reassessment only at a phase transition or after material new evidence.

Raise effort when:

- the scope expands across systems or public contracts;
- evidence conflicts or the root cause remains unclear;
- multiple plausible approaches require trade-off analysis;
- an attempted approach fails and invalidates an assumption;
- security, migration, concurrency, or irreversible impact appears.

Lower effort when:

- the root cause is confirmed;
- an architectural or product decision has been made;
- remaining work is a bounded implementation with clear tests;
- risk has been isolated behind a reversible change.

Avoid oscillation. Keep the current level until the phase changes or new evidence alters the decision.

## Output

Return concisely in the user's language:

```markdown
Recommended effort: high
For: Diagnose the failing cross-layer request lifecycle.

Why:
- The root cause is not localized.
- Backend and client state transitions interact.
- Correctness requires edge-case validation.

Reconsider:
- Raise to xhigh if a public contract or architectural choice is uncovered.
- Lower to medium once the cause is confirmed and only a local patch remains.
```

If current effort is known, also say `keep`, `raise`, or `lower`. If the target model does not support the recommended label, choose the nearest supported level and name the fallback. Do not claim that invoking this skill changes the effort of the response already in progress; apply the recommendation at the next available control point.
