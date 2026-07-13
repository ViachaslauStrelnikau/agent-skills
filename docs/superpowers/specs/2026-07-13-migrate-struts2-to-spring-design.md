# Migrate Struts 2 to Spring Skill Design

## Purpose

Create a reusable Codex skill named `migrate-struts2-to-spring` for analyzing, planning, implementing, and reviewing staged migrations from Struts 2 to Spring MVC. The skill must preserve client-visible behavior while migrating one backend route and its JSP, JavaScript, or external clients as a functional slice.

## Scope

The skill covers:

- Legacy Struts 2 route and dependency discovery.
- Current, version-aware documentation lookup through Context7.
- Characterization of existing HTTP, validation, security, session, redirect, upload, and view behavior.
- Route-by-route replacement with Spring MVC controllers.
- JSP and frontend-client rework that removes Struts conventions without changing observable behavior.
- Compatibility aliases when canonical routes change.
- A source-controlled route catalog for coordinating other client migrations.
- Verification gates for each route and for final Struts removal.
- Separation of Struts removal from subsequent Spring, Java, and container modernization.

The skill does not prescribe a frontend framework, force Spring Boot, redesign application workflows, or automate source rewrites across unknown project layouts.

## Structure

```text
migrate-struts2-to-spring/
├── SKILL.md
├── agents/
│   └── openai.yaml
├── assets/
│   └── route-mapping.yaml
└── references/
    └── migration-guidelines.md
```

- `SKILL.md` contains the concise workflow, task-mode behavior, mandatory safeguards, and resource-routing instructions.
- `references/migration-guidelines.md` contains the detailed migration rules and completion criteria.
- `assets/route-mapping.yaml` is a reusable template that records legacy routes, canonical routes, compatibility policy, ownership, contract changes, and client status.
- `agents/openai.yaml` provides generated user-interface metadata.

No executable migration script is included. Struts applications vary too much in build layout, XML conventions, plugins, and custom interceptors for a safe generic rewrite script.

## Workflow

1. Identify whether the request is analysis, planning, diagnosis, implementation, or review. Remain read-only unless implementation is requested.
2. Inspect build metadata or checked-in libraries, `web.xml`, Struts configuration, Spring configuration, filters, security rules, controllers, actions, JSPs, JavaScript, tests, and known external consumers.
3. Resolve exact framework versions and use Context7 to fetch current or version-specific Struts and Spring documentation before relying on framework APIs.
4. Inventory routes and select one low-risk functional slice.
5. Capture the current route contract and visible workflow with characterization and contract tests.
6. Replace the action with a thin Spring MVC controller that delegates to existing business services.
7. Rework every associated JSP and client to remove Struts tags, ValueStack behavior, action naming, implicit binding, and response assumptions.
8. Preserve legacy behavior through compatible Spring mappings or server-side adapters when canonical routes change.
9. Update the route catalog in the same change and retain the legacy route while any registered client is pending.
10. Run narrow tests, broader regression tests, and relevant security or end-to-end checks before removing the migrated Struts configuration.
11. Remove Struts dependencies only after all routes and clients meet the defined removal gate.
12. Treat Spring, Java, servlet-container, and Jakarta modernization as a later controlled phase.

## Error and Safety Handling

- Do not guess the effective Struts version when duplicate JARs are present.
- Do not combine framework migration with unrelated business-logic redesign.
- Do not expose persistence entities as HTTP contracts.
- Do not replace POST routes with redirects that alter method or body semantics.
- Do not weaken authentication, authorization, CSRF, session, CORS, validation, or error behavior to make a migration pass.
- Stop and report unresolved consumers before retiring compatibility routes.
- Preserve unrelated user changes in dirty worktrees.

## Validation Strategy

Before authoring the skill, run a baseline scenario without it and record omissions such as missing client migration, compatibility handling, or route-catalog coordination. After authoring, run the same scenario with the skill and verify that it follows the route-by-route workflow.

Forward-test at least one variation involving a JSP form flow and one involving an external REST client. Validate the folder with the official `quick_validate.py` script and inspect generated `agents/openai.yaml` metadata.

## Acceptance Criteria

- The skill name and folder are `migrate-struts2-to-spring`.
- Frontmatter contains only `name` and `description` and triggers on Struts 2 to Spring migration work.
- `SKILL.md` stays concise and routes detailed guidance to the reference file.
- The route catalog template is valid YAML and captures client migration status.
- The official validator passes.
- Forward tests demonstrate preservation of client-visible behavior, client rework, compatibility routes, and route-catalog updates.
