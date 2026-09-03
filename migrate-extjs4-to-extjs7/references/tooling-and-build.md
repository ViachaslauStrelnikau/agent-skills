# Tooling, Build, and Hosting

Everything the framework upgrade needs from Sencha Cmd, `app.json`, the loader, and the Java
application that serves the result.

## 1. Version facts to establish first

Record all of these before changing anything, and report any you cannot determine.

| Fact | Where to find it |
|---|---|
| Ext 4 patch level | `ext/version.properties`, `app.json` `"framework"`, or the SDK folder |
| Sencha Cmd version | `sencha which`, `.sencha/app/sencha.cfg`, CI configuration |
| Target Ext 7 release | Fixed at **7.7.0.31** for this migration (`SKILL.md`, Fixed decisions). Not "latest by accident" — pin it in `app.json` and in CI. |
| Paired Cmd release | **`@sencha/cmd@7.7.0`** (`version_full` 7.7.0.36), installed from npm. Still absent from Sencha's published matrix — see section 2. Record it in `.sencha/app/sencha.cfg` and in the build wrapper, and record *which* platform distribution the npm install actually resolved to. |
| Java version | Cmd requires it; the CI agent's version is the one that matters |
| Node and npm | Required by Fashion from Cmd 6 onward |
| Ruby | Required only while the Ext 4 or 5 build must still run |

## 2. Cmd compatibility matrix

Minimum Cmd version per Ext release:

| Ext JS | Minimum Cmd |
|---|---|
| 4.1.1a–4.1.3 | 3.0.0 |
| 4.2.0–4.2.1 | 3.1.0–3.1.2 |
| 4.2.2–4.2.4 | 4.0.0–4.0.5 |
| 5.0.0–5.0.1 | 5.0.0–5.0.1 |
| 5.1.0–5.1.1 | 5.1.0–5.1.3 |
| 6.0.0–6.0.2 | 6.0.0 |
| 6.2.0–6.2.1 | 6.2.0 |
| 6.5.0–6.5.3 | 6.5.0 |
| 6.6.0+ | 6.6.0+ |
| 7.0.0 | 7.0.0 |

**There is no published row for 7.7.** Sencha's matrix stops at Ext JS 7.0.0 / Cmd 7.0.0 and still does so in the Cmd 7.8.0 documentation, so the minimum Cmd for a 7.7.0.31 target is unpublished. Cmd 7.7.0 exists and is the matching release; treat the matching minor as the floor, verify it builds the application, and record the pairing rather than inferring one. Cmd 7.8.0 and 7.9.0 also exist and are the alternative if a 7.7.0 defect forces the issue — that is a deliberate choice with its own JDK consequence, see below.

The table is Sencha's published matrix and it stops at the releases listed. Later 4.2.x maintenance
builds exist — 4.2.5 and 4.2.6 were shipped to support customers — and are not in it. Treat them as
covered by the 4.2.2–4.2.4 row (Cmd 4.0.x) unless the project's own `sencha.cfg` says otherwise, and
read the actual `app.framework.version` and `app.cmd.version` from the project rather than inferring
either from this table.

Runtime requirements:

- **JDK range is Cmd-version-specific, and the 7.7 pairing is the narrow one.** Cmd 6.6.0 through
  **7.7.0** requires Oracle JRE (SE) 8–11 or OpenJDK 8–11. Only Cmd 7.8 raises the ceiling to 8–21.
  So pinning Cmd 7.7.0 to match the framework caps the build JDK at 11 — check the CI agent and the
  developer machines against that before pinning, because a JDK 17 or 21 agent will not run it.
- Node 8+ and npm 5+ for the Fashion module.
- Ruby 1.8–2.0.x only for building Ext JS 4 and 5 applications. Ext 6+ does not use Ruby.

Sencha states that recent Cmd releases remain backward compatible to Ext JS 4.1.1+, which in
principle allows one Cmd installation to build both the old and new app during the transition.
Verify that on the actual application before relying on it — the Ruby and Compass dependency of the
old build is the usual complication.

### Installing Cmd 7.7.0 from npm

`@sencha/cmd@7.7.0` is on the **public** npm registry — no authentication, unlike the ESLint plugin
in section 6. Its `version_full` is `7.7.0.36`; record that, not `7.7.0`, as the build's Cmd version.

The published package is a ~13 KB stub. Its `install` script runs `platform-install.js`, which calls
`which('java')` and then performs a **nested `npm install`** of a platform-specific package into its
own directory. Which package it picks depends on the machine (verified against the registry and the
package source, 2026-09-02):

| Platform | `java` on PATH | Package installed | Consequence |
|---|---|---|---|
| Windows | yes | `@sencha/cmd-windows` | No bundled JRE. **Runs on the system Java, so the 8–11 range above binds.** |
| Windows | no | `@sencha/cmd-windows-64-jre` (~92 MB) | Bundled JRE; the system JDK is irrelevant. Only the 64-bit variant is published — a 32-bit Node with no Java fails. |
| macOS | yes | `@sencha/cmd-macos` | No bundled JRE; system Java applies. |
| Linux | yes | `@sencha/cmd-linux-64` | No bundled JRE; system Java applies. |
| Linux | no | — | **Hard failure**, `exit 126`: "A JRE is required to download and run Sencha Cmd in linux." |

Four consequences that matter to a migration whose point is a reproducible build:

- **The install is environment-dependent.** The same `npm install` produces a different Cmd
  distribution depending on whether `java` happens to be on PATH, and the JDK version range only
  binds in the no-JRE case. Decide which arrangement you want, write it down, and verify which one
  each machine and CI agent actually got — do not let it be incidental.
- **The nested package is not in your lockfile.** `npm ci` still executes the install script and
  fetches the platform package unlocked, so the lockfile does not pin what actually runs the build,
  and the install needs network access at install time. An air-gapped or offline-cache CI will not
  work without vendoring the platform package deliberately.
- **Invocation changes shape.** The package's `bin` is `sencha`, which spawns `dist/sencha[.exe]`.
  It is `sencha <args>` or `npx sencha <args>`, **not** `java -jar sencha.jar`. Any wrapper script
  that pins a `sencha.jar` path has to be rewritten, not just repointed — see section 3.
- **`sencha switch` is unsupported under an npm install.** The stub intercepts it and prints
  "This command is not supported when installed via npm." So the usual way of keeping an old Cmd for
  the old build and a new Cmd for the new one is unavailable: keep the existing jar-based
  installation for the Ext 4 build, add the npm-installed 7.7.0 for the Ext 7 build, and invoke each
  one explicitly by path.

## 3. The build contract

`sencha app build` is often not the whole build. Before touching the framework, find and record
everything that wraps, post-processes, or bypasses it, because none of it survives an upgrade by
accident:

| Customization | Why it matters on the target |
|---|---|
| A wrapper script (`.bat`, `.sh`, Ant, Maven) that calls Cmd | The documented build is whatever the wrapper does, not what `sencha app build` does |
| A raw `sencha compile ... union ... concatenate` pass after the app build | Someone worked around a Cmd limitation. Find out which one, and whether the target release still has it. |
| A hand-set `--classpath` naming SDK internals | Those paths move in Ext 6/7. The classpath is a dependency declaration in disguise. |
| Copying a prebuilt theme CSS over Cmd's output | The app's real stylesheet is not the one Cmd produced. Fashion output will differ. |
| Appending custom CSS to the bundle, with path rewriting | The append order and the rewritten URLs are both load-bearing |
| A pinned absolute path to a specific `sencha.jar` | Blocks the Cmd upgrade until it is parameterized — and an npm-installed Cmd 7.7.0 has no jar to point at. The invocation changes from `java -jar sencha.jar …` to `sencha …`, so the wrapper is rewritten rather than repointed, and the old jar-based Cmd stays installed for as long as the Ext 4 build must still run (section 2). |
| Copying a page shell into the build output | The deployed shell is a build artifact, not the source file |

Reproduce each step deliberately on the target or delete it deliberately. Do not assume the Ext 7
build subsumes it. Where a step exists because Cmd 4 mis-detected dynamically referenced classes,
re-test whether the target Cmd still needs the workaround before carrying it forward — and if it
does not, removing it is a separate, verified change.

## 4. Running the upgrade

```
sencha app upgrade /path/to/ext-7.x.x
```

### Rehearse first, then choose a strategy

Run the upgrade on a throwaway branch before deciding how the real migration is structured. Sencha's
own guidance is to work from clean source control and review the entire generated diff; treat that
review as a decision point rather than a formality.

Two legitimate outcomes:

- **Upgrade in place.** The generated diff is reviewable, `app.json` and `.sencha/` are close to
  what Cmd generates, and the build contract survives. This is the normal case for an application
  that stayed on the generated scaffold.
- **Generate a clean Ext 7 classic scaffold and transplant.** Create a new app with the target Cmd,
  then move in the application source, the theme, and the build contract deliberately. Prefer this
  when `app.json` is near-empty, `.sencha/` has been hand-edited, the framework is vendored in an
  unusual layout, or the real build lives in a wrapper script. Transplanting into a known-good
  scaffold is often less work than reconciling a decade of drift inside a generated diff.

Either outcome still ships as a direct 4-to-7 migration. Record which one was chosen and why.

Preconditions and procedure:

1. Commit or stash everything. The command rewrites configuration and scaffolding in place, and a
   clean working tree is the only usable diff.
2. Configure a merge tool in `sencha.cfg` (p4merge, kdiff3, or similar) before running — conflicts
   in Cmd-managed files are expected and resolving them blind is worse.
3. Install the new Cmd, restart the shell, and confirm `sencha which` reports it.
4. Run the upgrade from the application root.
5. Resolve conflicts, then read the entire diff. This is a review step, not a formality: the command
   touches the microloader, bootstrap, and build properties.
6. `sencha app build --clean development` and fix until it succeeds. No component work before this
   passes.

Structural changes that arrive with it:

- `workspace.json` at the workspace root (new in Cmd 6), declaring `apps`, `build.dir`, and package
  directories.
- The `sass` object in `app.json` replaces the `app.sass.*` properties from `.sencha/app/sencha.cfg`.
- Microloader and build-property handling differ from Cmd 4/5. When the Cmd 6 upgrade guidance
  refers back to the Cmd 5 guide for Ext 4.x specifics — microloader and build properties — read
  that too; it applies directly to this migration.
- `sencha app watch` runs a built-in web server on port 1841 and drives Fashion Live Update. Whether
  that is usable depends on the hosting arrangement below.
- New apps can be generated `--classic` or `--modern`. This app stays classic.

## 5. app.json for an Ext 7 classic app

The properties that matter here:

```json
{
    "framework": "ext",
    "toolkit": "classic",
    "theme": "theme-classic",
    "requires": [
        "ux",
        "charts"
    ],
    "compatibility": { "ext": "4.2" }
}
```

- `toolkit` must be `classic`. Nothing in this migration targets modern.
- `theme` is `theme-classic`, the closest available baseline to the Ext 4 look. Not parity - see
  `theming-and-sass.md`, and the visual threshold in `SKILL.md`.
- `requires` must list `ux` if any `Ext.ux` class is used, and `charts` if any chart exists. Both
  were split out of the framework in Ext 6 and neither loads implicitly. Remove `ext-aria`, which no
  longer exists.
- `compatibility` is triage scaffolding: where the target release honors it, removed-API calls become
  console warnings with the old behavior restored, instead of hard failures. Verify it is honored by
  the target Ext 7 release before depending on it, and remove it before phase 4 closes.
- Also review, as `sencha app upgrade` rewrites them: `classpath`, `overrides`, the `js` and `css`
  arrays, `output`, and the development and production build profiles.

## 6. Static analysis with the Sencha ESLint plugin

Preferred over the desktop Upgrade Adviser because it runs in CI and produces a diffable report.
Conditional, though: it needs an authenticated registry, so run it when that is available and record
it as unavailable with the reason when it is not. Code inspection does not wait on registry
approval — see the fallback in the setup notes below, and phase 0 in `SKILL.md`.

```
npm login --registry=https://sencha.myget.org/F/extjs-upgrade-adviser/npm/ --scope=@sencha
npm install @sencha/eslint-plugin-extjs --save-dev
```

The MyGet username is the signup email address with `@` replaced by two periods, for example
`name..example.com`.

Enable the recommended set in the ESLint configuration:

```json
{
    "extends": ["plugin:@sencha/extjs/recommended"]
}
```

Eighteen rules across four categories: overrides (existing alias, class, and method overrides, plus
calls to overridden methods), deprecated items, private items, and removed items — each covering
class, config, method, and property usage.

Practical setup notes:

- The registry requires signup and access approval. Arrange it before the migration starts, not on
  the day it is needed. Have a fallback: the audit script in `assets/` covers the mechanical
  categories without any registry access.
- Pin the ESLint and plugin versions. The plugin tracks framework releases and an unpinned upgrade
  changes the finding count for reasons unrelated to the migration.
- Scope the lint to application source. Exclude the vendored framework, `build/`, generated
  bundles, and any third-party script; otherwise the report is mostly framework noise.
- The Adviser GUI takes toolkit, current version, and target version as inputs. If the plugin
  exposes an equivalent — a `settings.extjs` block naming toolkit and from/to versions — it will be
  documented in the installed package's own README; read
  `node_modules/@sencha/eslint-plugin-extjs/README.md` after installing rather than copying a
  configuration from elsewhere.
- Save each run's machine-readable output (`--format json`) as a committed baseline. The diff
  between runs is the progress metric; the raw count on its own is not.

Two documented coverage limits, both material:

- **False positives are expected.** Sencha's own guidance notes that some issues are reported that
  should not be — public configs flagged as private, for example, because of source-parser
  limitations — and advises checking the API documentation and ignoring the finding when the docs
  contradict it. Every finding is a research pointer, not a defect.
- **It only analyzes classes that extend Ext classes.** A custom base class that extends another
  custom class is not properly analyzed, so an application with its own component hierarchy has a
  blind spot exactly where its most bespoke code lives — and, because those are base classes, where
  the most other code depends on it. Cover it deliberately: rank the local inheritance graph and
  read the top of it by hand, per `overrides-and-custom-components.md` section 2a. A clean report
  over a codebase with its own `AbstractWindow` hierarchy is not evidence about that hierarchy.

Run it in phase 0 to size the work, and again at every phase boundary.

The **Ext JS Upgrade Adviser** desktop application is the GUI over the same rules, free to licensed
Ext JS customers. It takes toolkit, current version, target version, and a source folder; produces a
severity-ranked grid, exports to Excel, and can auto-fix some findings. Use it for the initial
survey or where a licence holder wants a report; use the plugin for the ongoing gate. Review every
autofix — an autofix is a diff, not a decision.

## 7. The loader

The single most disruptive non-API change in practice. Ext 4 codebases routinely depend on load
order that the Ext 5+ asynchronous loader does not guarantee.

Rules:

- Declare dependencies properly with `requires` on the class that needs them. That is the fix, and
  it is the only fix that stays fixed.
- Use `uses` for classes needed after startup rather than at definition time.
- Never reach for `Ext.syncRequire` or hand-ordered script tags as a solution. They are permitted
  only as a commented, tracked temporary measure with a named removal gate — real upgrades have
  reported measurable startup cost from exactly this shortcut.
- Symptoms of a missing `requires`: an undefined class at boot, an xtype that resolves to nothing, a
  store whose model is momentarily missing, an override that applies after the class it patches has
  already been used.
- The Cmd-built production bundle can mask the problem by including everything anyway. Test the
  development build, which loads dynamically.

## 8. The page-shell contract (phase 0b)

The Cmd build output is served by the Java application and the page shell is rendered server-side.
A long-lived Ext 4 application in that arrangement has almost always drifted away from the
arrangement Cmd assumes, and the drift is load-bearing. **Document it before changing it.**

### Inventory, per shell

There is usually more than one shell. Find every page that boots the application, not just the one
Cmd knows about.

Rows marked **(browser)** are runtime facts. Establish them from a capture against the running
application per `boot-path-evidence.md`, not by reading the shell files: the choice of shell
normally lives in the hosting application's controller, outside the web content tree, and dynamic
script injection leaves no static reference at all. The audit script reports its own versions of
these as *candidates* for exactly this reason.

| Item | Why it matters |
|---|---|
| Which shell each entry point and role actually receives **(browser)** | The Cmd-managed page and the deployed page are frequently different files, and a project of any age keeps several plausible-looking shells that nothing serves |
| Whether Cmd manages it (`app.page.name`, `x-compile` / `x-bootstrap` markers) | A shell outside those markers is hand-maintained and silently drifts from the build |
| What the page actually puts on the client — microloader, prebuilt bundle, or source framework **(browser)** | Cmd's `x-compile` and `x-bootstrap` directives are live HTML comments that say *who maintains the page*, not what it loads. A Cmd-managed page that references a prebuilt bundle is the normal arrangement when the deployed page is the build output, and reading the marker as a microloader signal misclassifies it. |
| Doctype **(browser)** | Ext 5+ requires an HTML5 doctype. Shells commonly disagree with each other, and a build step may rewrite the one in the source file. |
| Which build profile the shell points at (`testing`, `production`, `development`) **(browser)** | A "prod" shell serving the testing build is a real and common arrangement; changing it is a deployment change, not a cleanup |
| Context-path handling, `<base href>` | A `<base>` tag changes how every relative URL — including dynamically loaded framework classes and locale files — resolves |
| Cache busting | Cmd's cache manifest versus a hand-rolled `?v=` query parameter |
| Locale injection | How the server communicates locale, and how the app reads it before boot |
| Server-injected DOM and globals | Values written into the page by the server, and whether they exist before the framework loads |
| Auxiliary non-Ext scripts | Crypto, signature, or vendor bridges loaded outside the compiled bundle |
| CSS loaded outside the bundle | Typically UX or plugin stylesheets that the Ext 6+ package system would otherwise own |
| Inline script that calls into Ext | Page-level code that assumes the framework is already loaded |

### Rules

- **Do not replace a hand-maintained shell with a microloader arrangement until the table above is
  filled in for it.** The shell is a production dependency. Converting it is its own change, with
  its own verification, and belongs in phase 0b or later — never as a side effect of
  `sencha app upgrade`.
- **Server-injected values must be available before the application boots.** If the app reads a
  value out of the DOM at startup, that read is on the boot path: it fails hard when the method it
  uses was removed, and it fails silently when the element moves. Reading injected state through
  removed `Ext.dom.Element` methods is a specific, common boot-path break.
- **Locale files load from a framework-relative path.** The locale package was renamed and
  relocated between Ext 4 and Ext 6+, so any code building a locale URL by string concatenation
  breaks when the SDK moves. Find those URLs in phase 0b — and note that dynamic injection
  (`Ext.Loader.injectScriptElement` and friends) leaves no static reference to the file itself,
  only to the folder, so the browser capture is what proves which locale files are live.
- **Application translations hand-appended to a vendored locale file are application code.** It is
  the common case, not an oddity: a stock translation file with a few hundred application overrides
  added below it. That code sits inside the directory the audit script excludes as third-party, so
  it is invisible to the source scan, and it is destroyed when the vendored SDK is removed.
  Inventory it and rehome the active part before deleting anything under the SDK.
- **A vendored SDK checked into the web application** is the norm in Ext 4 projects and is not
  compatible with how Cmd 6/7 resolves the framework. Plan its removal explicitly, including the
  build artifacts and any resource paths that point into it.
- **`sencha app watch` and its port 1841 server** may not be usable when the app depends on the
  Java application for its shell, session, and API. Decide early how developers get a fast inner
  loop: proxy the API to the Java server, or deploy the development build into the WAR and accept a
  slower cycle. Fashion Live Update is worth arranging for the theming work specifically.
- **Session, authentication, and CSRF behavior are backend contracts.** They do not change as part
  of this migration. If a framework change alters how a request is formed — headers, parameter
  encoding, or the write payload — that is a defect in the slice, not a backend change to negotiate.

## 9. Build and CI gates

- **The project's canonical build must pass** — the wrapper script or task that actually produces
  what gets deployed, running the profile the deployed shell really serves (section 8) — before any
  component work and at every phase boundary. Where the real build is a wrapper, that wrapper *is*
  the gate; section 3 is the list of things it does that `sencha app build` does not.
- `sencha app build --clean <profile>` is an additional diagnostic, not a replacement. It is worth
  running to isolate whether a failure belongs to Cmd or to the wrapper's post-processing. Read the
  wrapper first: `--clean` empties the output tree, so where the wrapper copies a page shell, a
  prebuilt theme stylesheet, or a hand-assembled bundle *into* that tree, `--clean` deletes the
  deployed artifacts along with the generated ones. It can also target a profile nothing serves,
  which makes a green result meaningless.
- The production profile must pass before phase 4 closes. The production build compresses and
  reorders in ways development does not — a clean development build is not evidence of a working
  production build.
- The ESLint finding count is recorded per phase. A finding verified as deprecated-but-present on
  7.7.0 moves to the accepted-debt inventory rather than counting against the phase. What must not
  rise is the count of *unclassified* findings.
- **The hosting application's own test suite is a migration gate**, where it has one. This upgrade
  is not supposed to change a single request the backend receives, which makes the backend's tests
  the cheapest available evidence that it did not – and the only automated evidence covering the
  writer changes, which carry the highest data-loss risk in the migration and raise nothing on the
  client. Run the suite the project documents after any slice touching a reader, writer, proxy, or
  id format, and record the result. A failure there is a defect in the slice, not a test to update.
- The CI image needs: Java 8+ (8–21 for Cmd 7.8), Node 8+ and npm 5+, Sencha Cmd 7.x, and the
  framework available to the build. Ruby comes out once the Ext 4 build is retired.
