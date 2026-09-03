# Theming and SASS: Ext JS 4 to 7 (classic)

The goal for this migration is that users cannot tell the framework changed. Ext 7 classic still
ships `theme-classic`, the Ext 4 blue look, which is why it is the target. Everything below serves
visual parity, not restyling.

## 1. The compiler changed: Compass to Fashion

| Ext 4 | Ext 7 |
|---|---|
| Ruby Sass plus Compass, invoked by Sencha Cmd | Fashion, a JavaScript SCSS compiler |
| Ruby 1.8–2.0.x required on every build machine and CI agent | No Ruby. Node 8+ and npm 5+ required for the Fashion module. |
| Full recompile per change | Live Update: Fashion injects CSS into the running page under `sencha app watch` |

Ruby is only needed while the Ext 4 (or 5) build still has to run. Once phase 1 completes, remove
Ruby and Compass from the build documentation, the developer setup instructions, and the CI image.

Consequences for existing SCSS:

- Fashion is compatible with CSS3 syntax and most of the sass-spec suite, so ordinary SCSS carries
  over. Plain variables, nesting, mixins, and functions are fine.
- **Anything that depended on Compass is gone** — Compass mixins, helpers, and its Ruby-implemented
  functions. Each one needs a hand-written equivalent, or a JavaScript function loaded through
  Fashion's `require()`. Inventory Compass usage in phase 0; it is a fixed, countable list and it is
  better known early.
- Fashion adds **dynamic variables**, declared with `dynamic()`. They are evaluated in dependency
  order rather than source order, hoisted ahead of other Sass, and a plain variable referenced by a
  dynamic one is elevated to dynamic. They may only be assigned at file scope, never inside a
  control structure. Framework theme variables are dynamic — this is what allows live theme editing.
  Ext 4 SCSS that reassigned framework variables inside an `@if` or a mixin will not behave as
  written.

## 2. Package naming and layout

Ext 6 dropped the `ext-` and `sencha-` package prefixes:

| Ext 4 / 5 | Ext 6 / 7 |
|---|---|
| `ext-theme-classic` | `theme-classic` |
| `ext-theme-neptune` | `theme-neptune` |
| `ext-theme-gray` | `theme-gray` |
| `sencha-charts` | `charts` |
| `ext-charts` | discontinued |
| `ext-aria` | removed; accessibility is in the core |

Classic-toolkit themes live under `classic/` in the SDK: `theme-base`, `theme-neutral`,
`theme-classic`, `theme-gray`, `theme-neptune`, `theme-neptune-touch`, `theme-crisp`,
`theme-crisp-touch`, `theme-triton`. Triton is the Ext 6+ default and is **not** the target here.
Graphite and Material are modern-toolkit themes and are out of scope entirely.

Theme inheritance: `theme-classic` extends `theme-neutral`; `theme-crisp` and `theme-triton` extend
`theme-neptune`.

## 3. Choosing the theme in app.json

```json
"toolkit": "classic",
"theme": "theme-classic"
```

If the application has its own theme package, it should extend `theme-classic` for this migration.
A custom theme that extended an Ext 4 theme package needs its `extend` updated to the unprefixed
name in the package's own `package.json`.

## 4. Where SCSS lives under Cmd 6/7

Cmd 6 moved style configuration out of `.sencha/app/sencha.cfg` (`app.sass.*` properties) and into a
`sass` object in `app.json`, with `namespace`, `etc`, `var`, and `src`:

- `sass/etc/` — global definitions, mixins, and non-variable Sass, included first.
- `sass/var/` — variable declarations, mirroring the class hierarchy by file path.
- `sass/src/` — rules, mirroring the class hierarchy by file path.

The `namespace` maps a class name to a file path: `MyApp.view.user.Grid` maps to
`sass/var/view/user/Grid.scss` and `sass/src/view/user/Grid.scss`. Ext 4 apps that kept all styling
in one large SCSS file will build as-is, but placing per-component variables in the mapped location
is what makes the theme package predictable. Do that opportunistically per screen, not as a
migration-wide reorganization.

The `css` array in `app.json` gains a bundle entry along the lines of:

```json
{ "path": "${build.out.css.path}", "bundle": true, "exclude": ["fashion"] }
```

`sencha app upgrade` writes this. Do not hand-edit it unless it is wrong.

## 5. SASS variable changes to expect

Renamed and removed variables span three major versions, so the reliable procedure is: build, read
the Fashion errors, and resolve each against the target release's theming documentation. Known
examples from the 4-to-5 transition:

- Removed: `$tab-left-rotate-direction`, `$tab-right-rotate-direction` (the tab `rotation` config
  replaces them); `$form-field-font` and `$form-toolbar-field-font` (use the size/family/weight
  variants).
- Changed type: `$tab-text-padding` takes a single number, not a list. The `$ui-text-padding`
  parameter of the tab and button UI mixins likewise.
- Renamed: `$tip-header-body-padding` → `$tip-header-padding`, and the `extjs-tip-ui()` parameter
  `$ui-header-body-padding` → `$ui-header-padding`.
- Menu and toolbar scroller images were renamed to include the UI name, for example
  `menu/scroll-bottom.png` → `menu/default-scroll-bottom.png`. Custom themes referencing the old
  filenames render missing images rather than failing the build.

## 6. Structural CSS assumptions that break

The largest source of visual defects is not variables but custom CSS written against Ext 4 markup:

- Form fields no longer use table-based internal layout. Selectors targeting the old table, row, or
  cell structure hit nothing.
- Panel titles are `Ext.panel.Title` components, and the icon lives inside the title rather than
  beside it in the header.
- Buttons and fields use CSS-driven `liquidLayout` sizing.
- Framework-generated class names and element hierarchies changed broadly across 5 and 6.

Grep the application CSS and theme package for `x-` prefixed framework class names and treat each
one as a review item. A selector that silently stops matching produces a visual defect with no
console output, which is exactly what the phase 0 screenshots exist to catch.

## 7. Verification for theming work

This is the bar for **deliberate theming work** — someone editing the theme package, a SASS
variable, or a `.x-` selector. It is deliberately higher than the migration-wide visual gate, which
is structural for this pass (`SKILL.md`, Fixed decisions, Visual threshold). Touching the style
pipeline is the one activity where the deferred items are the whole point of the change, so they
come back into scope for it.

- Fashion build clean, no missing-variable or missing-function errors.
- Side-by-side screenshot comparison against the phase 0 baseline for every screen the change can
  reach, at the resolutions the users actually run, with the viewport pinned to the baseline's.
- Check the states that screenshots miss: hover, focus, disabled, invalid fields, selected grid
  rows, collapsed panels, and any print stylesheet.
- Missing-image check: no 404s for theme resources in the network log. This one is **not** deferred
  anywhere: a renamed theme image is a missing icon with no console error, so it is on the
  structural gate's artifact list too.
