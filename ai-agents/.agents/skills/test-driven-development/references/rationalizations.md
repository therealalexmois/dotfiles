# Rationalizations and Red Flags

**Load this reference when:** you are about to skip a failing test or claim that a passing characterization test proves a red-green cycle.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. The test takes 30 seconds. |
| "I'll test after" | A passing test can characterize existing behavior, but it does not prove the test would have caught the missing behavior before implementation. |
| "Tests after achieve the same goals" | Characterization tests answer "what does this do?" Test-first work answers "what should this do?" Use both honestly for their respective purposes. |
| "Already manually tested it" | Ad-hoc is not systematic. No record of what you tried, no way to re-run it, easy to forget cases under pressure. |
| "I wrote code first, so the next test counts as RED" | If the test passes immediately, it characterizes existing behavior. Report the missed RED and use the cycle for the next change. |
| "TDD requires deleting untested work" | Preserve existing code and the user's working tree. Add a behavioral baseline and continue test-first where behavior is still missing. |
| "Need to explore first" | Explore when needed. Preserve the resulting work and clearly distinguish its characterization tests from later red-green cycles. |
| "The test is hard to write" | Listen to the test. Hard to test means hard to use. Fix the design. |
| "TDD is dogmatic, I'm being pragmatic" | TDD finds bugs before commit, prevents regressions, documents behavior, and enables refactoring. The "pragmatic" shortcut is debugging in production. |
| "TDD will slow me down" | TDD is faster than debugging. Manual checks do not prove edge cases and get repeated on every change. |
| "The existing code has no tests" | You are improving it. Add tests for the code you touch. |
| "This case is different because..." | Check the task scope and existing code. Do not claim a test-first cycle that did not happen. |

## Red Flags - Stop and Correct Course

- Code written before its test
- Test written after the implementation
- Test passes the first time you run it
- You cannot explain why the test failed
- Tests deferred to "later"
- All tests written up front, then all the code
- Any excuse from the table above

**These mean the cycle was not followed for that slice. Preserve existing work, state the limitation, and return to a failing test for the next behavior.**
