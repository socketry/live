# Live.js

A JavaScript client library for building interactive web applications with Ruby Live framework.

[![Development Status](https://github.com/socketry/live-js/workflows/Test/badge.svg)](https://github.com/socketry/live-js/actions?workflow=Test)

## Features

- **Real-time Communication**: WebSocket-based client-server communication.
- **DOM Manipulation**: Efficient updating, replacing, and modifying HTML elements.
- **Event Forwarding**: Forward client events to server for processing.
- **Controller Loading**: Declarative JavaScript controller loading with `data-live-controller`.
- **Automatic Cleanup**: Proper lifecycle management and memory cleanup.
- **Live Elements**: Automatic binding and unbinding of live elements.

## Usage

### Installation

```bash
npm install @socketry/live
```

### Basic Setup

```javascript
import { Live } from '@socketry/live';

// Start the live connection
const live = Live.start({
  path: 'live',  // WebSocket endpoint
  base: window.location.href
});
```

### Controller Loading

Live.js supports declarative controller loading using the `data-live-controller` attribute:

```html
<div class="live" id="game" data-live-controller="/static/game_controller.mjs">
  <!-- Game content -->
</div>
```

```javascript
// game_controller.mjs
export default function(element) {
  console.log('Controller loaded for:', element);
  
  // Setup your controller logic
  element.addEventListener('click', handleClick);
  
  // Return a controller object with cleanup
  return {
    dispose() {
      element.removeEventListener('click', handleClick);
    }
  };
}
```

## API Reference

### Live Class

#### Static Methods

- `Live.start(options)` - Create and start a new Live instance
  - `options.window` - Window object (defaults to globalThis)
  - `options.path` - WebSocket path (defaults to 'live')
  - `options.base` - Base URL (defaults to window.location.href)

#### Instance Methods

##### Connection Management
- `connect()` - Establish WebSocket connection
- `disconnect()` - Close WebSocket connection

##### DOM Manipulation
- `update(id, html, options)` - Update element content
- `replace(selector, html, options)` - Replace elements
- `prepend(selector, html, options)` - Prepend content
- `append(selector, html, options)` - Append content  
- `remove(selector, options)` - Remove elements

##### Event Handling
- `forward(id, event)` - Forward event to server
- `forwardEvent(id, event, detail, preventDefault)` - Forward DOM event
- `forwardFormEvent(id, event, detail, preventDefault)` - Forward form event

##### Script Execution
- `script(id, code, options)` - Execute JavaScript code
- `loadController(id, path, options)` - Load JavaScript controller

##### Event Dispatching
- `dispatchEvent(selector, type, options)` - Dispatch custom events

### Options Parameter

Most methods accept an `options` parameter with:
- `options.reply` - If truthy, server will reply with `{reply: options.reply}`

### Controller Pattern

Controllers are JavaScript modules that manage view-specific behavior:

```javascript
// Simple controller
export default function(element) {
  // Setup code
  return {
    dispose() {
      // Cleanup code
    }
  };
}

// With options
export default function(element, options) {
  const config = options.config || {};
  // Use config...
}
```

## Live Elements

Elements with the `live` CSS class are automatically managed:

```html
<div class="live" id="my-element">
  Content that can be updated
</div>
```

## Event Examples

### Basic Event Forwarding

```javascript
// Forward click events
element.addEventListener('click', (event) => {
  live.forwardEvent('my-element', event, { button: 'clicked' });
});

// Forward form submissions
form.addEventListener('submit', (event) => {
  live.forwardFormEvent('my-form', event, { action: 'submit' });
});
```

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

## See Also

  - [lively](https://github.com/socketry/lively) — Ruby framework for building interactive web applications.
  - [live](https://github.com/socketry/live) — Provides client-server communication using websockets.
  - [live-audio-js](https://github.com/socketry/live-audio-js) — Web Audio API-based game audio synthesis library.
