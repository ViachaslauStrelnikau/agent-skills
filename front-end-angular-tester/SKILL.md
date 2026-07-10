---
name: front-end-angular-tester
description: Guide Angular (2+) application testing toward comprehensive, version-aware, maintainable coverage. Use when Codex needs to create, improve, review, debug, or plan Angular unit, service, component, signal, form, routing, guard, HTTP/resource, accessibility, visual, or end-to-end tests across Vitest, Karma/Jasmine, Jest, standalone, NgModule, zone-based, or zoneless projects. Do not use for AngularJS 1.x or non-Angular frontend work unless the request explicitly asks for transferable testing strategy.
---

# Front-end Angular Tester

## Overview

Design or revise Angular tests that protect useful behavior without duplicating implementation details. Preserve the project's runner, helpers, style, and naming conventions unless migration or test-infrastructure change is explicitly in scope.

## Workflow

1. Inspect `package.json`, the lockfile, `angular.json`, package scripts, CI commands, nearby specs, setup files, and custom test utilities. Identify the Angular/CLI versions, builder, runner, DOM or browser environment, standalone versus NgModule style, Zone.js versus zoneless behavior, and relevant feature APIs.
2. Match the task intent:
   - For review or planning, remain read-only and report risks, gaps, duplication, and the cheapest useful test layers.
   - For diagnosis, reproduce the failure first and identify its cause; change tests or production code only when the request includes a fix.
   - For implementation, edit the smallest in-scope test and setup surface that proves the requested behavior.
   - For migration, treat runner, builder, dependency, and global configuration changes as explicit migration work rather than incidental cleanup.
3. Treat project configuration as a compatibility boundary. Do not introduce Vitest, provider-only APIs, standalone-only setup, signal/resource helpers, zoneless assumptions, or modern fixtures unless the detected project supports them.
4. Fetch current documentation before using version-sensitive Angular or runner APIs. Use Context7 for Angular, Testing Library, Playwright, or other framework-specific behavior.
5. Choose the cheapest test layer that catches the risk: static check, pure unit, service, component, browser/accessibility/visual, or end to end. Do not prove the same local detail at every layer.
6. Assert public behavior: rendered text and states, accessible controls, user events, harness contracts, outputs, navigation results, submitted values, service/HTTP contracts, or visible error handling. Avoid private methods, internal signal/computed structure, incidental CSS/markup, and large snapshots unless they are the product contract.
7. Protect test integrity. Do not weaken assertions, add skips/focus markers, broaden mocks, accept visual baselines, increase retries/timeouts, force change detection, change production behavior, or add dependencies merely to obtain a green run.
8. Cover only applicable states: default, primary action, loading, success, empty, error, validation/disabled, permission, navigation fallback, focus, and one meaningful boundary or regression case.
9. Run the narrow relevant command, then the broader project command when proportionate to risk. Inspect scripts and configuration rather than guessing flags.

## References

Read only the references relevant to the task:

- Read `references/testing-guidelines.md` for test strategy, task modes, integrity guardrails, coverage selection, and the final review checklist.
- Read `references/runners-and-async.md` for runner detection, CLI/browser environments, Zone.js versus zoneless behavior, timers, stabilization, migration boundaries, or flaky-test diagnosis.
- Read `references/components-signals-defer.md` for `TestBed`, component bindings, Angular Testing Library, component harnesses, signals/resources, overlays, or `@defer` blocks.
- Read `references/forms-router-http.md` for reactive, template-driven, or Signal Forms; custom controls; routing, guards, and resolvers; or `HttpClient`/`httpResource` tests.
- Read `references/browser-quality.md` for accessibility, keyboard/focus behavior, visual regression, real-browser checks, or end-to-end workflows.
- Read `references/legacy-karma-jasmine.md` for confirmed Karma/Jasmine projects. For NgModule-heavy projects, legacy `*TestingModule` utilities, or established `fakeAsync` suites on another runner, use its module/setup guidance but keep the actual runner's mocks, timers, and commands from `references/runners-and-async.md`.

## Output Expectations

When adding or changing tests:

- Explain the behavior covered and why the chosen layer is appropriate.
- Keep mocks and fixtures minimal, named, and close to the test unless reused locally.
- State the exact command run and summarize failures that remain.
- Call out intentional gaps, especially untested real-browser rendering, accessibility, visual, integration, or multi-page risk.
- Disclose any production-code, configuration, dependency, baseline, retry, or quarantine change and why it was necessary.
