---
name: create-learning-roadmap
description: Create evidence-based, personalized learning roadmaps as interactive local HTML/CSS/JS bundles with dependency-aware topics, verified tiered sources, hands-on practice, completion criteria, progress tracking, and source-linked Anki cards. Use when a user asks to build, generate, design, personalize, extend, or research a roadmap, study plan, learning path, curriculum, or structured path for mastering a topic or closing a knowledge gap. Also use when the user wants a roadmap.sh-style experience enriched with practice, spaced-repetition cards, or an interactive visual artifact.
---

# Create Learning Roadmap

Create an original, research-backed learning system. Treat roadmap.sh as a UX reference only; never copy or redistribute its roadmap content, visual identity, or proprietary materials.

## Core contract

Produce one coherent deliverable:

1. A dependency-aware learning graph.
2. Tiered and verified sources for every substantive node.
3. Practice with observable outputs and completion criteria.
4. Source-linked Anki cards for durable knowledge.
5. A static local website generated from the bundled template.

The website is a navigational roadmap, not a syllabus rendered as cards. Within
30 seconds, a first-time learner must be able to identify where to start, what
is available next, why another node is blocked, and what the capstone requires.

Do not conduct Socratic teaching. Only flag nodes where a separate Socratic session would be valuable.

## Select the workflow

- If the user requests only planning, research, review, or a prompt, stop at that requested artifact.
- If the user requests a roadmap, create the complete static bundle unless they explicitly request another format.
- If the user supplies an existing roadmap, preserve useful intent but independently verify its structure and sources.
- If the request concerns a narrow knowledge gap, create a bounded remediation roadmap instead of expanding to the whole discipline.

## Phase 1: discover the learner

Read [interview-model.md](references/interview-model.md). Conduct an adaptive interview until material uncertainty is resolved. Ask one to three questions per turn according to the user's interaction preference.

At minimum establish:

- target capability and application context;
- current level and already-mastered topics;
- constraints: time, language, cost, tools, accessibility;
- desired depth and evidence of mastery;
- available user-provided materials.

Do not ask for facts already stated. Do not build a full roadmap while the target capability or scope remains materially ambiguous.

## Phase 2: model the domain

Build a knowledge graph before selecting resources.

1. Define the terminal capability in observable terms.
2. Decompose it into outcomes, not chapter titles.
3. Identify prerequisites and remove circular dependencies.
4. Classify nodes as `core`, `optional`, `deep-dive`, `remediation`, or `reference`.
5. Separate the base path from goal-dependent branches.
6. Remove nodes that do not trace to the learner's goal.

Keep prerequisites as the single source of truth for navigation. Derive graph
edges, blocked states, available nodes, and the next-step recommendation from
them; do not duplicate the route as prose or a second sequence field.

Follow [roadmap-schema.md](references/roadmap-schema.md). Do not force a linear sequence when branches can be learned independently.

## Phase 3: research and select sources

Read [source-quality.md](references/source-quality.md).

For each substantive node:

1. Search broadly enough to identify authoritative candidates.
2. Open each selected source and confirm that it supports the stated learning outcome.
3. Prefer primary and official material when available.
4. Use community discussions only as supplementary operational evidence.
5. Record why the source is included, its level, language, expected effort, and verification date.
6. Divide selected resources into `foundation`, `deepening`, and `reference` tiers.

Never invent a URL, paper, book edition, author, duration, or source description. Mark unavailable or uncertain facts explicitly.

## Phase 4: design practice

Read [practice-design.md](references/practice-design.md).

Use a progression appropriate to the topic:

1. Recall or explain.
2. Apply in a bounded task.
3. Diagnose an error or weak solution.
4. Compare alternatives and make a decision.
5. Integrate adjacent nodes in a mini-project.
6. Transfer the knowledge to an unfamiliar situation.

Every task must state the learner action, constraints, expected artifact, allowed assistance, and verifiable completion criteria. Prefer a progressive capstone when the domain supports one.

For a progressive capstone, define the concrete problem, system or artefact to
build, boundaries, starter scope, final deliverables, and stage-linked milestone
tasks. Milestones must say what to do, which nodes they exercise, what to
produce, and how to check the result. Acceptance criteria without a task brief
are invalid.

## Phase 5: create Anki cards

Read [anki-card-design.md](references/anki-card-design.md).

Create cards only for durable knowledge: mental models, mechanisms, distinctions, decision criteria, common misconceptions, and stable constraints. Link every card to a source and roadmap node.

Generate both:

- human-readable cards inside the site;
- importable TSV with `front`, `back`, `type`, `tags`, and `source` fields.

Do not generate cards for easily searchable trivia, unstable version details, long enumerations, or material the source does not establish.

## Phase 6: render the static roadmap

Create a JSON document conforming to [roadmap-schema.md](references/roadmap-schema.md), then run:

```bash
python3 scripts/validate_roadmap.py roadmap.json
python3 scripts/build_roadmap.py roadmap.json --output learning-roadmap
```

The resulting bundle must contain:

```text
learning-roadmap/
├── index.html
├── styles.css
├── app.js
├── roadmap-data.js
└── anki-cards.tsv
```

Use the bundled template. Do not introduce frameworks, package managers, remote fonts, CDNs, analytics, or a server unless the user explicitly requests them.

The page must support:

- a compact dependency graph with visible directional edges;
- an explicit starting point and a progress-aware next-step recommendation;
- human-readable prerequisites and visible `available` and `blocked` states;
- expandable node details separated from the overview;
- base and deep-dive filtering;
- source links, practice, criteria, and cards;
- `not-started`, `in-progress`, and `completed` states;
- local progress persistence with graceful fallback;
- progress export/import;
- Anki TSV download;
- keyboard-accessible controls and responsive layout.

Default to the base route and progressive disclosure. Keep summaries, sources,
practice, completion criteria, and cards out of the graph surface until the
learner opens a node. Never expose internal node IDs in user-facing labels.

Before accepting the site, perform the 30-second orientation check using only
the rendered overview:

1. Identify the first node.
2. Identify the next available node.
3. Explain one blocked node from its visible prerequisites.
4. State what the capstone asks the learner to build.

## Phase 7: verify

Read [evaluation-rubric.md](references/evaluation-rubric.md). Run:

```bash
python3 scripts/validate_roadmap.py roadmap.json
python3 scripts/check_links.py roadmap.json
python3 scripts/build_roadmap.py roadmap.json --output learning-roadmap
```

Then inspect the generated page in a browser and verify interaction, layout, progress persistence, filters, imports, and downloads. Treat broken or unverified links as failures, not cosmetic warnings.

## Output communication

Lead with the created roadmap and its intended outcome. Briefly state:

- what the base route teaches;
- which branches are optional;
- how mastery is checked;
- where the website and Anki TSV are located;
- any source gaps or unresolved assumptions.

Do not claim that a learner has mastered a topic merely because they completed readings or checked a node.
