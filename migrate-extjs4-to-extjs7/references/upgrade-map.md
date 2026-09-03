# Ext JS 4 to 7 Cumulative Change Map (classic toolkit)

A direct 4-to-7 hop inherits every breaking change from three major releases at once. The 4-to-5
transition carries the majority of them; 5-to-6 adds the toolkit and package restructuring; 6.x and
7.x add smaller diffs.

**Always confirm against the target release.** The target here is **Ext JS 7.7.0.31**. Sencha
publishes per-release Classic API Diff guides under `guides/whats_new/api_diffs/` in the docs for
each version, so the ones to read are those up to and including 7.7.0. This map tells you where to look
and what to expect; it does not replace reading the diff for the exact target patch level.

## 0. Mapping status — read this before using any table below

A table entry is a *research pointer*, never a search-and-replace instruction. Every entry has one
of these statuses, and the status decides the work:

| Status | Meaning | What it costs |
|---|---|---|
| **Removed** | Gone. Calls throw. | Must fix. Blocks boot if on the boot path. |
| **Deprecated but present** | Still works, still shipped, logs a warning. | Debt, not a blocker. Schedule it; do not let it hold up the migration. |
| **Compatibility alias** | Old name forwards to the new one. | Often no change needed. Verify the forward exists on the target release. |
| **Changed default** | Same API, different behavior when unspecified. | The dangerous one — no error, no warning, changed behavior. Usually server-visible. |
| **Changed signature** | Same name, different arguments or event payload. | Silent misbehavior in handlers. Read each call site. |
| **Private access** | Was never public API. | Must re-derive against the target source. |
| **Receiver-dependent** | The same method name exists on several classes and only some changed. | Determine the receiver's type per call site. Counting occurrences overstates the work, sometimes by an order of magnitude. |

**Statuses are release-specific.** Everything below is stated for the Ext 7.x line; the target for
this migration is **7.7.0.31**. A compatibility alias present in 7.0 can be gone by 7.9, and a class
deprecated in 7.4 can be removed later. Before any status drives a decision — especially a decision
to leave code alone — confirm it against 7.7.0's own API documentation and source viewer. Record the
release the check was made against and the date, so the next person knows how stale the answer is.

Three worked examples of why this matters:

- `getRootNode()` is **deprecated on `Ext.data.TreeStore`** (use `getRoot()`) but remains the normal,
  supported API on `Ext.tree.Panel`. In a codebase with hundreds of `getRootNode()` calls, the ones
  that need changing are only those whose receiver is a store — typically a small minority. A bulk
  rename breaks the tree panels.
- `root:` is **three different statuses under one search term**. On a reader it is *removed* with no
  alias and the failure is a silently empty grid. On a `Ext.data.writer.Json` it is a *compatibility
  alias* that still forwards to `rootProperty` and logs a warning. On a TreeStore or tree panel it is
  *unchanged* and correct. Counting `root:` hits as removed-API work overstates the job by a third or
  more. See `grid-and-data.md` section 3.
- `Ext.form.field.Trigger` is **deprecated but present in the target release**: confirmed against the
  7.7.0 classic API documentation (checked 2026-09-02), deprecated since 5.0 and still documented as
  "provided for compatibility reasons but is not used internally by the framework". Hundreds of
  `xtype: 'trigger'` sites are therefore deprecation debt to schedule, not a wall that blocks the
  upgrade. Custom subclasses that reach into `triggerCell`, `trigger1Cls`, or `onTrigger1Click` are
  the part that needs real work, because those are private-ish internals of a class the framework no
  longer maintains.

## 0a. Attributing breakage across three releases

"Direct 4 to 7" means one released target, not one mechanical transformation. A direct hop inherits
every breaking change from three major releases at once, so cumulative breakage is hard to
attribute: a failure could belong to any of them. Two ways to recover attribution:

1. **Bucket the findings by version.** Run the ESLint plugin, or the audit script, once per
   intermediate target and diff the reports. Work can then be planned as "the 4-to-5 work", "the
   5-to-6 work", without installing an intermediate framework. Do this by default.
2. **A throwaway intermediate build**, only when a specific class of breakage resists attribution.
   Nothing from that branch ships or merges.

Neither changes the released target, and neither is an excuse to ship an intermediate version.

## 1. Environment and boot

| Ext 4 | Ext 7 |
|---|---|
| Quirks or transitional doctype tolerated | HTML5 doctype required, plus `X-UA-Compatible: IE=edge` |
| IE6 and IE7 supported | Dropped in Ext 5. Remove IE6/IE7 browser-detection branches and their CSS. |
| `autoCreateViewport: true` | `mainView` on `Ext.app.Application` (`autoCreateViewport` deprecated in 5.1). `setMainView()` exists for cases where launch logic must run first. |
| Sync-ish load order tolerated | Loader is asynchronous. Missing `requires` surfaces as undefined classes at boot. |

In the classic toolkit, a `mainView` that does not extend `Ext.Viewport` is given a viewport plugin
automatically.

### Element ids

Ext 5 added id validation, `/^[a-z_][a-z0-9\-_]*$/i`, enforced in `Ext.get()` and the Component
constructor. Ids generated from server data — anything containing a dot, colon, slash, or leading
digit — now throw. Audit every place an id is built from a database key or a Java class name.

## 2. Class system and core

- `Ext.AbstractComponent`, `Ext.AbstractContainer`, `Ext.AbstractPanel`, and `Ext.dom.AbstractElement`
  were merged into their base classes. Any override or `callParent` chain targeting an `Abstract*`
  class breaks outright.
- The config system changed order: the Component constructor now calls `initConfig` **before**
  `initComponent`. Config setters, appliers, and updaters run during construction, and `callParent`
  is allowed in a custom setter. Ext 4 code that assigns instance properties in `initComponent` and
  expects them to be read later by the config system will misbehave.
- Related trap, seen repeatedly in real upgrades: `Ext.applyIf` inside `initComponent` becomes
  unreliable because the config may already be set. Unconditional `Ext.apply` is usually the fix,
  but decide per case rather than sweeping.
- `Ext.EventManager` is deprecated in favor of the `Ext.dom.Element` Observable API.
- `Ext.EventObject` as a stable singleton was removed in Ext 6; the object is only valid during
  event propagation. Code that stores it and reads it later gets stale or null data.
- `Ext.FocusManager` was removed. Focus and keyboard navigation are handled by the framework.
- `Ext.menu.MenuManager` no longer keeps a global menu registry; use `Ext.ComponentQuery`.
- `Ext.dom.Query` is no longer a default requirement — require it explicitly if used.
- `addListener()` and `removeListener()` no longer accept arrays of event names (Ext 6).
- Listener priority is now numeric `priority`. The `order` convenience methods
  (`onBefore`, `unBefore`, `onAfter`, `unAfter`, `addBeforeListener`, `addAfterListener`, and their
  removers) are deprecated.
- Declaratively defined listeners from superclasses and mixins are no longer replaced by subclass or
  instance listeners; they accumulate. Ext 4 code that relied on overriding a parent's `listeners`
  block now runs both. Override the handler method instead.
- `DomHelper`: attributes with `undefined` values produce no markup. Use `""` for valueless
  attributes.

### Element API removals

`Ext.dom.Element` no longer returns cached instances from its constructor — always use `Ext.get()`
or `Ext.fly()`. The `forceNew` constructor parameter is gone, `Ext.fly()` returns null for text
nodes, and listeners cannot be attached to flyweights. Removed or deprecated methods include
`getAttributeNS`, `isDisplayed`, `getStyleSize`, `getComputedWidth`, `getComputedHeight`,
`setLeftTop`, `setBounds`, `isBorderBox`, `relayEvent`, `isTransparent`, `replaceWith`, and
`Ext.dom.Element`'s own `setRegion` — which is **not** the `Ext.Component.setRegion()` named as the
`setBorderRegion()` replacement in section 3; check the receiver before acting on either.

`getHTML` is a **case rename, not a removal**: Ext 7 classic spells it `getHtml()`. The audit script
flags it under removed Element methods because the Ext 4 spelling does fail, and a hit on the boot
path is still a hard boot failure — a server-injected value read as
`Ext.get('someId').getHTML()` breaks before the application paints. Fix the casing rather than
redesigning the read.

## 3. Components, containers, layout

| Ext 4 | Ext 7 | Status |
|---|---|---|
| Component `margins` | `margin`, on the same component | Removed |
| Box-layout `defaultMargins` | **Not** `margin` on the layout. Move the value to the owning container's `defaults: { margin: … }`, then compare the screen against its phase 0 screenshot. | Removed |
| `setBorderRegion()` | `Ext.Component.setRegion()` (a border-layout component method, unrelated to the removed `Ext.dom.Element.setRegion`) | Removed |
| `setRegionWeight()` | `setWeight()` | Removed |
| `doLayout()` | `updateLayout()` | Removed in Ext 6 |
| `header.title` (string) | `header.getTitle().getText()` — the title is an `Ext.panel.Title` component, and the icon lives inside it | Changed signature |
| `titlePosition` | `iconAlign` | Removed |
| Container `move` event | Container `childmove` (resolves the clash with Component `move`) | Changed signature |
| `Ext.layout.container.Table` `cellId` | `cellCls` | Removed |
| `autoScroll` | `scrollable` | Receiver-dependent — verify per release and per class whether `autoScroll` still forwards; the two configs are not value-compatible (`autoScroll: true` maps to `scrollable: true`, but `scrollable` also takes `'x'`, `'y'`, and config objects) |

`margins` and `defaultMargins` share a search term and do not share a fix. `margins:` matches
inside `defaultMargins:`, so a single grep conflates a per-item rename with a container-level
restructure that changes which component owns the value. Split the hits before estimating, and treat
every `defaultMargins` site as a layout change needing a visual check rather than a rename.

`liquidLayout` defaults to true, so buttons and form fields size with CSS instead of a JavaScript
layout pass. Custom components that measured or corrected their own sizing in Ext 4 are the usual
casualties.

Container `items`/`floatingItems` and Panel `dockedItems` collections are destroyed and nulled on
component destruction (Ext 6). Teardown code that iterates them after destroy now throws.

Plugins are destroyed automatically with their component. Remove plugin code that listens for the
component's `destroy` event to clean itself up; it will double-destroy.

## 4. Forms

- Table-based internal field layout is gone; JavaScript no longer participates in field layout.
- Fields no longer shrink below their default width unless told to. Give the field a `width`, let
  the container layout set it, or make the container scrollable. This is the most common "the form
  suddenly overflows" symptom.
- `Ext.form.field.Trigger` is **deprecated but still present in 7.7.0** — confirmed against the
  7.7.0 classic API documentation (checked 2026-09-02): "This class has been deprecated. As of Ext JS
  5.0 this class has been deprecated. It is recommended to use a Ext.form.field.Text with the
  triggers config instead. This class is provided for compatibility reasons but is not used
  internally by the framework."
  Plain `xtype: 'trigger'` usage therefore keeps working and is scheduled debt. **Subclasses are the
  real work** — anything extending `Ext.form.field.Trigger` and touching `triggerCell`,
  `trigger1Cls`, `trigger2Cls`, `onTrigger1Click`, or the trigger markup depends on internals of an
  unmaintained class and should be re-derived against `Ext.form.field.Text` triggers. Text fields
  support a named `triggers` config:

  ```javascript
  triggers: {
      clear: {
          cls: 'my-clear-trigger',
          weight: 1,
          hideOnReadOnly: false,
          handler: function () { this.setValue(null); }
      }
  }
  ```

  Ext 4 `trigger1Cls` / `trigger2Cls` / `onTrigger1Click` patterns must be rewritten to named
  triggers.
- ComboBox `select` passes an array of records only when `multiSelect: true`. Single-select
  handlers that indexed `records[0]` need review.

## 5. MVC — what is preserved

Preserving MVC is the plan of record, and the framework supports it. In Ext 7 classic,
`Ext.app.Controller` still publicly provides `refs` (including `autoCreate` and `forceCreate`),
`control`, `listen`, `stores`, `models`, `views`, `id`, `application`, `getStore()`, `getModel()`,
`getView()`, `init()`, `activate()`, and `deactivate()`, none of them deprecated.

Rules for this migration:

- Global controllers stay global. Do not move `control` blocks into ViewControllers.
- Keep the `app/controller`, `app/model`, `app/store`, `app/view` classpath. Do not reorganize into
  a toolkit-split source tree unless the modern toolkit is actually adopted, which it is not.
- `Ext.app.Application`: replace `autoCreateViewport` with `mainView`. That is an allowed and
  necessary change, not an architecture change.
- One place where scope resolution intrudes: a **string** column renderer or handler is resolved
  against the component's scope chain in Ext 5+, which prefers a ViewController or an ancestor with
  `defaultListenerScope`. In Ext 4, a string renderer named an `Ext.util.Format` function. Verify
  each string renderer's behavior on the target release, and prefer either a real function or the
  `formatter` config over relying on either resolution rule.

## 6. Data package

See `grid-and-data.md`. It is the largest single area of change and has its own document.

## 7. Charts

The application's chart usage is limited, but if any exists:

- The Ext 4 chart package became the separate legacy `ext-charts` package in Ext 5 and was
  **discontinued** in Ext 6. There is no legacy chart option on Ext 7.
- The replacement is the `charts` package (called `sencha-charts` in Ext 5, renamed when the
  `sencha-` prefix was dropped in Ext 6). It must be declared in `app.json`.
- `Ext.chart.Chart` is replaced by the `cartesian` and `polar` xtypes.
- Polar series use `angleField` and `radiusField` instead of `field`/`xField` and
  `lengthField`/`yField`.
- Axis `renderer` and the `rangechange` listener now receive the axis as the first argument.
- `animate` became `animation`; `getBoundMarker` became `getMarker`.

Treat any chart as a rewrite, not a port, and budget it separately.

## 8. Accessibility validation (new in Ext 6)

Ext 6 added WAI-ARIA validation that logs console **errors** for non-compliant configs. On an Ext 4
codebase these fire immediately and in volume:

- A `Ext.button.Button` combining `menu` with `handler` or `href`. Global escape hatch is
  `Ext.enableAriaButtons = false`.
- Split buttons: `arrowHandler` combined with `menu` warns; split buttons now render two tab stops.
- `Ext.button.Cycle` is inherently non-compliant and warns at construction.
- Toolbars disable ARIA arrow-key navigation when a child consumes arrow keys; items then join the
  normal tab order.
- Windows trap focus by default; `tabGuard: false` disables it.
- Panel header tools join the tab order; border-layout panels get `ariaRole: "region"`.
- `Ext.Img` warns when `alt` is missing.

Fix the config where it is cheap — an `alt`, a menu button without a redundant handler. Use the
global flags only as a temporary, commented, tracked measure; they are the difference between a
console you can read and one you cannot.

## 9. Compatibility layer — and what it does not do

```json
"compatibility": { "ext": "4.2" }
```

Introduced for Ext 5. Where a framework class contains an explicit compatibility branch, this
setting activates it: the removed behavior is restored and a console warning replaces a hard
failure.

**Do not plan around it before proving it.** It enables framework-provided compatibility branches
only. It does not universally recreate removed APIs, and in particular it does not resurrect:

- removed `Ext.dom.Element` methods,
- UX classes that moved out of the framework,
- private or internal members an override depended on,
- changed DOM structure, generated markup, or CSS class names,
- changed defaults such as writer `writeAllFields`,
- changed event signatures.

Procedure: pick five failures from the phase 1 inventory that span different categories — a removed
Element method, a deprecated class, a changed default, a private-member override, a UX class — then
enable the setting and re-run. Record which of the five it actually mitigated. That list, not the
documentation, is what the setting is worth on this codebase. Verify it is still honored by the
target Ext 7 release at all before spending the time.

It must be removed before the migration is called complete, and the build and console must be clean
without it.

## 10. Detection tooling

Do not discover these changes by reading every file. Lint first:

- `@sencha/eslint-plugin-extjs` — 18 rules across four categories: overriding existing framework
  aliases, classes, and methods; use of deprecated classes, configs, methods, and properties; use of
  private members; and use of removed members. This is the CI-friendly form and the one to prefer.
- Ext JS Upgrade Adviser — the desktop application built on the same rules. Free to licensed Ext JS
  customers. Takes toolkit, current version, target version, and a source folder; produces a
  severity-ranked report, exportable to Excel, with autofixes for some findings.

Installation and configuration are in `tooling-and-build.md`.
