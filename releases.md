# Releases

## Unreleased

### JavaScript Test Packages

Live now uses Bake Node to install and project the JavaScript packages used by its browser integration tests. The generated static package manifest supplies the test page import map, while `node_modules` is treated as a disposable package-manager projection.

## v0.19.0

### Explicit Element Construction

Element construction now separates serialized element data from Ruby constructor options and makes the intended construction path explicit.

  - `Live::Element#initialize` now requires both `id` and `data`. Replace `MyView.new` with `MyView.root`, and replace `MyView.new("custom-id")` with `MyView.root("custom-id")`. Internal callers using `new` directly must pass the data hash explicitly, even when empty.
  - `Live::Element.root`, `.child`, and `.mount` now accept serialized attributes through `data:`. Other keyword arguments are forwarded to `initialize`. For example, change `MyView.root(mode: "presenter")` to `MyView.root(data: {mode: "presenter"})`; constructor dependencies such as `controller:` can remain ordinary keyword arguments.
  - Calls passing a positional data hash to `.mount` must use the `data:` keyword. Change `ChildView.mount(parent, "child", {mode: "compact"})` to `ChildView.mount(parent, "child", data: {mode: "compact"})`.
  - `Live::Resolver#root(view_class, id = view_class.unique_id, data: {}, **options)` constructs an allowed root using the same internal path as browser-resolved elements. Custom resolvers that inject dependencies can override the private `make(view_class, id, data, **options)` method instead of overriding `call`.

## v0.18.0

  - **Breaking Change**: Live now uses Web Components for managing life-cycle events instead of observers. You will need to use `live-js` v0.16.0 or later with this version of `live`, which emits `<live-view>` elements (instead of `<div>` elements).
      - Using older versions of `live-js` with this version of `live` may result in unexpected behavior or errors.
      - Using older versions of `live` with `live-js` v0.16.0 or later may also result in unexpected behavior or errors.
  - Updating both `live` and `live-js` to their latest versions is recommended to ensure compatibility, and requires no changes to application code.
