# Forms, Routing, and HTTP

Last verified against current Angular documentation: 2026-07-10.

Sources:

- https://angular.dev/guide/forms/signals/testing
- https://angular.dev/guide/routing/testing
- https://angular.dev/api/router/testing/RouterTestingHarness
- https://angular.dev/guide/http/testing
- Context7: `/websites/angular_dev`

## Contents

- Choose the boundary
- Test reactive and template-driven forms
- Test Signal Forms and custom controls
- Test routes, guards, and resolvers
- Test `HttpClient` and `httpResource`

## Choose the Boundary

| Contract | Preferred layer |
| --- | --- |
| Pure validator or form schema | Isolated unit test |
| Model/template wiring, validation message, focus, or submit behavior | Component test through user interaction |
| Custom control integration | Small host form component |
| Guard/resolver pure logic | Direct unit test |
| Route activation, redirect, params, or routed rendering | Focused router integration test |
| Real history, address bar, full shell, authentication, or cross-page path | End-to-end test |
| Request method/URL/body/headers and response mapping | `HttpTestingController` service or component test |

## Reactive and Template-Driven Forms

For reactive forms:

- Test pure validators without rendering when Angular wiring is irrelevant.
- Use DOM input/change/blur/submit events for component behavior. Direct `FormControl`/`FormGroup` mutation is appropriate only when the form model is the tested contract.
- Assert visible validation, disabled/enabled behavior, focus, submitted payloads, and service calls. Assert internal touched/dirty flags only when they control observable UI.
- Cover cross-field and async validation only where those rules exist; control timers, HTTP, and completion deterministically.
- In zoneless tests, do not assume direct form-model mutation schedules a render. Drive the production notification path or use an explicitly justified manual render in a legacy/manual suite.

For template-driven forms:

- Include the same forms imports used by the component.
- Dispatch realistic input, change, blur, and submit events, then await the appropriate stabilization.
- Assert errors after the interaction that reveals them, such as blur or submit, rather than on initial render unless that is the product behavior.

For all important forms, prefer label/role/name queries and verify accessible error relationships such as `aria-invalid`, `aria-describedby`, focus movement, and live announcements where they are part of the contract.

## Signal Forms

Use this guidance only when the project actually uses and supports `@angular/forms/signals`; do not retrofit Signal Forms into reactive or template-driven suites.

- Most schema behavior belongs in an isolated test. Create the smallest model signal, build the form with an explicit injector or inside `TestBed.runInInjectionContext()`, update field values, and assert meaningful field-state signals.
- Prefer error kind/meaning plus `valid()`/`invalid()`, `disabled()`, `required()`, or other public state over exact internal error-object snapshots.
- Test cross-field and conditional rules by changing the source field and asserting the dependent field.
- Add a component-bound test only for `[formField]` model/view flow, user input, blur/focus, accessibility attributes, submission, or custom control behavior.
- For async or HTTP validation, assert pending, success, validation error, and meaningful cancellation/stale-result behavior by controlling the dependency; do not sleep.

Classic `ControlValueAccessor` and Signal Forms custom controls have different contracts. For a CVA, use a small host with `FormControl` or `ngModel` and cover:

- Parent value to view.
- User interaction to parent value.
- Blur/touch propagation.
- Parent disabled/enabled state to UI.
- Validation and accessible error display.

Do not invoke private registered CVA callbacks directly. For Signal Forms custom controls, follow the installed version's public `[formField]`/value-state contract and test it through a component host; do not describe it as a CVA unless it actually implements that interface.

## Routes, Guards, and Resolvers

Choose the narrowest useful router depth:

- Test pure URL-building, guard, or resolver logic directly.
- Use `TestBed.runInInjectionContext()` for a direct functional guard/resolver call that relies on `inject()`.
- Use `provideRouter(...)` with focused routes and `RouterTestingHarness` when activation, params, redirects, guards, resolvers, or routed component output is the contract.
- Preserve `RouterTestingModule` or local helpers in legacy suites unless modernization is explicitly requested.

With `RouterTestingHarness`:

- Create one harness per test and await `navigateByUrl(...)`.
- Use typed navigation when proving the activated component type matters.
- Assert the final `Router.url`, routed content, component contract, redirect target, guard rejection, param/query handling, resolver outcome, and fallback behavior.
- Cover resolver success, empty, and error only when the application defines distinct outcomes.

The harness provides a focused test root and routed outlet. Use a fuller host/shell integration test for named or secondary outlets, layout integration, or app-wide providers. Use e2e for real address-bar/history behavior, scroll restoration, lazy chunk fetching, authentication across pages, and full application-shell behavior.

## `HttpClient` Tests

In current Angular, the test environment provides `HttpClient`; `provideHttpClientTesting()` configures its test backend and supplies `HttpTestingController`. Do not add a bare `provideHttpClient()` beside it as routine boilerplate. Add `provideHttpClient(...)` only when the test must configure production features such as interceptors; in that case, put it before `provideHttpClientTesting()` so the testing provider replaces the backend correctly. Recheck this setup against older project documentation before backporting it.

```typescript
beforeEach(() => {
  TestBed.configureTestingModule({
    providers: [ConfigService, provideHttpClientTesting()],
  });
});

afterEach(() => {
  TestBed.inject(HttpTestingController).verify();
});
```

For an interceptor test, use the required production feature before the test backend:

```typescript
providers: [
  provideHttpClient(withInterceptors([authInterceptor])),
  provideHttpClientTesting(),
]
```

- Subscribe or create the awaited result before expecting the request.
- Assert method, full URL/query, body, and only meaningful headers.
- Flush success, backend error, or network error deliberately, then assert the returned or visible contract.
- Use `match()` for intentional concurrent requests; do not make `expectOne()` vague to hide duplicates.
- Call `verify()` after every test so outstanding or unexpected requests fail the suite.
- Never use live network access in a unit/component HTTP test.

## `httpResource` and Signal-Driven HTTP

Keep the sequence deterministic and version-aware:

1. Create the resource through its component/service boundary or a supported injection context.
2. Trigger the public request cause; use version-supported Angular synchronization such as `TestBed.tick()` only when needed to start pending reactive work.
3. Match and flush the request with `HttpTestingController`.
4. Await the component or application stability required by that Angular version and local test style.
5. Assert public loading, value/success, empty, error, reload, parameter-change, or stale-result behavior.
6. Verify no unexpected requests remain.

Do not assume `fixture.whenStable()` starts or flushes HTTP, and do not assume timer advancement synchronizes Angular. Refresh current Angular documentation when the project version's resource APIs differ from this sequence.
