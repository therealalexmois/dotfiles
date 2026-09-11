# Roadmap data contract

## Top-level shape

```json
{
  "meta": {
    "id": "stable-kebab-case-id",
    "title": "Human-readable title",
    "goal": "Observable terminal capability",
    "audience": "Learner baseline",
    "generated_at": "2026-08-17",
    "language": "ru",
    "assumptions": []
  },
  "stages": [{"id": "foundations", "title": "Foundations", "description": "Why this stage exists", "order": 1}],
  "nodes": [],
  "capstone": null
}
```

When present, `capstone` has this shape:

```json
{
  "title": "Progressive capstone title",
  "problem": "Concrete problem the learner must solve",
  "system_to_build": "Concrete system or artefact to implement",
  "functional_requirements": ["Required observable behaviour"],
  "constraints": ["Boundary or non-goal"],
  "starter_scope": ["Smallest initial implementation"],
  "deliverables": ["Final artefact"],
  "milestones": [{
    "id": "stable-milestone-id",
    "title": "Milestone title",
    "after_stage": "foundations",
    "task": "Concrete learner action",
    "related_nodes": ["node-id"],
    "deliverable": "Observable milestone artefact",
    "checks": ["Pass/fail check"]
  }],
  "acceptance_criteria": ["Final pass/fail criterion"]
}
```

`after_stage` places a milestone after the stage whose knowledge it integrates.
Every `related_nodes` entry references an existing node. Milestones are part of
the learning route, not an unrelated block at the bottom of the page.

## Node shape

```json
{
  "id": "unique-node-id",
  "stage": "foundations",
  "title": "Topic title",
  "summary": "What the topic contributes to the goal",
  "kind": "core",
  "prerequisites": [],
  "learning_outcomes": ["Observable outcome"],
  "sources": {"foundation": [], "deepening": [], "reference": []},
  "practice": [],
  "completion_criteria": ["Observable criterion"],
  "anki_cards": [],
  "socratic_recommended": false
}
```

Allowed `kind` values: `core`, `optional`, `deep-dive`, `remediation`, `reference`.

## Source shape

```json
{
  "title": "Source title",
  "url": "https://example.org/resource",
  "type": "official-docs",
  "why": "Specific learning outcome supported",
  "level": "intermediate",
  "language": "en",
  "estimated_minutes": 45,
  "verified_at": "2026-08-17"
}
```

## Practice shape

```json
{
  "title": "Exercise title",
  "type": "implementation",
  "task": "Concrete learner action",
  "constraints": ["Constraint"],
  "deliverable": "Observable artifact",
  "allowed_assistance": "Documentation only",
  "checks": ["Pass/fail check"]
}
```

## Anki card shape

```json
{
  "front": "One unambiguous prompt",
  "back": "One concise answer",
  "type": "basic",
  "tags": ["roadmap-id", "node-id", "mechanism"],
  "source": "https://example.org/resource"
}
```

Allowed card types: `basic`, `cloze`, `comparison`, `mechanism`, `scenario`, `misconception`, `prediction`.

## Graph invariants

- Every node ID is unique.
- Every node references an existing stage.
- Every prerequisite references an existing node.
- The prerequisite graph is acyclic.
- Every `core` node traces to the terminal goal.
- `reference` nodes cannot block completion of the base route.
- A `core` node can depend only on `core` or `remediation` nodes so its route
  remains complete in the default base view.
- A node cannot depend on a later concept merely because it appears later visually.
- A non-null capstone contains a concrete brief, at least one final deliverable,
  one stage-linked milestone, and one acceptance criterion.
- Every milestone references an existing stage and at least one existing node.
- Required capstone milestones reference only `core` or `remediation` nodes.
  Optional and deep-dive nodes may suggest separate extensions but cannot become
  hidden requirements of the base route.

## Presentation invariants

- Prerequisites are the only source of truth for graph edges and route state.
- Nodes with no prerequisites are visible starting points.
- A not-started node is available only when all prerequisites are completed.
- Internal IDs never appear as user-facing prerequisite labels.
- The overview contains compact nodes; detailed learning content opens on demand.
- The base route is the default view. Optional and deep-dive branches remain
  discoverable without competing with the main route.

## Local bundle constraint

The builder emits `roadmap-data.js` rather than fetching JSON at runtime so the website works when opened directly with `file://`.
