# Decision & Intake Guide

Complete intake before authoring a workflow.
Use the questions and examples below to select a topology and confirm it.

## Why intake comes first

Choose topology before code. These choices change the script:

- pipeline or parallel stages;
- a known item list or a discovery loop;
- text or structured output;
- a workflow, a skill, or a single agent.

## The opening question set

Ask these at the start of a workflow-creation session. Lead with #1; the rest sharpen the shape.

1. **What repeatable, multi-step task do you want to automate?** (the goal)
2. **What is the one unit of work** a single sub-agent does once? (e.g., "review one file", "research one question")
3. **How many units** - a known list, or discovered by looping until some condition?
4. **Do later steps need *all* prior results at once** (dedup/merge/count), or can each item flow independently?
5. **Does any step need structured data back** - a verdict, a list, scores?
6. **How deep / how many tokens** should this go? (sets the budget guard)

Map answers → topology:

| Signal | Topology |
|--------|----------|
| Independent units, known list, combine at end | **fan-out → synthesize** (`parallel` + final `agent`) |
| Ordered stages, each item advances on its own | **pipeline** |
| A stage needs the whole prior set (dedup/merge/early-exit) | **barrier** (`parallel`, then process) |
| Unknown count, stop on goal / budget / dryness | **loop** (guarded) |
| Wide solution space, want best-of-N | **judge panel** |
| A wrong result is costly | add **skeptic-vote** verification on that finding |

## The vague-input playbook

When the user gives a one-liner ("I want to review my PRs") or skips the topology questions, **do not interrogate them in a loop.** Infer, propose, and explain. Run:

```bash
python scripts/workflow_intake.py --task "review my open PRs for bugs" \
  --units unknown --stages unknown --needs-all unknown --structured unknown
```

The engine uses task keywords and fills unknown inputs with defaults. It returns:

- a **recommended topology** (and a runner-up if it's close),
- **model picks** per stage (Haiku for triage/extraction, Opus for synthesis),
- a **budget guard** suggestion,
- a **one-line rationale for every choice** so you can present "here's what I'd build and why."

Present the topology, phases, and parallel-versus-pipeline choice with reasons.
Ask what should change. Scaffold only after the user confirms the shape.

### Defaults the engine applies to unknowns (and why)

| Unknown | Default | Why |
|---------|---------|-----|
| unit count | loop with a hard cap | safest when count is undiscovered; cap prevents the 1000-agent ceiling |
| stages | single stage unless the task names a verb chain | most fuzzy asks are one-pass fan-outs, not pipelines |
| needs-all-results | no (prefer pipeline) | pipeline is strictly faster and the default per the API; only add a barrier on evidence |
| structured output | yes, lightweight schema | a small schema makes downstream stages reliable at near-zero cost |
| budget | guard at `remaining() > 50k` | keeps runaway loops from draining the turn |

## Worked examples

### Review open PRs

- Unit: one PR, from a list gathered by the first agent.
- Topology: fan out independent reviews, then synthesize.
- Model example: Haiku for review, Sonnet to verify high-severity findings.
- Add skeptic-vote verification because false positives and missed bugs are costly.
- For a separate verification stage per PR, use a two-stage pipeline.

### Summarize a document folder

- Unit: one document, from a list gathered by the first agent.
- Topology: fan out summaries, then produce one synthesis.
- Model example: Haiku per document, Opus for synthesis.
- Use structured summaries. No discovery loop or intermediate barrier is needed.

### Find security issues within a budget

- Unit: one issue; total count is unknown.
- Topology: loop until the budget guard stops it.
- Guard example: `budget.remaining() > 50_000`.
- Return a structured issue and deduplicate by ID.
- Keep the guard to avoid the agent cap.

## When to walk away from a workflow

| Intake result | Recommendation |
| --- | --- |
| One agent and one task | Agent tool |
| A procedure with dynamically chosen steps | Skill |
| Fixed fan-out, pipeline, or loop with resume | Workflow |

---

## Sources

1. Ray Amjad - `claude-code-workflow-creator`, `SKILL.md` (the five topology questions, tool-selection table).
2. Anthropic - Claude Code documentation on when to use workflows vs. agents vs. skills.
3. Matt Pocock - `grill-me` skill (forcing-question, one-recommendation-at-a-time intake discipline).
4. Anthropic - sub-agent context-isolation rationale (why topology is a pre-code decision).
5. Google SRE Workbook - budget-guard discipline for bounded loops.
6. "LLM-as-a-judge" + ensemble verification literature (judge-panel / skeptic-vote selection).
7. YC / product-discovery practice - infer-and-propose over interrogate-in-a-loop for vague requests.
