---
name: call-tracer
disable-model-invocation: true
description: Trace a function or method call chain across the layers of a codebase and render it as a clean ASCII tree. Use whenever the user wants to understand how a symbol is called through the system, trace its dependencies, see the full call stack, or asks about method flow, call graph, or execution path. Handles both upstream (callers) and downstream (callees) tracing with depth control.
---

<!-- Provenance: adapted from hwaas/hwaas-go .nessy/skills/call-tracer, MR 1150. Tool vocabulary and examples generalized for Claude Code. -->

# Call Tracer

Trace a single function or method through the layers of a codebase and produce a clean ASCII tree of the actual call chain. The output shows the path of execution, not every method in every file.

## When to Use

- User wants to trace how a function or method is called through the system
- User needs the full execution path of a function
- User asks about call graphs, method flows, or dependencies
- User wants to see what calls a specific symbol (upstream) or what a symbol calls (downstream)

## Configuration

Accept these parameters from the request (defaults shown):

- `target_symbol`: name of the function or method to trace (required)
- `target_file`: path to the file containing the symbol (optional; search if omitted)
- `direction`: `both` | `upstream` | `downstream` (default: `both`)
- `max_depth`: integer (default: `10`)

## Core Principles

### 1. Show the Call Chain, Not All Methods

DO: trace the actual execution path, what calls what, in sequence.
DON'T: enumerate every method found in every file.

Good tracing:
```
Handler.GetItem()
└── service.GetItem()
    └── repository.Find()
        └── SQL SELECT [external DB call]
```

Bad enumeration (avoid):
```
Handler.GetItem()
├── GetItem() [file1]
├── GetItem() [file2]
├── GetItem() [file3]
├── SomeOtherMethod() [file1]
├── AnotherMethod() [file2]
...
```

### 2. Clean ASCII Trees Only

DO: output ASCII trees built from `├──`, `└──`, `│`.
DON'T: output JSON, YAML, or other structured formats.

### 3. Brief Inline Notes

DO: add a short one-line note explaining what each call does.
DO: show layer boundaries clearly (Handler, Service, Repository/Client, External).
DON'T: write paragraphs or long explanations.
DON'T: strip all context, leaving bare names.

Good balance:
```
├── handler.GetItem()
│   └── service.GetItem() [service layer]
│       └── repository.Find() [data access]
│           └── SQL SELECT items WHERE id = ? [external DB]
└── mapper.ToResponse()
    └── Transform row into response DTO [response formatting]
```

Too sparse (avoid):
```
├── handler.GetItem()
│   └── service.GetItem()
│       └── repository.Find()
│           └── query()
```

Too verbose (avoid):
```
├── handler.GetItem()
│   │   This is the HTTP handler that receives the request
│   │   Located at internal/api/handler.go:142
│   │   It implements the ItemServer interface and validates input
│   └── service.GetItem()
│       │   The service layer holds business logic and selects a repository
│       └── ...
```

## Process

### 1. Parse the Request

Extract the target symbol, optional target file, direction, and max depth. If the file is not given, locate it from the symbol name (see step 2).

### 2. Locate the Target

1. Find the definition. If the file is known, Read it. Otherwise use Grep for the definition (for example `func .*GetItem` in Go, `def get_item` in Python, `GetItem(` for a method) and Glob to narrow candidate files.
2. Identify the signature and, for methods, the receiver or owning type.
3. Note whether the symbol satisfies an interface or abstract method; record this for interface resolution.

### 3. Trace Downstream (What the Symbol Calls)

1. Read the body of the target.
2. Identify the main calls that form the execution flow.
3. For each call, follow to its implementation and recurse up to `max_depth`.

Include:
- Direct calls that are part of the flow
- Interface or abstract calls, resolved to their concrete implementation
- External calls (HTTP, database, queue, filesystem)

Skip:
- Helper calls that do not change the flow
- Logging and debug calls
- Pure error-handling wrappers

### 4. Trace Upstream (What Calls the Symbol)

1. Use Grep to find all occurrences of the symbol name across the repo.
2. Keep actual call sites, drop bare references (imports, comments, string matches).
3. Group call sites by entry point (HTTP/gRPC handler, CLI command, scheduled job, message consumer).
4. Trace back to the root callers up to `max_depth`.

### 5. Build the ASCII Tree

Format:
```
=== UPSTREAM CALLERS ===
├── Entry Point 1
│   └── Intermediate caller
│       └── TARGET_SYMBOL()
└── Entry Point 2
    └── TARGET_SYMBOL()

=== TARGET ===
TARGET_SYMBOL() [file:line]

=== DOWNSTREAM CALLEES ===
├── Main call 1
│   └── Sub call
│       └── External call
└── Main call 2
    └── Data transformation
```

Rules:
- Use `├──` for a branch with more siblings, `└──` for the last sibling, `│` for vertical continuation.
- Indent four spaces per level.
- Show a file path only for cross-package or cross-module calls: `[package/file]`.
- Mark interface or abstract calls with `(interface)`.
- Mark external calls with `(external)` or a short description of the call type.

### 6. Present the Result

1. Header: target symbol, file, direction, max depth.
2. ASCII tree: the call chain.
3. Summary: nodes traced, max depth reached, notable layers or patterns.

Keep it concise: no JSON, no large code blocks, no exhaustive file listings. Focus on the flow.

## Important Considerations

### Interface Resolution

When a call goes through an interface or abstract type (for example `svc.GetItem()` where `svc` has an interface type):

1. Find the interface or abstract definition.
2. Find the concrete implementation(s).
3. Trace into the implementation; do not stop at the interface.

If several implementations exist and the concrete one is not obvious from context, list the candidates and trace the most likely one, noting the ambiguity.

### Avoiding Infinite Loops

- Maintain a visited set of `(file, symbol)` pairs.
- When a call leads back to a visited node, mark it as recursive and do not expand it again.
- Stop at `max_depth` regardless.

### Output Quality

Good output:
- Readable at a glance
- Shows the real execution flow
- Minimal visual noise
- File paths only where they add context

Bad output:
- Wide trees that need horizontal scrolling
- File citations on every node
- JSON or structured data mixed in
- All methods enumerated instead of the chain traced

## Example Output

Generic Go example, no internal paths:
```
Call Trace for: GetItem()
File: internal/api/handler.go
Direction: downstream | Max Depth: 10

=== TARGET ===
GetItem(ctx, req)
  └── handler.go:142 [HTTP handler entry point]

=== DOWNSTREAM CALLEES ===
├── itemService.GetItem() (interface)
│   └── serviceImpl.GetItem() [service layer]
│       ├── cache.Get(key) [lookup before DB]
│       └── itemRepo.Find() (interface)
│           └── repoImpl.Find() [repository]
│               └── db.QueryRowContext(...) [external DB]
│                   └── SQL SELECT items WHERE id = ?
└── mapper.ToResponse()
    └── Transform row into response DTO [response formatting]

---
Summary: 9 nodes traced, max depth 6 reached
Key layers: HTTP Handler -> Service -> Repository -> External DB
```

## Tips

- Start with defaults: `both` direction and depth `10` cover most cases.
- Trace upstream when debugging "who calls this?".
- Trace downstream when understanding "what does this trigger?".
- Specify the file when the symbol name is common across the codebase.
- For independent branches that are expensive to follow, dispatch parallel Task subagents and merge their subtrees.

## Tools

- Read: read source files
- Grep: find definitions and call sites
- Glob: find candidate files by pattern
- Task: spawn subagents for parallel tracing of independent branches

## Notes

- The approach is language-neutral; the Go example is illustrative only.
- ASCII is chosen for terminal and Markdown compatibility.
- Prioritize clarity over completeness: show the flow, not everything.
