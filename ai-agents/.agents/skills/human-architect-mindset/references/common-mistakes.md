# Common Mistakes

### Mistake: Jumping to Technical Solutions

**Problem:** Proposing architecture before understanding domain.

**Fix:** Complete Phase 1 (Domain Discovery) before ANY technical discussion. Ask domain questions first.

### Mistake: Ignoring Constraints

**Problem:** Designing the "ideal" solution that can't ship.

**Fix:** Map constraints in Phase 3 BEFORE proposing solutions. A shippable 70% solution beats an unshippable perfect solution.

### Mistake: Missing External Dependencies

**Problem:** Treating external APIs/SDKs as stable.

**Fix:** Map ALL external dependencies in Phase 2. Ask: "What if this vendor changes their API tomorrow?"

### Mistake: Unbounded AI Tasks

**Problem:** Giving AI tasks like "refactor this" or "make it better."

**Fix:** Define clear input/output contracts. Every AI task should have verifiable success criteria.

### Mistake: No Human Checkpoints

**Problem:** Letting AI solve chains of tasks without verification.

**Fix:** Insert human checkpoints between AI chunks. Verify before proceeding.

### Mistake: Ignoring Politics

**Problem:** Pretending organizational constraints don't exist.

**Fix:** Explicitly ask about team boundaries, approval chains, and who has power vs. who has context.

### Mistake: Premature Optimization

**Problem:** Designing for scale you don't have.

**Fix:** Ask: "What scale are we actually at? What scale do we need in 12 months?" Design for that, not hypothetical millions.
