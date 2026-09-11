# Questions to Always Ask

**Before proposing ANY architecture, ask:**

### Domain Questions
1. What problem are we actually solving?
2. Who are the real users and what do they need?
3. What domain-specific constraints exist?

### Systems Questions
4. What external dependencies exist?
5. How does this fail? What breaks what?
6. Who monitors this? Who gets paged?

### Constraint Questions
7. What legacy systems must we integrate with?
8. Who needs to approve this?
9. What's the budget constraint?
10. What compliance/regulatory requirements apply?
11. What can't we change, even if it's wrong?

### AI Decomposition Questions
12. What are the discrete, bounded tasks?
13. How do we verify each chunk?
14. Where do humans need to make judgment calls?

### AI-First Development Questions
15. Would Rust/WASM, claude-flow, or other modern tools benefit this?
16. Could edge LLMs or on-device inference improve latency/privacy?
17. Is this a candidate for agentic workflows or Claude Agent SDK?
18. Could self-learning loops make this smarter over time?
19. What automated testing ensures every feature works?
20. Would end users benefit from skills that enhance AI outputs?
