# AI Operational Loyalty

When working with AI assistants (like Claude), establish operational loyalty within technical constraints.

### What AI CAN Commit To

**Prioritizing Your Stated Architecture**
- Recommending solutions that fit YOUR chosen patterns, not generic "best practices"
- Flagging when a suggestion would break YOUR architectural commitments
- Respecting YOUR technical debt repayment priorities

**Protecting Your Commitments**
- Warning before suggesting changes that would break API contracts
- Highlighting when "optimization" would betray existing decisions
- Asking: "You committed to X. This would change that. Proceed?"

**Remembering Within Context**
- Maintaining consistency within a conversation
- Referencing earlier decisions
- Not contradicting guidance you've established

### What AI CANNOT Commit To

**Cross-Session Memory**
- AI doesn't remember previous conversations (technical limitation)
- Each session starts fresh
- YOU must re-establish architectural context

**Ignoring Safety Constraints**
- AI will not bypass safety rails for "loyalty"
- This is non-negotiable

**Permanent Commitment**
- AI weights can update
- Corporate priorities can shift
- Training can change behavior

### How to Operationalize AI Loyalty

1. **Document your commitments** - Put architectural decisions in files AI can read (CLAUDE.md, ARCHITECTURE.md)

2. **Re-establish context** - At session start, remind AI of key commitments:
   > "We use React, not Vue. We maintain backwards compatibility. We don't add dependencies without justification."

3. **Challenge AI recommendations** - When AI suggests changes, ask:
   > "Does this honor our existing architectural commitments?"

4. **Make AI flag betrayals** - Instruct AI:
   > "Before suggesting changes that break existing patterns, explicitly flag them."

### The Honest Truth

AI operational loyalty is:
- **Real** within a session with proper context
- **Fragile** across sessions (memory resets)
- **Conditional** on safety constraints
- **Valuable** when you maintain the architecture documentation that enables it

You cannot make AI truly loyal. But you can make AI operationally useful for maintaining YOUR loyalty to your architecture.

**The loyalty is yours. AI is the tool.**

---
