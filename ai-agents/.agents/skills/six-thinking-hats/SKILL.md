---
name: six-thinking-hats
disable-model-invocation: true
description: "Apply Edward de Bono's parallel thinking framework to analyze a decision, idea, or problem from six independent perspectives simultaneously. Use when: making complex decisions that require multiple perspectives; evaluating new products, offers, or strategies before launch; breaking out of analysis paralysis with structured thinking; running productive meetings where everyone thinks in the same direction; balancing optimism with caution in strategic planning. Each perspective runs as an independent agent — results are uncontaminated by other hats."
license: MIT
metadata:
  origin: first-party
  author: ClawFu (multi-agent rewrite)
  version: 2.0.1
---

# Six Thinking Hats

> Apply Edward de Bono's parallel thinking framework (1985). Five independent agents each analyze the problem through a single lens, then the parent session synthesizes as Blue Hat.

## Core principle

Each hat agent receives only the original problem, never another hat's output. That isolation is what de Bono's "parallel thinking" requires: no perspective gets softened or dulled by the others.

## How to run

### Step 1 - Blue Hat setup

Before spawning agents, clarify what is being analyzed. If the user's request is ambiguous, ask one focused question: "What exactly do you want to evaluate?" Then formulate a clean problem statement that all agents will receive.

Format it as:

```
Problem / decision to analyze: [one clear sentence]
Context: [2-3 sentences of background if needed]
```

### Step 2 - Spawn five hat agents in parallel

Set the model and effort in every spawn tool call. Use these skill-specific defaults unless the user explicitly requests different settings:

| Client | Tool | Model | Effort | Context |
|--------|------|-------|--------|---------|
| Claude Code | `Agent` | `model: "sonnet"` | `effort: "low"` | `subagent_type: "general-purpose"` |
| Codex | `spawn_agent` | `model: "gpt-6.2-sol"` | `reasoning_effort: "low"` | `fork_context: false` or `fork_turns: "none"`, according to the tool schema |

Use low effort for the bounded, single-perspective analyses. Check the active tool schema before spawning. If the tool cannot explicitly set both model and effort, use the sequential workflow below.

Launch all five agents before waiting for their results. Each agent receives:
- The problem statement from Step 1
- Its hat-specific instructions (read the file below before spawning)

| Agent | Instructions file | Focus |
|-------|------------------|-------|
| White Hat | `references/white-hat.md` | Facts, data, information gaps |
| Red Hat | `references/red-hat.md` | Emotions, intuition, gut reactions |
| Black Hat | `references/black-hat.md` | Risks, weaknesses, failure modes |
| Yellow Hat | `references/yellow-hat.md` | Benefits, value, reasons for optimism |
| Green Hat | `references/green-hat.md` | Alternatives, creative approaches |

Include the contents of each hat's instructions file directly in its prompt so the agent can start without resolving a file path.

Agent prompt template:

```
[contents of the corresponding hat instructions file]

Problem to analyze:
[problem statement from Step 1]
```

When an agent comes back empty or fails, respawn that hat once with the same prompt, model, effort, and context settings. If the runtime rejects the chosen model or effort, treat the hat as missing immediately. Continue with the hats you have and open the synthesis by naming any missing perspectives. If no hat returns an analysis, report the failure and omit the verdict.

### Step 3 - Blue Hat synthesis

Once all hat runs are resolved, synthesize the available outputs in the parent session. Your job as Blue Hat:

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

If the client has no spawn tool with both model and effort controls, run each hat sequentially in the parent session. State that the analysis ran sequentially in a shared context. Label each hat section and base it on the original problem and its own instructions.
