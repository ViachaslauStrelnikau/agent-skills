---
name: migrate-struts2-to-spring
description: Use when Codex needs to analyze, plan, implement, diagnose, or review a staged migration from Apache Struts 2 actions, JSPs, interceptors, or `.do` routes to Spring MVC while preserving HTTP contracts and client-visible behavior.
---

# Migrate Struts 2 to Spring

## Core principle

Migrate one route and every associated JSP, JavaScript caller, and external client as a functional slice. Preserve observable behavior during Struts removal; modernize Spring, Java, and the container afterward.

## Comment rule

Write concise comments that explain migration-specific intent a maintainer cannot
reliably infer from the code: legacy compatibility behavior, protocol or
payload quirks, business rules retained for parity, and non-obvious security,
session, validation, or error-handling decisions. For every new or materially
changed controller, endpoint, or public service method, add short Javadoc that
states its purpose and describes every parameter with `@param`; include
`@return` when a returned value has a meaningful contract. Do not comment
obvious syntax, restate method names, or add large block comments.

## Logging checkpoint

Review production logging while the legacy and migrated flows are both fresh:

- Preserve meaningful legacy operational, business, security, and audit events.
- Rely on centralized HTTP logging for routine request lifecycle information
  and on the global exception handler for consistent unhandled-exception logs.
- Verify that centralized logs or metrics distinguish canonical `/rest/...`
  traffic from legacy compatibility traffic.
- Do not add routine controller or service method-entry or method-exit events.
  Do not require every new class to declare a logger.
- Add service events for significant business operations, state changes,
  integrations, retries, rejected operations, unusual conditions, and failures
  that are not already captured with sufficient context.
- Include safe, stable identifiers such as document, operation, client, user,
  and correlation IDs when available.
- Never log credentials, tokens, secrets, complete personal data, sensitive
  document contents, or complete request and response bodies.
- Avoid duplicate events and repeated stack traces across filters, controllers,
  services, repositories, integration clients, and exception handlers.
- Treat the logging review as migration acceptance evidence. Use
  `$add-production-logging` for a detailed module or application audit.

## Workflow

1. Classify the request as analysis, planning, diagnosis, implementation, or review. Stay read-only unless implementation is requested.
2. Inspect build metadata/JARs, `web.xml`, Struts/Spring configuration, filters, security, actions, controllers, JSPs, JavaScript, tests, and consumers.
3. Establish effective framework versions. If duplicate JARs exist, report uncertainty rather than guessing. Use Context7 to resolve and fetch version-current Struts and Spring documentation before applying framework-specific APIs.
4. Inventory routes and select one low-risk slice. Capture method, path, parameters, payload, validation, security, session, errors, redirects, uploads, view, and consumers.
5. Write characterization and contract tests before migration changes.
6. Replace the action with a thin Spring MVC controller delegating to existing services. Use explicit request, response, and view models.
7. Rework the slice's JSP and clients to remove Struts tags, ValueStack access, action names, implicit binding, and response assumptions without changing visible behavior.
8. When the canonical route changes, retain the legacy route as a Spring mapping or server-side adapter. Do not redirect when doing so can change method, body, authentication, or status semantics.
9. Copy `assets/route-mapping.yaml` into the target project and update it in the same change. Keep the legacy mapping while any registered client is pending.
10. Add the required concise comments and Javadoc while the migrated behavior is fresh; verify that non-obvious parameters are described.
11. Apply the logging checkpoint while the legacy decisions and failure paths are known. Record useful events preserved or added and intentional omissions.
12. Run narrow controller/client tests, then relevant regression, security, upload, and end-to-end checks. Remove migrated Struts configuration only after both routes pass and traffic confirms the old route can retire.
13. Remove Struts filters, plugins, configuration, tags, and JARs only after every route and client passes the removal gate.

## Task modes

| Request | Action |
|---|---|
| Analyze or review | Report route coupling, compatibility risks, and missing clients. List required contract, security, and regression evidence as three separate items; do not edit. |
| Plan | Produce ordered slices, contracts, catalog entries, tests, rollback, and completion gates. |
| Diagnose | Reproduce behavior and identify the Struts/Spring boundary; do not fix unless requested. |
| Implement | Change the smallest complete route-and-client slice and verify it. |

## Resources

- Read `references/migration-guidelines.md` before planning, implementing, or reviewing a migration.
- Copy and adapt `assets/route-mapping.yaml` when the target project lacks a route catalog.

## Non-negotiable safeguards

- Preserve URLs or provide compatibility mappings, payloads, status codes, validation messages, redirects, cookies, locale, security, and session behavior.
- Do not expose persistence entities as HTTP contracts.
- Do not weaken authentication, authorization, CSRF, CORS, validation, assertions, or tests to complete a migration.
- Do not combine route migration with unrelated business redesign.
- Do not retire a legacy route while its catalog contains a pending client.
- Preserve unrelated changes in dirty worktrees.

## Handoff

State the migrated route, compatibility route, clients updated, catalog path,
logging review and intentional omissions, tests run, remaining consumers,
rollback method, and retirement gate.
