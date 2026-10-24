# Workflow API Reference

Complete surface for Claude Code's Workflow tool: every global, option, cap, and constant a workflow `.js` file can rely on. A workflow file has exactly two parts in order — a `meta` literal, then an async body that uses the injected globals below.

## 1. `meta` declaration

`meta` must be the **first statement** and a **pure object literal** — no variables, spreads, template strings, or function calls inside it. Reserved keys (`__proto__`, `constructor`, `prototype`) are rejected by the parser.

```js
export const meta = {
  name: 'workflow-name',            // required, non-empty string
  description: 'One-line summary',  // required
  whenToUse: 'When to run this',    // optional
  phases: [                         // optional, one entry per phase() call
    { title: 'Phase Name', detail: 'Description', model: 'haiku' }
  ]
}
```

## 2. Injected globals

| Global | Signature | Returns |
|--------|-----------|---------|
| `agent()` | `agent(prompt, opts?) → Promise<string\|object>` | Text, or a validated object when `schema` is set |
| `pipeline()` | `pipeline(items, ...stages) → Promise<any[]>` | Streamed per-item results (no barrier between stages) |
| `parallel()` | `parallel(thunks) → Promise<any[]>` | Concurrent results (barrier — waits for all) |
| `phase()` | `phase(title) → void` | Groups subsequent agents under a heading |
| `log()` | `log(message) → void` | Narrator output to the workflow log |
| `console` | `.log()`, `.error()`, … | Routed into the workflow log |
| `workflow()` | `workflow(nameOrRef, args?) → Promise<any>` | Result of a nested workflow (one level deep max) |
| `args` | any | The input passed to the workflow, unchanged |
| `budget` | `{ total, spent(), remaining() }` | Token tracking |

## 3. `agent()` options

```js
agent(prompt, {
  label: 'string',           // display name (~60 char default)
  phase: 'phase-name',       // progress-group assignment
  schema: { type: 'object' },// JSON Schema — validates + structures the return
  model: 'sonnet',           // 'sonnet' | 'opus' | 'haiku' | 'fable' | full-model-id — default: omit
  effort: 'high',            // 'low' | 'medium' | 'high' | 'xhigh' | 'max' — reasoning effort, default: omit
  isolation: 'worktree',     // run in a fresh git worktree (~200-500 ms + disk)
  agentType: 'agent-type',   // custom sub-agent type
  stallMs: 180000            // per-agent stall timeout override (ms)
})
```

### Model and effort inheritance

- Omit `model` by default. It inherits the session's main-loop model.
- Override it only when a specific tier fits the stage.
- `haiku`, `sonnet`, `opus`, and `fable` resolve to current family defaults.
- A full model ID passes through unchanged.
- Omit `effort` to inherit session reasoning effort.
- Use `low` for a cheap mechanical stage, or `high`/`xhigh`/`max` for a demanding
  verification or judgment stage when justified.

### Resume cache key

The cache key is the full `(prompt, opts)` pair.
An identical call returns its cached result on resume.
Changing any option makes it a new live call, including `schema`, `model`,
`effort`, `isolation`, or `agentType`.

## 4. `pipeline()` vs `parallel()`

| Function | Flow | Use when |
| --- | --- | --- |
| `pipeline(items, stage1, stage2, …)` | Each item advances independently | Default for multi-stage work |
| `parallel(thunks)` | Wait for all concurrent results | A later step needs the full result set |

Pipeline callbacks receive `(prevResult, originalItem, index)`.
Stage 2 starts for an item as soon as its stage 1 finishes.
Wall time is approximately the slowest item's full chain, rather than the sum
of the slowest item in each stage.

Use a parallel barrier for deduplication, merging, or a count-based exit.
Pass thunks rather than bare promises:

```js
parallel([() => agent(a), () => agent(b)])
```

## 5. `budget` object

```js
budget.total        // user-set target, or null if none
budget.spent()      // output tokens spent this turn
budget.remaining()  // max(0, total - spent()), or Infinity when total is null
```

Throws `WorkflowBudgetExceededError` once `spent()` reaches `total`. Use `budget.remaining()` as a loop guard for depth-scaling workflows.

## 6. Caps & limits

| Limit | Value | Behavior on breach |
|-------|-------|--------------------|
| Agent calls per run | 1000 | throws `WorkflowAgentCapError` |
| Concurrent agents | `min(16, max(2, cores − 2))` | excess calls queue |
| Script size | 524,288 bytes | rejected before parsing |
| Per-agent stall | 180,000 ms (3 min) | aborted, retried up to 5× |
| Sync timeout | 30,000 ms | catches infinite synchronous loops |

## 7. Sandbox restrictions

**Banned (non-reproducible — break resume):**
- `Math.random()` → vary the agent prompt by index instead.
- `Date.now()` → pass timestamps in via `args`.
- argless `new Date()` → use `new Date(specificValue)`.

**No access** to filesystem, Node APIs (`require`, `fs`, `process`), or network from the orchestrator. Any work needing those must happen *inside* an `agent()` call (the sub-agent has full tool access).

## 8. Execution & resume

1. The script is persisted to the session directory.
2. A background task launches and returns a run ID (`wf_…`).
3. A journal records each `agent()` call keyed by a hash of `(prompt, opts)`.
4. Resume via `Workflow({ scriptPath, resumeFromRunId })` — cached calls return instantly; only changed or new calls re-run. Resume works **same-session only**; edit the saved file and re-invoke with `scriptPath`.

## 9. Enabling the feature

No environment variable enables Workflow. It is built in, but requires opt-in:

- `ultracode` in the request;
- an ultracode-enabled session;
- a direct request to run a workflow or use multi-agent orchestration;
- a skill/slash command whose instructions call the tool.

Without opt-in, describe the proposed workflow and ask before running it.

Save scripts under `.claude/workflows/`. Open `/workflows` to browse and run them.

| Key | Action |
| --- | --- |
| Up / Down | Select an agent |
| `p` | Pause or resume |
| `x` | Stop the workflow |
| Escape | Go back |
| `s` | Save as a named workflow |

---

## Sources

1. Anthropic — Claude Code documentation, Workflow tool & `/workflows` (code.claude.com/docs).
2. Ray Amjad — `claude-code-workflow-creator`, `references/api-reference.md` (github.com/ray-amjad/claude-code-workflow-creator).
3. Anthropic — Claude Code changelog, v2.1.147 release notes (Workflow tool introduction).
4. Anthropic — sub-agents & the Agent tool documentation (fresh-context isolation model).
5. Anthropic — Claude Agent SDK: orchestration and background-task execution patterns.
6. JSON Schema specification (json-schema.org) — the `schema` option's validation contract.
7. Node.js / ECMAScript — async/await and `Promise.all` semantics underlying `parallel()`.
8. Google SRE Workbook — error-budget discipline, analogous to the `budget` guard pattern.
