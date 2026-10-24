---
name: workflow-builder
disable-model-invocation: true
description: Design and write deterministic multi-agent workflow scripts (.js files in .claude/workflows/) for Claude Code's Workflow tool. Use when a user wants to build, create, author, scaffold, or run a custom Claude Code workflow, orchestrate sub-agents (fan-out, pipeline, loop, judge-panel), or automate a repeatable multi-step task across fresh-context agents.
license: MIT
metadata:
  origin: derived
  upstream: https://github.com/alirezarezvani/claude-skills/tree/main/.gemini/skills/workflow-builder
  upstream_note: "reworked 2026-09-29 to match the built-in workflow-authoring reference: dropped the CLAUDE_CODE_WORKFLOWS env-var gate (the tool now activates on explicit user opt-in, e.g. ultracode), corrected the /workflows key bindings, and added the effort option and default-omit model guidance"
  imported_at: 2026-06-04
  inspired_by: "https://github.com/ray-amjad/claude-code-workflow-creator (Ray Amjad)"
  targets: "Claude Code Workflow tool (/workflows)"
  version: 1.1.0
---

# Workflow Builder

Write deterministic `.js` workflows for Claude Code's Workflow tool.
JavaScript controls orchestration; leaf `agent()` calls use tokens.
Each sub-agent has a fresh context. Runs can resume within the session.

## Start with intake

Complete intake before proposing or writing a workflow. Do not skip to code.

1. Ask about missing requirements:
   - What repeatable, multi-step task should run?
   - What does one sub-agent do once?
   - Is the unit list known, or discovered in a loop?
   - Do later stages need all prior results, or can each item advance alone?
   - Does a stage return structured data such as a verdict, list, or score?
   - What depth or token budget is intended?
2. For vague input, infer and propose instead of repeating questions. Run:

   ```bash
   python scripts/workflow_intake.py --task "their description" \
     --units unknown --stages unknown --needs-all unknown --structured unknown
   ```

   Present 1-2 concrete proposals with topology, phases, models, budget guard,
   and the engine's rationale. Do not ask for information already supplied.
3. Confirm topology, phases, and parallel-versus-pipeline choice before writing.
   This is the authoring approval gate.

Details: [intake guide](references/decision_and_intake_guide.md).

## Select the tool

| Task | Tool |
| --- | --- |
| One sub-agent, one task | Agent tool |
| Reusable procedure with dynamically chosen steps | Skill |
| Fixed multi-agent topology with deterministic control and resume | Workflow |

Use a workflow when parallel stages, reproducibility, resume, or context isolation
justify it. Use Claude directly for a one-off task that does not need these.

## Build, validate, and run

1. Scaffold the confirmed topology:

   ```bash
   python scripts/scaffold_workflow.py --topology pipeline --name pr-triage \
     --description "Triage open PRs" > .claude/workflows/pr-triage.js
   ```

2. Edit `meta` first, then the async body. Available globals are `agent()`,
   `pipeline()`, `parallel()`, `phase()`, `log()`, `budget`, `args`, and `workflow()`.
   Use the [API reference](references/api_reference.md) and
   [orchestration examples](references/orchestration_patterns.md).
3. Validate before running:

   ```bash
   python scripts/validate_workflow.py .claude/workflows/pr-triage.js
   ```

4. Save under `.claude/workflows/`. Run through `/workflows` only with explicit
   opt-in: a direct request to run a workflow, `ultracode`, or an ultracode-enabled session.
   Invoking this authoring skill alone does not authorize execution.

| Key in `/workflows` | Action |
| --- | --- |
| Up / Down | Select an agent |
| `p` | Pause or resume |
| `x` | Stop the whole workflow |
| Escape | Go back |
| `s` | Save as a named workflow |

Failed agents retry automatically.

## Script rules

- Make `meta` the first statement and a pure literal.
  Do not use variables, spreads, template strings, or calls inside it.
- Keep orchestration deterministic. Avoid `Date.now()`, `Math.random()`, and
  argument-free `new Date()`. Pass timestamps through `args`.
- Keep filesystem, Node, and network access inside `agent()` prompts.
  The orchestrator cannot use `require`, `fs`, or `process`.
- Pass thunks to `parallel()`: `() => agent(...)`, not bare promises.
- Prefer `pipeline()` unless a stage needs the whole previous result set.
- Bound open-ended loops with a counter or `budget.remaining()`.
  Unguarded loops can hit the 1000-agent cap.
- Filter skipped or failed results with `results.filter(Boolean)`.
- Omit `model` and `effort` by default to inherit session settings.
  Override only when a specific tier or effort fits the stage.

The validator checks script rules before execution.

## Package tools

| Path | Purpose |
| --- | --- |
| `scripts/workflow_intake.py` | Recommend topology, model, budget, and rationale |
| `scripts/validate_workflow.py` | Report PASS / WARN / FAIL with line numbers |
| `scripts/scaffold_workflow.py` | Generate a starter `.js` |
| `assets/templates/` | Fan-out, pipeline, and budget-loop starters |
| `assets/examples/` | Complete runnable example |

All scripts support `--help` and sample execution with `--sample` or no arguments.
