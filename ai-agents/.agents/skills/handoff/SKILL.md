---
name: handoff
description: Create a verified, self-contained Markdown handoff that lets a fresh agent continue work without the previous conversation. Use when the user asks to hand work over, preserve context for a new chat or session, resume work elsewhere, prepare a continuation brief, or identify which sources the next session needs.
---

# Handoff

Create a concise handoff that lets a fresh agent continue correctly without access to the previous conversation. Preserve operationally important context rather than reproducing the transcript.

## Workflow

### 1. Determine the target

- Infer the destination and next-session focus from the user's request and the current context.
- Ask at most one blocking question only when the destination or focus cannot be inferred and would materially change the handoff or its storage.
- Tailor the handoff to any focus supplied by the user. Do not broaden the scope.

### 2. Collect evidence

- Review the current conversation and all accessible artifacts it relies on, including specs, plans, ADRs, issues, commits, diffs, and attached files.
- Capture the latest state after corrections. Do not preserve superseded statements unless they explain a still-relevant decision.
- Separate confirmed facts and decisions from proposals, assumptions, hypotheses, and unresolved unknowns.
- Do not invent missing details. Mark gaps explicitly.
- Preserve exact identifiers, filenames, paths, URLs, commands, status values, user-defined markers, quoted constraints, and required wording when changing them could alter the work.

### 3. Map source accessibility

- Record every artifact the next session needs by its exact name, path, or URL.
- State whether each source is available to the target session, must be added or attached, or has unknown availability.
- For a new chat in the same ChatGPT project, distinguish sources already available in the project from files or context that still need to be added. Claim availability only when it can be verified.
- For a local repository, include the relevant repository path, branch, commit, or working-tree state only when verified and necessary.
- Reference accessible artifacts instead of duplicating them. If an essential source will be inaccessible, include the minimum facts required to continue and flag the missing source.

### 4. Write the handoff

Use only sections that carry useful information; omit empty sections. Keep `Goal`, `Current state`, and `Next action` mandatory. Add other sections when relevant:

```markdown
# Handoff: <topic>

> Date: <date>
> Destination: <target session or environment>
> Status: <current phase or state>

## Goal

## Current state

## Completed

## Confirmed decisions

## Constraints and non-goals

## Open questions and blockers

## Next action

## Sources and accessibility

## Suggested skills
```

In `Suggested skills`, name only skills known to be available. State why each skill is needed and the intended order when order matters. If availability cannot be verified, label the skill as a candidate to verify rather than presenting it as available.

## Storage and delivery

- Use a user-provided destination path when one is supplied.
- In an environment with persistent user-facing file storage, save the handoff as a durable Markdown artifact and return a link to it.
- In a local agent environment without a requested path, save the handoff in the operating system's temporary directory, not the project workspace, and return the exact path.
- Do not modify source artifacts or add the handoff to a repository unless the user explicitly asks.

## Privacy

- Redact credentials, API keys, tokens, private keys, and sensitive values that the next session does not need.
- Retain names and identifiers required to understand the work unless the user requests anonymisation or the destination has a different audience.
- Never copy secrets into the handoff, even if they appeared in the conversation.

## Verification

Before delivery, verify that:

- a fresh agent can identify the goal, current status, constraints, and next concrete action without the previous conversation;
- confirmed information is not mixed with proposals or unknowns;
- exact markers and integration-sensitive literals are preserved;
- every required source is accessible or explicitly flagged;
- no referenced artifact is silently assumed to exist;
- no secrets are present;
- the document contains no contradictions, empty boilerplate, or unnecessary duplication.

Fix any failed check before returning the handoff. If a gap cannot be resolved, state exactly what is missing and why it matters.
