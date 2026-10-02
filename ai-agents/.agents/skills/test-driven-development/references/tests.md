# Good and Bad Tests

## Good Tests

**Integration-style**: Test through real interfaces, not mocks of internal parts.

```typescript
// GOOD: Tests observable behavior
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

Characteristics:

- Tests behavior users/callers care about
- Uses public API only
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

## Bad Tests

**Implementation-detail tests**: Coupled to internal structure.

```typescript
// BAD: Tests implementation details
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

Red flags:

- Mocking internal collaborators
- Testing private methods
- Asserting on call counts/order
- Test breaks when refactoring without behavior change
- Test name describes HOW not WHAT
- Verifying through external means instead of interface

```typescript
// BAD: Bypasses interface to verify
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// GOOD: Verifies through interface
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

## Name the Break

Before writing the test body, answer: what production change should make this test fail, and is that change a bug or a decision? A test earns its place by catching a wrong branch, missing side effect, wrong argument, boundary case, or broken contract. Cannot name one? Redesign around an observable behavior instead of writing the test as-is.

## No Change Detectors

**Derive expectations independently.** Use literals and hand-checked fixtures. An expected value computed by the code under test - or its own helpers - passes no matter what that code does:

```typescript
// BAD: mirror assertion - the same builder computes both sides, always true
const expected = buildSearchQuery({ tag: "urgent" });
expect(buildSearchQuery({ tag: "urgent" })).toBe(expected);

// GOOD: hand-derived literal
expect(buildSearchQuery({ tag: "urgent" })).toBe('tag:"urgent"');
```

If only intentional decisions can fail a test - a constant's value, exact message wording, private structure - it fires on redesign and sleeps through bugs. Test the behavior that depends on the decision, not `expect(MAX_RETRIES).toBe(5)` but "a failing call is retried 5 times and the 6th attempt never happens."

## Your Code, Not the Framework

Test the contract your code makes at its boundaries - the route you register, the query you emit, the payload you produce. Upstream mechanics are their maintainers' tests to write; asserting that your router invokes a registered handler is the framework's test, not yours. The same boundary applies inside your code: constructors, getters, constants, and trivial forwarding earn tests only when they validate, normalize, default, derive, enforce, or cause side effects - otherwise assert the first consumer-visible result that depends on them.
