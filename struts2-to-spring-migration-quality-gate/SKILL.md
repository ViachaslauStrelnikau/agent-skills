---
name: struts2-to-spring-migration-quality-gate
description: Verify that functionality migrated from Struts 2 to Spring works correctly in the running application from the API, client, and user perspective. Use after a migration step to gate a migrated action, route, workflow, form, grid, report, or state change through focused project-rule review, targeted build/tests, HTTP verification, browser E2E when UI integration matters, persistence checks for mutations, and optional old-versus-new comparison. Return PASS, FAIL, or INCOMPLETE. Do not use as a generic repository-wide Java, Spring, architecture, security, performance, or clean-code review.
---

# Struts 2 to Spring Migration Quality Gate

## Objective

Answer: **Does the migrated functionality actually work correctly in the running application from the API, client, or user perspective?**

Make runtime evidence the main value. Use static review only to apply project rules or catch migration-critical defects in the current slice. Never modify source code to make the gate pass; report failures for the implementation workflow to fix.

## Workflow

1. Determine the current migration slice.
2. Discover and apply project-specific migration/review rules.
3. If none exist, perform the lightweight fallback review.
4. Discover the project's build, test, runtime, authentication, and scenario procedures.
5. Run the smallest useful build and automated-test set.
6. Select the lowest adequate verification level: A, B, C, or D.
7. Confirm that the running instance contains the current migration slice.
8. Inventory and exercise the required migration surfaces through the running application.
9. Reconcile migration status labels with the collected evidence.
10. Report functional acceptance separately from delivery and retirement gates.
11. Return exactly one high-level outcome: `PASS`, `FAIL`, or `INCOMPLETE`.

Keep every step scoped to the current migration slice. Do not review the whole repository or load unrelated migration history.

## Determine the Slice

Use the current task and acceptance criteria first. Supplement them only as needed with:

- the current migration diff, changed files, commit, branch range, or project migration metadata;
- the old Struts mapping/action and new Spring controller;
- directly involved services, DAOs/repositories, DTOs, frontend callers, and tests;
- migration documentation and route catalogs.

Do not assume a Git workflow. If the exact range is unavailable, infer the smallest defensible slice from the task and changed files and disclose the inference.

## Discover Project Rules

Before doing a static review, search narrowly for instructions whose names or contents indicate Struts-to-Spring migration, migration review, route compatibility, or acceptance criteria. Check applicable `AGENTS.md` files and likely documentation locations, including README migration sections and migration-oriented directories. Example names such as `migration-goal.md` or `migration-rules.md` are hints, never requirements.

Follow any document-loading or index-navigation procedure defined by the discovered project instructions. Load only the current ticket, route records, acceptance criteria, checkpoint, and diff required by that procedure. Treat relevant instructions as authoritative unless they conflict with higher-level instructions. Apply their applicable checks, record that they were found, and avoid repeating equivalent static checks. Always continue with this skill's runtime verification.

When multiple migration-rule sources overlap, follow explicit project-defined precedence first. Otherwise prefer current durable migration records and indexes over producer-side skill instructions or bundled examples. Do not silently merge conflicting records; if a conflict affecting the route or expected behavior cannot be resolved, record it and mark the affected verification `INCOMPLETE`.

Do not import assumptions, paths, conventions, or infrastructure from another project.

### Fallback changed-files review

When no relevant project-specific review rules exist, review only changed files, direct callers, direct tests, and code needed to understand the request/response path. Keep findings concise and limited to migration-critical defects:

- endpoint path or HTTP method mismatch;
- missing parameters, incorrect body binding, or response-contract mismatch;
- obvious controller/service wiring, transaction, or persistence mistakes;
- Struts dependencies left in the migrated execution path;
- behavior from the old action omitted in the Spring path;
- missing/failing relevant tests or accidental unrelated changes;
- authentication/authorization accidentally bypassed;
- validation or localization behavior lost.

Do not broaden this into architecture, style, clean-code, security, performance, or repository-wide review. Mention those areas only when they directly break migrated behavior.

## Discover the Environment and Scenario

Inspect only relevant project instructions and configuration to learn:

- build and targeted test commands;
- application/frontend/database startup and migrations;
- Docker or Compose procedures;
- base URLs, environment variables, test data, and test users;
- authentication steps or an available authenticated session;
- existing functional or E2E scenarios;
- availability of the bundled Browser skill and authorized Developer mode/CDP access;
- existing `playwright.config.*`, Playwright E2E specs, authentication setup, fixtures, base URL, and project scripts or CLI commands that run them.

Reuse a running application and project-defined procedures. Start local development/test services only when documented and safe. Never target production or an unconfirmed shared environment.

Before HTTP testing, confirm that the running instance contains the current migration slice using project-defined deployment evidence, such as a build/version identifier, artifact timestamp or hash, deployment log, known changed response, or documented reload/restart procedure. Do not assume that the checked-out source matches the deployed application. If runtime freshness cannot be established, mark required runtime verification `INCOMPLETE`.

Prefer an existing scenario in the project's own format. Otherwise infer a minimal scenario from the task, acceptance criteria, old action, new endpoint, frontend caller, tests, and affected business logic. Establish the feature, preconditions, input, action, expected request/response/UI/persisted state, and cleanup. Do not invent a custom DSL.

Do not invent credentials. If authentication instructions or a reusable session cannot be found, mark required authenticated checks `INCOMPLETE`.

## Build and Automated Tests

Run the smallest useful checks first: affected-module compilation, directly related unit/controller/integration tests, migration tests, or feature E2E tests. If the project exposes no narrower compile or build target, run the smallest relevant project-defined test suite. Run a repository-wide suite only when project rules or the change's blast radius require it.

Record commands and outcomes concisely. A successful build is supporting evidence, never proof that the migration works. If a required check cannot run, explain why and reflect the gap in the final outcome. Runtime verification may proceed against an already running environment when project rules permit it.

## Select the Verification Level

Choose the lowest level that proves the actual behavior:

- **A — API functional verification:** Use when UI behavior does not materially affect correctness.
- **B — API + browser:** Use when an existing browser UI consumes the endpoint and its request or rendering contract matters.
- **C — API + browser + persistence:** Use for create, save, update, delete, assignment, status, workflow, or other state mutations. If no browser client exists, perform API + persistence and state that browser verification is not applicable.
- **D — Manual / partially automatable:** Use only when required meaningful verification cannot be automated or accessed safely. Specify automated evidence, the unverified behavior, why, and exact manual steps. Required unverified behavior makes the overall result `INCOMPLETE`.

Do not select a lower level merely because the environment is unavailable; select the required level, then report `INCOMPLETE`.

## Execute Runtime Verification

### Level A — API

Exercise the real application through HTTP, not only mocked controller tests. Verify applicable contract elements:

- reachability, path, method, authentication, and authorization;
- query/form parameters, request body, content type, and validation;
- status, response structure, important values, filtering, and contractual sorting;
- compatible error behavior and absence of unexpected 4xx/5xx responses.

Capture only request and response fragments needed as evidence. Do not dump secrets or large payloads.

### Level B — Browser

Use the bundled Browser skill when available and follow its browser-selection and authentication procedures. Use its Playwright automation surface and, when available and authorized, Developer mode/CDP to collect the required UI, network, console, page-error, transport-failure, and HTTP-status evidence. If the Browser skill is unavailable or cannot capture the required evidence, reuse the project's existing Playwright configuration, specs, authentication setup, fixtures, base URL, and script or CLI command. Do not improvise an unrelated browser harness. Apply the same mechanism when Level C includes a browser. If neither mechanism is available, mark required browser evidence `INCOMPLETE`.

Open the application, authenticate through documented means or an existing session, navigate to the feature, and perform the actual migrated action. A page-open smoke test is insufficient. Capture the relevant browser-initiated request and response, including XHR/fetch when applicable; visible UI behavior after the action; console messages and uncaught page errors; transport failures from `requestfailed`; and unexpected HTTP error statuses from response events. Playwright does not emit `requestfailed` for completed 4xx/5xx responses, so inspect response statuses separately. Verify response-shape compatibility and cover the material interaction: for example submit the form, execute the search, populate the grid, change the filter, open the dependent control, or generate the report.

JavaScript syntax checks, source-level caller review, and direct HTTP parity do not replace browser verification when the existing UI materially participates in the migrated workflow.

### Level C — Persistence

After the mutation succeeds, reload or re-query and verify the persisted state and dependent state. Check update/delete semantics and accidental duplicates where relevant. Prefer public UI/API verification. Inspect the database directly only when useful, authorized, and safe.

Use dedicated temporary test data in a development/test environment. Avoid important existing records and irreversible operations. Clean up data created by the gate when appropriate, but do not let cleanup erase failure evidence before it is recorded.

### Level D — Partial/manual

Complete every safe automated check. Give numbered manual steps with preconditions, actions, and expected results for the remainder. Never label partially verified required behavior as `PASS`.

If the bundled Browser skill and project Playwright fallback cannot reach the application, authenticate, or capture the required evidence, record each exact attempt and failure reason. Retain the required B or C level and return `INCOMPLETE`; do not downgrade environment unavailability to D.

## Verify Required Migration Surfaces

Inventory the observable paths required by the project: the canonical Spring endpoint, a Spring compatibility endpoint or forward, and the legacy Struts route. Exercise every retained surface required by the current slice with equivalent method, input, authentication, and expected semantics. Verify forwarded-route operation inference when applicable. Mark absent surfaces `N/A`; do not invent compatibility routes.

Compare success/failure, response values, record counts, identifiers, important fields, filtering, sorting, validation, errors, authorization, persisted state, and user-visible results across required surfaces.

Compare semantics rather than bytes. Ignore property ordering, immaterial formatting, generated timestamps, and implementation differences. Skip a surface when it is gone, unsafe, unavailable, mutates shared data dangerously, or was intentionally replaced. State the reason briefly; do not force parity against an intentionally changed contract.

## Reconcile Evidence and Delivery State

Treat statuses such as `implemented`, `verified`, or `complete` as claims, not proof. Reconcile them with recorded tests and runtime evidence. If required verification remains pending, determine the gate result from the evidence and report the stale or contradictory status as an actionable blocker.

Distinguish functional/runtime acceptance from delivery-only gates such as commit, push, acceptance-batch completion, rollout, traffic observation, compatibility retirement, and cleanup. Report delivery gates separately. Do not make functional `PASS` depend on them unless the requested gate explicitly includes full migration-step completion or they are necessary to exercise the behavior.

## Decide the Outcome

- **PASS:** Required functional checks for the selected A/B/C level succeeded against the confirmed current runtime. Required build/tests and project rules also succeeded or were explicitly not applicable.
- **FAIL:** Runtime evidence demonstrates incorrect migrated behavior, including a wrong contract, runtime exception, broken UI, persistence mismatch, or violated expected parity; or a required automated test or migration-critical fallback check fails.
- **INCOMPLETE:** Runtime freshness, browser behavior, successful mutation/persistence, authentication, fixtures, environment startup, dependency availability, safety constraints, or another required verification cannot be established.

Do not convert `INCOMPLETE` to `PASS`. Distinguish a demonstrated product defect (`FAIL`) from unavailable evidence (`INCOMPLETE`).

Pending commit, push, observation, or alias retirement remains informational unless full migration-step completion was explicitly requested.

## Report

Use this strict concise shape. Retain every section and mark nonapplicable checks `N/A`:

```text
STRUTS2 → SPRING MIGRATION QUALITY GATE: PASS | FAIL | INCOMPLETE

Feature:
<migrated behavior>

Migration scope:
<changed production/test files or inferred slice>

Project review rules:
Found and applied | Not found; fallback changed-files review performed

Verification level:
<A | B | C | D — label>

Runtime under test:
PASS | INCOMPLETE
<evidence that the running deployment contains the migration slice>

Build/tests:
PASS | FAIL | INCOMPLETE | N/A
<targeted command/result summary>

API verification:
PASS | FAIL | INCOMPLETE | N/A
<method path → status and material result>

Browser verification:
PASS | FAIL | INCOMPLETE | N/A
<actual user action and visible result>

Browser console:
PASS | FAIL | INCOMPLETE | N/A
<relevant evidence only>

Failed HTTP requests:
PASS | FAIL | INCOMPLETE | N/A
<relevant evidence only>

Persistence verification:
PASS | FAIL | INCOMPLETE | N/A
<state after reload/re-query>

Compatibility verification:
PASS | FAIL | INCOMPLETE | N/A
<canonical, compatibility, and legacy surfaces exercised>

Migration evidence:
CONSISTENT | INCONSISTENT
<status labels reconciled with actual evidence>

Delivery/retirement gates:
COMPLETE | PENDING | N/A
<commit, push, observation, or alias-retirement state; informational unless in scope>

BLOCKERS:
<0, or numbered actionable failures/verification blockers>

RESULT:
MIGRATED FUNCTIONALITY VERIFIED |
MIGRATED FUNCTIONALITY NOT VERIFIED |
FULL MIGRATION VERIFICATION NOT COMPLETED
```

For each failure, include only the useful diagnosis evidence: feature, request method/path and input shape, status, expected behavior, actual behavior, important response fragment, UI result, console/failed request, persistence mismatch, or old/new difference. Never dump large logs, HTML, responses, or database contents.
