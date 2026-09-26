---
name: test-driven-development
description: Test-first implementation with the red-green-refactor loop - plan testable interfaces, write one failing test, write minimal code to pass, then refactor. Use when the user asks for TDD, test-first development, red-green-refactor, or a tracer-bullet approach, or when a task states that tests are part of the implementation to deliver. Do not use for adding tests to code that already exists without a behavior change, for throwaway prototypes, or for generated code.
metadata:
  origin: derived
  upstream: https://github.com/obra/superpowers/tree/main/skills/test-driven-development
  imported_at: 2026-06-09
---

# Test-Driven Development (TDD)

## Overview

Write the test first. Watch it fail. Write minimal code to pass. Refactor.

**Core principle:** if you did not watch the test fail, you do not know whether it tests the right thing.

**Second principle:** tests verify behavior through public interfaces, not implementation details. The code can change entirely; the tests should not.

Apply the cycle honestly to behavior being implemented now. Do not claim RED for a test that already passes against existing code.

## When to Use

**Use for:**

- New features and behavior changes
- Bug fixes
- Refactoring that changes observable behavior

**Outside this workflow unless explicitly requested:**

- Throwaway prototypes
- Generated code
- Configuration files without testable behavior changes

**Not this skill's job:** covering already-shipped code with characterization tests when no behavior changes. Write those tests through the public interface as a safety net, then apply TDD again the moment the refactor introduces new behavior.

Existing code includes work present when the current task began, whether committed or not. Preserve it and the user's working tree. When adding tests to such code, establish a behavioral baseline first; apply the red-green-refactor loop to subsequent behavior changes.

## The Iron Law

```
NO NEW BEHAVIOR IN THIS TASK WITHOUT A FAILING TEST FIRST
```

If you wrote production code during this task before its test, stop adding behavior. Preserve the work, write a test that exposes the missing behavior or regression, and verify that it fails for the right reason before continuing. If the code already satisfies the behavior, add a characterization test and explain that this slice was not test-first. Do not delete or overwrite user code to recreate a failing test.

## 1. Plan Before the First Test

Before writing any test or code:

- [ ] Determine the needed interface and priority behaviors from the request and repository contracts
- [ ] Identify opportunities for [deep modules](references/deep-modules.md) - small interface, deep implementation
- [ ] Design interfaces for [testability](references/interface-design.md)
- [ ] List behaviors to test, not implementation steps
- [ ] Ask the user only if a material interface or behavior choice remains unresolved

If the interface or priority is clear, start the first test. Otherwise ask a focused question that resolves the blocking choice.

Use the project's domain glossary so test names and interface vocabulary match the project's language, and respect the ADRs covering the area you touch.

**You cannot test everything.** Prioritize critical paths and complex logic. Confirm priorities only when the request and local contracts do not resolve them.

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

**Test passes?** The behavior may already exist. Check the contract; keep the passing test as characterization when useful, then identify the next missing behavior. Do not change a correct test merely to force RED.

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
| "I'll test after" | A passing test can characterize existing behavior, but it does not show that the test caught the missing behavior before implementation. |
| "I wrote the code first, so I'll pretend the next test is RED" | A test passing against existing code is characterization, not a red-green cycle. Report that distinction and use RED for the next behavior. |
| "I need to delete the user's code to enforce TDD" | Preserve existing work. TDD does not authorize destructive cleanup. |

If the cycle was missed or the situation is unclear, read [references/rationalizations.md](references/rationalizations.md), preserve existing work, and use a failing test for the next missing behavior.

## When Stuck

| Problem | Solution |
|---------|----------|
| Do not know how to test it | Inspect the public contract, sketch the wished-for API, and write the assertion first. Ask only if a material choice remains unresolved. |
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

- [ ] Each new observable behavior has a relevant test
- [ ] You watched each test fail before implementing it
- [ ] Each test failed for the expected reason - missing feature, not a typo
- [ ] You wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output is pristine: no errors, no warnings
- [ ] Tests use real code; mocks only where unavoidable
- [ ] Edge cases and error paths are covered

If a test was not observed failing first, report that limitation accurately and use the cycle for the remaining behavior. Do not destroy existing work to manufacture a RED result.
