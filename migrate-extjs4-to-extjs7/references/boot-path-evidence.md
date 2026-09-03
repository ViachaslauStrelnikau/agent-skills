# Boot-path evidence (phase 0b)

The audit script reads source text. Source text cannot answer which shell a user is actually
served, what the browser actually fetches, or whether a vendored locale file is still live. Those
are runtime facts, and a browser pointed at the running application answers all of them directly.

Capture them before planning the upgrade. Everything in `tooling-and-build.md` section 8 that this
procedure settles is marked there as browser-settled; the rest stays source-derived.

## 1. Why this is not optional

An Ext 4 project of any age accumulates candidate shells: an old pre-Cmd page, a dev twin of the
production page, a redirect stub, a theme sandbox. Reading them tells you what each *would* do.
It does not tell you which one the deployment serves, and the difference decides what the
migration is.

The specific errors this procedure prevents, all of which have been observed:

| Question | What source text gives you | What the browser gives you |
|---|---|---|
| Which shell is live? | every candidate, unranked — the choice is usually made in the hosting application's controller, outside the web content tree | the document request URL |
| Microloader or prebuilt bundle? | Cmd's `x-compile` / `x-bootstrap` markers, which are *live directives written as HTML comments* and say who manages the page, not what it loads | whether `bootstrap.js` was requested at all |
| Which build profile is deployed? | any `build/<profile>/` string in the file, including ones in comments | the bundle URL actually fetched |
| Doctype | the doctype in the source file, which a build step may rewrite | `document.doctype` on the served page |
| Is a vendored locale file active? | nothing — dynamic injection leaves no static reference to the file | a request for it, and its position in the waterfall |
| Which framework version runs? | `.sencha/app/sencha.cfg` and the vendored SDK | `Ext.getVersion().version` in the page |

A marker-based guess is the trap worth naming twice: a Cmd-managed page and a page that loads a
microloader are **independent facts**. A page can be Cmd-managed and still reference a prebuilt
bundle, which is the normal arrangement when the deployed page is the build output.

## 2. Mechanism

Use the bundled Browser skill when available, and follow its browser-selection and authentication
procedures. Use its Playwright automation surface and, when available and authorized, Developer
mode/CDP to collect the request, console, page-error, and transport-failure evidence below.

If the Browser skill is unavailable or cannot capture the required evidence, reuse the project's
existing Playwright configuration, specs, authentication setup, fixtures, base URL, and script or
CLI command. Do not improvise an unrelated browser harness, and do not add a test runner to a
project that has none.

If neither mechanism can reach the application, authenticate, or capture the evidence, record each
exact attempt and its failure reason and return the phase `INCOMPLETE`. **Do not fall back to
inferring the boot path from source.** An unverified boot path is the thing this procedure exists
to prevent; a source-derived guess presented as a finding is worse than a recorded gap.

Playwright does not emit `requestfailed` for completed 4xx/5xx responses. Inspect response statuses
separately from transport failures.

## 3. What to capture

Once per entry point, per role that reaches a different shell, and per locale the application
offers.

1. **The served document.** Final URL after redirects, HTTP status, and the response body's
   identity — which shell file produced it. Then `document.doctype` (`name`, `publicId`,
   `systemId`), which is the doctype as served rather than as written. Ext 5+ requires an HTML5
   doctype, so this value is a work item, not a note.
2. **The ordered request waterfall** for every script and stylesheet, in arrival order:
   - was `bootstrap.js` requested — yes or no, which settles microloader versus prebuilt bundle;
   - the bundle URL fetched, which settles the deployed profile;
   - every stylesheet arriving outside the bundle, which the Ext 6+ package system would otherwise
     own;
   - auxiliary non-Ext scripts, with their cache-busting query parameters.
3. **Locale activity.** For each locale: whether a locale file is requested, its URL, its response
   status, and its position relative to the main bundle. A request arriving *after* the bundle is
   dynamic injection — record the injecting call site from the source, now that you know the
   injection is real. A locale the application offers whose file is never requested is a dead
   translation; record it as dead, with the evidence, because that is what makes it safe to drop.
4. **Runtime version facts.** `Ext.getVersion().version` and `Ext.versions` from the page,
   compared against the framework version declared in `.sencha/`. A disagreement means the deployed
   bundle was not built from the vendored SDK, which changes what the upgrade is operating on.
5. **Server-injected DOM and globals** that the boot path reads: present or absent, per shell and
   per role, with the element id or global name. An injected value the application reads at startup
   is on the boot path — it fails hard when the accessor was removed and silently when the element
   moves.
6. **The console baseline.** Console messages, uncaught page errors, `requestfailed` entries, and
   unexpected HTTP error statuses. This is the Ext 4 baseline the later console gate is measured
   against, so capture it while the old application still runs.

## 4. Output, and what disagreement means

Write the capture to JSON next to the audit script's JSON baseline, and commit both. Diff each at
every phase boundary.

The two files overlap deliberately. The audit script reports `LoadsCandidate`, `ProfileCandidate`,
`DoctypeSource`, and `Liveness = undetermined`; this capture reports the observed value for each.

**Where they disagree, the capture wins and the script's heuristic is a defect to file.** That
comparison is the regression mechanism for the script's boot-path detection — a scanner defect
shows up as a mismatch against reality rather than as a plausible-looking number nobody checks.

Carry the results into `assets/inventory-templates.md` section 6, and only then answer phase 0b's
question: which shell is deployed, on which profile, with which doctype, loading the framework
which way, in which locales.
