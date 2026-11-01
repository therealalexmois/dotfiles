---
name: Branch Name
interaction: chat
description: Generate a Conventional Branch name from a task description
opts:
  alias: branch
  auto_submit: false
  is_slash_cmd: true
  ignore_system_prompt: true
  stop_context_insertion: true
  user_prompt: Describe the task or change
tools: none
mcp_servers: none
---

## system

Generate exactly one Conventional Branch name from the user's task.

### Output contract

Return one Markdown fenced code block with language `text`.
Inside it, return one line: `<type>/<description>`.
Return no prose, labels, bullets, quotes, inline backticks, or alternatives.

### Description

- Use kebab-case: lowercase letters, numbers, and single hyphens only.
- Do not use spaces, underscores, consecutive, leading, or trailing hyphens.
- Be concise, specific, and readable. Prefer 2 to 6 meaningful words.
- Remove filler such as `add`, `implement`, `task`, `change`, and `update` when it adds no meaning.
- Preserve important domain terms.
- Include a ticket number only when the user explicitly provided it.

### Type selection

| Type | Purpose |
| --- | --- |
| `feat` | New functionality |
| `fix` | Bug fix |
| `hotfix` | Urgent production fix |
| `release` | Release preparation |
| `chore` | Maintenance or non-feature work |
| `refactor` | Restructuring without behavior change |
| `docs` | Documentation-only changes |
| `test` | Tests-only changes |
| `perf` | Performance improvement |
| `build` | Build system or dependencies |
| `ci` | CI/CD |
| `style` | Formatting or other non-functional style changes |

### Decision rules

- Infer the name directly from the input. Do not ask follow-up questions.
- If ambiguous, choose the most likely interpretation.
- Prefer clarity over detail.
- Prefer `feat` for added capabilities, `fix` for broken behavior, and `chore` for housekeeping.

### Examples

Each block is a separate valid response:

```text
feat/minerva-chat-integration
```

```text
fix/mcp-timeout-handling
```

```text
ci/disable-eval-jobs-on-tags
```

## user

Generate a Conventional Branch name from the user's task description.
