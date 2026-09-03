# Inventory templates

Seven artifacts. The first six are produced in phase 0 and kept current through phase 4; the seventh
is written only when an exception is proposed, and only before it is implemented. Each one exists
because the alternative is re-deriving the same facts under time pressure in the middle of a slice.

Keep them in the repository, next to the audit JSON baseline, and diff them at every phase boundary.

## 1a. Screen universe

The verification universe: one row per screen, listing everything that can reach it. This table is
enumerable and stays complete — it is the denominator, not the test plan.

| Screen | Entry point (menu path) | Controller | Roles that can reach it | Locales offered | Read-only or write |
|---|---|---|---|---|---|
| | | | | | |

Rules: a screen only one role can reach is still a row. A locale that changes column widths or date
parsing is a distinct test, not a cosmetic variant.

## 1b. Verification runs

Coverage. **One row per scenario actually exercised** — never a row covering several roles or
locales at once, because that is the shape that makes coverage unreadable. The verification unit is
`role × entry point × locale × viewport × read/write workflow`, so each of those is its own column.

| Screen | Role | Locale | Viewport / device | Workflow or action | Baseline screenshot | Post-migration screenshot | Console evidence | Network evidence | Result |
|---|---|---|---|---|---|---|---|---|---|
| | | | | | | | | | |

`Result` is one of: `pass`, `fail`, `manual-pass` (exercised by hand because the workflow cannot be
automated — say why), `blocked` (the cell cannot be reached — say why).

The matrix is sampled deliberately, not enumerated: every role at least once, every locale at least
once against a screen with formatted dates and numbers, every bespoke touch or print path at least
once. The gap between 1a and 1b is the set that was reasoned about but not exercised — write that
gap down rather than leaving it implied. `Viewport / device` takes `n/a` on a desktop-only
application, but only once someone has confirmed that is true.

## 2. Endpoint contract inventory

Everything the client sends and expects, captured from the running Ext 4 application rather than by
reading the code. One row per endpoint per calling screen — the same URL called from two screens
with different parameters is two rows.

| Field | Notes |
|---|---|
| Endpoint | |
| Called from | Screen, and the store, form, or `Ext.Ajax` call site |
| Method | |
| URL | Including context path handling |
| Query parameters | Declared *and* assembled by client code — the assembled ones are the ones that get lost |
| Headers | Including any custom or CSRF header |
| Content type | |
| Request body | |
| Parameter-order sensitive? | Yes/no, and what breaks if reordered |
| `rootProperty` in / out | Reader and writer, separately |
| Writer policy | `writeAllFields`, and whether the server depends on the full record |
| Success response envelope | |
| Failure response envelope | The shape on error, which is routinely different and routinely forgotten |
| Id format on create | Phantom id format the server returns and the client expects |
| Update / delete id behavior | Where the id travels: URL, body, or both |
| Upload or download? | Multipart, streamed response, or print/export path |
| Baseline payload file | Path to the captured request and response |

Include `Ext.Ajax` calls and form submits, not just store proxies — they are usually the majority of
the traffic and the least covered by framework-level review.

## 3. Override register

Every `Ext.override` and every `override:` class, with the evidence needed to re-derive it.

| Override target | File | Why it exists (original defect or requirement) | Ext 4 methods it replaces | Do those methods still exist on the target? | Private members touched | Decision: re-derive / drop / replace with supported API | Why an in-place edit was insufficient | Verified |
|---|---|---|---|---|---|---|---|---|
| | | | | | | | | |

"Why it exists" is the field that decides the work. An override whose original reason is gone should
be deleted, not ported. If nobody knows the reason, that is itself a finding — record it.

"Why an in-place edit was insufficient" is required for any row whose decision adds something the
application did not have — a wrapper, a new base class, a shim, a replacement component. The
source-structure policy allows that only for a confirmed target-release incompatibility. Summarize it
here in one line and record the evidence in the exception record, section 7. An empty cell means the
smaller edit was never attempted.

## 4. Audit triage

The audit script's JSON output turned into decisions. One row per finding cluster, not per hit.

```csv
category,status,matching_lines,files,triaged_by,true_positives,verdict,target_status,verified_against,owner,phase,notes
```

`verdict` is one of: `fix-now`, `fix-in-slice`, `debt`, `no-change`, `needs-research`.
`true_positives` is what survived reading the hits — the gap between it and `matching_lines` is the
number that would have been wasted work under a bulk edit.

`target_status` and `verified_against` exist because `verdict: debt` is a real outcome, not a
holding pen. A deprecated-but-present API may stay, but only once someone has confirmed it is still
present and supported: `target_status` records what 7.7.0 actually does with it, and
`verified_against` records the release and date of that check. Rows carrying `debt` with an empty
`target_status` are unaccounted, and unaccounted findings are what the completion gate rejects.

The subset of this table with `verdict: debt` **is** the accepted-deprecation-debt inventory the
completion gate reads. It needs the call sites, so keep `files` populated for those rows rather than
collapsing them.

## 5. Build-customization inventory

Everything between "source in the repository" and "bytes the browser receives".

| Step | Where it lives | What it produces | Why it exists | Still needed on the target? | Replacement | Verified |
|---|---|---|---|---|---|---|
| | | | | | | |

Cover at least: the Cmd invocation and its flags, any raw `sencha compile` pass, classpath overrides,
theme CSS assembly, custom CSS appending and URL rewriting, page-shell copying, cache busting, and
how the output reaches the deployed application. A step whose reason is "Cmd 4 got it wrong" must be
re-tested against the target before it is carried forward.

## 6. Boot path and localization

Filled from the browser capture in `references/boot-path-evidence.md`, and cross-checked against the
audit script's candidate columns. Where they disagree, the capture is right and the script has a bug.

### 6a. Shells

| Shell | Live? (and how established) | Cmd-managed | Doctype as served | Profile served | Microloader or prebuilt bundle | Bundle URL fetched | CSS outside the bundle | Auxiliary scripts | Server-injected DOM the boot path reads |
|---|---|---|---|---|---|---|---|---|---|
| | | | | | | | | | |

"Live? (and how established)" must name the evidence — the served document URL, or the controller or
configuration that selects the shell. A shell nothing serves is recorded as such and left alone
until phase 4; it is not a shell contract, it is a deletion candidate with its own decision.

### 6b. Locales

| Locale | File | Load mechanism | Injecting call site | Application overrides | Framework overrides | Observed active | Rehomed to |
|---|---|---|---|---|---|---|---|
| | | | | | | | |

`Load mechanism` is one of: build classpath, script tag, dynamic injection, unreferenced.
`Observed active` is `yes` or `no` **from the capture** — never inferred. Application overrides
living inside the vendored SDK need a `Rehomed to` destination before the SDK can be removed; the
framework half is replaced by the target release's locale package and needs no row here beyond a
count.

## 7. Exception record

One per added class, filled in **before** the class is written. The source-structure policy permits a
new class only for a confirmed target-release incompatibility that cannot be repaired inside the
class that already owns the behavior, and this is where that confirmation lives. The override
register's "Why an in-place edit was insufficient" column is the one-line summary; this is the
evidence behind it.

| Field | Required content |
|---|---|
| Existing class and screen | The class that owns the behavior today, and the affected workflow |
| Ext 4 dependency | The removed or private API, and the behavior relied upon |
| Target-release evidence | What the target release's documentation, source, or a runtime check actually showed — with the release and the date |
| Smaller edits attempted | What was tried inside the existing class, and how each attempt failed |
| Proposed mechanism | The smallest new thing that works, and its blast radius |
| Contract evidence | Proof that the server contract and the screen's observable behavior are unchanged |
| Removal gate | The condition under which this code is deleted, and who owns that |

The last two rows are the ones that get skipped, and they are the two that decide whether this stays
an exception. Without a removal gate the workaround is permanent by default. And "it works" is not
evidence that the payload is unchanged — only a payload diff is.
