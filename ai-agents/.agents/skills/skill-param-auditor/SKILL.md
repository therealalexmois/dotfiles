---
name: "skill-param-auditor"
disable-model-invocation: true
description: >
  Audit agent skills for poor parameterization: hardcoded runtime data, brittle
  environment assumptions, and config values that should not live inside SKILL.md.
  Detects hardcoded bot/thread/channel IDs, Kubernetes namespaces and cluster
  names, environment names, URLs and endpoints, absolute paths, org/project/board
  IDs, secrets and tokens, fixed model names, and magic constants. Classifies each
  finding by risk (Critical / Major / Minor) and proposes the simplest extraction
  strategy: invocation argument, config, env var, secret manager, resolver script,
  runtime discovery, or MCP/tool call. Use this skill whenever the user wants to
  review, audit, or harden a skill, mentions hardcoded values, brittle skills,
  runtime config review, parameterization problems, "values that should be config",
  or asks to extract IDs/namespaces/URLs out of a SKILL.md, even if the word
  "audit" is not used. Works on a single SKILL.md, one skill directory, a folder of
  skills, or a repo subtree. Defaults to analyze-only and never edits files unless
  the user explicitly asks to fix, refactor, apply, or implement the changes.
---

# Skill Parameterization Auditor

Find mutable runtime data that has leaked into a skill's instructions, explain why
it makes the skill brittle, and propose the simplest way to move it out. A skill
should encode a stable workflow that survives infra changes; the moment a bot ID,
namespace, URL, or token is baked into `SKILL.md`, the skill silently rots the next
time that value changes.

## Operating mode

**Default: analyze-only.** Read the target, produce the audit report, change
nothing. This is the default for "review", "audit", "analyze", "check", "look at".

**Implementation mode** activates only when the user explicitly asks to fix,
refactor, apply, implement, or "extract these for me". Even then, show the plan
first and apply only safe mechanical edits (see [Implementation mode](#implementation-mode)).

**Fail closed.** When you cannot tell whether a value is a stable part of the skill
contract or mutable runtime data, report it as a finding and ask, do not guess.
Never invent an ID, namespace, URL, alias, or config key that you cannot source.

## Workflow

### 1. Resolve the target

The user may point at any of:

- a single `SKILL.md` file;
- one skill directory (contains `SKILL.md` plus optional `scripts/`, `references/`, `assets/`, `examples/`);
- a folder holding several skill directories;
- a repo subtree where skill folders are nested somewhere inside.

Detect skills by locating every `SKILL.md`. Each `SKILL.md` plus its sibling files
is one audited unit. If no `SKILL.md` exists under the target, say so and stop, do
not audit unrelated files.

### 2. Enumerate the skill's files

For each skill, collect what to inspect:

- `SKILL.md` (always);
- `scripts/` (`.py`, `.sh`, `.bash`, `.js`, `.ts`);
- `references/` and any other `.md`;
- `assets/`, templates, `examples/`;
- any `config*`, `*.toml`, `*.yaml`, `*.yml`, `*.json`, `.env*` shipped with the skill.

### 3. Optional pre-scan (helper, not required)

A regex pre-scanner seeds the audit with candidate values so you do not eyeball
every line. It is a convenience, not a dependency, the skill works without it.

```bash
python3 scripts/find_hardcoded_values.py <target-path>        # human-readable
python3 scripts/find_hardcoded_values.py <target-path> --json  # machine-readable
```

Treat its output as candidates only. Regex over-flags (every URL, every `/abs/path`)
and under-flags (a bare numeric thread ID looks like any integer). You still have to
judge each candidate against the stable-vs-mutable test below. Never report a
pre-scanner hit verbatim as a finding without that judgment.

### 4. Classify each candidate: stable contract or mutable runtime data

This is the core decision. For every suspicious value ask:

> If this value changed in six months, or differed on another machine, team, or
> environment, would the skill silently do the wrong thing?

- **Yes -> mutable runtime data.** It does not belong hardcoded in `SKILL.md`. It is
  a finding. Pick an extraction strategy.
- **No, it is part of what the skill *is*** -> stable contract. Leave it. Examples:
  the `feat|fix|chore|...` set in a Conventional Commits skill, a fixed output
  template, a standard algorithm step, a well-known format string. Calling these
  out as problems is noise and erodes trust in the report.

Anything that is a secret is always a finding regardless of stability.

### 5. Score risk

| Level | What belongs here |
| --- | --- |
| **Critical** | Secrets, credentials, tokens, API keys. Unsafe production assumptions (a default that points at prod, a silent prod->non-prod fallback). Destructive commands wired to a hardcoded target (delete/scale/rollout against a baked-in namespace or cluster). |
| **Major** | Brittle identifiers that break the skill when they change: bot/user/channel/thread IDs, namespace lists, cluster/context names, URLs and endpoints, project/repo/board IDs, Jira project keys, absolute local paths, hardcoded model/provider names that should be configurable. |
| **Minor** | Maintainability and clarity: unclear or unlabeled example values, weak naming, magic constants without explanation, missing "how to update this" docs, no preflight check for an assumed tool. |

When unsure between two levels, pick the higher one and say why.

### 6. Write the report

Use the exact template in [Report format](#report-format). Findings must be
specific and actionable, point at a file and location, name the value or pattern,
explain the concrete failure, and recommend one strategy. Generic advice ("consider
using config") is not a finding.

## Hardcoded value categories

Detect these. Full detection cues and edge cases are in
[references/audit-checklist.md](references/audit-checklist.md).

- Messenger identifiers: bot IDs, user IDs, channel IDs, thread/root IDs.
- Kubernetes: namespaces, contexts, cluster names, deployment/service names.
- Environment names and aliases (`prod`, `stage`, `dev`, `qa`) when used as real
  targets rather than illustrative examples.
- URLs, API endpoints, hostnames, ports.
- Absolute local paths and assumptions about project layout.
- Organization-specific identifiers.
- Project IDs, repository IDs, board IDs, Jira project keys.
- Secrets: tokens, credentials, API keys (always Critical).
- Fixed model names, provider names, inference endpoints that should be configurable.
- Feature-flag names and release identifiers.
- Project-specific filenames treated as if universal.
- Magic constants controlling runtime behavior.
- Assumptions that a tool is installed (no preflight check).
- Assumptions about current branch, namespace, service, or cluster.

## Extraction strategies

Recommend the simplest strategy that fits. Depth, trade-offs, and worked examples
are in [references/parameterization-patterns.md](references/parameterization-patterns.md).

| Strategy | Fits when |
| --- | --- |
| Invocation argument (positional) | Per-run value the caller always knows (target path, issue key). |
| Named argument | Per-run value among several optional ones. |
| Local project config | Stable-but-environment-specific value that lives with the repo. |
| User-level config | Per-user value reused across runs (default cluster, handle). |
| Environment variable | Value the surrounding shell/CI already exports. |
| Secret manager / env secret | Anything sensitive. Never inline, never in config committed to git. |
| Resolver script | Value derivable by a small deterministic lookup. |
| Runtime discovery (k8s label selector, etc.) | Infra that changes often; query it instead of hardcoding. |
| Repository metadata discovery | Value readable from the repo (remote URL, project id from CI metadata). |
| MCP / tool call | A reusable, operationally important integration boundary already exists. |
| Documented example only | Value is genuinely illustrative; label it clearly as an example. |
| Leave as-is | Value is a stable, intentional part of the skill contract. |

### Design rules

- `SKILL.md` describes stable workflow, decision rules, and safety constraints.
- Mutable runtime data does not live in `SKILL.md`.
- Secrets never live in `SKILL.md`, examples, references, or scripts.
- Prefer logical aliases over physical IDs.
- Use discovery where infra changes often; config where values are stable but
  environment-specific; arguments for per-run values.
- Fail closed when resolution is ambiguous. Never silently fall back from prod to
  another environment. Never silently guess a bot, namespace, cluster, user, or repo.
- KISS / YAGNI. Do not introduce a config system when one argument suffices. Do not
  introduce an MCP/tool abstraction unless the boundary is reusable or operationally
  important.

## Report format

Produce exactly this structure. Omit a severity subsection only if it is empty.

```markdown
# Parameterization Audit Report

## Summary

- Skills analyzed:
- Critical issues:
- Major issues:
- Minor issues:
- Safe automatic fixes:
- Manual fixes required:

## Findings by skill

### <skill-name>

#### Critical issues

- Location: <file:line or section>
- Value / pattern: <detected value or pattern>
- Category: <category>
- Problem: <why this is brittle or dangerous>
- Recommendation: <one extraction strategy>
- Suggested target location: <where the value should live>
- Safe to auto-fix: yes / no

#### Major issues
(same structure)

#### Minor issues
(same structure)

## Recommended config model

Describe the minimal config shape only if config is actually recommended. If a few
arguments suffice, say so and do not invent a config system.

## Suggested changes

Concrete edits or a patch plan. Reference exact files and lines.

## Open questions

Only questions that block safe implementation (e.g., "where does the real bot ID
come from", "is the prod default intentional"). Omit if none.
```

When auditing a folder, repeat the `### <skill-name>` block per skill and reflect
all of them in the Summary counts.

## Implementation mode

Only when the user explicitly asks to apply changes:

1. Show the planned changes first and wait for the value sources you do not know.
2. Apply only safe mechanical edits, replace a brittle literal with an argument,
   config reference, env lookup, or resolver call when the value's source is clear.
3. Preserve existing behavior. Do not change unrelated skill logic.
4. Never invent unknown IDs, namespaces, URLs, or aliases. If the real value is
   unknown, leave a clearly named placeholder and an Open question, do not fabricate.
5. Create a config file only if one is genuinely needed, and explain why before
   creating it. Keep it minimal.
6. Add a short note or comment explaining how to update the runtime value later.
7. After editing, show a concise diff summary (files changed, practical effect),
   not a full dump.
8. Secrets are never written into any tracked file, propose env/secret-manager
   wiring instead.

## References and examples

- [references/parameterization-patterns.md](references/parameterization-patterns.md)
  Extraction strategies in depth, fail-closed patterns, and four worked examples
  (messenger bot/thread IDs, release-manager namespaces, hardcoded API URL, and a
  value that should stay hardcoded).
- [references/audit-checklist.md](references/audit-checklist.md)
  Per-category detection cues, the example-vs-real heuristic, and the risk rubric.
- `examples/` Four small fixture skills you can audit to see the workflow end to end.
