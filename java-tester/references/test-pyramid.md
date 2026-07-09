# Test Pyramid Guidance

Source inspiration: Ham Vocke, "The Practical Test Pyramid", https://martinfowler.com/articles/practical-test-pyramid.html.

## Core Rules

- Write tests at different granularities.
- The higher the level, the fewer tests there should be.
- Push a test as far down the pyramid as it can go while preserving useful confidence.
- Prefer fast feedback in local development and early CI stages.
- Keep higher-level tests only when they cover behavior lower-level tests cannot cover.

## Levels

### Unit Tests

Use for isolated behavior in domain classes, services, validators, mappers, policies, parsers, and small controller/service orchestration.

Prefer:

- Real collaborators when they are cheap, deterministic, and clarify behavior.
- Test doubles for network, filesystem, database, clocks, queues, payment gateways, external APIs, and slow or nondeterministic collaborators.
- Observable behavior assertions over internal sequencing.

Avoid:

- Testing private methods directly.
- One test per method as a mechanical rule.
- Mock-heavy tests that mirror implementation details.
- Tests for trivial getters, setters, generated code, or framework boilerplate unless a regression risk exists.

### Integration and Slice Tests

Use for boundaries where unit tests cannot prove confidence:

- Database mappings, repositories, migrations, custom queries, transaction behavior.
- Spring MVC/WebFlux routes, serialization, validation, exception handling, security filters.
- Message producer/consumer configuration and serialization.
- Filesystem, HTTP clients, caches, and framework configuration.

Prefer focused slices over full application startup when possible. Move to full-context tests only when cross-component wiring is the behavior under test.

### Contract Tests

Use when independently deployable services communicate through HTTP, messaging, or other APIs. Consumer tests should capture the expectations the consumer relies on. Provider tests should verify the provider satisfies published contracts.

Use contracts to reduce broad end-to-end coverage across service fleets. They are not a replacement for unit tests or a few smoke-level deployment checks.

### End-to-End Tests

Use sparingly for critical user or system journeys that require the full stack:

- Login and a representative protected action.
- Checkout/payment happy path with controlled fakes or test providers.
- A key workflow spanning UI, API, persistence, and asynchronous processing.

Avoid using end-to-end tests to exhaustively cover validation branches, domain edge cases, repository behavior, or API permutations. These belong lower in the pyramid.

## CI Placement

Order pipeline stages by speed and diagnostic value, not by terminology alone:

1. Static checks, compilation, and fast unit tests.
2. Fast slice tests and narrow integration tests.
3. Slower integration tests with containers or real dependencies.
4. Contract verification.
5. Small end-to-end or smoke suite.

Fail fast. Do not make developers wait for broad tests when narrow tests would have found the issue earlier.

## Duplication Policy

Use these rules during implementation and review:

- If a high-level test fails and no lower-level test fails, add or improve a lower-level test.
- If all meaningful conditions are covered at a lower level, keep the high-level test only for the unique integration confidence it provides.
- Delete or avoid tests whose only value is repeating lower-level assertions through a slower path.

## Test Quality Checklist

- The test name states behavior and expected result.
- Setup is minimal and relevant.
- The assertion would fail for a real regression.
- The test is deterministic and order-independent.
- The failure message or assertion context helps locate the issue.
- The test does not require live third-party services.
- The chosen level is the lowest level that gives real confidence.
