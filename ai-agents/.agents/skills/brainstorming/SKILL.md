---
name: brainstorming
description: "Design complex or materially uncertain changes before implementation: architecture redesigns, multi-service work, security-sensitive changes, database migrations, and public API contracts. Explore requirements and trade-offs, then record a proportionate design. For small or medium engineering decisions, use brainstorm-lite instead."
metadata:
  origin: derived
  upstream: https://github.com/obra/superpowers/tree/main/skills/brainstorming
  imported_at: 2026-06-03
---

# Brainstorming Ideas Into Designs

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Use this workflow when the task has architectural consequences or a user choice could materially change the outcome. For a small or medium scoped change, use `brainstorm-lite` instead. A clear, already-authorized implementation does not need a new approval gate.

## Checklist

1. **Explore project context** - read relevant files, contracts, docs, and recent changes.
2. **Clarify material uncertainty** - ask focused questions only when the answer changes the design and cannot be inferred safely. Use a visual aid when it materially clarifies a decision.
3. **Compare viable approaches** - present meaningful alternatives, trade-offs, and a recommendation. Do not invent options solely to reach a fixed count.
4. **Describe the design** - cover boundaries, data flow, failure handling, and verification in proportion to the task. Request a decision only if a material choice remains unresolved.
5. **Record and review** - write a spec when its complexity warrants a persistent artifact or the user asks for one. Review it for placeholders, consistency, scope, and ambiguity.
6. **Continue authorized work** - hand off to a plan or implementation as appropriate. Ask before a material expansion of scope or an irreversible action that lacks authorization.

## Process Flow

Explore context -> resolve material choices -> compare approaches -> describe and review design -> plan or implement authorized work.

## The Process

**Understanding the idea:**

- Check out the current project state first (files, docs, recent commits)
- Before asking detailed questions, assess scope: if the request describes multiple independent subsystems (e.g., "build a platform with chat, file storage, billing, and analytics"), flag this immediately. Don't spend questions refining details of a project that needs to be decomposed first.
- If the project is too large for a single spec, help the user decompose it into independent pieces and sequence them.
- For appropriately scoped projects, ask only questions that affect the outcome and cannot be answered from context.
- Prefer multiple choice questions when possible, but open-ended is fine too
- Group related questions when that makes a decision easier.
- Focus on understanding: purpose, constraints, success criteria

**Exploring approaches:**

- Compare viable approaches with their trade-offs; one clear option is sufficient when alternatives would be artificial.
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Presenting the design:**

- Once you believe you understand what you're building, present the design
- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Check understanding at decision points, not after every section.
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

**Design for isolation and clarity:**

- Break the system into smaller units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently
- For each unit, you should be able to answer: what does it do, how do you use it, and what does it depend on?
- Can someone understand what a unit does without reading its internals? Can you change the internals without breaking consumers? If not, the boundaries need work.
- Smaller, well-bounded units are also easier for you to work with - you reason better about code you can hold in context at once, and your edits are more reliable when files are focused. When a file grows large, that's often a signal that it's doing too much.

**Working in existing codebases:**

- Explore the current structure before proposing changes. Follow existing patterns.
- Where existing code has problems that affect the work (e.g., a file that's grown too large, unclear boundaries, tangled responsibilities), include targeted improvements as part of the design - the way a good developer improves code they're working in.
- Don't propose unrelated refactoring. Stay focused on what serves the current goal.

## After the Design

**Documentation:**

- When a persistent spec is useful, write it at the location required by the project or user. Use `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` only when no convention exists.
- Commit only when the user has explicitly requested a commit.

**Spec Self-Review:**
After writing the spec document, look at it with fresh eyes:

1. **Placeholder scan:** Any "TBD", "TODO", incomplete sections, or vague requirements? Fix them.
2. **Internal consistency:** Do any sections contradict each other? Does the architecture match the feature descriptions?
3. **Scope check:** Is this focused enough for a single implementation plan, or does it need decomposition?
4. **Ambiguity check:** Could any requirement be interpreted two different ways? If so, pick one and make it explicit.

Fix issues inline. Ask for user input only when a material design choice remains unresolved or the next action requires separate authorization.

**Implementation:**

- Use `writing-plans` if the task needs a detailed multi-step implementation plan. Otherwise continue with the authorized implementation.

## Key Principles

- **Focused questions** - Ask only what the design cannot resolve from context; group related questions when helpful.
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Compare meaningful options when they exist.
- **Incremental validation** - Verify decisions as the design takes shape.
- **Be flexible** - Go back and clarify when something doesn't make sense

## Visual Companion

The browser companion is optional. Use it for mockups, layouts, or diagram comparisons when it materially improves a design decision and the required tool access is already authorized. Otherwise use text or a static diagram and continue the design. Do not pause an authorized task to offer the companion or seek a separate conversational approval for it.

Before using the browser companion, read `references/visual-companion.md`. Follow any tool-level approval required to open a browser.
