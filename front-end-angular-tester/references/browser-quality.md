# Browser Quality Tests

Last verified against current Playwright documentation: 2026-07-10.

Sources:

- https://playwright.dev/docs/best-practices
- https://playwright.dev/docs/accessibility-testing
- https://playwright.dev/docs/test-snapshots
- https://playwright.dev/docs/trace-viewer-intro
- https://playwright.dev/docs/test-retries
- https://www.chromatic.com/frontend-testing-guide
- Context7: `/microsoft/playwright`

## Contents

- Accessibility
- Visual determinism
- Reliable end-to-end workflows
- Browser-test integrity and reporting

Use browser tests when the risk depends on a real browser, rendered appearance, assistive semantics, native interaction, or a cross-page workflow. Keep local behavior at a cheaper unit or component layer.

## Accessibility

- Prefer semantic locators that reflect the accessibility tree: role plus accessible name, label, heading, and visible text. Use test IDs only when no stable user-facing locator exists; avoid CSS/XPath tied to markup structure.
- Reuse the project's accessibility tooling. In Playwright projects, `@axe-core/playwright` is a common automated baseline, but adding it is a dependency change and must be in scope.
- Scan representative stable states and fail on unexpected automatically detectable violations. Scope scans intentionally and document every disabled rule or exclusion with a concrete reason.
- Test relevant keyboard behavior: Tab/Shift+Tab order, Enter/Space activation, arrow navigation, Escape dismissal, and focus return.
- Assert focus after dialog open/close, route changes, validation failures, and destructive confirmations when the behavior is part of the contract.
- Verify labels, accessible names, roles/states, error relationships, and live-region behavior for custom or dynamic controls.

Automated axe checks are a baseline, not accessibility certification. They cannot prove overall usability, logical reading order, announcement quality, or a good screen-reader experience. For materially changed critical flows or complex widgets, call out the need for focused manual keyboard and assistive-technology verification; record the browser, platform, assistive technology, scenario, and result when performed.

## Visual Determinism

Make the rendering environment reproducible before capturing or updating a baseline:

- Pin the browser/runtime and canonical operating environment.
- Set viewport, device scale, color scheme, locale, and timezone explicitly.
- Use known fonts and wait for them to load.
- Wait for the target state with a web-first assertion; do not sleep.
- Disable or fast-forward animations/transitions, hide the caret, and freeze time when they affect pixels.
- Control random IDs, generated content, network responses, and test data at an intentional boundary.
- Avoid live ads, analytics, third-party content, and mutable services.
- Prefer a component or stable-region screenshot when that is the contract; use full-page screenshots only when the page layout is the contract.
- Mask only unavoidable dynamic content, never the area whose appearance is under test.
- Keep pixel thresholds narrow and justified.

Generate baselines in the canonical environment and inspect both the rendered image and diff. Updating a baseline accepts a product appearance change; it is not a fix for an unexplained failing test. Cover only meaningful states, themes, and responsive breakpoints rather than multiplying snapshots without distinct contracts.

## Reliable End-to-End Workflows

- Reserve e2e for a small set of critical workflows and integration boundaries. Do not mock away the boundary the test exists to prove.
- Give each test an isolated browser context and parallel-safe server data. Seed through supported APIs/fixtures, use unique identifiers, and clean up when required.
- Reuse authenticated storage state only when isolation remains valid. Keep separate state per role, avoid shared mutation-prone accounts, refresh expiration deterministically, and never commit credentials or tokens.
- Use semantic locators, awaited actions, and web-first assertions that retry until the observable UI state is reached. Wait for readiness, not fixed delays.
- Avoid force clicks unless forced interaction is the scenario. A force action often hides an overlay, disabled state, animation, or locator bug.
- Capture traces on first retry or failure, plus screenshots/video and application logs where useful. Prevent credentials, tokens, or personal data from leaking into artifacts.
- Keep retries low and visible. A pass on retry is evidence of flakiness, not a clean pass; fix the cause or quarantine temporarily with an owner and follow-up instead of raising retries.

## Browser-Test Integrity and Reporting

- Do not add `only`, `skip`, broad quarantine, arbitrary sleeps, excessive timeouts, force actions, or extra retries merely to obtain green CI.
- Do not weaken assertions, axe rules, scan scope, screenshot thresholds, or visual coverage without explaining the product-contract change.
- Do not regenerate baselines or broaden masks until the diff has been inspected and intentionally accepted.
- Do not replace required integration coverage with mocks and continue calling the test end to end.
- Do not add browser-testing dependencies or change production behavior solely to accommodate a test without making that scope explicit.
- Diagnose from the trace, screenshot diff, console/network errors, and seed/auth state before changing the test.

Report the browser(s), viewport(s), exact command, result, retries/flakes, and artifacts reviewed. Call out manual accessibility checks, accepted baseline changes, intentional exclusions, untested browsers, and quarantined scenarios.
