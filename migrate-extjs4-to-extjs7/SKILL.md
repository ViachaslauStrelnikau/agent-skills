---
name: migrate-extjs4-to-extjs7
description: Use when Codex needs to analyze, plan, implement, diagnose, or review a direct upgrade of a Sencha Cmd Ext JS 4.x application to the Ext JS 7.x classic toolkit while preserving the existing Ext.app.Controller MVC structure, the Ext 4 visual appearance, and every server contract. Not for MVC-to-MVVM or ViewController refactors, not for modern-toolkit or mobile ports, not for Ext JS 3 to 4 work, and not for restyling.
---

# Migrate Ext JS 4 to Ext JS 7 (classic toolkit)

## Core principle

One framework hop, no redesign. The application moves from Ext JS 4.x to Ext JS 7.x classic on a single cutover branch, keeping global `Ext.app.Controller` MVC, the classic theme, and every request and response the Java backend already sees. Architecture change, restyling, and API modernization are separate later projects.

## Fixed decisions

Settled for this migration. Do not reopen them and do not quietly improve past them mid-slice.

| Decision | Value |
|---|---|
| Target | **Ext JS 7.7.0.31**, classic toolkit only |
| Path | Direct 4 to 7. No intermediate 5.x or 6.x release ships. |
| Architecture | Existing MVC preserved: `Ext.app.Application` plus global `Ext.app.Controller` with `refs`, `control`, `listen`, `stores`, `models`, `views` and their generated getters. No ViewController, no ViewModel, no `bind`. |
| Theme | `theme-classic`, the closest available baseline to the Ext 4 blue look. It ships in the 7.x classic toolkit theme set (`<SDK>/classic/theme-classic`), alongside `theme-gray`, `theme-neptune`, `theme-crisp` and `theme-triton`. It is a starting point, not parity: markup, layout, fonts, icons, sizing, and every custom `.x-` selector still require full visual regression testing against the phase 0 screenshots. |
| Build | Sencha Cmd, pinned to `@sencha/cmd@7.7.0` (build 7.7.0.36) from npm; the existing jar-based Cmd 4.0.5 installation stays until the Ext 4 build is retired, because `sencha switch` does not work under an npm install. Whether the existing scaffold is upgraded in place or a clean Ext 7 scaffold is generated and the application transplanted into it is decided by the rehearsal in step 9 — not assumed. Either way the shipped result is a direct 4-to-7 migration. |
| Source structure | Preserved by default: class names, namespaces, aliases, xtypes, folder layout, inheritance, controller ownership, `refs`, selectors, events, and public behavior. See the source-structure policy below. Restructuring requires separate user authorization. |
| Deprecation debt | Deprecated-but-present APIs verified against 7.7.0 may remain. Warnings are inventoried and accepted as migration debt; they do not fail completion. |
| Hosting | Cmd build output served by the Java web application, page shell rendered server-side. |

`Ext.app.Controller` and its Ext 4 configs, generated getters, `refs`, `control`, `listen`, `getStore`, `getModel`, and `getView` are still public and carry no deprecation flag in Ext JS 7 classic. Preserving MVC is a supported configuration, not a workaround.

## Source-structure policy

The framework changes. The application's shape does not.

**Preserved by default:** class names, namespaces, aliases, xtypes, folder layout, inheritance,
controller ownership, `refs`, component selectors, event names, and public behavior. Modify the
existing class locally whenever possible — the smallest edit inside the class that already owns the
behavior.

**Not introduced by default:** replacement components, wrapper classes, compatibility abstractions,
new base classes, shims, or duplicated implementations. Each of those adds a class the application
did not have, and a migration that adds classes is no longer a migration anyone can review against
the Ext 4 original.

The single exception is a **confirmed** Ext 7.7.0 incompatibility that cannot be repaired safely
inside the existing class. Confirmed means verified against the target release, not inferred from an
audit count or a mapping table. When that happens, fill in the exception record
(`assets/inventory-templates.md` section 7) **before** writing the class: the incompatible API, the
target-release evidence with its date, what was tried inside the existing class and how it failed,
the smallest mechanism that works, the evidence that the server contract is unchanged, and the
condition under which the new code is deleted. Absent that record, the smaller edit was not
attempted.

**The clean-scaffold option replaces generated infrastructure only** — `.sencha/`, the generated
`app.json` and bootstrap, theme package scaffolding, and build configuration. Application classes
are transplanted as they are. Do not reorganize, rename, or rewrite them on the way in: a transplant
that also restructures is two changes at once, and only one of them is this migration. Application
restructuring requires separate user authorization and is its own project.

## Comment rule

Write concise comments that explain upgrade-specific intent a maintainer cannot infer from the
code: why an override still exists, which framework behavior changed underneath a workaround,
payload or id-format quirks the server depends on, and non-obvious layout, focus, or event-timing
decisions. Do not comment obvious syntax, restate method names, or leave large commented-out Ext 4
blocks.

A short JSDoc block stating what framework behavior is involved and which Ext version last
validated it is **required only** for:

- retained or reworked framework overrides,
- any dependency on a private or undocumented framework member,
- compatibility shims and temporary loader workarounds,
- custom components whose behavior had to change because of the framework upgrade,
- non-obvious server-contract preservation, such as a writer or parameter setting that exists only
  to keep the Ext 4 wire format.

A view that migrated cleanly gets no migration comment. On a codebase with hundreds of views, a
blanket documentation requirement produces noise that hides the entries that matter.

## Workflow

1. Classify the request as analysis, planning, implementation, diagnosis, or review. Stay read-only unless implementation is requested.
2. Establish actual versions before touching anything: Ext 4 patch level, Sencha Cmd version, `app.json`, `.sencha/`, workspace layout, theme package, Compass and Ruby dependency, and Java and Node versions. The target framework release is fixed at 7.7.0.31 and Cmd at `@sencha/cmd@7.7.0`; what still has to be established per environment is which platform distribution the npm install resolves to and therefore whether the JDK 8–11 range binds — see `tooling-and-build.md` sections 1 and 2, and note that Sencha's published compatibility matrix has no row for 7.7. Report ambiguity instead of guessing.
3. Fetch the guides for the specific target release rather than relying on recall. The 4-to-5 and 5-to-6 upgrade guides carry the bulk of the breaking changes; the per-release Classic API Diff guides under `guides/whats_new/api_diffs/` carry the rest. Use Context7 or the official docs; do not apply a framework API from memory.
4. Inventory the surface: **every** page shell that boots the application, `Ext.application` boot, controllers, stores, models, proxies, views, custom components, plugins, `Ext.override` calls, `Ext.ux` usage, charts, locale loading, and the theme. Locale loading includes translations hand-appended to files *inside* the vendored SDK: the audit script excludes those directories from its source scan, so application code living in them is invisible until its embedded-code pass reports it. Record every screen a user can reach; that list seeds the verification matrix.
5. Run the audit script (`assets/extjs4-audit.ps1`) before reading code by hand: it gives file-and-line counts per change category and needs no credentials. Run the Sencha ESLint plugin **when it is available** — its registry requires signup and access approval — for removed, deprecated, private, and overridden framework members. When it is not available, record it as unavailable with the reason and cover its ground explicitly: the audit's `Private` and `Removed` categories, the override register, `Ext.ux` and chart usage, and the target release's API diff guides. Do not hold up code inspection waiting for registry approval, and do not present the audit alone as equivalent coverage. Neither tool is complete — see the coverage limits in `tooling-and-build.md`.
6. Classify every audit hit by mapping status before planning any edit: **removed**, **deprecated but present**, **compatibility alias**, **changed default**, **changed event signature**, **private access**, or **receiver-dependent**. A raw occurrence count is not a work estimate, and a mapping table is not a search-and-replace instruction.
7. Capture the Ext 4 baseline while it still runs: per-screen screenshots, the full HTTP contract for the busiest stores (see the Verification section), and a console-error baseline. Capture the boot path in the same pass, per `references/boot-path-evidence.md` — which shell each entry point actually serves, what the browser actually fetches, which build profile is really deployed, and which locale files are actually requested. Nothing later can be judged without it.
8. Document the page-shell contract before changing it. Establish *which* shell and *which* profile from the browser capture rather than by reading the files: the choice normally lives in the hosting application's controller, outside the web content tree, and a project of any age keeps several plausible-looking shells that nothing serves. Which shell each user role and entry point actually gets, doctype, context-path handling, which build profile the shell points at, cache busting, locale injection, server-injected DOM and globals, and auxiliary non-Ext scripts. Do not replace a hand-maintained shell with a Cmd-managed one until its current behavior is written down.
9. Inventory the build contract before running anything. `sencha app build` is frequently not the whole build: wrapper scripts, raw `sencha compile` invocations, hand-concatenated bundles, copied or appended stylesheets, and pinned Cmd paths are all load-bearing and all invisible to the framework upgrade. Record each step, what it produces, and why it exists. The audit script reports candidate wrappers; read them.
10. **Rehearse the upgrade on a throwaway branch before committing to a strategy.** Run `sencha app upgrade` against a clean tree, read the entire generated diff, and record what it rewrote and what it destroyed. Then choose, with the diff as evidence:
    - **upgrade in place** — the generated scaffold is reviewable and the build contract survives; or
    - **generate a clean Ext 7 classic scaffold and transplant** the application source and the build contract into it — the right answer when `app.json` is minimal, `.sencha/` has been hand-edited, or the real build lives outside Cmd. The scaffold replaces generated framework and build infrastructure only; application classes move across unchanged. See the source-structure policy.
    Record the decision and the reason. Discard the rehearsal branch either way.
11. Upgrade the toolchain and framework by the chosen strategy: Cmd, then the framework, then the `app.json` toolkit, theme, and package declarations. Then run a build and **save the complete failure inventory**. Do not expect a clean build here; on a large Ext 4 codebase the first Ext 7 build fails in bulk, and that failure list is a deliverable, not an obstacle.
12. Repair only what blocks boot: class resolution, loader and `requires` failures, the application object, the main view, and theme loading. Everything else stays on the list. The gate is a rendered main view with no uncaught exception, not a warning-free build.
13. Fix screens one at a time in dependency order. Shared models and stores first, then the views that use them. Each screen is a slice: fix, verify, commit.
14. Preserve the server contract in every slice. Reader `rootProperty` renames, writer `writeAllFields`, phantom id format, and extra-params handling all change what the backend receives; keep the wire format identical unless the backend is changed deliberately in the same slice with tests.
15. Add the required comments and JSDoc for the categories the comment rule names, while the reasoning is fresh.
16. Close out: remove the temporary compatibility layer, remove dead overrides and shims, retire the vendored Ext 4 SDK and its build artifacts once the application code embedded in it has been extracted, and close out the deprecation-debt inventory: every remaining framework deprecation warning verified as deprecated-but-present on 7.7.0 and recorded as accepted debt with its call sites. Deprecation warnings do not block completion; unexplained warnings do.

## Phases

One *shipped* target, ordered so that the work is diagnosable and the branch is never a mystery.

| Phase | Goal | Done when |
|---|---|---|
| 0. Baseline | Reproducible Ext 4 build, screen matrix, screenshots, HTTP contract captures, boot-path capture, audit and lint reports | Old build reproduces from a clean checkout and every screen is in the matrix |
| 0b. Page shell | Every shell that boots the app documented: doctype, build profile, injected values, auxiliary scripts, locale | The deployed shell, the served profile, the doctype as served, and the locale load mechanism are established from a browser capture and written down — or the phase is `INCOMPLETE` |
| 1. Toolchain | Cmd upgraded, `sencha app upgrade` applied, `app.json` toolkit, theme, packages correct | A build has been attempted and its **complete failure inventory** is recorded |
| 2. Boot | Class resolution, loader, `Ext.application`, main view, theme, locale | Main view paints with zero uncaught exceptions; remaining failures are triaged, not fixed |
| 3. Screens | Per-screen fixes in dependency order | Each screen passes its verification gate |
| 4. Cleanup | Compatibility layer removed, overrides pruned, vendored SDK retired, deprecation debt inventoried and accepted | Production build clean, zero uncaught exceptions, and every remaining deprecation warning accounted for in the debt inventory with its verified 7.7.0 status |

### Non-shipping checkpoints

"Direct 4 to 7" means one released target, not one mechanical transformation. On a large codebase,
cumulative breakage is hard to attribute — a failure could belong to any of three major versions.
Two ways to recover attribution, in increasing cost:

1. **Bucket the findings by version.** Run the ESLint plugin, or the audit script, once per
   intermediate target and diff the reports. Change sets can then be planned as "the 4-to-5 work",
   "the 5-to-6 work", and so on, without installing an intermediate framework. Do this by default.
2. **A throwaway intermediate build.** Stand up the app against Ext 5 or 6 on a scratch branch
   purely to see which failures disappear. Only worth it when a specific class of breakage resists
   attribution. Nothing from that branch ships or merges.

Neither changes the released target, and neither is an excuse to ship an intermediate version.

## Task modes

| Request | Action |
|---|---|
| Analyze or review | Report version facts, override and private-API exposure, `Ext.ux` and chart usage, theme customization depth, and per-screen risk. List missing baseline evidence explicitly; do not edit. |
| Plan | Produce the phase plan, the ordered screen list with dependencies, the verification gate for each, rollback, and the completion gate. |
| Diagnose | Reproduce the failure, identify which Ext 4-to-7 change causes it, and cite the guide or diff entry. Do not fix unless asked. |
| Implement | Change the smallest complete slice — one screen and the models, stores, and overrides it needs — and verify it before moving on. Edit existing classes in place; do not add classes or restructure. |

## Verification

### The screen matrix

A flat list of screens is not enough where menus are role-driven, the UI is localized, and mobile
behavior differs. The unit of verification is:

```
role × entry point (menu item) × locale × desktop/mobile × read-only vs write workflow
```

Enumerate it in phase 0 and cover it by sampling deliberately, not accidentally: every role at least
once, every locale at least once against a screen with formatted dates and numbers, mobile at least
once against any screen with bespoke touch handling. Record which cells were covered and which were
reasoned about but not exercised.

### The four gates

Every slice needs all four, and each is evidence rather than opinion.

- **Build gate.** The project's own canonical build — the wrapper script or task that actually produces what gets deployed — running the profile the deployed shell really serves, as established in phase 0b. From phase 2 onward, zero build errors. Record the deprecation warning count. The production profile must build before phase 4 closes. A stock `sencha app build --clean <profile>` is a useful additional diagnostic and is **not** a substitute: where a wrapper post-processes Cmd's output, `--clean` deletes the hand-placed artifacts in the output tree along with the generated ones, so read the wrapper before running it.
- **Runtime console gate.** The threshold is *accounted for*, not *zero*. Deprecation output is expected on a 4-to-7 hop, and a compatibility layer deliberately adds to it.
  - *During migration:* zero uncaught exceptions, and zero **unaccounted** warnings — every warning is either already on the triage list or newly filed onto it. The count of unclassified warnings must be zero at every phase boundary; the count of classified, accepted ones may stay flat.
  - *At completion:* zero uncaught exceptions, the compatibility layer disabled, and every remaining framework deprecation warning present in the accepted-debt inventory with its verified 7.7.0 status and call sites. **A non-zero deprecation count does not fail completion. An unaccounted warning does.**
  - Replace a deprecated-but-present API only when it malfunctions on the target release, depends on removed or private internals, affects security or a server contract, or the user asks for modernization. "It logs a warning" is not one of those reasons.
- **Browser E2E.** Drive the screen with Playwright against the running Java application: the workflow users actually perform, plus the console assertion above. Compare the HTTP contract against the phase 0 capture for any screen that writes.
- **Manual screen checklist.** For every screen: layout, sort and filter, paging or scrolling, editing, validation messages, dialogs, keyboard behavior, and print or export paths. Unchecked items stay visible as unchecked.

### What the HTTP contract capture must include

Write payload JSON alone is not the contract. For every request a screen makes, capture: method,
URL, query parameters (including ones assembled by client code rather than declared), headers,
content type, request body, parameter ordering where the server is sensitive to it, the response
envelope, the failure-response shape, and the record-id format on create. Tree loads, form
submissions, standalone `Ext.Ajax` calls, custom filter and sort encodings, uploads, downloads, and
print or export endpoints all count and are all easy to forget.

Report the work `INCOMPLETE` rather than passing it when the baseline is missing, a matrix cell
cannot be reached, or the evidence was not actually collected. A workflow that cannot be automated —
one gated on a hardware token, a browser plugin, or an external service — is verified manually and
recorded as manually verified, never silently skipped.

## Resources

- Run `assets/extjs4-audit.ps1` in phase 0 and at every phase boundary. It reports matching lines and match counts per change category, detects page shells and how each one boots, finds stylesheets coupled to framework markup and build scripts that wrap Cmd, and writes a machine-readable baseline to diff against.
- Fill in `assets/inventory-templates.md` in phase 0: the screen universe and the verification-run log (kept as two tables so that coverage stays readable), the endpoint contract inventory, the override register, the audit triage, the build-customization inventory, and the boot-path and localization inventory. These are the migration's working memory. The seventh template, the exception record, is filled in only when a new class is proposed — before it is written, not after.
- Follow `references/boot-path-evidence.md` in phase 0b to settle the boot path in a browser: which shell is served, what it loads, which profile is deployed, and which locale files are live. The audit script reports all of these as candidates; this is how they stop being guesses.
- Read `references/upgrade-map.md` before planning or implementing any slice. It is the cumulative 4-to-7 API change map, with every entry labelled by mapping status.
- Read `references/grid-and-data.md` before touching a grid, store, model, proxy, reader, or writer.
- Read `references/theming-and-sass.md` before touching the theme package, SASS variables, or the style pipeline.
- Read `references/overrides-and-custom-components.md` before keeping, rewriting, or deleting any `Ext.override`, custom component, plugin, or `Ext.ux` usage.
- Read `references/tooling-and-build.md` before upgrading Cmd, editing `app.json`, changing the loader, or altering how the Java application serves the app.

## Non-negotiable safeguards

- Do not treat an audit count as a defect count. A single search term routinely spans several
  mapping statuses — `root:` alone covers a removed reader config, a working writer alias, and an
  unchanged tree config. Split by status and read the hits before estimating or editing.
- Do not assume `sencha app build` is the whole build. Inventory the wrapper scripts, raw compile
  passes, and hand-assembled stylesheets first, and reproduce or retire each one deliberately.
- Do not choose the upgrade strategy before the rehearsal. Read the generated diff, then decide
  between upgrading in place and transplanting into a clean scaffold.
- Do not describe `theme-classic` as visual parity. It is the closest baseline; every screen still
  needs a visual comparison against its phase 0 screenshot.
- Do not convert MVC to MVVM. No `ViewController`, no `ViewModel`, and no `bind` introduced as an architectural change. Use a scope-resolution config only where the framework requires one to resolve a string reference, and say so in a comment.
- Do not restyle. `theme-classic` is the target; visual differences are defects to fix, not improvements to keep.
- Do not change what the server sees. Payload shape, parameter names, phantom id format, and response handling stay identical unless the backend changes in the same slice with tests.
- Do not bundle business change, refactoring, or unrelated dependency upgrades into a migration slice.
- Do not delete an override, plugin, or workaround you cannot explain. Establish what framework behavior it modified and whether Ext 7 still behaves that way, then decide.
- Do not paper over the asynchronous loader with `Ext.syncRequire` or hand-ordered script tags. Declare `requires` correctly. A synchronous shim is permitted only as a commented, tracked temporary measure with a named removal gate.
- Do not silence detection. Globally disabling ARIA validation flags, suppressing deprecation output, or disabling `bufferedRenderer` across the app to avoid fixing row heights all hide work rather than doing it. Accepting an inventoried deprecation is the opposite of silencing it: the warning keeps printing and the debt is written down.
- Do not add a class the application did not have. No replacement components, wrapper classes, compatibility abstractions, new base classes, shims, or duplicated implementations unless a confirmed 7.7.0 incompatibility cannot be repaired inside the existing class — and then only with the incompatible API and the reason the smaller edit failed both recorded.
- Do not rename, move, or reorganize application classes during a transplant. The clean scaffold replaces generated infrastructure; the application moves across as it is. Restructuring is separately authorized work.
- Do not replace a deprecated-but-present API to tidy up. Verify its status on 7.7.0 and leave it, recorded as debt, unless it malfunctions, reaches into removed or private internals, affects security or a server contract, or the user asked for modernization.
- Do not weaken or skip tests, accept new screenshot baselines, or relax assertions to make a slice pass.
- Do not leave the compatibility layer enabled at completion. It is triage scaffolding with an explicit removal gate, and its coverage must be proven on the target release before anything is planned around it. This is not in tension with accepting deprecation debt: the compatibility layer restores *removed* API behavior, while accepted debt is API that the target release still ships and still supports.
- Do not convert an occurrence count into a bulk edit. Every mapping carries a status, several are receiver-dependent, and some deprecated APIs are still present and working. Verify the receiver and the target-release status before changing a call site.
- Do not settle the boot path from source when a browser can be pointed at the running application. Which shell is served, what it loads, which profile is deployed, and which locale files are requested are runtime facts; the audit script labels its versions of them candidates for that reason. When no browser can reach the application, record the phase `INCOMPLETE` rather than promoting a source-derived guess to a finding.
- Do not delete the vendored SDK, or anything under it, until the application code embedded in it is inventoried and its active part extracted. Hand-appended application overrides inside a vendored locale file are the common case, they are excluded from the source scan, and they are load-bearing.
- Do not restructure the page shell or the deployment arrangement before its current behavior is documented. A hand-maintained shell that Sencha Cmd does not know about is a production dependency, not an oversight to tidy.
- Preserve unrelated changes in dirty worktrees.

## Handoff

State the target Ext and Cmd versions in use, the phase reached, the screens migrated and verified, the verification evidence collected per screen, the overrides retained and why, the compatibility-layer status, remaining deprecation warnings, known visual differences, and the rollback method.
