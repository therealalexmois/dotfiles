---
name: uml
description: >-
  Write UML diagrams as PlantUML text: pick the diagram type, declare the elements and their
  relationships, apply styling, and return the source in a plantuml fence that renders in Markdown
  and wikis. Covers class, sequence, activity, state machine, component, use case, deployment,
  object, package, communication, composite structure, interaction overview and profile diagrams,
  plus a bundled stencil reference for cloud, network and infrastructure icon sets. Use when the
  user asks to draw, model or diagram a system, requests any of those diagram types by name, or
  wants a diagram kept as text in a document rather than as an image file.
metadata:
  version: "1.0"
  origin: first-party
---

# UML Diagram Generator
**Quick Start:** Choose diagram type → Write PlantUML text → Define elements and relationships → Wrap in ` ```plantuml ` fence.
> ⚠️ **IMPORTANT:** Always use ` ```plantuml ` or ` ```puml ` code fence. NEVER use ` ```text ` — it will NOT render as a diagram.

## Critical Rules

- Every diagram starts with `@startuml` and ends with `@enduml`
- Use standard PlantUML keywords: `class`, `interface`, `abstract`, `enum`, `actor`, `participant`, `component`, `node`, `database`, `package`
- Relationships use arrow syntax: `-->`, `<|--`, `*--`, `o--`, `..>`, `..|>`
- Use `skinparam` for global styling and colors
- Use `#color` on individual elements for specific colors
- Notes use `note left of`, `note right of`, `note over`, or standalone `note "text" as N`

## UML Diagram Types
| Type | Purpose | Key Syntax |
|------|---------|------------|
| Class | Class structure and relationships | `class`, `interface`, `<\|--` |
| Sequence | Message interactions over time | `participant`, `->`, `-->` |
| Activity | Workflow and process flow | `start`, `:action;`, `if/else` |
| Swimlane Activity | Multi-role activity with swimlanes | `\|Lane\|`, `:action;` |
| State Machine | Object lifecycle states | `state`, `[*] -->` |
| Component | System component organization | `component`, `[name]`, `interface` |
| Use Case | User-system interactions | `actor`, `usecase`, `(name)` |
| Deployment | Physical deployment architecture | `node`, `artifact`, `database` |
| Object | Runtime object snapshot | `object "name" as id` |
| Package | Module organization | `package "name"` |
| Communication | Object collaboration | Numbered messages with sequence syntax |
| Composite Structure | Internal class structure | `component` with nested `port` |
| Interaction Overview | Activity + sequence combination | `group`, `ref over` |
| Profile | UML extension mechanisms | `<<stereotype>>` labels |

A minimal working diagram for each of these types lives in [references/diagram-examples.md](references/diagram-examples.md) - read it when the type is unfamiliar or the syntax tokens above are not enough.

## Mxgraph Stencil Icons

draw-uml supports 9500+ mxgraph stencil icons (AWS, Azure, Cisco, Kubernetes, etc.) via the `mxgraph.*` syntax. Default colors are applied automatically — you do NOT need to specify `fillColor` or `strokeColor`.

**Full stencil reference:** See [references/README.md](references/README.md).

### Syntax

```
mxgraph.<namespace>.<icon> "Label" as <alias>
mxgraph.<namespace>.<icon> "Label" as <alias> #color
mxgraph.<namespace>.<icon> <alias>
```

- `mxgraph.<namespace>.<icon>` — the stencil shape key (e.g. `mxgraph.aws4.lambda`, `mxgraph.kubernetes.pod`)
- `"Label"` — display text (quoted if contains spaces, unquoted for single word)
- `as <alias>` — identifier for use in relationships
- `#color` — optional override color (e.g. `#FF6600`, `#LightBlue`)

### Examples

```plantuml
@startuml
' Simple icon declaration
mxgraph.aws4.lambda "Lambda\nFunction" as fn
mxgraph.aws4.api_gateway "API GW" as gw
mxgraph.aws4.dynamodb "DynamoDB" as db

gw --> fn
fn --> db
@enduml
```

```plantuml
@startuml
' Kubernetes architecture with icons
mxgraph.kubernetes.ing "Ingress" as ing
mxgraph.kubernetes.svc "Service" as svc
mxgraph.kubernetes.pod "Pod" as pod
mxgraph.kubernetes.deploy "Deployment" as deploy

ing --> svc
svc --> pod
deploy --> pod
@enduml
```

```plantuml
@startuml
' Mixing standard UML with stencil icons
node "Cloud" {
  mxgraph.aws4.ec2 "EC2" as ec2
  mxgraph.aws4.rds "RDS" as rds
}
database "Legacy DB" as legacy

ec2 --> rds
rds --> legacy
@enduml
```
