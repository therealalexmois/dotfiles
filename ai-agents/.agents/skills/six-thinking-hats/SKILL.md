---
name: six-thinking-hats
description: "Apply Edward de Bono's parallel thinking framework to analyze a decision, idea, or problem from six independent perspectives simultaneously. Use when: making complex decisions that require multiple perspectives; evaluating new products, offers, or strategies before launch; breaking out of analysis paralysis with structured thinking; running productive meetings where everyone thinks in the same direction; balancing optimism with caution in strategic planning. Each perspective runs as an independent agent — results are uncontaminated by other hats."
license: MIT
metadata:
  author: ClawFu (multi-agent rewrite)
  version: 2.0.0
---

# Six Thinking Hats

> Apply Edward de Bono's parallel thinking framework (1985). Six independent agents each analyze the problem through a single lens, then Blue Hat synthesizes.

## Core principle

The reason this works: each hat agent receives only the original problem — no other hat's output. This prevents context contamination. The Yellow Hat cannot be softened by the Black Hat's risks. The Black Hat cannot be dulled by optimism. Each perspective is genuinely independent, which is exactly what de Bono's "parallel thinking" requires.

## How to run

### Step 1 - Blue Hat setup

Before spawning agents, clarify what is being analyzed. If the user's request is ambiguous, ask one focused question: "What exactly do you want to evaluate?" Then formulate a clean problem statement that all agents will receive.

Format it as:

```
Problem / decision to analyze: [one clear sentence]
Context: [2-3 sentences of background if needed]
```

### Step 2 - Spawn five hat agents in parallel

Use the Agent tool to spawn all five agents **in the same message** (parallel execution). Each agent receives:
- The problem statement from Step 1
- Its hat-specific instructions (read the file below before spawning)

| Agent | Instructions file | Focus |
|-------|------------------|-------|
| White Hat | `agents/white-hat.md` | Facts, data, information gaps |
| Red Hat | `agents/red-hat.md` | Emotions, intuition, gut reactions |
| Black Hat | `agents/black-hat.md` | Risks, weaknesses, failure modes |
| Yellow Hat | `agents/yellow-hat.md` | Benefits, value, reasons for optimism |
| Green Hat | `agents/green-hat.md` | Alternatives, creative approaches |

Read each agent's instructions file before composing its prompt so you pass them accurately.

Agent prompt template:

```
Read and follow the instructions in [agents/<hat>.md].

Problem to analyze:
[problem statement from Step 1]
```

### Step 3 - Blue Hat synthesis

Once all five agents complete, synthesize their outputs. Your job as Blue Hat:

1. Present each hat's output in a consistent format (hat name as header, output below)
2. Identify the key tension - usually the sharpest Black Hat risk vs. the strongest Yellow Hat benefit
3. Note any creative Green Hat alternatives worth considering given the Black/Yellow balance
4. End with a **Blue Hat verdict**: a concrete recommendation or next step, grounded in the five perspectives

## Output format

```markdown
## White Hat - Facts
[agent output]

## Red Hat - Feelings
[agent output]

## Black Hat - Risks
[agent output]

## Yellow Hat - Benefits
[agent output]

## Green Hat - Alternatives
[agent output]

---

## Blue Hat - Synthesis

**Key tension:** [Black Hat risk X vs. Yellow Hat benefit Y]

**Worth considering:** [top Green Hat idea if relevant]

**Verdict:** [concrete recommendation or next step]
```

## When agents are not available

If the Agent tool is not available, run each hat sequentially in the same context. Explicitly label each hat section and avoid letting one hat's output influence the next while writing it. The parallel isolation is lost, but the structured coverage is preserved.
