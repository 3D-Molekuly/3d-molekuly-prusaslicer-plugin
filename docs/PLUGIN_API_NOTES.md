# PrusaSlicer 3.0 plugin API notes

What we learned while building this plugin against PrusaSlicer **3.0.0-alpha14**. The Lua plugin
API is experimental, so re-check these against the current source before relying on them.

## Sources

- [`ProjectApi.cpp`](https://github.com/prusa3d/PrusaSlicer/blob/master/src/slic3r-shared/src/Slic3r/App/Lua/ProjectApi.cpp):
  the actual API (`api.*`, `add_object`, mesh primitives, config access) with LuaLS annotations.
  The most reliable reference.
- [`doc/Plugin_API.md`](https://github.com/prusa3d/PrusaSlicer/blob/master/doc/Plugin_API.md):
  official getting-started guide: manifest fields, `info` table, parameter types. Incomplete
  (e.g. it omits the `string` and `combobox` parameter types).
- Other files in the same folder: `PluginDialog.cpp` (how the dialog renders parameters),
  `PluginBundle.cpp` (manifest parsing, bundle loading, signature check), `PluginSystem.cpp`.
- Example plugins shipped with PrusaSlicer: `Contents/Resources/lua/` in the macOS app
  (calibration towers, print modes) and `Contents/Resources/lua_template/` (template of
  `PrusaSlicer plugin init`).
- [leotrax3d/prusaslicer-plugins-unofficial](https://github.com/leotrax3d/prusaslicer-plugins-unofficial):
  community plugins; its `DEVINFO.md` collects practical findings about the API.
- [prusa3d/plugin-marketplace-example](https://github.com/prusa3d/plugin-marketplace-example):
  minimal plugin that publishes itself to the marketplace.

## Loading

- Every `.lua` file in the bundle is first run in a **bare engine without `require` and
  without `api`**, only to read the global `info` table. A top-level `require(...)` or `api.…`
  call makes loading fail ("Failed loading plugin"). Call `require` inside `execute()` or
  resolve modules lazily. Files without `info` are logged as "may be a shared module", which is
  fine.
- Plugin errors (from `error()` or a failed `require`) are only written to
  `<PrusaSlicer3 folder>/shared_runtime/log.txt`; the user sees nothing. This plugin embosses the
  error message onto the bed instead.
- `print()` also goes to the log.

## Dialog parameters

- Types: `float`, `int`, `bool`, `string` (single-line field), `combobox` (with
  `allowed_values`), `font`.
- Labels must be single-line: a `\n` in a label breaks the rendering of the whole dialog.
- A very long text in a `string` field (hundreds of kB) breaks the rendering too.
- The dialog remembers the last values per parameter name. Decimal defaults (e.g. `0.4`) were
  seen arriving as `0`, so validate numbers and fall back to defaults.

## Meshes and objects

- Primitives: `api.make_cube(w, h, d)` (origin at a corner), `make_sphere(r, fa)`,
  `make_cylinder(r, h, fa)`, `make_cone`, `make_torus`, … `fa` is the facet angle **in degrees**,
  default 1°, which gives ~82k triangles per sphere. Pass a larger angle for small parts.
- `Mesh` exposes `bounds()` and `translate(x, y, z)`; triangles cannot be read or built.
- `api.project:add_object{ mesh, translate, rotate, object_params, other_volumes }`:
  - top-level `translate`/`rotate` apply to the **main volume only**, not to the object;
  - the instance is centered on the bed with z = 0, so give every volume an absolute position;
  - `rotate = { x, y, z }` in degrees, applied X, then Y, then Z, about the volume origin, before
    `translate`.
- A volume in `other_volumes` that has `params` but no `type` becomes a **modifier**. Set
  `type = VolumeType.Solid` for printed parts with their own settings (e.g. `extruder`).
- Volumes cannot be named. Volume types: `Solid`, `Negative`, `Modifier`, `SupportBlocker`,
  `SupportEnforcer`.

## Config access

- `bed:print_presets()`, `printer_presets()`, `tool_print_presets(i)`, `material_presets(i)`
  return config boxes with `value(name)` and `set(name, value)`.
- `set` only writes numbers, percentages and enums; strings (e.g. `filament_colour`) silently
  fail. Unknown keys only log an error.
- `value` can read strings. `material_presets(i)` with an index past the last filament raises a
  normal Lua error, so it can be probed with `pcall`.
- Plugins cannot add filaments or tools; that comes from the printer preset.

## Ids, signing and the CLI

- No part of the plugin id may start with a digit (`cz.vscht.3dmolekuly…` is rejected as "not in
  reverse DNS form").
- `PrusaSlicer plugin init | keygen | sign`: `sign` writes `manifest.txt` (SHA-256 of every file)
  and `manifest.sig` into the bundle folder and a flat zip next to it.
- Renaming menu entries (plugin or `info.id` changes) and then using *Rescan plugins* can leave a
  stale entry in the native macOS menu that crashes PrusaSlicer when clicked. Restart instead.

## Sandbox

- No network and no file access outside the bundle (`api.load_stl` only loads files shipped in
  the bundle). There is no API to open a URL or a window.
- The `prusaslicer://open?file=` URL scheme only downloads from allowed Prusa domains, so a web
  app cannot push a model into PrusaSlicer that way either.
