---
name: java-tester
description: Comprehensive Java test design and implementation guidance. Use when Codex needs to add, improve, review, or organize automated tests for Java applications, including unit tests, integration tests, Spring Boot tests, Spring Security authorization tests, REST/API tests, contract tests, Testcontainers-backed tests, database seeding and cleanup strategy, Mockito-based collaborator tests, regression tests, CI test strategy, or test pyramid decisions.
---

# Java Tester

## Operating Model

Add tests that increase confidence at the lowest practical level of the test pyramid. Prefer many fast unit tests, fewer integration or contract tests, and a very small number of end-to-end tests for critical journeys.

Start by reading the production code, existing tests, build files, and CI conventions. Preserve the project's test style unless it is clearly weak or inconsistent. Do not introduce a new testing library when the project already has an adequate equivalent.

Use Context7 for current documentation before adding or changing library-specific syntax, configuration, annotations, extensions, or dependency versions for JUnit, Mockito, AssertJ, Spring Boot Test, Testcontainers, REST Assured, Pact, WireMock, Maven, Gradle, or other Java testing tools.

## Workflow

1. Identify the behavior to protect.
   - Find public APIs, service methods, domain rules, persistence boundaries, messaging handlers, controllers, schedulers, and error paths touched by the request.
   - Prefer behavior assertions over implementation assertions.
   - Treat private methods as implementation details; test through public behavior or extract a focused collaborator if the private logic is complex.

2. Choose the lowest useful test level.
   - Use unit tests for pure domain logic, branching, validation, mapping, and collaborator orchestration that can be tested without real I/O.
   - Use slice or integration tests for framework wiring, persistence queries, data migrations, serialization, transactions, HTTP routing, security filters, and external boundary adapters.
   - Use contract tests when a service boundary is owned by multiple teams or independent deployables.
   - Use end-to-end tests only for core flows that cannot be trusted through lower-level tests.

3. Implement focused coverage.
   - Cover happy paths, edge cases, boundary values, invalid inputs, failures, security authorization outcomes, database state changes, and regression cases.
   - Use parameterized tests for repeated input/output examples.
   - Keep one reason to fail per test. Name tests by behavior and expected outcome.
   - Use deterministic data. Avoid sleeps, wall-clock assumptions, random order, network dependencies, and shared mutable state.

4. Keep tests maintainable.
   - Use arrange/act/assert or given/when/then consistently.
   - Create builders, fixtures, or test data mothers only when repeated setup obscures intent.
   - Keep mocks at process boundaries or genuinely awkward collaborators. Do not mock value objects, collections, or trivial domain logic.
   - Avoid verifying every interaction. Verify outcomes first; verify interactions only when the interaction is the behavior.

5. Verify and report.
   - Run the narrowest relevant test command first, then the broader suite if the blast radius warrants it.
   - If a higher-level test exposes a bug that no lower-level test catches, add a lower-level regression test.
   - Remove or avoid duplicated high-level checks when lower-level tests already cover the conditions and the high-level test adds no unique confidence.

## References

Read `references/test-pyramid.md` when deciding test scope, CI placement, duplication, or how much end-to-end testing to add.

Read `references/java-testing-tooling.md` when choosing Java testing tools, dependencies, annotations, mocking style, Spring Boot test shape, Testcontainers patterns, API tests, or contract tests.
