# Rationalizations and Red Flags

**Load this reference when:** you are about to skip the failing test, keep code that was written before its test, or argue that tests-after are good enough.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. The test takes 30 seconds. |
| "I'll test after" | Tests written after the code pass immediately, which proves nothing: they may test the wrong thing, test implementation instead of behavior, or miss the edge cases you forgot. You never saw them catch anything. |
| "Tests after achieve the same goals" | Tests-after answer "what does this do?" Tests-first answer "what should this do?" Tests-after are biased by the implementation you already wrote: you verify remembered edge cases, not discovered ones. |
| "Already manually tested it" | Ad-hoc is not systematic. No record of what you tried, no way to re-run it, easy to forget cases under pressure. |
| "Deleting X hours of work is wasteful" | Sunk cost. The time is gone either way. The real waste is keeping code you cannot trust. |
| "Keep it as reference, write the tests first" | You will adapt it. That is testing after. Delete means delete. |
| "Need to explore first" | Fine. Throw the exploration away, then start with TDD. |
| "The test is hard to write" | Listen to the test. Hard to test means hard to use. Fix the design. |
| "TDD is dogmatic, I'm being pragmatic" | TDD finds bugs before commit, prevents regressions, documents behavior, and enables refactoring. The "pragmatic" shortcut is debugging in production. |
| "TDD will slow me down" | TDD is faster than debugging. Manual checks do not prove edge cases and get repeated on every change. |
| "The existing code has no tests" | You are improving it. Add tests for the code you touch. |
| "This case is different because..." | It is not. Ask the user for an explicit exception instead of granting yourself one. |

## Red Flags - Stop and Start Over

- Code written before its test
- Test written after the implementation
- Test passes the first time you run it
- You cannot explain why the test failed
- Tests deferred to "later"
- All tests written up front, then all the code
- Any excuse from the table above

**All of these mean: delete the code and start over with TDD.**
