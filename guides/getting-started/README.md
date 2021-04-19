# Getting Started

This guide explains how to use `live` to render dynamic content in real-time.

## Installation

Add the gem to your project:

~~~ bash
$ bundle add live
~~~

Install the JavaScript client:

~~~ bash
$ npm add @socketry/live
~~~

## Core Concepts

`live` has several core concepts:

- A {ruby Live::View} which represents a single content area on a web page.
- A {ruby Live::Page} which represents a single page on the client side with zero or more bound views which can be dynamically updated.

## Implementing a View

This view tracks how many times it's been clicked.

~~~ bash
require 'live/view'

class ClickCounter < Live::View
	def initialize(id, **data)
		super
		
		# Setup the initial state:
		@data[:count] ||= 0
	end
	
	# Handle a client event which was forwarded to the server:
	def handle(event, details)
		@data[:count] = Integer(@data[:count]) + 1
		
		replace!
	end
	
	def render(builder)
		# Forward the `onclick` event to the server:
		builder.tag :button, onclick: forward do
			builder.text("I've been clicked #{@data[:count]} times!")
		end
	end
end

~~~

Render the tag in your view layer:

~~~ ruby
#{ClickCounter.new('click-counter').to_html}
~~~

## Implementing the Server

On the server side, in the controller layer, we need to handle the incoming WebSocket request:

~~~ ruby
# This controls which classes can be created by the client tags:
RESOLVER = Live::Resolver.allow(ClickCounter)

# At the same path as the request:
on 'live' do |request|
	Async::WebSocket::Adapters::Rack.open(request.env) do |connection|
		Live::Page.new(RESOLVER).run(connection)
	end
end
~~~

You will need to host this using an `async`-aware server, like (Falcon)[https://github.com/socketry/falcon].

## Example Server

You can try the included example in `example/basic`.

### Start the Server

``` bash
$ cd example/basic
$ falcon serve
```

### Connect the Browser

Open `https://localhost:9292` and enjoy the example. You may like to use the inspector to see the messages going across the WebSocket connection.
