# Java Testing Tooling

Use Context7 for current docs before changing version-specific syntax, dependency coordinates, annotations, extensions, or configuration.

## Default Tool Choices

Prefer the project's existing choices. If adding tests to a new or under-tooled Java project, these are sensible defaults:

- JUnit Jupiter for test structure and execution.
- AssertJ or the project's current assertion library for fluent assertions.
- Mockito for test doubles inside JVM-level tests.
- Spring Boot Test slices for Spring MVC, WebFlux, JSON, persistence, and configuration behavior.
- Testcontainers for integration tests that need real databases, brokers, object stores, or service-like dependencies.
- WireMock or mock web servers for HTTP clients when a full provider is not needed.
- REST Assured, WebTestClient, MockMvc, or the project's existing client for API-level assertions.
- Pact or Spring Cloud Contract when consumer/provider contracts matter.

## JUnit Jupiter Patterns

Use:

- `@Test` for single examples.
- `@ParameterizedTest` for repeated input/output cases.
- `@Nested` to group behavior by state or scenario.
- `@BeforeEach` for cheap per-test setup.
- `@BeforeAll` only for expensive immutable setup.
- `@TempDir` for filesystem tests.
- `assertAll` when multiple assertions describe one behavior.

Avoid:

- Sharing mutable fixtures across tests.
- Test ordering dependencies.
- Catch-all tests that assert many unrelated behaviors.
- `Thread.sleep`; prefer Awaitility, polling with timeouts, or framework test utilities.

Name tests in a readable behavior style, such as `returnsDiscountForEligibleCustomer` or `rejectsExpiredToken`.

## Mockito Patterns

Prefer constructor injection in production code so tests can provide dependencies directly.

Use mocks for:

- External ports and adapters.
- Slow or nondeterministic collaborators.
- Failure paths that are hard to trigger with real collaborators.

Avoid mocks for:

- Simple data classes.
- Domain entities and value objects.
- Collections and standard library types.
- Collaborators that are easier and clearer to use for real.

Guidelines:

- Stub before the act phase.
- Verify interactions only when the interaction is the observable behavior.
- Prefer strict stubs so unused or mismatched stubbing fails early.
- Prefer argument captors only when the produced argument is the important outcome.
- Use spies rarely; they often indicate that the design or test boundary is unclear.

## Spring Boot Testing

Choose the narrowest Spring test that proves the behavior:

- Plain JUnit for domain logic and services that do not need Spring.
- `@WebMvcTest` or equivalent web slice for controllers, validation, JSON, filters, and exception handlers.
- `@DataJpaTest` for JPA repositories, mappings, transactions, and custom queries.
- JSON test slices for serialization/deserialization rules.
- `@SpringBootTest` for cross-component wiring, configuration, startup, or behavior requiring the full application context.

Keep full-context tests few. They are slower and more brittle than focused tests.

For web tests:

- Assert status, content type, important headers, and response body.
- Cover validation failures and exception mapping.
- Keep authentication/security setup explicit.

### Spring Security Tests

Use Spring Security test support when security filters, endpoint authorization, method security, CSRF, or JWT/resource-server behavior is part of the behavior under test. Keep ordinary controller or service tests security-free only when security is irrelevant to the behavior.

For servlet web tests:

- Apply Spring Security to MockMvc through the project's existing setup, such as `springSecurity()`, when building MockMvc manually.
- Use `@WithMockUser` or request post-processors such as `user(...)`, `anonymous()`, `csrf()`, `jwt()`, or `opaqueToken()` according to the project's authentication model.
- Test `401 Unauthorized` for unauthenticated requests and `403 Forbidden` for authenticated users without sufficient authority.
- Cover role, authority, scope, ownership, tenant, or permission boundaries that affect access decisions.
- Include CSRF-positive and CSRF-negative examples for state-changing endpoints when CSRF protection is enabled.

For method security:

- Test `@PreAuthorize`, `@PostAuthorize`, and similar rules through the secured public method.
- Assert allowed access for the minimum required role/authority and denied access for a wrong or missing authority.
- Avoid bypassing security proxies by instantiating secured services directly when the security annotation is the behavior under test.

For JWT or resource-server tests:

- Prefer framework test helpers over hand-building tokens unless token parsing itself is under test.
- Include claims, scopes, subject, tenant, or audience values that drive authorization.
- Add malformed, missing, expired, or insufficient-scope cases only where the application handles them differently or they protect a regression.

For persistence tests:

- Use real schema/migrations where feasible.
- Verify custom queries with representative data.
- Avoid testing generated CRUD behavior unless configuration or mapping makes it risky.

### Database Seeding and Cleanup

Choose a database state strategy before writing persistence or integration tests. Make state explicit enough that tests are deterministic and can run in any order.

Use:

- Builders, repositories, or test fixtures for small per-test records that are easiest to read in Java.
- `@Sql` for compact setup/cleanup scripts, shared reference data, or cases where SQL shape matters.
- Flyway or Liquibase migrations in integration tests when schema compatibility, migration order, constraints, indexes, or production-like DDL are part of the confidence.
- Testcontainers when database dialect, transaction, locking, JSON, index, or constraint behavior matters.

Guidelines:

- Prefer per-test data setup over broad global seed data.
- Keep seed data minimal and named around the behavior under test.
- Rely on transactional rollback for Spring-managed tests only when the code under test participates in the same transaction model.
- Use explicit cleanup with `@Sql(executionPhase = AFTER_TEST_METHOD)`, repository deletion, truncation, or container/database reset when tests commit data, use async work, cross transaction boundaries, or share containers.
- Avoid order-dependent IDs and timestamps. Use stable identifiers and injected clocks where possible.
- Do not hide important test setup in large SQL files unless the file represents realistic reference data or migration input.

## Testcontainers Patterns

Use Testcontainers when behavior depends on real dependency behavior that in-memory fakes cannot represent well:

- Database dialect differences, migrations, constraints, indexes, JSON columns, locks, or transactions.
- Kafka/RabbitMQ/message broker behavior.
- Redis/cache semantics.
- S3-compatible storage behavior.

Guidelines:

- Use static containers for class-level shared lifecycle when test isolation is maintained through data cleanup.
- Use per-test containers only when isolation matters more than runtime.
- Prefer official module containers such as PostgreSQLContainer when available.
- Configure readiness with explicit wait strategies when port listening is not enough.
- Inject container connection details through framework-supported dynamic properties.
- Do not rely on reusable containers in CI unless the environment is explicitly designed for it.

## API and Contract Tests

For REST API tests, assert the public contract:

- Method, path, status, response shape, error shape, headers, and important side effects.
- Authentication and authorization boundaries.
- Compatibility-sensitive fields and enum values.

Do not repeat every domain edge case through HTTP if unit tests already cover it. Add one or two API-level examples per behavior class to prove routing, serialization, validation, and integration.

Use contract tests when consumer and provider can change independently. Keep contracts focused on fields and interactions consumers rely on, not the provider's entire schema.

## Comprehensive Coverage Heuristic

For each changed behavior, consider:

- Happy path.
- Null, empty, missing, malformed, or boundary input.
- Authorization or permission failure.
- Dependency failure or timeout.
- Duplicate, concurrent, idempotent, or retry case when relevant.
- Persistence state before and after.
- Backward-compatible API behavior.

Stop when additional tests only repeat an already protected condition at a slower or more brittle level.
