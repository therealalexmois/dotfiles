---
name: writing-prd-draft
description: >-
  Turn what the conversation and the codebase already established into a PRD draft: state the problem
  and solution from the user's point of view, sketch the modules the work touches and confirm them,
  enumerate user stories, record implementation and testing decisions, mark what is out of scope, then
  offer to save the document. Runs on existing context and never interviews the user. Use only when the
  user invokes /writing-prd-draft or explicitly asks «создай PRD», «сделай PRD из контекста», «оформи
  это как PRD», or to draft a PRD from this conversation without an interview.
disable-model-invocation: true
metadata:
  version: "1.0"
  origin: first-party
---

This skill takes the current conversation context and codebase understanding and produces a PRD. Do NOT interview the user — just synthesize what you already know.

## Process

1. Explore the repo to understand the current state of the codebase, if you haven't already. Use the project's domain glossary vocabulary throughout the PRD, and respect any ADRs in the area you're touching.

2. Sketch the modules the implementation builds or modifies, as a list of `module name - one-line responsibility - the interface it exposes`. Prefer deep modules: a lot of functionality behind a small interface that rarely changes and can be tested in isolation.

Check with the user that these modules match their expectations, and which of them they want tests written for.

3. Write the PRD using the template below.

4. Check the draft before presenting it: every Implementation Decision traces to at least one user story, every module from step 2 appears in Implementation Decisions, Out of Scope is not empty, and no section is a placeholder. Fix what fails, then present the draft and ask whether to save it (suggest `<repo>/.prompts/prd-<feature>.md` as the default path).

<prd-template>

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

This list of user stories should be extremely extensive and cover all aspects of the feature.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Out of Scope

A description of the things that are out of scope for this PRD.

## Further Notes

Any further notes about the feature.

</prd-template>
