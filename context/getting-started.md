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

~~~ ruby
require 'live/view'

class ClickCounter < Live::View
	def initialize(id, data)
		super(id, data)
		
		# Setup the initial state:
		@data[:count] ||= 0
	end
	
	# Handle a client event which was forwarded to the server:
	def handle(event)
		@data[:count] = Integer(@data[:count]) + 1
		
		update!
	end
	
	def render(builder)
		# Forward the `onclick` event to the server:
		builder.tag :button, onclick: forward_event do
			builder.text("I've been clicked #{@data[:count]} times!")
		end
	end
end

~~~

Render the tag in your view layer:

~~~ ruby
#{ClickCounter.root.to_html}
~~~

## Handling Forms

Forms can forward submissions to their server-side view without navigating away from the page. The {ruby Live::Element#forward_form_event} helper prevents the normal submission, serializes the successful form controls, and sends them as part of the event.

~~~ ruby
class ContactForm < Live::View
	def handle(event)
		return unless event[:type] == "submit"
		
		fields = event[:form_data].to_h
		@data[:status] = "Received: #{fields.fetch("message")}"
		
		update!
	end
	
	def render(builder)
		builder.tag :form, action: "/contact", method: "post", onsubmit: forward_form_event do
			builder.tag :textarea, name: "message" do
				builder.text("")
			end
			
			builder.tag :button, type: "submit", name: "action", value: "send" do
				builder.text("Send")
			end
			
			if status = @data[:status]
				builder.tag :p do
					builder.text(status)
				end
			end
		end
	end
end
~~~

The `event[:form_data]` value is an array of name-value pairs, preserving repeated controls with the same name. Convert it to a hash only when the form uses unique control names. The submitting button's name and value are included when available.

The form's normal `action` and `method` still provide a fallback when JavaScript is unavailable. The application is responsible for handling that HTTP endpoint.

Render the form in the same way as any other live view:

~~~ ruby
#{ContactForm.root.to_html}
~~~

## Implementing the Server

On the server side, in the controller layer, we need to handle the incoming WebSocket request:

~~~ ruby
# This controls which classes can be created by the client tags:
RESOLVER = Live::Resolver.allow(ClickCounter, ContactForm)

# At the same path as the request:
run do |env|
	if env['REQUEST_PATH'] == '/live'
		Async::WebSocket::Adapters::Rack.open(env) do |connection|
			Live::Page.new(RESOLVER).run(connection)
		end
	else
		# Handle the normal request here...
	end
end
~~~

You will need to host this using an `async`-aware server, like [Falcon](https://github.com/socketry/falcon).
