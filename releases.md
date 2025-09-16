# Releases

## Unreleased

  - **Breaking Change**: Live now uses Web Components for managing life-cycle events instead of observers. You will need to use `live-js` v0.16.0 or later with this version of `live`, which emits `<live-view>` elements (instead of `<div>` elements).
    - Using older versions of `live-js` with this version of `live` may result in unexpected behavior or errors.
    - Using older versions of `live` with `live-js` v0.16.0 or later may also result in unexpected behavior or errors.
  - Updating both `live` and `live-js` to their latest versions is recommended to ensure compatibility, and requires no changes to application code.
