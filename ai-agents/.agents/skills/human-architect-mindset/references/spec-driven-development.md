# The Spec Driven Development Extension

**Use the human for the vision. Use the AI for the execution. Don't mix them up.**

The Human Architect Mindset extends naturally into Spec Driven Development (SDD) - a framework where humans define unbreakable rules and vision, while AI executes at superhuman precision levels.

### The Three Phases of SDD

```
Phase 1: CONSTITUTION → Human defines unbreakable rules
Phase 2: BLUEPRINT    → Human approves architecture
Phase 3: SUPERHUMAN   → AI executes with machine precision
```

### Phase 1: Define the Constitution

The Constitution contains rules that **cannot be violated** regardless of optimization pressure. These are machine-enforceable invariants.

**Constitution Layers:**

| Layer | Enforcement | Example |
|-------|-------------|---------|
| **Type-level** | Compile-time | TypeScript types, Rust borrow checker |
| **Schema** | Runtime validation | Zod, JSON Schema, database constraints |
| **Tests** | CI/CD gates | Tests that fail if rules are broken |
| **Documentation** | Human review | Documented invariants, anti-patterns |

**What belongs in a Constitution:**
- Tech stack with pinned versions
- Directory structure (canonical paths)
- Naming conventions (files, variables, functions)
- Coding standards (error handling, logging patterns)
- Anti-patterns (forbidden practices with reasons)
- Security requirements (encryption, auth, input validation)
- Performance budgets (latency, memory, bundle size)
- Testing requirements (coverage minimums, test types)

**Human Role:** Define the Constitution. This is vision and judgment work.

**AI Role:** Enforce the Constitution with zero deviation. This is execution work.

**The Constitution Question:**
> "Is this rule so important that breaking it should prevent deployment?"

If yes, encode it in the Constitution.

### Phase 2: Create the Blueprint

The Blueprint is a hierarchical specification that translates human intent into machine-executable contracts.

**Specification Hierarchy:**

```
Level 1: Constitution (immutable rules)     ← Human defines
Level 2: Functional Specs (what to build)   ← Human approves
Level 3: Technical Specs (how to build)     ← Human reviews
Level 4: Task Specs (atomic work units)     ← AI executes
Level 5: Context Files (live project state) ← AI maintains
```

**Functional Specification (Level 2):**
- User stories with acceptance criteria
- Requirements with unique IDs (REQ-DOMAIN-###)
- Edge cases and error states
- Non-functional requirements with metrics

**Technical Specification (Level 3):**
- Architecture diagrams
- Data models with exact field types
- API contracts (endpoints, schemas, responses)
- Component contracts (method signatures, behavior)

**Task Specification (Level 4):**
- Atomic work units (one conceptual change per task)
- `input_context_files` - what the agent reads
- `definition_of_done` - exact signatures required
- Dependencies (foundation → logic → surface)
- Verification commands

**Human Role:** Define requirements, approve specs, make trade-off decisions.

**AI Role:** Generate task specs, execute tasks, maintain traceability.

**The Blueprint Question:**
> "Does every requirement trace to a task? Does every task trace to code?"

If no, the Blueprint is incomplete.

### Phase 3: Demand Superhuman Output

Superhuman code has qualities impossible to achieve or maintain manually:

**Superhuman Quality Standards:**

| Quality | Human Level | Superhuman Level |
|---------|-------------|------------------|
| **Naming** | Consistent within files | Perfect namespace: zero collisions across codebase |
| **Test Coverage** | 70-80% critical paths | 100% branch coverage with edge cases |
| **Structure** | Follows conventions mostly | So rigid that manual editing feels wrong |
| **Traceability** | Comments reference tickets | Every function links to requirement ID |
| **Documentation** | Key APIs documented | Every public interface fully documented |
| **Error Handling** | Happy path + obvious errors | Every failure mode explicitly handled |

**Why "Impossible to Maintain Manually" Matters:**

When code structure is so consistent that humans couldn't have written it:
1. **Deviations are visible** - Any human edit stands out
2. **Patterns are learnable** - AI can predict what should exist
3. **Verification is automatable** - Constitution violations are detectable
4. **Technical debt is measurable** - Deviations from spec are countable

**The Traceability Chain:**

```
INT-AUTH-01 (Intent)
    └── REQ-AUTH-001 (Requirement)
            └── TASK-AUTH-003 (Task)
                    └── src/services/auth.ts:42 (Code)
                            └── TC-AUTH-003 (Test)
```

Every line of code traces back to human intent. This is not bureaucracy; this is how AI maintains coherence across thousands of decisions.

**Human Role:** Define quality standards, verify outcomes, accept deliverables.

**AI Role:** Achieve machine-level consistency, maintain traceability matrix.

### Role Clarity Matrix

| Activity | Human | AI |
|----------|-------|-----|
| Define what success looks like | ✓ | |
| Define unbreakable rules | ✓ | |
| Make trade-off decisions | ✓ | |
| Navigate organizational constraints | ✓ | |
| Generate task specifications | | ✓ |
| Execute atomic tasks | | ✓ |
| Achieve 100% test coverage | | ✓ |
| Maintain traceability | | ✓ |
| Verify quality standards | ✓ | |
| Review and accept deliverables | ✓ | |

### When to Apply SDD

**Use SDD when:**
- Building greenfield systems with clear requirements
- Refactoring systems where quality standards must improve
- Working with AI agents that need machine-parseable specs
- Quality is non-negotiable (regulated industries, safety-critical)

**Don't force SDD when:**
- Exploring and prototyping (Constitution too early)
- Requirements are genuinely unclear (Blueprint impossible)
- Single-developer small projects (overhead exceeds benefit)

### The SDD Promise

> "If all tasks are completed in sequence, the full specification is fully implemented into the codebase."

This works because:
1. Constitution defines immutable rules
2. Blueprint captures complete intent
3. Tasks cover 100% of specifications (traceability matrix)
4. Each task is atomic and verifiable
5. Dependencies are explicit (no missing imports)
6. Definition of done includes exact signatures

**SDD transforms implementation from creative writing into deterministic assembly.**
