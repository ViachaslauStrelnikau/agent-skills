# Overrides, Custom Components, and Ext.ux

This is the code most likely to break silently. Framework API changes announce themselves; an
override that still applies cleanly to a method whose contract changed underneath it does not.

## 1. Why overrides are the high-risk category

An Ext 4 override exists for one of a few reasons, and each has a different fate on Ext 7:

| Reason it was written | Fate on Ext 7 |
|---|---|
| Works around an Ext 4 bug | Usually fixed upstream. Deleting it is correct; keeping it may re-break the fixed behavior. |
| Adds behavior the framework never had | Port it. It is application code wearing an override's clothes. |
| Patches a private method | The riskiest. Private members change without notice between releases. |
| Targets an `Abstract*` class | Hard failure — those classes were merged into their base classes. |
| Adjusts layout or sizing | Probably obsolete. `liquidLayout` and the removal of table-based field layout changed the ground under it. |

Never delete an override because it looks old, and never keep one because deleting it feels risky.
Establish which of the rows above it is, then decide, then write the reason in a comment.

## 2. Inventory procedure (phase 0)

1. Find every override. Search for `Ext.override(`, `override:` in `Ext.define`, direct prototype
   assignment (`SomeClass.prototype.method =`), and anything under an `overrides/` folder or the
   `overrides` entry in `app.json`.
2. For each one record: target class and member, whether the member is public or private in Ext 4,
   the reason (from comments, commit message, or issue tracker), and the screens it affects.
3. Run `@sencha/eslint-plugin-extjs`. Its four override rules flag overrides of existing framework
   aliases, classes, and methods, and calls to overridden methods; its private-member rules flag the
   rest of the exposure. This turns "we have a lot of overrides" into a list.
4. Mark every override that targets a private member, an `Abstract*` class, a layout method, or a
   data-package internal as **must re-derive**, not **must port**.

Carry this inventory as a working document for the whole migration. Each entry ends in one of three
states: deleted (with the reason it is no longer needed), ported (with the reason it is still
needed), or replaced by a supported API.

## 3. Re-deriving an override

For each `must re-derive` entry:

1. Read the Ext 7 source of the target member. The docs are not enough — you are checking whether
   the behavior the override compensated for still exists.
2. Decide whether the framework now does the thing natively. Several Ext 4-era override motives were
   absorbed: focus management (`Ext.FocusManager` removed and replaced by built-in handling), grid
   row buffering, cell updating without a full re-render (`updater`), field triggers (`triggers`
   config), and grid filtering (`Ext.grid.filters.Filters`).
3. If it is still needed, rewrite it against the Ext 7 member signature rather than adapting the Ext
   4 body. Copy-adapting an old override body is how a subtle behavior difference survives.
4. Prefer, in order: a config the framework already offers; a subclass; a plugin; an override of a
   public member; an override of a private member as the last resort, commented with why nothing
   else worked.

## 4. Custom components

Ext 4 custom components most often break on the constructor and layout changes:

- **`initConfig` now runs before `initComponent`.** Ext 4 components that set properties in
  `initComponent` and expected the config system to pick them up will not behave the same. Config
  appliers, setters, and updaters all run during construction, and `callParent` is allowed inside a
  custom setter.
- **`Ext.applyIf` inside `initComponent`** becomes unreliable for the same reason — the config may
  already be assigned. Switch to unconditional `Ext.apply` where that is what was meant, deciding
  case by case rather than sweeping the codebase.
- **`Abstract*` base classes are gone.** A component extending `Ext.AbstractComponent` or
  `Ext.AbstractPanel` must extend the concrete base class.
- **`doLayout()` was removed** in favor of `updateLayout()`. Components that forced layout passes are
  usually doing so because of an Ext 4 layout bug; check whether the call is needed at all before
  translating it.
- **`liquidLayout` defaults to true.** Components that measured themselves or corrected their own
  size in JavaScript are the ones to re-check first.
- **Declarative listeners accumulate.** A subclass `listeners` block no longer replaces the parent's;
  both run. Override the handler method instead.
- **Plugins are auto-destroyed with their component.** Remove plugin self-cleanup wired to the
  component's `destroy` event.
- **Collections are nulled on destroy.** Container `items` and `floatingItems`, and Panel
  `dockedItems`, are destroyed during teardown. Custom destroy logic that iterates them afterwards
  throws.
- **Element ids.** A component that builds its own id from server data must satisfy
  `/^[a-z_][a-z0-9\-_]*$/i`.

## 5. Ext.ux

`Ext.ux` moved out of the framework into a separate `ux` package in Ext 6. To keep using it, declare
it in `app.json`:

```json
"requires": [
    "ux"
]
```

Then check each `Ext.ux` class individually. The package is not a stable API and several Ext 4-era
UX classes were absorbed, replaced, or dropped. The two most commonly hit:

- Grid filtering. The Ext 4 UX grid-filter feature is replaced by the supported
  `Ext.grid.filters.Filters` plugin. Migrate to the plugin rather than trying to keep the UX version
  working; see `grid-and-data.md`.
- Any UX class the application forked locally. A forked UX class is application code — treat it as a
  custom component, not as a framework dependency.

## 6. Event and DOM-level custom code

- `Ext.EventManager` is deprecated; use the `Ext.dom.Element` Observable API.
- `Ext.EventObject` is no longer a stable singleton — it is only valid during propagation. Code that
  cached it reads stale data with no error.
- Element flyweights cannot carry listeners, and `Ext.get()` / `Ext.fly()` no longer return cached
  instances the way Ext 4 did.
- Several `Ext.dom.Element` methods were removed outright: `getAttributeNS`, `isDisplayed`,
  `getStyleSize`, `getComputedWidth`, `getComputedHeight`, `setLeftTop`, `setBounds`, `isBorderBox`,
  `relayEvent`, `isTransparent`, `getHTML`, `replaceWith`, `setRegion`.
- `Ext.dom.Query` is no longer required by default.
- Listener priority is numeric `priority`; the `onBefore` / `onAfter` family is deprecated.

## 7. Definition of done for this area

- Every inventory entry is in a terminal state: deleted, ported, or replaced by a supported API.
- Every retained override and custom component carries the JSDoc required by the skill's comment
  rule: what framework behavior it modifies, and which Ext version last validated it.
- No override targets a private member without a comment explaining why no supported alternative
  exists.
- The lint report shows no override or private-member finding that is not accounted for in the
  inventory.
