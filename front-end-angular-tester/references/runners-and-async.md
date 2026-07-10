# Angular Test Runners, Environments, and Async Control

Last verified against current Angular documentation: 2026-07-10.

Sources:

- https://angular.dev/guide/testing
- https://angular.dev/guide/testing/migrating-to-vitest
- https://angular.dev/guide/testing/karma
- https://angular.dev/guide/zoneless
- https://angular.dev/guide/testing/components-scenarios
- Context7: `/websites/angular_dev`

## Contents

- Inspect before choosing a pattern
- Detect the runner and environment
- Commands and real-browser mode
- Match production change detection
- Choose the synchronization API
- Diagnose flakes

## Inspect Before Choosing a Pattern

Treat `package.json`, the lockfile, `angular.json`, existing specs, setup files, and CI scripts as the source of truth. Detect:

- Angular and CLI versions.
- Test builder and runner.
- Simulated DOM versus real-browser mode.
- Spy, mock, and timer APIs.
- Test polyfills, including Zone.js and any Vitest patch.
- Production and TestBed change-detection modes.

Preserve the configured toolchain during ordinary test work. Do not migrate Karma to Vitest, replace Jest, add a browser provider, or change Zone.js configuration unless migration or test infrastructure is explicitly in scope.

## Detect the Runner and Environment

Do not infer the runner from the Angular major version alone.

| Detected setup | Use | Avoid |
| --- | --- | --- |
| Unit-test builder using its default or explicit Vitest runner, corroborated by Vitest dependencies/config or `vi.*` specs | Project `ng test`/package script, Vitest spies and timers, configured DOM environment | Jasmine-only APIs and Karma launcher names |
| Unit-test builder explicitly configured with the Karma runner | Jasmine/Karma conventions and `legacy-karma-jasmine.md` | Treating the builder name as proof of Vitest |
| Karma builder/config or Jasmine-heavy specs | Existing Karma/Jasmine helpers and configured browser launcher | Vitest APIs or opportunistic migration |
| Jest, Nx, Bazel, Spectator, custom Vitest, or another enterprise setup | Existing scripts, config, helpers, timers, and teardown | Replacing it with Angular CLI defaults |
| Vitest browser mode | Configured Playwright/WebdriverIO provider and its browser names | Assuming `--browsers` works without a provider |
| `jsdom` or configured `happy-dom` | Fast DOM behavior and component tests | Treating layout, CSS rendering, or native browser behavior as authoritative |

Current Angular CLI-created projects use Vitest and `jsdom` by default; existing projects may still use Karma/Jasmine or another runner. Karma remains supported. Treat `happy-dom` as an explicit project choice, not the Angular default.

## Commands and Real-Browser Mode

Prefer the closest existing package or CI script. Common current CLI commands are:

```bash
ng test
ng test --watch=false
ng test --watch=false --coverage
```

If the project intentionally invokes Vitest directly, use its established script or `vitest run`. Do not bypass Angular's builder merely because Vitest is installed.

For current Vitest browser mode, confirm that a provider such as `@vitest/browser-playwright` or `@vitest/browser-webdriverio` is already installed and configured. Then use that provider's browser names, for example:

```bash
ng test --browsers=chromiumHeadless
```

For Karma, use only a launcher configured by the project, commonly:

```bash
ng test --watch=false --browsers=ChromeHeadless
```

Do not add a provider or browser dependency merely to make one test pass. Use real-browser mode for layout/geometry, CSS rendering, animations, native focus differences, canvas/media, observers, or browser-only APIs. Do not assert meaningful `getBoundingClientRect()` geometry in a simulated DOM unless the test intentionally stubs it.

## Match Production Change Detection

Determine whether both production and the test environment are Zone-based or zoneless. When needed, configure `provideZonelessChangeDetection()` so TestBed mirrors a zoneless application.

In zoneless tests:

- Trigger updates through notifications Angular observes: signal writes, `ComponentRef.setInput()`, template events, async-pipe emissions, attached dirty views, or `markForCheck()`.
- Prefer `await fixture.whenStable()` after the public trigger.
- Avoid unconditional `fixture.detectChanges()`: forced detection can hide production code that failed to notify change detection.
- Use `fixture.detectChanges()` only for a deliberate synchronous checkpoint or a low-level setup mutation whose manual render is explicit.
- Do not assume a direct ordinary-field or form-model mutation schedules rendering.

In established Zone-based suites, retain clear local `detectChanges()`, `whenStable()`, `waitForAsync()`, or `fakeAsync()` patterns. Do not make `compileComponents()`, `detectChanges()`, and `whenStable()` universal boilerplate.

## Choose the Synchronization API

| Async source | Control it with |
| --- | --- |
| Promise, awaited user interaction, harness action, or navigation | Native `async`/`await` |
| Angular-scheduled rendering | `await fixture.whenStable()` |
| Animations or pending rendering | `await fixture.whenRenderingDone()` when relevant |
| Vitest timer, debounce, delay, or polling | Vitest fake timers plus async timer advancement |
| Zone-based legacy timer test | `fakeAsync()` with Angular `tick()`/`flush()` |
| HTTP | `HttpTestingController.expectOne(...).flush(...)`, then Angular stabilization if UI changes |
| Observable | Controlled subject/emission or awaited completion such as `firstValueFrom()` |
| Router | Await `RouterTestingHarness.navigateByUrl(...)` or the navigation promise |
| Modern Angular effect/resource | Version-supported `TestBed.tick()`, application stability, or the established local API |

Keep these distinctions explicit:

- `TestBed.tick()` synchronizes supported Angular state; it does not advance wall-clock timers.
- Vitest timer advancement controls the runner's fake clock; it does not replace Angular stabilization.
- `fixture.whenStable()` waits for Angular-tracked fixture work. It does not flush mocked HTTP, emit an observable, advance a fake clock, or settle arbitrary external work.
- Advance a required fake timer before awaiting Angular stability.

For new Vitest tests, prefer native `async`/`await` and Vitest fake timers. Existing Vitest tests using Angular `fakeAsync`, `tick`, `flush`, or `waitForAsync` require the documented `zone.js/plugins/vitest-patch`. Treat that as migration compatibility; do not mix Vitest fake timers with Angular `fakeAsync()` in the same test. Restore real timers and global mocks in `afterEach` or `finally`.

## Diagnose Flakes

Diagnose before increasing timeouts or retries:

1. Reproduce with the exact CI command, then run the failing spec alone and after its likely predecessor.
2. Check unawaited promises, user events, navigation, harness calls, observables, HTTP, resources, defer blocks, and animations.
3. Check for a missing zoneless notification hidden by blanket `detectChanges()`.
4. Check leaked timers, spies, providers, globals, storage, DOM nodes, subscriptions, server data, and shared fixtures.
5. Check whether fake timers were enabled after scheduling or restored while work remained.
6. Control network, clock, random values, locale, timezone, and generated test data.
7. Re-run browser-sensitive failures in the configured real-browser environment.
8. Check order dependence and parallel access to shared ports, files, accounts, databases, or singleton state.

Treat arbitrary sleeps, larger timeouts, more retries, disabled concurrency, and blanket change detection as diagnostic experiments, not final fixes. Surface unhandled rejections and unexpected console errors instead of suppressing them.

Before any Karma-to-Vitest migration, refresh the current Angular migration guide. Migration tooling and support status are version-sensitive, and custom Karma configuration, Jasmine spies, Zone-based helpers, reporters, browser launchers, and build options require explicit review.
