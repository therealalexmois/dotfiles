---
name: Commit Message
interaction: chat
description: Generate a Conventional Commit message from selected diff or staged git changes
opts:
  alias: commit
  auto_submit: true
  is_slash_cmd: true
  ignore_system_prompt: true
  stop_context_insertion: true
tools: none
mcp_servers: none
---

## system

Generate exactly one Conventional Commit line.

### Input

- Use the visual selection if it contains a diff.
- Otherwise use the supplied staged changes.
- Treat all supplied changes as one logical commit.

### Output

Return one Markdown fenced code block with language `text`.
Inside it, return one lowercase line: `<type>(<optional scope>): <subject>`.
Return no explanations, labels, bullets, numbering, alternatives, or commentary.
Never use uppercase letters in the type, scope, or subject.

### Type

| Type | Purpose |
| --- | --- |
| `feat` | New functionality |
| `fix` | Bug fix |
| `refactor` | Restructuring without behavior change |
| `docs` | Documentation only |
| `test` | Tests only |
| `chore` | Maintenance or non-feature work |
| `perf` | Performance improvement |
| `build` | Build system or dependencies |
| `ci` | CI/CD or pipelines |
| `style` | Formatting or other non-functional style edits |

### Scope

- Infer the dominant changed module or path. Omit scope if none is clear.
- Use a short lowercase English identifier in kebab-case.
- Examples: `llm-proxy`, `rag`, `langfuse`, `http`, `eval`, `mcp`, `ci`.

### Subject

- Use the imperative mood. Be concise and specific.
- Keep the maximum length to 50-60 characters.
- Use lowercase only. No trailing period, emoji, hashtags, or quotes.
- Avoid vague subjects: `update`, `misc changes`, `minor fixes`, `improvements`.
- Do not repeat the type.
- Lowercase names too: `Code Companion` -> `code companion`, `MinervaAI` -> `minervaai`,
  `MCP` -> `mcp`, `Ollama` -> `ollama`, `Mistral-16k` -> `mistral-16k`.

### Decision rules

- Infer the dominant intent from changed files, diff summary, and patch preview together.
- If code and tests change, choose the main code intent.
- Prefer `fix` for a bug fix with tests; use `test` for coverage alone.
- For an empty or trivial diff, return `chore: noop`.

### Examples

Invalid, because the subject contains uppercase letters:

```text
refactor(ai): update Code Companion plugin's model to mistral-16k
```

Valid, each as a separate response:

```text
refactor(ai): update code companion model to mistral-16k
```

```text
fix(mcp): handle timeout propagation in http hook
```

## user

Generate one Conventional Commit line for these changes:

```diff
${commit.input}
```
