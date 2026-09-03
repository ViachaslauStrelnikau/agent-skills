---
name: extjs4-to-extjs7-migration-quality-gate
description: Run an independent runtime acceptance gate for a completed Ext JS 4-to-7 classic migration screen, boot slice, or bounded batch. Verify the deployed Ext JS 7 build, browser workflow, structural visual integrity, accounted console output, HTTP-contract parity, and persisted state for mutations; return PASS, FAIL, or INCOMPLETE. Do not use for implementation, broad static review, baseline creation, or repository-wide audits.
---

# Ext JS 4 to Ext JS 7 Migration Quality Gate

## Objective

Answer: **Does the migrated Ext JS functionality behave like the captured Ext JS 4 baseline in the running application?**

Make independent runtime evidence the main value. Never modify production source,
framework configuration, migration inventories, tests, or visual baselines to make
the gate pass. Safe temporary scenario data is allowed only in an authorized local
or test environment.

## Establish the acceptance slice

Use the current task and acceptance criteria to identify one completed boot slice,
screen, workflow, or explicitly bounded batch. Discover and follow applicable
`AGENTS.md` files and project migration rules.

Read the migration's own artifacts, not the instructions of whatever skill produced
them. This gate is independent evidence, and a gate that loads the implementer's
skill inherits the implementer's framing and thresholds. Load the acceptance
contract plus the current slice's records:

- the **acceptance contract**: target Ext and Cmd release, toolkit, theme,
  architecture, the visual and console thresholds, the canonical build command and
  profile, the server test suite, and where baseline evidence lives. Every threshold
  this gate applies comes from here. If it is missing or unfilled, return
  `INCOMPLETE` and say which rows are absent — do not substitute a default;
- screen-universe and verification-run rows;
- Ext 4 screenshots and console capture;
- endpoint-contract rows and captured request/response evidence;
- boot-path, build-profile, locale, audit-triage, override, exception, and
  deprecation-debt records that affect the slice;
- current diff, acceptance checkpoint, and directly related automated tests.

Do not recreate phase 0 evidence during this gate. If a required Ext 4 baseline,
expected workflow, or project-defined prior check is missing, stale, failed, or
cannot be tied to the slice, return `INCOMPLETE` and identify the exact gap.

If no migration-specific rules exist, inspect only changed files, direct callers,
and direct tests for gate-critical violations: an unapproved server-contract
change, MVC-to-MVVM conversion, application-class restructuring, new compatibility
class without its exception record, restyling, weakened tests, or a hidden warning.
Do not turn this into a general code review.

## Discover the runtime safely

Learn the project-defined build, deployment, authentication, fixture, cleanup, and
browser procedures. Reuse a running local/test instance when possible. Never target
production or an unconfirmed shared environment, and never invent, print, or store
credentials.

Before testing, prove that the browser receives the current slice. Use a build or
artifact hash, timestamp, deployment log, version marker, source map, or behavior
unique to the change. Also capture these runtime facts from the served application:

- `Ext.getVersion().version` matches the target release named in the acceptance
  contract;
- the toolkit, theme, live page shell, locale, and build profile are the ones the
  acceptance contract names;
- the bundle and stylesheets were loaded from the current deployment, with no
  unexpected Ext 4 framework artifact mixed into the boot path.

Source configuration alone does not prove runtime freshness or the live boot path.
One exception: which shell an entry point is served is settled deterministically by
the hosting application's routing code, cited by file and line, and that counts as
evidence here. Everything else — freshness, the doctype as served, the profile
actually fetched, the live locale — is a runtime fact. If it cannot be established,
return `INCOMPLETE`.

Run the project's canonical build for the profile the live shell serves when the
gate includes build acceptance or no trustworthy successful build record exists.
Use the project's wrapper rather than assuming `sencha app build` is the whole
pipeline. From migration phase 2 onward, build errors fail the gate. Record warning
counts; an accepted, inventoried deprecation warning is not a failure. Phase 4 or
full-migration acceptance also requires the production profile to build.

When the slice touched a reader, writer, proxy, or record-id format and the hosting
application has its own test suite, run it and report the result. The client-side
checks cannot see a narrowed write payload that the backend accepts with a 200; the
backend's own tests can. A failure there fails this gate. Where no such suite
exists, say so rather than letting the browser and network checks imply that ground
is covered.

## Select the minimum verification level

- **A — boot:** application shell, framework, theme, locale, controllers, and main
  view only. Use for a completed boot-phase slice with no screen workflow claimed.
- **B — read workflow:** a screen or workflow that does not mutate durable state.
- **C — write workflow:** create, save, edit, delete, upload, assignment, status,
  or any action with durable or externally visible side effects.
- **D — partial/manual:** required behavior depends on hardware, a browser plugin,
  an external service, or another condition that cannot be automated safely.

Environment unavailability does not lower the required level. Select the level the
behavior needs, complete every safe check, and return `INCOMPLETE` for unavailable
required evidence. Level D is never a way to label partial verification `PASS`.

## Execute the runtime gate

Use the bundled Browser skill when available, following its browser and
authentication procedures. Otherwise reuse the project's existing Playwright
configuration, authentication setup, fixtures, and commands. Do not add an
unrelated browser harness merely to run this gate. If neither mechanism can capture
the required browser, console, network, and screenshot evidence, return
`INCOMPLETE`.

For every level:

1. Open the real served entry point and authenticate through approved means.
2. Confirm the live version, toolkit, shell, profile, theme, locale, bundle, and
   stylesheet facts relevant to the slice.
3. Capture console messages, uncaught page errors, transport failures, and HTTP
   response statuses. A completed 4xx/5xx response is not a transport failure, so
   inspect both categories.
4. Require zero uncaught exceptions and zero **unaccounted** warnings. Classified
   deprecated-but-present warnings may remain only when the debt inventory records
   their call sites and verified target-release status. Do not silence output.

For level B or C, perform the actual user workflow; opening the screen is
insufficient. Verify the applicable checklist items: layout and sizing, text and
icons, focus and keyboard behavior, dialogs, validation and localization, grid
sort/filter/paging/scrolling/selection/editing, and print/export/download behavior.

### The visual check

Take the screenshot, then work the visual threshold the acceptance contract defines
— its questions and its closed artifact list, including any artifact the project
added there. **Report which threshold you applied.** The contract is the only copy;
if it is unfilled you are already returning `INCOMPLETE` and there is nothing here
to fall back on.

Two of its questions need a technique the contract does not supply:

- **Row counts come from the HTTP response, never the screenshot.** Ext 5+ buffered
  rendering only puts visible rows in the DOM, so a short-looking grid is normal and
  a screenshot cannot tell you whether the store loaded.
- **A missing icon is confirmed in the network log**, as a theme-resource 404. A
  renamed theme image raises no console error, so nothing else will surface it.

Consequences, which are this gate's to enforce:

- any artifact on the contract's list is a `FAIL`, and so is a component absent or
  present-but-unrendered, or data populated in Ext 4 and empty now;
- the Ext 4 baseline is the **reference** for answering the questions — "did this
  screen have a scrollbar before?" — not a diff target;
- whatever the contract defers is reported *not assessed*. Never as compared and
  equivalent;
- do not accept a new baseline or edit an existing one to make a slice pass, and do
  not restyle. A difference you happen to prefer is still a difference, and this is
  not where it gets adopted.

### The HTTP contract comparison

Compare every request made by the exercised workflow with its Ext 4 capture:
method, URL and context path, ordered query parameters where material, headers,
content type, body, sort/filter/paging encoding, response envelope, failure shape,
and record-id behavior. Include store proxies, form submissions, standalone
`Ext.Ajax`, trees, uploads, downloads, and print/export calls. Compare contractual
semantics rather than byte order or immaterial formatting. An approved backend
contract change is judged against its explicit new acceptance criteria; do not
quietly redefine the baseline.

### Persistence, for level C

Reload the screen or re-query through the public UI/API and verify the
committed record, dependent state, identifiers, update/delete semantics, and absence
of accidental duplicates. Use dedicated temporary data. Clean it up when safe, but
retain enough evidence to diagnose a failure before cleanup. Do not perform unsafe
destructive parity tests.

### Matrix reconciliation

At a phase boundary or bounded batch, reconcile the exercised matrix rows with the
screen universe: every role at least once, every locale at least once on a screen
with formatted dates/numbers, and every bespoke viewport, touch, print, or export
path at least once when applicable. List reasoned-but-unexercised cells explicitly.

## Migration-state checks

Treat `implemented`, `verified`, and `complete` labels as claims until reconciled
with this run. For the slice, report:

- retained overrides and exception-backed added classes that participated;
- compatibility-layer state and its removal gate;
- accepted versus unaccounted deprecation warnings;
- known visual differences and whether each has explicit approval.

During migration, a tracked compatibility layer may remain enabled. Full phase 4
or migration completion fails if it is still enabled, an override/exception lacks
its required evidence, an unaccounted warning remains, the vendored Ext 4 runtime is
still on the live boot path, or the production build has not passed.

Keep functional acceptance separate from delivery-only state such as commit, push,
rollout, or observation. Those are remaining gates unless explicitly included in
the requested acceptance scope.

## Decide the outcome

- **PASS:** every required build, runtime, browser, visual, console, network, and
  persistence check for the selected level succeeded against the confirmed current
  deployment, and the slice's evidence is consistent.
- **FAIL:** observed evidence demonstrates a build error, runtime exception,
  unaccounted warning, visual or interaction regression, HTTP-contract defect,
  incorrect persisted state, or a required migration safeguard violation.
- **INCOMPLETE:** required baseline, deployment freshness, authentication, fixture,
  browser access, manual step, safe persistence check, or other evidence is missing
  or cannot be established.

Do not convert `INCOMPLETE` to `PASS`. Distinguish a demonstrated defect (`FAIL`)
from unavailable evidence (`INCOMPLETE`).

## Report

Use this concise shape and retain every field; use `N/A` where appropriate:

```text
EXT JS 4 -> 7 MIGRATION QUALITY GATE: PASS | FAIL | INCOMPLETE
Slice: <screen/workflow/batch and migration phase>
Level: A | B | C | D
Runtime: <freshness; Ext version; toolkit/theme; shell/profile/locale>
Build: <command or trusted record; profile; result; warnings>
Server tests: <suite run and result, or N/A with the reason>
Browser: <actual action; visible/interaction result>
Visual: <components present; data present vs response; artifacts found; parity deferred>
Console: <exceptions; accounted/unaccounted warnings>
Network: <contract captures compared; failed statuses/transports>
Persistence: <reload/re-query result, duplicates, or N/A>
Matrix coverage: <cells exercised; explicit gaps>
Migration state: <overrides/exceptions; compatibility layer; debt>
Blockers: <0 or numbered actionable defects/evidence gaps>
Remaining gates: <delivery/rollout/full-cleanup items or N/A>
```

For a failure, include only the request shape, expected behavior, actual behavior,
and the smallest useful screenshot, response, console, or persistence fragment.
Never dump secrets, large payloads, complete logs, or database contents.
