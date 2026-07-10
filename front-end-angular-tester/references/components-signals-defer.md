# Components, Signals, Harnesses, and Deferred Blocks

Last verified against current Angular and Angular Testing Library documentation: 2026-07-10.

Sources:

- https://angular.dev/guide/testing/components-scenarios
- https://angular.dev/guide/zoneless
- https://angular.dev/guide/testing/component-harnesses-overview
- https://angular.dev/guide/testing/using-component-harnesses
- https://angular.dev/best-practices/performance/defer
- https://testing-library.com/docs/angular-testing-library/intro
- Context7: `/websites/angular_dev`, `/testing-library/angular-testing-library`

## Contents

- Compile, create, and render deliberately
- Bind inputs and outputs through supported APIs
- Test signals and resources through behavior
- Use component harnesses and Testing Library intentionally
- Separate deferred states from deferred triggers

## Compile, Create, and Render Deliberately

Do not standardize on one universal `TestBed` template. Match the project's compiler, change-detection mode, and nearby tests.

- Call `compileComponents()` only when the runner performs runtime compilation and must resolve component resources, or when local setup requires it. Apply overrides before compilation and fixture creation.
- In current scheduled or zoneless-style tests, create the fixture, drive a public input/event, and prefer `await fixture.whenStable()` for initial or scheduled rendering.
- Keep `fixture.detectChanges()` in established Zone-based/manual suites or when the test explicitly needs an immediate change-detection checkpoint.
- Do not call `compileComponents()`, `detectChanges()`, and `whenStable()` mechanically. Forced detection can hide missing zoneless or OnPush notifications; redundant stabilization makes intermediate-state tests harder.
- Use `await fixture.whenRenderingDone()` when animations or rendering work, rather than ordinary Angular task stability, is the boundary.

A current zoneless-style test can stay small:

```typescript
beforeEach(() => {
  TestBed.configureTestingModule({
    imports: [ExampleComponent],
    providers: [{provide: ExampleService, useValue: exampleServiceMock}],
  });
  fixture = TestBed.createComponent(ExampleComponent);
});

it('shows the supplied value', async () => {
  fixture.componentRef.setInput('value', 'ready');
  await fixture.whenStable();

  expect(fixture.nativeElement.textContent).toContain('ready');
});
```

Use the project's runner matcher syntax and reset shared mocks between tests.

## Bind Inputs and Outputs Through Supported APIs

- Use `fixture.componentRef.setInput(name, value)` for a one-off input change. It preserves input/update semantics better than assigning an input field directly.
- In Angular versions that support TestBed bindings, use `inputBinding(...)`, `outputBinding(...)`, and `twoWayBinding(...)` for reactive parent-like wiring.
- Use a small host component when projected content, directives, structural context, multiple bindings/children, or realistic parent-child behavior is the contract.
- Use DOM events for user behavior. Do not call a private click, submit, or change handler directly.
- Assert rendered state, accessible properties, emitted values, or collaboration with a public dependency rather than internal fields.

Feature-detect newer binding APIs from the installed Angular version and local typings; do not introduce them into older suites merely to modernize one spec.

## Test Signals and Resources Through Behavior

- Drive the public cause: change an input/bound signal, dispatch a user event, change a route value, or flush a controlled dependency.
- Await scheduled rendering before asserting. Use version-supported `TestBed.tick()` only where the project and current docs use it for pending effects or resources; it does not advance timer time.
- Use `TestBed.runInInjectionContext()` when test-created code calls `inject()` or constructs an effect/resource that requires an injection context.
- Prefer the component or service boundary for `resource`/`httpResource` so both request/state mapping and visible loading, success, empty, error, retry, or refresh behavior can be observed.
- Do not assert a private signal, computed, effect execution count, or implementation-only resource internals when UI or output proves the contract.
- Do not use sleeps to trigger effects. Control the dependency, time source, request, or Angular stabilization explicitly.

## Use Component Harnesses Intentionally

Prefer Angular CDK, Material, Angular Aria, or project-provided harnesses for shared interactive components and design-system controls. Harnesses provide a supported user-facing API and reduce coupling to internal DOM structure.

- Use `TestbedHarnessEnvironment.loader(fixture)` for content inside the fixture.
- Use `TestbedHarnessEnvironment.documentRootLoader(fixture)` for dialogs, menus, selects, tooltips, and other overlay content attached outside the fixture root.
- Await harness actions and queries. Do not combine a harness interaction with private overlay selectors unless the public harness cannot express the required contract.
- Use a real-browser test when simulated harness events cannot prove native focus, layout, pointer, or rendering behavior.
- Create a custom harness mainly for reusable interactive components consumed by many tests; a one-off page component rarely justifies the abstraction.

## Use Angular Testing Library Conditionally

Use `@testing-library/angular` when the project already depends on it, or when adding it is explicitly in scope and the team wants user-centered component tests.

- Render with realistic inputs, output handlers, providers, imports, and routes.
- Query by role and accessible name, label, heading, or visible text. Use `within(...)` for repeated regions and test IDs only when no user-facing locator represents the contract.
- Create `userEvent` with `userEvent.setup()` and await clicks, typing, selection, tabbing, and submission.
- Prefer `findBy...` or awaited user-visible changes over manual polling.
- Do not mix Testing Library style with low-level fixture mutation unless a specific Angular synchronization, harness, or unsupported interaction requires it.

Follow the project's installed Testing Library version; render option names and runner-specific mock helpers can change.

## Separate Deferred States From Deferred Triggers

Use manual defer fixtures only when state rendering is the contract:

- Configure `deferBlockBehavior: DeferBlockBehavior.Manual`.
- Retrieve blocks with `await fixture.getDeferBlocks()`.
- Render and assert only meaningful `Placeholder`, `Loading`, `Complete`, or `Error` states.

A manual `render(state)` test does not prove the configured trigger, viewport observer, interaction, hover/focus event, idle scheduling, prefetch timing, or lazy chunk loading.

When the trigger is the contract, exercise the actual `when` condition or interaction. Use a configured real-browser test for viewport, idle, pointer, or other browser-dependent triggers that the simulated DOM cannot represent faithfully. Keep trigger tests separate from state-rendering tests.
