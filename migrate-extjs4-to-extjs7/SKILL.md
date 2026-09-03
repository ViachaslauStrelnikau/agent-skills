---
name: migrate-extjs4-to-extjs7
description: Use when Codex needs to analyze, plan, implement, diagnose, or review a direct upgrade of a Sencha Cmd Ext JS 4.x application to the Ext JS 7.x classic toolkit while preserving the existing Ext.app.Controller MVC structure, the Ext 4 visual appearance, and every server contract. Not for MVC-to-MVVM or ViewController refactors, not for modern-toolkit or mobile ports, not for Ext JS 3 to 4 work, and not for restyling.
---

# Migrate Ext JS 4 to Ext JS 7 (classic toolkit)

## Core principle

One framework hop, no redesign. The application moves from Ext JS 4.x to Ext JS 7.x classic on a
single cutover branch, keeping global `Ext.app.Controller` MVC, the classic theme, and every request
and response the Java backend already sees. Architecture change, restyling, and API modernization
are separate later projects.

## Fixed decisions

Settled for this migration. Do not reopen them and do not quietly improve past them mid-slice.

| Decision | Value |
|---|---|
| Target | **Ext JS 7.7.0.31**, classic toolkit only |
| Path | Direct 4 to 7. No intermediate 5.x or 6.x release ships. |
| Architecture | Existing MVC preserved: `Ext.app.Application` plus global `Ext.app.Controller` with `refs`, `control`, `listen`, `stores`, `models`, `views` and their generated getters. No ViewController, no ViewModel, no `bind`. |
| Theme | `theme-classic`, from the 7.x classic theme set (`<SDK>/classic/theme-classic`, alongside `theme-gray`, `theme-neptune`, `theme-crisp`, `theme-triton`). It is the closest available baseline to the Ext 4 blue look and **not visual parity**: markup, layout, fonts, icons, sizing, and every custom `.x-` selector change underneath it. Visual differences are defects to fix, not improvements to keep — but see the visual threshold below for which of them this migration gates on now. |
| Visual threshold | **Structural, not pixel parity, for this pass.** A screen gates on: every component present, the data present and matching the HTTP response, and no significant artifact from the closed list in the quality-gate skill. Pixel parity, font metrics, spacing, exact colors, and the hover/focus/disabled/invalid/selected/print states are deferred and recorded as visual debt, not passed. Phase 0 screenshots are still captured for every screen — they are the reference for the structural questions, and the diff target if the bar is raised later. |
| Build | Sencha Cmd, pinned to `@sencha/cmd@7.7.0` (build 7.7.0.36) from npm; the existing jar-based Cmd 4.0.5 installation stays until the Ext 4 build is retired, because `sencha switch` does not work under an npm install. Upgrade-in-place versus clean-scaffold-and-transplant is decided by the phase 1 rehearsal, not assumed. Either way the shipped result is a direct 4-to-7 migration. |
| Source structure | Preserved by default. See the policy below. |
| Deprecation debt | Deprecated-but-present APIs verified against 7.7.0 may remain. Warnings are inventoried and accepted as migration debt; they do not fail completion. |
| Hosting | Cmd build output served by the Java web application, page shell rendered server-side. |

`Ext.app.Controller` and its Ext 4 configs, generated getters, `refs`, `control`, `listen`,
`getStore`, `getModel`, and `getView` are still public and carry no deprecation flag in Ext JS 7
classic. Preserving MVC is a supported configuration, not a workaround.

## Source-structure policy

The framework changes. The application's shape does not.

**Preserved by default:** class names, namespaces, aliases, xtypes, folder layout, inheritance,
controller ownership, `refs`, component selectors, event names, and public behavior. Modify the
existing class locally whenever possible — the smallest edit inside the class that already owns the
behavior.

**Not introduced by default:** replacement components, wrapper classes, compatibility abstractions,
new base classes, shims, or duplicated implementations. Each adds a class the application did not
have, and a migration that adds classes is no longer one anyone can review against the Ext 4
original.

The single exception is a **confirmed** Ext 7.7.0 incompatibility that cannot be repaired safely
inside the existing class — confirmed meaning verified against the target release, not inferred from
an audit count or a mapping table. Fill in the exception record (`assets/inventory-templates.md`
section 7) **before** writing the class. Absent that record, the smaller edit was not attempted.

**The clean-scaffold option replaces generated infrastructure only** — `.sencha/`, the generated
`app.json` and bootstrap, theme package scaffolding, build configuration. Application classes are
transplanted as they are: do not reorganize, rename, or rewrite them on the way in. A transplant
that also restructures is two changes at once, and only one of them is this migration. Application
restructuring requires separate user authorization and is its own project.

## Comment rule

Write concise comments that explain upgrade-specific intent a maintainer cannot infer from the code:
why an override still exists, which framework behavior changed underneath a workaround, payload or
id-format quirks the server depends on, and non-obvious layout, focus, or event-timing decisions. Do
not comment obvious syntax, restate method names, or leave large commented-out Ext 4 blocks.

A short JSDoc block stating what framework behavior is involved and which Ext version last validated
it is **required only** for: retained or reworked framework overrides; any dependency on a private or
undocumented framework member; compatibility shims and temporary loader workarounds; custom
components whose behavior had to change because of the upgrade; and non-obvious server-contract
preservation, such as a writer or parameter setting that exists only to keep the Ext 4 wire format.

A view that migrated cleanly gets no migration comment. On a codebase with hundreds of views, a
blanket documentation requirement produces noise that hides the entries that matter.

## Workflow

Ordered, and mapped onto the phases below. Each step names the reference that carries its detail;
read that rather than working from recall.

1. Classify the request as analysis, planning, implementation, diagnosis, or review. Stay read-only
   unless implementation is requested.
2. Establish actual versions first and report ambiguity instead of guessing — including which
   platform distribution the npm Cmd install resolved to, which decides whether the JDK 8-11 range
   binds. `tooling-and-build.md` sections 1-2.
3. Fetch the target release's own guides — the 4-to-5 and 5-to-6 upgrade guides plus the Classic API
   Diffs under `guides/whats_new/api_diffs/` — through Context7 or the official docs. Never apply a
   framework API from memory. `upgrade-map.md`.
4. Run `assets/extjs4-audit.ps1` before reading code by hand, and classify **every** hit by mapping
   status before planning any edit. `upgrade-map.md` section 0.
5. Run the Sencha ESLint plugin when its registry is available. When it is not, record it as
   unavailable with the reason and cover its ground explicitly; do not wait on registry approval and
   do not present either tool as complete coverage. `tooling-and-build.md` section 6.
6. Inventory the surface: every page shell, `Ext.application` boot, controller, store, model, proxy,
   view, custom component, plugin, `Ext.override`, `Ext.ux` class, chart, the locale mechanism, and
   the theme — plus application code and classpath dependencies living *inside* the vendored SDK,
   which the source scan excludes by design. Record every screen a user can reach; that list seeds
   the verification matrix.
7. Rank base classes by subclass count from the local `extend:` graph and migrate them before their
   subclasses. On a large Ext 4 codebase the dependency spine is as much view inheritance as shared
   stores, and the linter cannot see it.
   `overrides-and-custom-components.md` section 2a.
8. Settle the boot path from evidence and capture the Ext 4 baseline while it still runs — per-screen
   screenshots, the HTTP contract for the busiest stores, a console-error baseline. Nothing later can
   be judged without it. `boot-path-evidence.md`.
9. Document the page-shell contract and the build contract before changing either. Several
   plausible-looking shells that nothing serves, and a build that is not `sencha app build`, are
   both the normal case. `tooling-and-build.md` sections 3 and 8.
10. **Rehearse `sencha app upgrade` on a throwaway branch before committing to a strategy.** Read the
    entire generated diff, then choose upgrade-in-place or clean-scaffold-and-transplant with that
    diff as the evidence, and record the reason. Discard the branch either way.
    `tooling-and-build.md` section 4.
11. Upgrade Cmd, then the framework, then the `app.json` toolkit, theme, and package declarations.
    Build, and **save the complete failure inventory** — on a large codebase the first Ext 7 build
    fails in bulk, and that list is a deliverable, not an obstacle.
12. Repair only what blocks boot; everything else stays on the list.
13. Fix screens one at a time in dependency order — shared models, stores, and ranked base classes
    first. Each screen is a slice: fix, verify, commit. Preserve the server contract in every one.
    `grid-and-data.md`.
14. Add the comments and JSDoc the comment rule requires, while the reasoning is fresh.
15. Close out: remove the compatibility layer, prune dead overrides and shims, retire the vendored
    SDK once the code embedded in it is extracted, and close the deprecation-debt inventory.

## Phases

One *shipped* target, ordered so that the work is diagnosable and the branch is never a mystery.

| Phase | Goal | Done when |
|---|---|---|
| 0. Baseline | Reproducible Ext 4 build, screen matrix, screenshots, HTTP contract captures, audit and lint reports, inheritance ranking | Old build reproduces from a clean checkout, every screen is in the matrix, and every audit category has a triage verdict |
| 0b. Page shell | Every shell that boots the app documented: doctype, build profile, injected values, auxiliary scripts, locale | The deployed shell, the served profile, the doctype as served, and the locale load mechanism are established from evidence and written down — or the phase is `INCOMPLETE` |
| 1. Toolchain | Rehearsal read, strategy chosen, Cmd upgraded, `app.json` toolkit, theme, packages correct | A build has been attempted and its **complete failure inventory** is recorded |
| 2. Boot | Class resolution, loader, `Ext.application`, main view, theme, locale | Main view paints with zero uncaught exceptions; remaining failures are triaged, not fixed |
| 3. Screens | Per-screen fixes in dependency order | Each screen passes its verification gate |
| 4. Cleanup | Compatibility layer removed, overrides pruned, vendored SDK retired, deprecation debt accepted | Production build clean, zero uncaught exceptions, every remaining deprecation warning accounted for in the debt inventory with its verified 7.7.0 status, and the deferred visual debt inventoried per screen |

Raising the visual bar is its own decision, taken once the structural check passes across the
screen matrix: at that point the phase 0 screenshots become a diff target, the deferred states get
captured, and the pixel threshold and viewport are pinned. It is a separate piece of work with its
own authorization — not something a slice drifts into, and not something phase 4 closes by default.

### Non-shipping checkpoints

"Direct 4 to 7" means one released target, not one mechanical transformation. On a large codebase
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
| Analyze or review | Report version facts, override and private-API exposure, `Ext.ux` and chart usage, theme customization depth, base-class fan-out, and per-screen risk. List missing baseline evidence explicitly; do not edit. |
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
reasoned about but not exercised. Tables: `assets/inventory-templates.md` sections 1a and 1b.

### The gates

Every slice needs all five, and each is evidence rather than opinion.

- **Build gate.** The project's own canonical build — the wrapper or task that actually produces what
  gets deployed — on the profile the deployed shell really serves. From phase 2 onward, zero build
  errors; record the deprecation warning count. The production profile must build before phase 4
  closes. `sencha app build --clean <profile>` is an additional diagnostic and not a substitute;
  read `tooling-and-build.md` section 9 before running it.
- **Runtime console gate.** The threshold is *accounted for*, not *zero*: deprecation output is
  expected on a 4-to-7 hop, and a compatibility layer deliberately adds to it.
  - *During migration:* zero uncaught exceptions, and zero **unaccounted** warnings — every warning
    either already on the triage list or newly filed onto it. Unclassified warnings must be zero at
    every phase boundary; classified, accepted ones may stay flat.
  - *At completion:* zero uncaught exceptions, the compatibility layer disabled, and every remaining
    deprecation warning in the accepted-debt inventory with its verified 7.7.0 status and call sites.
    **A non-zero deprecation count does not fail completion. An unaccounted warning does.**
- **Browser E2E.** Drive the screen with Playwright against the running Java application: the
  workflow users actually perform, plus the console assertion above. For any screen that writes,
  compare every request against the phase 0 capture — every field in
  `assets/inventory-templates.md` section 2, for store proxies, tree loads, form submissions,
  standalone `Ext.Ajax` calls, uploads, downloads, and print or export endpoints alike. Payload JSON
  alone is not the contract.
- **Server-side test gate**, where the hosting application has its own suite. A framework upgrade is
  not supposed to change what the backend receives, so the backend's own tests are the cheapest
  evidence that it did not — above all for the writer changes, which carry the highest data-loss
  risk in the migration and produce no client-side error. Run it after any slice touching a reader,
  writer, proxy, or id format, and record the result. Where no suite exists, say so rather than
  letting the client-side gates imply that ground is covered.
- **Visual check.** Structural, at the threshold in Fixed decisions: every component present, the
  data present and matching the HTTP response, no significant artifact. The
  `extjs4-to-extjs7-migration-quality-gate` skill carries the closed artifact list and what is
  deferred. Capture the post-migration screenshot either way — a deferred comparison still needs
  its evidence to exist.
- **Manual screen checklist.** Layout, sort and filter, paging or scrolling, editing, validation
  messages, dialogs, keyboard behavior, print and export. Unchecked items stay visible as unchecked.

Report the work `INCOMPLETE` rather than passing it when the baseline is missing, a matrix cell
cannot be reached, or the evidence was not actually collected. A workflow that cannot be automated —
gated on a hardware token, a browser plugin, or an external service — is verified manually and
recorded as manually verified, never silently skipped.

## Resources

- Run `assets/extjs4-audit.ps1` in phase 0 and at every phase boundary. It reports matching and
  active line counts per change category, detects page shells and how each one boots, finds
  application code and classpath dependencies inside the vendored SDK, stylesheets coupled to
  framework markup, and build scripts that wrap Cmd, and writes a machine-readable baseline to diff
  against.
- Fill in `assets/inventory-templates.md` in phase 0: the screen universe and verification-run log,
  the endpoint contract inventory, the override register, the audit triage, the build-customization
  inventory, and the boot-path and localization inventory. These are the migration's working memory.
  The seventh template, the exception record, is filled in only when a new class is proposed —
  before it is written, not after.
- Follow `references/boot-path-evidence.md` in phase 0b to settle the boot path. The audit script
  reports all of it as candidates; this is how they stop being guesses.
- Read `references/upgrade-map.md` before planning or implementing any slice. It is the cumulative
  4-to-7 API change map, with every entry labelled by mapping status.
- Read `references/grid-and-data.md` before touching a grid, store, model, proxy, reader, or writer.
- Read `references/theming-and-sass.md` before touching the theme package, SASS variables, or the
  style pipeline.
- Read `references/overrides-and-custom-components.md` before keeping, rewriting, or deleting any
  `Ext.override`, custom component, plugin, or `Ext.ux` usage.
- Read `references/tooling-and-build.md` before upgrading Cmd, editing `app.json`, changing the
  loader, or altering how the Java application serves the app.

## Non-negotiable safeguards

- Do not treat an audit count as a defect count, and do not convert an occurrence count into a bulk
  edit. A single search term routinely spans several mapping statuses — `root:` alone covers a
  removed reader config, a working writer alias, and an unchanged tree config; `margins:` also
  matches `defaultMargins:`, which is a different fix. Counts include commented-out code. Split by
  status, verify the receiver, and read the hits before estimating or editing.
- Do not assume `sencha app build` is the whole build. Inventory the wrapper scripts, raw compile
  passes, and hand-assembled stylesheets, establish which are still live, and reproduce or retire
  each one deliberately.
- Do not convert MVC to MVVM. No `ViewController`, no `ViewModel`, and no `bind` introduced as an
  architectural change. Use a scope-resolution config only where the framework requires one to
  resolve a string reference, and say so in a comment.
- Do not change what the server sees. Payload shape, parameter names, phantom id format, and
  response handling stay identical unless the backend changes in the same slice with tests.
- Do not bundle business change, refactoring, or unrelated dependency upgrades into a migration
  slice.
- Do not delete an override, plugin, or workaround you cannot explain. Establish what framework
  behavior it modified and whether Ext 7 still behaves that way, then decide.
- Do not paper over the asynchronous loader with `Ext.syncRequire` or hand-ordered script tags.
  Declare `requires` correctly. A synchronous shim is permitted only as a commented, tracked
  temporary measure with a named removal gate.
- Do not silence detection. Globally disabling ARIA validation flags, suppressing deprecation
  output, or disabling `bufferedRenderer` across the app to avoid fixing row heights all hide work
  rather than doing it. Accepting an inventoried deprecation is the opposite of silencing it: the
  warning keeps printing and the debt is written down.
- Do not replace a deprecated-but-present API to tidy up. Verify its status on 7.7.0 and leave it,
  recorded as debt, unless it malfunctions, reaches into removed or private internals, affects
  security or a server contract, or the user asked for modernization.
- Do not weaken or skip tests, accept new screenshot baselines, or relax assertions to make a slice
  pass. The visual threshold is the one exception, and only because it was set deliberately and in
  writing for the whole migration: lowering a bar on the record, with what it defers written down,
  is the opposite of a slice quietly relaxing it to get through.
- Do not report deferred visual parity as compared and equivalent. "Components present, data
  correct, no artifact" is what the structural check establishes; it says nothing about spacing,
  fonts, or color, and the report has to say so.
- Do not leave the compatibility layer enabled at completion. It is triage scaffolding with an
  explicit removal gate, and its coverage must be proven on the target release before anything is
  planned around it. This is not in tension with accepting deprecation debt: the compatibility layer
  restores *removed* API behavior, while accepted debt is API the target release still ships and
  still supports.
- Do not promote a guess about the boot path to a finding. Which shell is served, which profile is
  deployed, and which locale files are requested are settled by a browser against the running
  application, or failing that by the hosting application's own routing code cited by file and line
  — never by picking the most plausible-looking file in the web content tree. When neither is
  available, record the phase `INCOMPLETE`. See `boot-path-evidence.md` section 2.
- Do not delete the vendored SDK, or anything under it, until the application code embedded in it is
  inventoried and its active part extracted, and every classpath entry pointing into it is
  accounted for. Hand-appended application overrides inside a vendored locale file, and stock
  third-party classes relocated into the SDK so the build resolves them, are both the common case,
  both excluded from the source scan, and both load-bearing.
- Do not restructure the page shell or the deployment arrangement before its current behavior is
  documented. A hand-maintained shell that Sencha Cmd does not know about is a production
  dependency, not an oversight to tidy.
- Preserve unrelated changes in dirty worktrees.

## Handoff

State the target Ext and Cmd versions in use, the phase reached, the screens migrated and verified,
the verification evidence collected per screen, the overrides retained and why, the
compatibility-layer status, remaining deprecation warnings, known visual differences, and the
rollback method.
