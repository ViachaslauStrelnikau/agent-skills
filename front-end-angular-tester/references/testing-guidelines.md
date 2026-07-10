# Angular Testing Strategy and Review

Use this reference for the durable decisions that apply across Angular versions and runners. Load the feature-specific reference from `SKILL.md` before using version-sensitive APIs.

## Task Mode

Match the work to the request:

| Mode | Required behavior |
| --- | --- |
| Review or plan | Inspect without editing. Report observable coverage, duplication, brittleness, missing risks, and recommended layers. |
| Diagnose | Reproduce with the project's command, isolate the cause, and explain it. Do not implement a fix unless requested. |
| Add or repair tests | Make the smallest test/setup change that proves the requested contract. Preserve production behavior unless a production fix is in scope. |
| Migrate tooling | Confirm migration is explicit. Treat runner, builder, global setup, dependency, and broad rewrite changes as migration work. |

For a regression fix, demonstrate that the new or corrected assertion fails against the broken behavior when feasible, then passes after the fix.

## Choose the Test Layer

Prefer this order, stopping at the cheapest layer that catches the meaningful failure:

1. Static checks for typing, linting, template diagnostics, formatting, and build errors.
2. Pure unit tests for functions, pipes, validators, reducers, and logic without Angular wiring.
3. Service tests for dependency injection, async contracts, HTTP mapping, caching, and error behavior.
4. Component tests for rendering, bindings, DOM interaction, forms, child integration, focus, and local state transitions.
5. Real-browser, accessibility, or visual tests when semantics, rendering, keyboard behavior, layout, or appearance is the contract.
6. End-to-end tests for a small set of critical workflows across routes, authentication, backends, or system boundaries.

Do not repeat a component-level detail in e2e unless the integration path is the actual risk. Do not replace an integration test's defining boundary with a mock and continue to describe it as end to end.

## Design Tests Around Contracts

- Name tests after observable behavior and the condition that produces it.
- Act through public inputs, DOM events, accessible controls, harness APIs, service methods, navigation, or controlled dependencies.
- Assert visible state, emitted output, navigation result, submitted payload, request contract, or returned value.
- Stub only slow, flaky, destructive, external, or irrelevant boundaries. Keep the real collaboration between units when it is part of the risk.
- Keep fixtures realistic but minimal. Prefer local builders over giant shared objects when only a few fields matter.
- Use setup helpers when they reveal intent or support meaningful variants; avoid abstractions that hide the behavior under test.

Avoid private methods, internal signals/computeds/effects, exact markup, incidental CSS classes, framework mechanics, trivial property assignment, and large snapshots unless one is explicitly the supported contract.

## Select Applicable States

Use this matrix as a menu, not a requirement to test every row:

| Feature risk | Useful states |
| --- | --- |
| Data loading | Initial/loading, success, empty, expected error, retry or refresh when supported |
| User input | Valid action, meaningful invalid/disabled case, submitted value, async failure when relevant |
| Permissions | Allowed, denied/hidden/disabled, redirect or fallback |
| Navigation | Destination, blocked/redirected path, missing or changed parameter, fallback |
| Interactive UI | Default, primary interaction, keyboard/focus behavior, close/cancel, one boundary |
| Deferred or async UI | Placeholder/pending, resolved, error, and the real trigger only when trigger behavior matters |
| Regression | The smallest input and assertion that would fail if the bug returns |

Stop when another case only restates implementation branches or duplicates a contract already protected at a cheaper layer.

## Integrity Guardrails

- Do not delete, weaken, invert, or broadly rewrite assertions merely to make a test pass.
- Do not add `.only`, focused specs, `.skip`, disabled suites, broad quarantine, arbitrary sleeps, excessive timeouts, retries, or force actions as a final fix.
- Do not mock the subject under test or the integration boundary the test exists to prove.
- Do not mutate production behavior solely to satisfy a brittle test. If production change is part of the requested fix, explain the behavior change separately.
- Do not add a dependency, migrate a runner, change global TestBed providers, alter Zone.js mode, or replace project-wide configuration unless that scope is explicit.
- Do not bulk-accept screenshot baselines, widen pixel thresholds, mask the tested area, disable accessibility rules, or shrink scan scope without inspecting and explaining the product-contract change.
- Restore fake timers, globals, storage, DOM additions, spies, server data, and other shared state. Keep tests independent of order and parallel-safe.
- Surface unexpected console errors, unhandled rejections, HTTP requests, and leaked work rather than suppressing them.

## Review Checklist

- Does each test describe and prove observable behavior?
- Is the selected layer the cheapest one that catches the risk?
- Can implementation details change without rewriting unrelated tests?
- Are mocks narrower than the subject and the contract being tested?
- Are async sources controlled and waits deterministic?
- Are only applicable success, failure, empty, permission, focus, or boundary states covered?
- Are runner, Angular version, and Zone.js/zoneless assumptions compatible with the project?
- Are production, dependency, configuration, baseline, retry, timeout, or quarantine changes explicit and justified?
- Did the relevant local or CI-equivalent command run?
- Are untested browser, accessibility, visual, integration, or multi-page risks called out?
