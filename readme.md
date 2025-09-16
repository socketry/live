# Live

Provides bi-directional live HTML views using WebSockets for communication. You can try out a [live example](https://utopia-falcon-heroku.herokuapp.com/live/index)

[![Development Status](https://github.com/socketry/live/workflows/Test/badge.svg)](https://github.com/socketry/live/actions?workflow=Test)

## Features

  - Transparent support for both static initial rendering and dynamic updates.
  - Bi-directional event handling for seamless client/server implementation.
  - Event-driven architecture for efficient handling of thousands of active connections.

## Usage

Please see the [project documentation](https://socketry.github.io/live/) for more details.

  - [Getting Started](https://socketry.github.io/live/guides/getting-started/index) - This guide explains how to use `live` to render dynamic content in real-time.

  - [Rails Integration](https://socketry.github.io/live/guides/rails-integration/index) - This guide explains how to use the `live` gem with Ruby on Rails.

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.

## Releases

Please see the [project releases](https://socketry.github.io/live/releases/index) for all releases.

### v0.18.0

  - **Breaking Change**: Live now uses Web Components for managing life-cycle events instead of observers. You will need to use `live-js` v0.16.0 or later with this version of `live`, which emits `<live-view>` elements (instead of `<div>` elements).
      - Using older versions of `live-js` with this version of `live` may result in unexpected behavior or errors.
      - Using older versions of `live` with `live-js` v0.16.0 or later may also result in unexpected behavior or errors.
  - Updating both `live` and `live-js` to their latest versions is recommended to ensure compatibility, and requires no changes to application code.

## See Also

  - [live-js](https://github.com/socketry/live-js) – The client-side JavaScript library.
  - [morphdom](https://github.com/patrick-steele-idem/morphdom) – Efficiently update the client-side HTML.
  - [stimulus-reflex](https://github.com/hopsoft/stimulus_reflex) — An alternative framework which provides similar functionality.

### Examples

  - [Flappy Bird](https://github.com/socketry/flappy-bird) – A clone of the classic Flappy Bird game.
