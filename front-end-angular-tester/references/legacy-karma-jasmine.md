# Legacy Karma/Jasmine Angular Testing

Last verified against current Angular documentation: 2026-07-10.

Sources:

- https://angular.dev/guide/testing/karma
- https://angular.dev/guide/testing/migrating-to-vitest
- Context7: `/websites/angular_dev`

Use this reference for Angular projects that still run Karma/Jasmine, are NgModule-heavy, or use older Angular testing utilities. Preserve the project's runner and patterns unless the user explicitly asks to migrate.

## Detection

Confirm the runner before applying Jasmine-specific advice. Strong Karma/Jasmine evidence includes:

- An `angular.json` test target or package/CI script explicitly configured for Karma.
- `karma.conf.*`, Karma dependencies/reporters/launchers, or configured names such as `ChromeHeadless`.
- Jasmine dependencies or unmistakable Jasmine APIs such as `jasmine.createSpyObj`, `jasmine.objectContaining`, or Jasmine-specific matcher configuration.

Do not infer the runner from Angular APIs alone:

- `fakeAsync`, Angular `tick`/`flush`, and `waitForAsync` come from Angular testing, not Jasmine. They can appear under Vitest when the documented Zone patch is configured.
- `declarations`, NgModules, `HttpClientTestingModule`, `RouterTestingModule`, and broad shared test modules indicate a module-based or older setup, not a particular runner.
- Global `describe`/`it` and even `spyOn` can be exposed by multiple runners.

If the project is NgModule-heavy but runs Vitest, Jest, or another runner, use the compatible module/TestBed guidance below while retaining that runner's spy, timer, teardown, and command conventions.

## TestBed Setup

Prefer the local project style:

```typescript
beforeEach(waitForAsync(() => {
  TestBed.configureTestingModule({
    declarations: [ExampleComponent],
    imports: [FormsModule, HttpClientTestingModule],
    providers: [
      { provide: ExampleService, useValue: exampleServiceSpy },
    ],
  }).compileComponents();
}));

beforeEach(() => {
  fixture = TestBed.createComponent(ExampleComponent);
  component = fixture.componentInstance;
  fixture.detectChanges();
});
```

Use `declarations` for non-standalone components, pipes, and directives owned by the test module. Use `imports` for Angular modules, shared modules, material modules, and standalone components only when the project already supports them.

## Jasmine and Async

- Use `spyOn` or `jasmine.createSpyObj` when the suite already uses Jasmine spies; do not introduce `vi.fn()` or `jest.fn()` into Karma specs.
- Use `fakeAsync`/`tick` for timers, debounced form controls, delayed observables, and code already written in that style.
- Use `waitForAsync` plus `fixture.whenStable()` for promises, template compilation, routing, and async Angular rendering.
- Avoid arbitrary `setTimeout` waits; make the async source deterministic.
- Clean up global spies, localStorage/sessionStorage state, fake clocks, and shared mutable fixtures after each spec.

## HTTP and Router

For older suites, follow the existing module-based utilities:

```typescript
beforeEach(() => {
  TestBed.configureTestingModule({
    imports: [HttpClientTestingModule],
    providers: [ExampleService],
  });
  httpTesting = TestBed.inject(HttpTestingController);
});

afterEach(() => {
  httpTesting.verify();
});
```

Assert request method, URL, body, important headers, success, and error behavior. Use `RouterTestingModule` or the project's existing router helpers for route-dependent components and guards. Prefer `RouterTestingHarness` only when the project already uses modern provider-based router tests.

For guard, resolver, and routed-component tests in legacy suites, keep the existing route helper style. Assert the public result: allowed navigation, redirect URL/tree, rendered route data, missing-param behavior, or fallback route. Do not migrate a whole route test to `provideRouter()` just to add one assertion.

## Forms

For NgModule-based form tests, import the same forms modules the component uses, commonly `ReactiveFormsModule` or `FormsModule`. Test visible validation, disabled controls, submitted values, async validator outcomes, and `ControlValueAccessor` integration through a small host component when needed.

Use `fakeAsync`/`tick` for debounced controls or async validators when the suite already uses that style. Use `waitForAsync` plus `fixture.whenStable()` for promise-driven template updates. Avoid reaching into private form helper methods unless the public contract is otherwise impossible to observe.

## CI Commands

Inspect `package.json` first and run the closest existing CI script. Common Karma commands are:

```bash
ng test --watch=false
ng test --watch=false --browsers=ChromeHeadless
ng test --watch=false --browsers=ChromeHeadless --code-coverage
```

Use the configured browser name from `karma.conf.js`; do not assume `ChromeHeadless` exists in every workspace. Keep `--browsers` out of Vitest/jsdom projects.

## Modernization Boundaries

Do not convert a Karma/Jasmine suite to Vitest, standalone TestBed imports, provider-based APIs, or Angular Testing Library as part of ordinary test coverage work. Modernize only the smallest necessary piece when the existing pattern cannot test the requested behavior or the user explicitly asks for migration.
