# Evaluation rubric

## Blocking checks

Any failure below blocks completion:

- malformed roadmap data;
- duplicate or missing IDs;
- missing prerequisite or cycle;
- substantive node without outcomes, sources, practice, or completion criteria;
- selected link that is broken or was not inspected;
- Anki card without a source;
- generated site that does not open locally;
- progress, filtering, import, or export interaction is broken.
- graph edges or direction are not visible in the rendered overview;
- starting and next available nodes cannot be identified from the overview;
- internal node IDs appear in user-facing prerequisite labels;
- node details overwhelm the graph instead of opening on demand;
- a non-null capstone lacks a concrete task brief or stage-linked milestones.

## Scored dimensions

Score each from 0 to 2.

| Dimension | 0 | 1 | 2 |
| --- | --- | --- | --- |
| Goal alignment | Generic syllabus | Mostly relevant | Every core node traces to goal |
| Coverage | Critical gaps | Minor gaps | Complete enough for target capability |
| Dependency model | Arbitrary order | Mostly plausible | Explicit, acyclic, justified graph |
| Sources | Weak/unverified | Mixed quality | Verified, authoritative, tiered |
| Practice | Vague activity | Some measurable work | Outcome-aligned and verifiable |
| Cards | Trivia or compound | Mostly usable | Atomic, durable, source-linked |
| Personalization | Cosmetic | Some adaptation | Scope and route reflect learner context |
| Interface | Route is unclear | Functions work but orientation requires reading | Start, direction, availability and details are immediately clear |

Target: no blocking failures and at least 14/16.

## Required eval scenarios

1. Broad technical field with multiple valid branches.
2. Narrow gap discovered during a real task.
3. Non-technical applied field.
4. Learner with partial prior completion.
5. Underspecified request where the skill must interview rather than generate prematurely.

For at least one scenario, verify that an irrelevant popular topic is intentionally excluded.

For every rendered scenario, run a 30-second orientation check. Without opening
node details, identify the first node, one next available node, the prerequisite
that blocks another node, and the capstone system to build. Any failed answer is
an interface failure even when the underlying graph data is correct.
