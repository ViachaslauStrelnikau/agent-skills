---
name: front-end-angular-tester
description: Guide Angular and frontend testing work toward comprehensive but maintainable coverage. Use when Codex needs to create, improve, review, debug, or plan Angular tests, component tests, service tests, frontend behavior tests, accessibility checks, visual tests, or end-to-end test strategy without overcomplicating the suite.
---

# Front-end Angular Tester

## Overview

Use this skill to design or revise Angular/frontend tests that prove useful behavior without duplicating implementation details. Prefer the project's existing test runner, helpers, style, and naming conventions before introducing new tools.

## Workflow

1. Inspect the project first: identify Angular version, test runner, existing specs, custom test utilities, package scripts, CI commands, and whether the app uses standalone components, NgModules, signals, routing, forms, HTTP, or browser-only APIs.
2. Classify the requested change by risk and user value: pure logic, Angular service, component rendering and interaction, accessibility, visual appearance, or cross-page workflow.
3. Choose the smallest test layer that can catch the failure with confidence. Prefer fast unit/service/component tests for local behavior; add browser, visual, accessibility, or e2e coverage only when the risk requires it.
4. Write tests against public behavior: rendered text, accessible controls, component harnesses, events, service contracts, navigation outcomes, HTTP requests, and visible states. Avoid asserting private methods, internal signal/computed structure, CSS implementation details, or exact markup unless that is the product contract.
5. Keep setup boring and local. Use `beforeEach` for repeated setup, use Angular `TestBed`, provider-based test utilities, and dependency injection intentionally, and stub only boundaries that make the test slow, flaky, or unrelated to the behavior.
6. Exercise realistic states: default, loading, success, empty, validation/error, permission/disabled, and one meaningful edge case. Stop when another test would only restate the implementation.
7. Run the relevant test command. If the command is unknown, inspect `package.json` and Angular config before guessing.

## Reference

Read `references/testing-guidelines.md` when writing more than a trivial spec, reviewing frontend test coverage, choosing between test layers, or debugging flaky Angular tests.

## Output Expectations

When adding or changing tests:

- Explain the behavior covered and why the chosen layer is appropriate.
- Keep mocks and fixtures minimal, named, and close to the test unless reused locally.
- Prefer user-observable assertions and accessible selectors where the project's tooling supports them.
- Include the exact command run and summarize failures if tests cannot be made green.
- Call out intentional coverage gaps, especially untested browser rendering, visual, accessibility, or multi-page workflow risk.
