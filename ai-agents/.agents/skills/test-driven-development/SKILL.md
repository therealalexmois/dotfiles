---
name: test-driven-development
description: Test-first implementation with the red-green-refactor loop - plan testable interfaces, write one failing test, write minimal code to pass, then refactor. Use when the user asks for TDD, test-first development, red-green-refactor, or a tracer-bullet approach, or when a task states that tests are part of the implementation to deliver. Do not use for adding tests to code that already exists without a behavior change, for throwaway prototypes, or for generated code.
---

# Test-Driven Development (TDD)

## Overview

Write the test first. Watch it fail. Write minimal code to pass. Refactor.

**Core principle:** if you did not watch the test fail, you do not know whether it tests the right thing.

**Second principle:** tests verify behavior through public interfaces, not implementation details. The code can change entirely; the tests should not.

Violating the letter of the rules is violating the spirit of the rules.

## When to Use

**Use for:**

- New features and behavior changes
- Bug fixes
- Refactoring that changes observable behavior

**Ask the user first:**

- Throwaway prototypes
- Generated code
- Configuration files

**Not this skill's job:** covering already-shipped code with characterization tests when no behavior changes. Write those tests through the public interface as a safety net, then apply TDD again the moment the refactor introduces new behavior.

"Already shipped" means committed and running before this task started. Code that you or the user wrote minutes ago *instead of* a test is not existing code - it is untested new code, and the Iron Law below applies to it. When in doubt, ask: was this code already in production before the current request? If not, it is new.

Thinking "skip TDD just this once"? Stop. That is rationalization.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Wrote code before the test? Delete it. Start over.

**No exceptions:**

- Do not keep it as "reference"
- Do not "adapt" it while writing tests
- Do not look at it
- Delete means delete

Implement fresh from the tests.

## 1. Plan Before the First Test

Before writing any test or code:

- [ ] Confirm with the user what interface changes are needed
- [ ] Confirm with the user which behaviors to test, in priority order
- [ ] Identify opportunities for [deep modules](references/deep-modules.md) - small interface, deep implementation
- [ ] Design interfaces for [testability](references/interface-design.md)
- [ ] List behaviors to test, not implementation steps
- [ ] Get the user's approval on that list

Ask: "What should the public interface look like? Which behaviors matter most?"

Use the project's domain glossary so test names and interface vocabulary match the project's language, and respect the ADRs covering the area you touch.

**You cannot test everything.** Confirm with the user which behaviors matter. Spend testing effort on critical paths and complex logic, not on every conceivable edge case.

## 2. Anti-Pattern: Horizontal Slices

**Do not write all the tests first, then all the implementation.** That is horizontal slicing - treating RED as "write all tests" and GREEN as "write all code."

It produces bad tests:

- Tests written in bulk verify *imagined* behavior, not *actual* behavior
- You end up testing the *shape* of things - data structures, signatures - instead of user-facing behavior
- Tests become insensitive to real changes: they pass when behavior breaks and fail when behavior is fine
- You commit to a test structure before you understand the implementation

**Correct approach:** vertical slices via tracer bullets. One test, one implementation, repeat. Each test responds to what the previous cycle taught you.

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED -> GREEN: test1 -> impl1
  RED -> GREEN: test2 -> impl2
  RED -> GREEN: test3 -> impl3
```

The first vertical slice is the **tracer bullet**: one test that confirms one thing about the system and proves the path works end to end.

## 3. The Red-Green-Refactor Loop

```
RED            write one failing test
  |
VERIFY RED     run it, confirm it fails for the right reason
  |            (wrong failure? fix the test and re-run)
GREEN          write the minimal code to pass
  |
VERIFY GREEN   run it, confirm it passes and nothing else broke
  |            (still failing? fix the code, never the test)
REFACTOR       clean up while staying green
  |
NEXT           back to RED for the next behavior
```

### RED - Write a Failing Test

Write one minimal test showing what should happen.

<Good>
```typescript
test('retries failed operations 3 times', async () => {
  let attempts = 0;
  const operation = () => {
    attempts++;
    if (attempts < 3) throw new Error('fail');
    return 'success';
  };

  const result = await retryOperation(operation);

  expect(result).toBe('success');
  expect(attempts).toBe(3);
});
```
Clear name, tests real behavior, one thing.
</Good>

<Bad>
```typescript
test('retry works', async () => {
  const mock = jest.fn()
    .mockRejectedValueOnce(new Error())
    .mockRejectedValueOnce(new Error())
    .mockResolvedValueOnce('success');
  await retryOperation(mock);
  expect(mock).toHaveBeenCalledTimes(3);
});
```
Vague name, tests the mock rather than the code.
</Bad>

**Requirements:**

- One behavior
- Clear name describing the behavior
- Real code; no mocks unless unavoidable

See [references/tests.md](references/tests.md) for more good and bad test examples, and [references/mocking.md](references/mocking.md) for where mocking is legitimate.

### Verify RED - Watch It Fail

**Mandatory. Never skip.**

```bash
npm test path/to/test.test.ts
```

Confirm:

- The test fails, not errors
- The failure message is the one you expected
- It fails because the feature is missing, not because of a typo

**Test passes?** You are testing existing behavior. Fix the test.

**Test errors?** Fix the error and re-run until it fails correctly.

### GREEN - Minimal Code

Write the simplest code that passes the test.

<Good>
```typescript
async function retryOperation<T>(fn: () => Promise<T>): Promise<T> {
  for (let i = 0; i < 3; i++) {
    try {
      return await fn();
    } catch (e) {
      if (i === 2) throw e;
    }
  }
  throw new Error('unreachable');
}
```
Just enough to pass.
</Good>

<Bad>
```typescript
async function retryOperation<T>(
  fn: () => Promise<T>,
  options?: {
    maxRetries?: number;
    backoff?: 'linear' | 'exponential';
    onRetry?: (attempt: number) => void;
  }
): Promise<T> {
  // YAGNI
}
```
Over-engineered for the current test.
</Bad>

Do not add features, refactor other code, or "improve" beyond the test.

### Verify GREEN - Watch It Pass

```bash
npm test path/to/test.test.ts
```

Confirm:

- The test passes
- Other tests still pass
- Output is pristine: no errors, no warnings

**Test fails?** Fix the code, not the test.

**Other tests fail?** Fix them now.

### REFACTOR - Clean Up

Only after green. Never refactor while red.

- [ ] Extract duplication
- [ ] Improve names, extract helpers
- [ ] Deepen modules: move complexity behind simple interfaces
- [ ] Apply SOLID principles where they fit naturally
- [ ] Consider what the new code reveals about the existing code
- [ ] Run the tests after each refactoring step

See [references/refactoring.md](references/refactoring.md) for the candidate list and [references/deep-modules.md](references/deep-modules.md) for the interface-depth criterion. Keep the tests green and add no behavior.

## Good Tests

| Quality | Good | Bad |
|---------|------|-----|
| **Minimal** | One thing. "and" in the name? Split it. | `test('validates email and domain and whitespace')` |
| **Clear** | The name describes the behavior | `test('test1')` |
| **Shows intent** | Demonstrates the desired API | Obscures what the code should do |
| **Behavioral** | Verifies through the public interface | Asserts on call counts, private methods, or raw DB rows |

## Mocking

Mock at system boundaries only - external APIs, time, randomness, sometimes the database or file system. Do not mock your own classes, internal collaborators, or anything you control. See [references/mocking.md](references/mocking.md).

**Before extending an existing test file, audit it.** Do not inherit its mocking style. Check whether it mocks internal collaborators, asserts on call counts or call arguments, or verifies behavior through anything other than the public interface. If it does, say so and propose the behavioral version instead of adding one more test in the same shape.

When adding mocks or test utilities, read [references/testing-anti-patterns.md](references/testing-anti-patterns.md) to avoid:

- Testing mock behavior instead of real behavior
- Adding test-only methods to production classes
- Mocking without understanding dependencies

## Rationalizations

The three most common, and the answer to each:

| Excuse | Reality |
|--------|---------|
| "I'll test after" | Tests written after the code pass immediately, which proves nothing. You never saw them catch anything. |
| "Deleting X hours of work is wasteful" | Sunk cost. The real waste is keeping code you cannot trust. |
| "Keep it as reference, write the tests first" | You will adapt it. That is testing after. Delete means delete. |

Hearing a different excuse - yours or the user's - or unsure whether a situation is a genuine exception? Read [references/rationalizations.md](references/rationalizations.md) for the full table and the red-flag list that means "start over".

## When Stuck

| Problem | Solution |
|---------|----------|
| Do not know how to test it | Write the wished-for API. Write the assertion first. Ask the user. |
| Test too complicated | The design is too complicated. Simplify the interface. |
| Must mock everything | The code is too coupled. Use dependency injection. |
| Test setup is huge | Extract helpers. Still complex? Simplify the design. |

## Bug Fixes

Found a bug? Write a failing test that reproduces it, then follow the cycle. The test proves the fix and prevents the regression. Never fix a bug without a test.

**Example**

```typescript
// RED: empty email is accepted
test('rejects empty email', async () => {
  const result = await submitForm({ email: '' });
  expect(result.error).toBe('Email required');
});
// Verify RED: FAIL - expected 'Email required', got undefined

// GREEN
function submitForm(data: FormData) {
  if (!data.email?.trim()) {
    return { error: 'Email required' };
  }
  // ...
}
// Verify GREEN: PASS
```

## Verification Checklist

Before marking the work complete:

- [ ] Every new function or method has a test
- [ ] You watched each test fail before implementing it
- [ ] Each test failed for the expected reason - missing feature, not a typo
- [ ] You wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output is pristine: no errors, no warnings
- [ ] Tests use real code; mocks only where unavoidable
- [ ] Edge cases and error paths are covered

Cannot check every box? You skipped TDD. Start over.
