# AGENTS.md

## Project overview

<Only material context the agent cannot reliably infer.>

## Repository layout

- `<path>` – <purpose>.

## Commands

- Setup: `<command>`
- Unit tests: `<command>`
- Full tests: `<command>`
- Lint: `<command>`
- Typecheck: `<command>`

Do not invent unknown commands. Use `TBD` until verified from project config.

## Architecture rules

- <Concrete dependency or boundary rule.>

## Coding and testing rules

- <Project-specific rule not enforced elsewhere.>

## Verification

- After <change type>, run <check>.
- If a check is skipped, report the reason.

## Security

- Do not print, commit or log secrets.
- Do not modify credentials or production config without explicit request.
- Do not run destructive operations without confirmation and supported controls.

## Done means

- Scope matches the user request.
- Relevant checks passed or failures were reported.
- Final response lists changed files, checks and known risks.

## Additional context

- Read `<scoped source>` only when <trigger>.

---

# CLAUDE.md adapter

Use this part only if current Claude Code documentation confirms the selected import or adapter mechanism.

```md
<Import or reference to the canonical project instruction>

## Claude-specific rules

- <Only behavior specific to Claude Code.>
```

Do not duplicate the common project contract.
