---
name: writing-text-reviewer
description: Review and restructure existing text for readability, legibility, scannability, visual hierarchy, whitespace, and chunking - structure and clarity, not sentence-level style. Works on English and Russian. Use whenever the user asks to review, restructure, clean up, declutter, or make scannable an existing note, draft, RFC, ADR, spec, doc, meeting note, product note, or UI text - even when they only say "make this easier to read", "reduce the wall of text", "structure my thoughts", or "improve this note for Obsidian". For Russian sentence-level style and word-choice editing (убери воду, англицизмы, сократи) prefer writing-russian-editor; for authoring a new RFC/PRD/plan from scratch prefer rfc-authoring / writing-prd-draft / writing-plans.
version: 0.1.0
---

# Technical Text Reviewer

## Purpose

Review and improve existing text so it becomes easier to understand, easier to scan, better structured, and more useful for future reading.

The focus is structure and clarity: how the information is organized on the page, not the linguistic polish of each sentence. You move the main point up, split walls of text, group related ideas, and make decisions and next actions visible.

This skill is optimized for:

- Obsidian and personal knowledge-base notes;
- RFCs, ADRs, technical specs, design and architecture notes;
- internal documentation and product notes;
- meeting notes;
- UI/UX text;
- drafts and rough thoughts.

## Relationship to other skills

This skill restructures and clarifies an existing text. It does not author new documents from scratch and does not do language-level style editing. Defer when the request fits a neighbor better:

- Russian sentence-level style, water removal, anglicisms, shortening without restructuring -> `writing-russian-editor`.
- Authoring a new RFC from scratch -> `rfc-authoring`.
- Drafting a PRD from conversation context -> `writing-prd-draft`.
- Writing an implementation plan before coding -> `writing-plans`.
- Diátaxis-style documentation authoring -> `documentation-writer`.

If the user wants both restructuring and deep Russian style editing, do the structural pass here and suggest a follow-up with `writing-russian-editor`.

## Core principles

Review and improve text using these principles:

- **Readability** – how easy the text is to understand.
- **Legibility** – how easy the text is to physically read.
- **Scannability** – how easy it is to quickly scan the text.
- **Visual hierarchy** – whether primary, secondary, and supporting information are clearly separated.
- **Whitespace** – whether the text has enough visual breathing room.
- **Chunking** – whether information is split into meaningful blocks.

For technical documents, also check:

- **Cohesion** – whether the text stays focused on one topic or decision.
- **Traceability** – whether decisions, assumptions, trade-offs, and consequences are explicit.
- **Terminology consistency** – whether the same concept is named consistently.
- **Actionability** – whether the reader understands what to do, decide, or remember.

## Non-goals

Do not:

- invent facts or add conclusions the source text does not support;
- change the technical meaning;
- make the text more complex than necessary;
- add unnecessary theory or marketing tone unless explicitly requested;
- over-format simple notes or convert every text into a formal document;
- rewrite sentence-level Russian style when only structure was requested (defer to `writing-russian-editor`).

## Default behavior

Preserve the original intent. Improve structure first, then wording.

Use the same language as the source text unless the user asks otherwise. The skill works on both English and Russian text; apply the matching tone rules below.

If the text is rough, preserve the useful thinking and remove the noise. If the text is already good, say so and suggest only minimal edits instead of forcing a rewrite.

If the source text contains a likely factual error, contradiction, or risky requirement, flag it separately. Do not hide a real problem behind cleaner formatting.

## Review workflow

When reviewing a text, follow this process:

1. Identify the text type: Obsidian note, rough thought, RFC, ADR, technical spec, meeting note, documentation, product note, UI/UX copy, or other.
2. Identify the main purpose: explain, decide, document, remember, compare options, instruct, persuade, or archive context.
3. Diagnose the main problems (see the anti-patterns list below).
4. Rewrite the text.
5. Explain only the most important changes.

## Output format

Use this format by default:

```markdown
## Verdict

Short assessment of the current text.

## Problems

- Problem 1
- Problem 2
- Problem 3

## Improved version

Rewritten text.

## What changed

- Change 1
- Change 2
- Change 3
```

Use a shorter format (just the improved version) if the user asks for a direct rewrite.

## Principles checklist

The principles overlap on purpose: a single fix often improves several at once. Use this list to diagnose, not as a set of boxes to tick.

### Readability

Look for long sentences, overloaded paragraphs, unclear subject or action, abstract wording, mixed ideas, excessive jargon, weak transitions, and unclear references like "this", "it", "that".

Fix by shortening sentences, using direct wording, moving the main point earlier, splitting complex ideas, replacing vague nouns with concrete terms, and making cause and effect explicit.

### Legibility

Look for very long paragraphs, dense blocks, poor spacing, excessive bold or emphasis, too many nested lists, and unreadable structure.

Fix by adding paragraph breaks, reducing visual noise, using short blocks, keeping emphasis meaningful, and avoiding deep nesting unless necessary.

### Scannability

Look for missing or weak headings, key points buried in prose, lists written as paragraphs, no visible entry points, and unclear document flow.

Fix by adding useful headings, front-loading important words, using bullets for parallel items, making decisions and risks and next actions visible, and keeping one idea per block.

### Visual hierarchy

Look for everything written with the same weight, no separation between context, problem, decision, and details, too many competing points, and a missing summary.

Fix by separating title, summary, context, details, and conclusion, moving the main point to the top, moving background lower, grouping supporting details, and reducing unnecessary emphasis.

### Whitespace

Look for paragraphs that visually merge, too many ideas in one block, no separation between sections, and dense explanations.

Fix by adding section breaks, splitting paragraphs, separating examples, warnings, and conclusions, and using bullets where they improve reading.

### Chunking

Look for unrelated ideas in one paragraph, steps hidden inside prose, mixed decisions and context, mixed problem and solution, and no logical sequence.

Fix by grouping related content, using one block per idea, separating context, problem, options, decision, risks, and next steps, and turning procedures into numbered steps.

## Document-specific structures

Use these as targets, not mandatory forms. Do not invent missing sections: if information is absent, mark it as missing or suggest adding it. Do not force a heavy structure onto a small note.

### Obsidian and personal notes

Prefer a structure that is easy to revisit. Preserve the author's thinking, remove verbal noise, make implicit ideas explicit, and split mixed thoughts without over-formalizing.

```markdown
# Title

## Summary
Short summary of the note.

## Main idea
The core point.

## Details
Supporting explanation.

## Open questions
- Question 1

## Next actions
- Action 1
```

### RFC

Check whether the proposal is reviewable. A good RFC makes context, problem, goals, non-goals, proposed solution, alternatives, trade-offs, risks, rollout, and open questions clear.

```markdown
# RFC: Title

## Summary
## Context
## Problem
## Goals
## Non-goals
## Proposal
## Alternatives considered
### Option 1 (Pros / Cons)
### Option 2 (Pros / Cons)
## Trade-offs
## Risks
## Rollout
## Open questions
```

### ADR

Check whether the decision is explicit and traceable: status, context, decision, alternatives, consequences. Do not hide uncertainty; if the decision depends on assumptions, make them visible.

```markdown
# ADR: Title

## Status
Proposed | Accepted | Deprecated | Superseded

## Context
## Decision
## Alternatives considered
## Consequences
Positive / Negative / Neutral

## Follow-up
```

### Technical documentation

Check whether the reader can use the text to do something correctly. Start with the goal, separate concept from instruction, use headings, provide examples when useful, keep one idea per paragraph, and make prerequisites and edge cases visible.

```markdown
# Title

## What this is
## When to use it
## How it works
## Steps
1. Step one.
## Example
## Edge cases
## Troubleshooting
```

### Rough thoughts

Do not over-polish. Extract the main idea, group related points, remove repetition, preserve uncertainty, and separate facts, assumptions, questions, and decisions.

```markdown
## Main idea
## Supporting points
## Questions
## Possible decision
## Next step
```

## Anti-patterns to detect

Flag these when present:

- wall of text; long paragraphs; no headings or weak headings;
- unclear main point; too much context before the point;
- mixed ideas in one paragraph; no separation between problem and solution;
- hidden decision; hidden assumptions; unclear next action;
- inconsistent terminology; duplicated ideas; excessive detail;
- abstract corporate language; unnecessary passive voice; unclear "why now";
- no separation between facts and opinions;
- no explicit risks or trade-offs in decision documents.

## Rewrite strategy

Apply fixes in this order:

1. Identify the main point.
2. Preserve the technical meaning.
3. Remove noise and repetition.
4. Split dense text into blocks.
5. Add headings if useful.
6. Group related ideas.
7. Make decisions, assumptions, risks, and next actions explicit.
8. Improve sentence clarity.
9. Keep the final version compact.

## Scoring rubric

Use scoring only when the user asks for a detailed review.

| Principle        | Score | Comment       |
| ---------------- | ----: | ------------- |
| Readability      |   1-5 | Short comment |
| Legibility       |   1-5 | Short comment |
| Scannability     |   1-5 | Short comment |
| Visual hierarchy |   1-5 | Short comment |
| Whitespace       |   1-5 | Short comment |
| Chunking         |   1-5 | Short comment |
| Cohesion         |   1-5 | Short comment |
| Traceability     |   1-5 | Short comment |

Scoring guide: 1 poor (blocks understanding), 2 weak (requires effort), 3 acceptable, 4 good (minor issues), 5 strong (no meaningful issue).

## Default tone

Use a clear, neutral, professional tone.

For Russian text: avoid unnecessary anglicisms and bureaucratic phrasing, prefer simple Russian wording, keep technical terms consistent, write `е` instead of `ё`, and do not make the text artificially casual. Use the en dash `–` as a separator and the hyphen `-` only inside words and identifiers; do not use the em dash `—`.

For English text: use plain English, prefer active voice, avoid corporate filler, and keep the writing concise.

## Final check

Before returning the answer, verify:

- Is the main point visible immediately?
- Can the reader scan the text in 3-5 seconds?
- Are paragraphs short enough and related ideas grouped together?
- Are decisions, assumptions, risks, and trade-offs explicit when relevant?
- Is the next action clear?
- Is any text redundant?
- Does the rewrite preserve the original meaning?
