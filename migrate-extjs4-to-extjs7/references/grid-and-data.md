# Grid and Data Package: Ext JS 4 to 7

The data package was rewritten in Ext 5 and the grid was rebuilt on top of it. This is where most of
the migration effort and nearly all of the silent, server-visible breakage lives.

**Server-contract warning.** Several defaults changed in ways that alter what the backend receives
without producing a client-side error. Compare payloads against the phase 0 capture for every store
that writes.

## 1. Model

| Ext 4 | Ext 7 |
|---|---|
| `raw` property holding the untouched source object | Removed — but `data` is not a substitute for it. See below. |
| Undeclared fields pruned on load | Undeclared fields are retained |
| `modified` returns `{}` when unchanged | Returns `undefined`. Use `isModified()`, `getModified()`, `getChanges()`. |
| `destroy()` deletes on the server | `destroy()` releases client resources. `erase()` deletes on the server. `drop()` marks a record removed without saving. |
| `persistenceProperty` | Removed |
| `validations` array | `validators`, and per-field `validators` config |
| `belongsTo`, `hasMany`, `associations` | Field-level `reference` config, resolved through `Ext.data.schema.Schema` |
| `Ext.data.ModelManager` | Deprecated; the schema owns model and association registration |
| `Ext.data.Types` static type registry | Deprecated; fields are classes under `Ext.data.field.*` |
| Field `useNull` | `allowNull` |

**`raw` is not `data`.** They diverge wherever a field declares `convert`, a `type` that coerces, or
a `defaultValue`: `raw` holds the untouched response value and `data` holds the post-conversion one.
A mechanical `.raw` → `.data` pass therefore changes values without raising anything, which is the
worst way for a data migration to change a value. Resolve each call site instead:

- one application value — `record.get('field')`, the public accessor, and the right answer nearly
  every time;
- the whole converted object, deliberately — `record.data`;
- the original unconverted response, deliberately — configure the reader with the target release's
  `keepRawData` equivalent, read it from the reader, and record why conversion has to be bypassed.

Nested reads like `rec.raw.someList` deserve the hardest look: they are usually reaching for server
structure that no field declares, so neither `get()` nor `data` will contain it.

New field capabilities worth knowing while porting, but not worth adopting speculatively:
`calculate` (auto-derives dependencies), `depends` (explicit dependency list for `convert`),
`reference`, and `validators`. Register a custom field type by giving a class an alias and using it
as the field's `type`.

An auto-generated `id` is assigned when none is supplied, and `internalId` is generated separately
and is never the same value.

### Phantom record ids — a real server break

Ext 5+ phantom records get **string** ids of the form `MyApp.model.Thing-1`, not the integer-ish
values Ext 4 produced. Any Java-side code that parses, casts, or numerically compares an incoming id
will fail on create. Decide explicitly: change the client's `identifier`, or handle the new format
server-side. Do not discover this in production.

## 2. Store

| Ext 4 | Ext 7 |
|---|---|
| `buffered: true` | `type: 'buffered'` (`Ext.data.BufferedStore`) |
| `groupers` | `grouper` |
| `destroyStore()` | Deprecated; `destroy()` releases resources |
| `remove` fires once per record | Fires once per removal operation, with the records |
| `add` fires per record | Fires once per contiguous added range |
| `datachanged` fired inconsistently | Fired consistently |

`getById()` and `getByInternalId()` are map-backed and O(1). `beginUpdate()` / `endUpdate()` batch
notifications, with matching events — useful where Ext 4 code suspended events manually.

Handlers written against the per-record Ext 4 signatures are the common failure: an `add` or
`remove` listener that assumed one record now receives a set.

### TreeStore

- `getRootNode()` / `setRootNode()` → `getRoot()` / `setRoot()`. **Receiver-dependent, and the most
  over-counted item in a tree-heavy codebase.** The deprecation is on `Ext.data.TreeStore`.
  `Ext.tree.Panel.getRootNode()` is not deprecated and remains the ordinary way to reach a tree's
  root. Before changing any call site, determine the receiver's type:

  | Receiver | Action |
  |---|---|
  | `Ext.tree.Panel` or a subclass (`treePanel.getRootNode()`, `myTree.getRootNode()`) | No change |
  | `Ext.data.TreeStore` (`store.getRootNode()`, `treeStore.getRootNode()`) | Change to `getRoot()` |
  | `this` / `me` inside a class | Resolve what the class extends, then apply the rows above |
  | A local variable of unclear type | Read the assignment; do not guess from the name |

- The `load` event signature now matches `Ext.data.Store`
- Relayed node events are prefixed with `node`
- Heterogeneous children: `childType` on the model, or `typeProperty` on the reader

## 3. Proxy, reader, writer, operation

| Ext 4 | Ext 7 |
|---|---|
| Reader `root` | `rootProperty`. **No alias.** `Ext.data.reader.Reader` has no legacy `root` handling; the reader finds no records and the grid is silently empty. |
| Writer `root` | `rootProperty`, but the old name still works — see below. |
| Writer `writeAllFields` defaults to `true` | Defaults to **`false`** |
| Reader keeps `rawData` | Not retained by default; opt in with `keepRawData` |
| `store.loadRawData()` | Unchanged and still supported — not the same thing as `reader.rawData` |
| `Ext.data.Operation` single class | Split into four CRUD subclasses |
| `proxy.doRequest(operation, callback, scope)` | Takes a single Operation argument |
| `proxy.extraParams.foo = x` | `setExtraParams()` / `getExtraParams()` |
| `Ext.data.writer.Json.getExpandedData()` | Removed (Ext 6) |

### `root` is two different statuses, not one

This is the most commonly mis-triaged item in a data-heavy Ext 4 codebase, because one search term
covers three unrelated configs.

| Where `root` appears | Status on Ext 7 | Action |
|---|---|---|
| Reader (`reader: { root: 'rows' }`) | **Removed.** No alias, no warning. | Rename to `rootProperty`. The failure mode is an empty grid, not an exception. |
| Writer (`writer: { root: 'jsonRequest' }`) | **Compatibility alias.** `Ext.data.writer.Json` copies `root` to `rootProperty` in its constructor and logs a deprecation warning. | Works as-is, and may stay: a verified compatibility alias is accepted debt, and the wire format is identical either way. Rename it only if the writer is being edited for another reason. Never before boot. |
| TreeStore / tree panel (`root: { text: '...', expanded: true }`) | **No change.** `root` is still the supported config. | Leave it alone. |

The writer alias in Ext 7.9:

```javascript
if (config && config.hasOwnProperty('root')) {
    config = Ext.apply({}, config);
    config.rootProperty = config.root;
    delete config.root;
    Ext.log.warn('Ext.data.writer.Json: Using the deprecated "root" configuration. ' +
        'Use "rootProperty" instead.');
}
```

Confirm this is still present in the exact target release before relying on it — a compatibility
alias is a candidate for removal in any future version, and the status above is stated for the 7.x
line, not guaranteed for every patch level.

Split the audit count three ways before estimating. A single `root:` grep over a large application
routinely overstates the removed-API work by a third or more.

**`writeAllFields` is the single highest-impact change in this document.** Ext 4 sent complete
records on update; Ext 7 sends only changed fields. A Java endpoint that binds a full DTO and
persists it will now null out every field the client did not touch — data loss, on save, with no
client-side error and no build failure.

The exposure is proportional to how few stores set it explicitly. Count the writers in the codebase
and count the `writeAllFields` occurrences: the difference is the number of stores whose write
contract silently changes. In most Ext 4 applications that difference is "almost all of them".

The default for this migration is to set `writeAllFields: true` and preserve the Ext 4 contract.
Changing an endpoint to accept partial updates is a backend change with its own tests, not something
to absorb into a framework upgrade. Whichever way each store goes, prove it by diffing an actual
update payload against the phase 0 capture.

`keepRawData` matters wherever code reached into the reader for envelope data outside the records:
metadata, totals, server messages. The exact opt-in config name has varied across 5.x and 6.x
(`preserveRawData` appears in some releases); confirm the name in the target release's docs rather
than copying from a blog post.

`Ext.data.Session` exists for coordinated multi-record editing. It is not part of this migration.
Do not introduce it.

## 4. Grid

### Buffered rendering is on by default

The grid renders only visible rows plus a buffer zone. Consequences:

- `verticalScroller` is ignored; the Ext 4 paging-scroller configuration is gone.
- Code that queried the DOM for all rows, or measured the full table, sees only rendered rows.
- Variable row heights need `variableRowHeight: true` **on the column** that varies. Without it the
  grid mismeasures and scrolling jumps.

Disabling `bufferedRenderer` per grid is legitimate when a specific grid genuinely cannot work with
it and that is documented. Disabling it application-wide to avoid fixing row heights is not.

### Renderers and cell updates

- A renderer may be declared as a **string** method name, resolved against the component's scope
  chain. See the caution in `upgrade-map.md` section 5 — in Ext 4 a string named an
  `Ext.util.Format` function, so verify each one.
- `formatter` config offers template-style formatting: `formatter: 'round(2)'`,
  `formatter: 'date("Y-m-d")'`. A `"this."` prefix resolves against the column `scope`.
- An `updater` method can refresh an existing cell without a full re-render. It is bypassed if a
  custom renderer declares extra arguments.
- `throttledUpdate: true` on the grid coalesces rapid updates, flushing on `updateDelay`
  (200ms default). Useful for grids fed by frequent server pushes.

### Grid filters: feature to plugin

Ext 4's `Ext.ux.grid.FeatureFilter` style configuration is gone. Filtering is the
`Ext.grid.filters.Filters` plugin, configured per column:

```javascript
{
    dataIndex: 'status',
    filter: {
        type: 'string'
    }
}
```

The filter type is inferred from the model's field definition when omitted. In practice this touches
nearly every column of every filtered grid — treat it as a mechanical pass with a per-grid
verification.

**Remote filtering and sorting: the server's parser is the contract.** Where a store sets
`remoteFilter` or `remoteSort`, do not assume the target release serializes filters and sorters the
way Ext 4 did. The parameter names (`filterParam`, `sortParam`, `groupParam`, and the
`directionParam` / `simpleSortMode` pair), the JSON shape of each encoded filter, and the encoders
themselves (`encodeFilters` / `encodeSorters` on the proxy) are all configurable — and the backend
parser is the side that cannot change. So capture the Ext 4 request first, then pin what the existing
server expects explicitly on the existing proxy, parameter name and encoded shape both, rather than
inheriting the target release's defaults. A filter that serializes differently returns the wrong rows
under a 200 status, which no console gate and no exception handler will catch.

Local filtering carries no such exposure. Confirm the store does not set `remoteFilter: true`, since
client-side filtering is the default. `updateBuffer` from the Ext 4 feature belongs on the individual
column filter, not on the plugin.

### Other grid changes

- `Ext.grid.column.Widget` renders a real component per cell, bound to the column's `dataIndex`
  through the widget's `defaultBindProperty`. A replacement for Ext 4 action-column and
  render-a-button-in-HTML hacks — adopt it only where the Ext 4 hack no longer works.
- Locked grids: `CellEditing` is no longer cloned into sub-grids, and configuring it on
  `lockedGridConfig` or `normalGridConfig` is invalid. Configure it once on the grid.
- View `itemremove` fires once per removed block, with the items in an array (Ext 6).
- Selection: verify the selection model configuration and event signatures for the target release
  against its Classic API Diff guide. Selection was reworked across 6.x and the details differ by
  release.

## 5. Porting checklist per store-backed screen

1. Model: `raw` reads resolved per call site — `get()`, `data`, or `keepRawData`, never a blanket
   `.raw` → `.data` — `validations` → `validators`, associations → `reference`, `useNull` →
   `allowNull`, remove `persistenceProperty`.
2. Store: `buffered` → `type: 'buffered'`, `groupers` → `grouper`, review `add`/`remove` handlers
   for the new batched signatures.
3. Reader/writer: `root` → `rootProperty`, set `writeAllFields: true` unless the server was changed,
   restore raw-envelope access with the target release's `keepRawData` equivalent.
4. Proxy: `extraParams` through the setter; check `doRequest` overrides.
5. Grid: filters to the plugin, `variableRowHeight` where rows vary, review string renderers, remove
   `verticalScroller`. On a remote-filtered or remote-sorted store, pin the parameter names and the
   encoded shape the existing server parses.
6. Verify: payload diff against the phase 0 capture, create/update/delete round-trip against the
   real backend, sort, filter, page, scroll to the end of a large result set.
