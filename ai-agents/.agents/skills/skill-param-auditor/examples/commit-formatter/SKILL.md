---
name: "commit-formatter"
description: >
  Turn a description of a code change into a Conventional Commits message. Use when
  the user asks for a commit message from a diff or a change summary.
---

# Commit Formatter

Produce exactly one line in Conventional Commits format:
`<type>(<optional-scope>): <description>`.

## Allowed types

Use only these types. This set is the contract of the skill; do not extend it at
run time.

`feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `style`, `build`, `ci`, `chore`.

## Rules

- Pick the type by the main meaning of the change, not by secondary files.
- Add a scope only when it is obvious from the paths.
- Lowercase, imperative, no trailing period.
- Return only the single line, no body or explanation.

## Example

Input: added JWT validation to the auth middleware
Output: `feat(auth): validate JWT in middleware`
