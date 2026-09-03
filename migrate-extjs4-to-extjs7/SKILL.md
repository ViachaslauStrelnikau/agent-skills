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

Settled. Do not reopen them and do not quietly improve past them mid-slice. Recorded per project in
the acceptance contract, `assets/inventory-templates.md` section 0 — which is also what the
verification gate reads, so that neither skill has to load the other.

| Decision | Value |
|---|---|
| Target | **Ext JS 7.7.0.31**, classic toolkit only |
| Path | Direct 4 to 7. No intermediate 5.x or 6.x release ships. |
| Architecture | Global `Ext.app.Controller` MVC preserved, with `refs`, `control`, `listen`, `stores`, `models`, `views` and their generated getters — all still public and undeprecated in 7 classic, so this is a supported configuration, not a workaround. No ViewController, ViewModel or `bind`. |
| Theme | `theme-classic` — the closest baseline to the Ext 4 blue look, and **not parity**. Markup, layout, fonts, icons, sizing and every custom `.x-` selector change underneath it. Differences are defects to fix, never improvements to keep. |
| Visual threshold | **Structural, not pixel parity, for this pass**: every component present, data present and matching the HTTP response, no significant artifact. Parity and the hover/focus/disabled/invalid/selected/print states are deferred as recorded visual debt, not passed. Contract section 0 carries the closed artifact list; phase 0 screenshots are captured regardless. |
| Build | Sencha Cmd pinned to `@sencha/cmd@7.7.0` (7.7.0.36) from npm. The jar-based Cmd 4.0.5 install stays until the Ext 4 build retires, because `sencha switch` does not work under npm. |
| Source structure | Preserved by default. See the policy below. |
| Deprecation debt | Deprecated-but-present APIs verified against 7.7.0 may remain, inventoried as accepted debt. They do not fail completion. |
| Hosting | Cmd build output served by the Java web application, page shell rendered server-side. |

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

The single exception is a **confirmed** 7.7.0 incompatibility that cannot be repaired safely inside
the existing class — confirmed meaning verified against the target release, not inferred from an
audit count or a mapping table. Fill in the exception record (`assets/inventory-templates.md`
section 7) **before** writing the class. Absent that record, the smaller edit was not attempted.

**The clean-scaffold option replaces generated infrastructure only** — `.sencha/`, the generated
`app.json` and bootstrap, theme scaffolding, build configuration. Application classes transplant as
they are: do not reorganize, rename, or rewrite them on the way in. Restructuring requires separate
user authorization and is its own project.

## Phases

One *shipped* target, ordered so the work is diagnosable and the branch is never a mystery. Each
phase names the reference carrying its detail; read that rather than working from recall.

| Phase | Work | Done when |
|---|---|---|
| **0. Baseline** | Establish actual versions; report ambiguity rather than guess (`tooling-and-build.md` §1–2). Fetch the target release's own guides through Context7 or the official docs, never from memory (`upgrade-map.md`). Run `assets/extjs4-audit.ps1` before reading code by hand, then classify **every** hit by mapping status (`upgrade-map.md` §0). Run the Sencha ESLint plugin where its registry allows, else record it unavailable and cover its ground (`tooling-and-build.md` §6). Inventory the surface, including code and classpath dependencies *inside* the vendored SDK. Rank base classes by subclass count (`overrides-and-custom-components.md` §2a). Capture the Ext 4 baseline while it still runs. | Old build reproduces from a clean checkout, every screen is in the matrix, every audit category has a triage verdict, and the acceptance contract is filled in |
| **0b. Page shell** | Settle the boot path from evidence — a browser, or the hosting application's routing code cited by file and line — never from the most plausible-looking file in the tree (`boot-path-evidence.md`). Document each shell's contract and the whole build contract before changing either (`tooling-and-build.md` §3, §8). Do not assume `sencha app build` is the whole build: wrappers, raw compile passes and hand-assembled stylesheets are frequently load-bearing, and a retired wrapper left in the tree looks identical to a live one — establish liveness, then reproduce or retire each step deliberately. | The deployed shell, served profile, doctype as served and locale mechanism are established and written down — or the phase is `INCOMPLETE` |
| **1. Toolchain** | Rehearse `sencha app upgrade` on a throwaway branch, read the entire diff, *then* choose upgrade-in-place or clean-scaffold-and-transplant on that evidence and record why (`tooling-and-build.md` §4). Upgrade Cmd, then the framework, then `app.json`. Build. | A build has been attempted and its **complete failure inventory** recorded. Expect bulk failure; that list is a deliverable |
| **2. Boot** | Repair only what blocks boot — class resolution, loader, `Ext.application`, main view, theme, locale. Everything else stays on the list. Fix load order with proper `requires`; a synchronous shim is permitted only as a commented, tracked measure with a named removal gate (`tooling-and-build.md` §7). | Main view paints with zero uncaught exceptions; remaining failures are triaged, not fixed |
| **3. Screens** | One slice at a time in dependency order: shared models and stores, then ranked base classes, then the views using them. Fix, verify, commit. Preserve the server contract in every slice (`grid-and-data.md`). Comment the upgrade-specific reasoning while it is fresh (`overrides-and-custom-components.md` §7). | Each screen passes every gate in Verification |
| **4. Cleanup** | Remove the compatibility layer; the build and console must be clean without it. Prune dead overrides and shims. Retire the vendored SDK and its artifacts once the code embedded in it is extracted. Close the deprecation-debt and visual-debt inventories. | Production build clean, zero uncaught exceptions, every remaining deprecation warning accounted for with its verified 7.7.0 status, visual debt inventoried per screen |

Raising the visual bar to pixel comparison is separately authorized work, taken once the structural
check passes across the matrix — not something a slice drifts into, and not something phase 4 closes
by default.

When a phase-1 or phase-2 failure cannot be attributed to a particular major release, bucket the
findings per version before planning the fix (`upgrade-map.md` §0a). Nothing intermediate ships.

## Task modes

| Request | Action |
|---|---|
| Analyze or review | Report version facts, override and private-API exposure, `Ext.ux` and chart usage, theme customization depth, base-class fan-out, and per-screen risk. List missing baseline evidence explicitly; do not edit. |
| Plan | Produce the phase plan, the ordered screen list with dependencies, the verification gate for each, rollback, and the completion gate. |
| Diagnose | Reproduce the failure, identify which 4-to-7 change causes it, and cite the guide or diff entry. Do not fix unless asked. |
| Implement | Change the smallest complete slice — one screen and the models, stores and overrides it needs — and verify before moving on. Edit existing classes in place; do not add classes or restructure. Do not bundle business change, refactoring, or unrelated dependency upgrades into a slice. |

## Verification

These are the **criteria** — what must be true for a slice to be done. The procedure for
establishing them independently, and the `PASS`/`FAIL`/`INCOMPLETE` verdicts, belong to the
verification gate, which works from the acceptance contract rather than from this file.

**The screen matrix.** A flat list of screens is not enough where menus are role-driven, the UI is
localized, and mobile behavior differs. The unit of verification is:

```
role × entry point (menu item) × locale × desktop/mobile × read-only vs write workflow
```

Enumerate it in phase 0 and sample it deliberately, not accidentally: every role at least once,
every locale at least once against a screen with formatted dates and numbers, mobile at least once
against any screen with bespoke touch handling. Record which cells were covered and which were
reasoned about but not exercised. Tables: `assets/inventory-templates.md` sections 1a and 1b.

**Five gates, each evidence rather than opinion.**

- **Build** — the project's own canonical build, on the profile the deployed shell really serves.
  Zero errors from phase 2 onward; the production profile before phase 4 closes.
- **Runtime console** — zero uncaught exceptions and zero *unaccounted* warnings. The threshold is
  *accounted for*, not zero, because deprecation output is expected on a 4-to-7 hop: unclassified
  warnings must be zero at every phase boundary, while classified, accepted ones may stay flat.
  **A non-zero deprecation count does not fail completion. An unaccounted warning does.**
- **Browser workflow and structural visual check** — the workflow users actually perform, at the
  visual threshold in Fixed decisions. Deferred parity is reported *not assessed*, never as compared
  and equivalent.
- **HTTP contract** — every request the screen makes, against the phase 0 capture, on every field
  `assets/inventory-templates.md` section 2 lists. Store proxies, tree loads, form submissions,
  standalone `Ext.Ajax`, uploads, downloads and print or export endpoints all count; payload JSON
  alone is not the contract.
- **Server-side tests**, where the hosting application has a suite. Nothing the backend receives
  should change, so its own tests are the cheapest evidence that nothing did — and the only automated
  evidence covering the writer changes, which carry the highest data-loss risk and raise nothing on
  the client. Run after any slice touching a reader, writer, proxy or id format; where no suite
  exists, say so rather than letting the client-side gates imply that ground is covered.

Report `INCOMPLETE` rather than passing when the baseline is missing, a matrix cell cannot be
reached, or evidence was not actually collected. A workflow that cannot be automated — gated on a
hardware token, a browser plugin, an external service — is verified manually and recorded as
manually verified, never silently skipped.

## Resources

| Read this | Before |
|---|---|
| `assets/extjs4-audit.ps1` | Reading code by hand. Run it in phase 0 and at every phase boundary; it writes a machine-readable baseline to diff against |
| `assets/inventory-templates.md` | Anything. Section 0 is the acceptance contract; 1–6 are phase 0 working memory; 7 is written only when an exception is proposed, before the class is written |
| `references/upgrade-map.md` | Planning or implementing any slice. The cumulative 4-to-7 change map, every entry labelled by mapping status |
| `references/grid-and-data.md` | Touching a grid, store, model, proxy, reader or writer |
| `references/boot-path-evidence.md` | Phase 0b. How the boot path stops being a guess |
| `references/tooling-and-build.md` | Upgrading Cmd, editing `app.json`, changing the loader, inventorying the build contract, or altering how the Java application serves the app |
| `references/overrides-and-custom-components.md` | Keeping, rewriting or deleting any `Ext.override`, custom component, plugin or `Ext.ux` usage. Also carries the comment and JSDoc rule (§7) |
| `references/theming-and-sass.md` | Touching the theme package, SASS variables or the style pipeline |

## Non-negotiable safeguards

- **Do not treat an audit count as a defect count, or convert an occurrence count into a bulk edit.**
  One search term routinely spans several mapping statuses — `root:` alone covers a removed reader
  config, a working writer alias and an unchanged tree config; `margins:` also matches
  `defaultMargins:`, which is a different fix. Counts include commented-out code. Split by status,
  verify the receiver, read the hits.
- **Do not convert MVC to MVVM.** No `ViewController`, no `ViewModel`, no `bind` as an architectural
  change. Use a scope-resolution config only where the framework requires one to resolve a string
  reference, and say so in a comment.
- **Do not change what the server sees.** Payload shape, parameter names, phantom id format and
  response handling stay identical unless the backend changes in the same slice with tests.
- **Do not delete what you cannot explain.** For an override, plugin or workaround: establish what
  framework behavior it modified and whether Ext 7 still behaves that way, then decide. For the
  vendored SDK or anything under it: extract the application code embedded in it and account for
  every classpath entry pointing into it first. Hand-appended translations inside a vendored locale
  file, and stock third-party classes relocated into the SDK so the build resolves them, are both
  the common case, both excluded from the source scan, and both load-bearing.
- **Do not silence detection.** Globally disabling ARIA validation, suppressing deprecation output,
  or turning off `bufferedRenderer` app-wide to avoid fixing row heights all hide work rather than
  doing it. Accepting an inventoried deprecation is the opposite: the warning keeps printing and the
  debt is written down.
- **Do not replace a deprecated-but-present API to tidy up.** Verify its status on 7.7.0 and leave
  it, recorded as debt, unless it malfunctions, reaches into removed or private internals, affects
  security or a server contract, or the user asked for modernization.
- **Do not weaken or skip tests, accept new screenshot baselines, or relax assertions to make a slice
  pass.** The visual threshold is the one exception, and only because it was lowered deliberately and
  in writing for the whole migration, with what it defers recorded — the opposite of a slice quietly
  relaxing a bar to get through.
- **Preserve unrelated changes in dirty worktrees.**

## Handoff

State the target Ext and Cmd versions in use, the phase reached, the screens migrated and verified,
the verification evidence collected per screen, the overrides retained and why, the
compatibility-layer status, remaining deprecation warnings, known visual differences, and the
rollback method.
