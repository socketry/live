# Live (JavaScript)

This is the JavaScript library for implementing the Ruby gem of the same name.

## Document Manipulation

### `live.update(id, html, options)`

Updates the content of the element with the given `id` with the given `html`. The `options` parameter is optional and can be used to pass additional options to the update method.

- `options.reply` - If truthy, the server will reply with `{reply: options.reply}`.

### `live.replace(selector, html, options)`

Replaces the element(s) selected by the given `selector` with the given `html`. The `options` parameter is optional and can be used to pass additional options to the replace method.

- `options.reply` - If truthy, the server will reply with `{reply: options.reply}`.

### `live.prepend(selector, html, options)`

Prepends the given `html` to the element(s) selected by the given `selector`. The `options` parameter is optional and can be used to pass additional options to the prepend method.

- `options.reply` - If truthy, the server will reply with `{reply: options.reply}`.

### `live.append(selector, html, options)`

Appends the given `html` to the element(s) selected by the given `selector`. The `options` parameter is optional and can be used to pass additional options to the append method.

- `options.reply` - If truthy, the server will reply with `{reply: options.reply}`.

### `live.remove(selector, options)`

Removes the element(s) selected by the given `selector`. The `options` parameter is optional and can be used to pass additional options to the remove method.

- `options.reply` - If truthy, the server will reply with `{reply: options.reply}`.

### `live.dispatchEvent(selector, type, options)`

Dispatches an event of the given `type` on the element(s) selected by the given `selector`. The `options` parameter is optional and can be used to pass additional options to the dispatchEvent method.

- `options.detail` - The detail object to pass to the event.
- `options.bubbles` - A boolean indicating whether the event should bubble up through the DOM.
- `options.cancelable` - A boolean indicating whether the event can be canceled.
- `options.composed` - A boolean indicating whether the event will trigger listeners outside of a shadow root.

## Event Handling

### `live.forward(id, event)`

Connect and forward an event on the element with the given `id`. If the connection can't be established, the event will be buffered.

### `live.forwardEvent(id, event, details)`

Forward a HTML DOM event to the server. The `details` parameter is optional and can be used to pass additional details to the server.

### `live.forwardFormEvent(id, event, details)`

Forward an event which has form data to the server. The `details` parameter is optional and can be used to pass additional details to the server.
