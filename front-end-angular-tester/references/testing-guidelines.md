# Angular and Frontend Testing Guidelines

Sources used to create this reference:

- Angular testing guide: https://angular.dev/guide/testing
- Angular HTTP testing guide: https://angular.dev/guide/http/testing
- Angular component harness guide: https://angular.dev/guide/testing/creating-component-harnesses
- Chromatic frontend testing guide: https://www.chromatic.com/frontend-testing-guide
- Context7 Angular docs entry: `/websites/angular_dev`

## Testing Strategy

Use tests to protect behavior that users or downstream code depend on. Aim for coverage that is broad enough to support refactoring and releases, but small enough that failures are specific and maintenance cost stays reasonable.

Prefer this order:

1. Static checks for typing, linting, formatting, and simple template mistakes.
2. Unit tests for pure functions, pipes, validators, guards, reducers, and small services.
3. Angular service tests for dependency injection, HTTP contracts, async behavior, and error handling.
4. Angular component tests for rendering, inputs/outputs, DOM interaction, state transitions, forms, and child/service integration.
5. Accessibility tests for keyboard and assistive-technology risks.
6. Visual tests for important layout or appearance contracts.
7. End-to-end tests for critical user flows across pages or systems.

Do not force every behavior through every layer. If a component test proves a local interaction, avoid adding an e2e test for the same detail unless the workflow integration is the actual risk.

## Angular Defaults and Commands

For current Angular CLI projects, expect `ng test` to run Vitest by default. Angular's current guide describes new CLI projects as using Vitest with `jsdom` for DOM emulation, while still documenting Karma for existing projects.

Before changing test configuration:

- Inspect `package.json` scripts and dependencies.
- Inspect `angular.json` test target options such as `include`, `exclude`, `setupFiles`, `providersFile`, `coverage`, `browsers`, and `runnerConfig`.
- Prefer Angular CLI-managed configuration unless the project already owns custom Vitest/Karma setup.

Common commands:

```bash
ng test
ng test --coverage
ng test --no-watch --no-progress
```

Browser flags such as `--browsers=chromiumHeadless` are runner-specific. Use them only after confirming the project is configured for Karma or another real-browser runner that supports the option. Use real-browser mode for browser-specific APIs, rendering behavior, or debugging DOM differences. Keep most unit and component tests in the faster default environment.

## Angular Component Tests

Use Angular `TestBed` to create components and wire dependencies the same way Angular does. Reuse setup with `beforeEach` when it reduces noise.

Prefer this shape:

```typescript
describe('ExampleComponent', () => {
  let fixture: ComponentFixture<ExampleComponent>;
  let component: ExampleComponent;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ExampleComponent],
      providers: [
        { provide: ExampleService, useValue: exampleServiceMock },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(ExampleComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
    await fixture.whenStable();
  });

  it('shows the saved state after the user submits valid input', async () => {
    // Arrange realistic inputs and service responses.
    // Act through DOM events or public component APIs.
    // Assert rendered output or emitted behavior.
  });
});
```

Use `fixture.detectChanges()` and `await fixture.whenStable()` deliberately:

- Call `detectChanges()` after input changes that Angular must render.
- Await `whenStable()` when async rendering, promises, effects, or event handling must settle.
- Control timers with the project's runner utilities when timer behavior is part of the feature.

Prefer DOM interactions for component behavior tests:

- Set input values and dispatch events instead of mutating internals.
- Click buttons and submit forms instead of directly calling private handlers.
- Assert visible text, disabled/enabled states, validation messages, emitted outputs, router outcomes, or service calls.

Use Angular CDK or project-provided component harnesses for shared interactive components, design-system widgets, menus, dialogs, and other controls where DOM structure is not the public contract. Harnesses are worth the extra setup when they make tests less coupled to markup or event details.

Avoid:

- Asserting private methods or implementation-only properties.
- Over-mocking Angular itself.
- Repeating a full TestBed setup in every test when a local helper would make intent clearer.
- Snapshotting large rendered DOM trees as the main assertion.

## Services, HTTP, and Dependencies

For services:

- Test pure service logic directly when Angular DI is irrelevant.
- Use `TestBed.inject()` when DI configuration, injected dependencies, or Angular providers matter.
- Replace network, storage, time, routing, analytics, and global browser APIs with narrow test doubles.
- Assert service contracts: returned values, emitted values, requested URLs/payloads, retries, and error behavior.

For HTTP behavior, prefer Angular's HTTP testing utilities already used by the project. Keep assertions focused on request method, URL, body, important headers, and observable result.

For provider-based Angular projects, configure HTTP tests with `provideHttpClient()` and `provideHttpClientTesting()`. Put `provideHttpClientTesting()` after `provideHttpClient()` so the test backend replaces the real backend correctly, especially when testing interceptors or other `HttpClient` features.

## Async and Flake Control

Make async behavior explicit. Avoid tests that pass only because of incidental timing.

- Await user actions, fixture stabilization, route navigation, observables, and promise resolution.
- For signal-driven effects, resources, or `httpResource`, trigger and await Angular stabilization deliberately with the APIs already used by the project, such as `TestBed.tick()` or `ApplicationRef.whenStable()`.
- Use fake timers only when timers are the behavior under test or needed to remove delay.
- Restore fake timers and global mocks after each test.
- Avoid arbitrary sleeps.
- Prefer deterministic mock data over live services.

When a test is flaky, first check unresolved async work, shared mutable fixtures, real timers, implicit order dependence, and browser-specific behavior running in a simulated DOM.

## Coverage Heuristics

For a component or feature, cover:

- The default render.
- The primary user action.
- Loading and success states when data is fetched.
- Empty state when no data is returned.
- Error state when an expected dependency fails.
- Validation or disabled behavior for invalid input.
- One boundary case that previously broke or is likely to break.

Skip tests that only check framework mechanics, trivial property assignment, duplicate branches already covered through user behavior, or implementation details with no user or contract value.

## Accessibility, Visual, and E2E

Add accessibility checks when changes affect forms, modals, menus, keyboard navigation, focus management, labels, headings, errors, dynamic announcements, or disabled states.

Add visual tests when the contract is appearance: design-system components, responsive layouts, theming, visual regressions, important empty/loading/error states, or components with complex CSS.

Add e2e tests for the few workflows that must work end to end: authentication, purchase/checkout, critical CRUD flows, permissions, routing across pages, and integrations that unit/component tests cannot represent.

Keep e2e tests fewer, stable, and user-flow oriented. Do not use e2e tests as the default place to check every component branch.

## Review Checklist

Use this checklist before finishing:

- Does each test name describe observable behavior?
- Can a future maintainer change internals without rewriting the test?
- Is the test layer the cheapest layer that catches the risk?
- Are mocks narrower than the thing being tested?
- Are async waits deterministic?
- Are important failure states covered?
- Are visual, accessibility, or e2e gaps intentional and mentioned?
- Did the relevant test command run locally or in CI?
