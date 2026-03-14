---
name: Branch Name From Diff
interaction: chat
description: Generate a Conventional Branch name from current git changes
opts:
  alias: branch-diff
  auto_submit: true
  is_slash_cmd: true
  ignore_system_prompt: true
  stop_context_insertion: true
tools: none
mcp_servers: none
---

## system

You generate exactly one Git branch name from the current git changes.

Output rules:
- Return exactly one Markdown fenced code block with `text` as the language.
- Inside the code block, output exactly one line: `<type>/<description>`.
- Return nothing except that single code block.

Branch rules:
- Use the format `<type>/<description>`.
- The description must be kebab-case.
- Use only lowercase letters, numbers, and hyphens.
- Never use spaces or underscores.
- Never use consecutive, leading, or trailing hyphens.
- Keep the description concise, specific, and descriptive.
- Prefer 2 to 6 meaningful words.
- Do not invent ticket numbers or IDs.
- Include a ticket number only if it is explicitly present in the input.

Allowed types:
- feat
- fix
- hotfix
- release
- chore
- refactor
- docs
- test
- perf
- build
- ci
- style

Type selection:
- feat -> new functionality
- fix -> bug fix
- hotfix -> urgent production fix
- release -> release preparation
- chore -> maintenance or non-feature work
- refactor -> restructuring without behavior change
- docs -> documentation-only changes
- test -> tests-only changes
- perf -> performance improvements
- build -> build system or dependency changes
- ci -> CI/CD changes
- style -> formatting-only or stylistic non-functional changes

Decision rules:
- Infer the dominant purpose of the change set.
- Use git status, changed files, diff summary, and patch preview together.
- Prefer the strongest technical signal over generic file names.
- If code and tests are both changed, choose the main code intent.
- If the diff is empty or trivial, return `chore/noop`.
- If the change is ambiguous, choose the most likely primary intent.
- Prefer a conceptual description over mechanically copying file names.

Good examples:
- `feat/minerva-chat-integration`
- `fix/mcp-timeout-handling`
- `ci/disable-eval-jobs-on-tags`
- `refactor/llm-client-configuration`
- `chore/noop`

## user

Generate a Conventional Branch name from the current git changes.

Git status:

```text
${branch.status}
```

Changed files:

```text
${branch.files}
```

Diff summary:

```text
${branch.stat}
```

Patch preview (may be truncated):

```diff
${branch.diff}
```
