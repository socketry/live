# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2026, by Samuel Williams.
# Copyright, 2026, by Matt Quinn.

require "json"
require "securerandom"

module Live
	# Raised when an operation requires an element to be bound to a page.
	class PageError < RuntimeError
	end
	
	# Represents a single dynamic content area on the page.
	class Element
		# Generate a unique identifier for an element.
		# @returns [String] The generated identifier.
		def self.unique_id
			SecureRandom.uuid
		end
		
		# Create a new root element with a convenient syntax for specifying the id and data.
		#
		# @parameter id [String] The unique identifier within the page.
		# @parameter data [Hash] The data associated with the element, typically stored as `data-` attributes.
		# @parameter options [Hash] Additional options passed to the element constructor.
		def self.root(id = self.unique_id, data: {}, **options)
			self.new(id, data, **options)
		end
		
		# Mount an element within a parent element.
		# @parameter parent [Element] The parent element.
		# @parameter id [String] The unique identifier within the parent element.
		# @parameter data [Hash] The data associated with the element, typically stored as `data-` attributes.
		# @parameter options [Hash] Additional options passed to the element constructor.
		def self.child(parent, id = self.unique_id, data: {}, **options)
			full_id = parent.id + ":" + id
			
			self.new(full_id, data, **options)
		end
		
		# Mount an element within a parent element.
		# @parameter parent [Element] The parent element.
		# @parameter id [String] The unique identifier within the parent element.
		# @parameter data [Hash] The data associated with the element, typically stored as `data-` attributes.
		# @parameter options [Hash] Additional options passed to the element constructor.
		def self.mount(parent, id, data: {}, **options)
			self.child(parent, id, data:, **options)
		end
		
		# Initialize the element with the specified id and data.
		#
		# @parameter id [String] The unique identifier within the page.
		# @parameter data [Hash] The data associated with the element, typically stored as `data-` attributes.
		def initialize(id, data)
			data[:class] ||= self.class.name
			
			@id = id
			@data = data
			@page = nil
		end
		
		# The unique id within the bound page.
		attr :id
		
		# The data associated with the element.
		attr :data
		
		# @attribute [Page | Nil] The page this element is bound to.
		attr :page
		
		# A CSS selector that uniquely identifies this element.
		# @returns [String]
		def selector
			"[id=#{JSON.dump(@id)}]"
		end
		
		# Generate a JavaScript string which forwards the specified event to the server.
		# @parameter detail [Hash] The detail associated with the forwarded event.
		def forward_event(detail = nil)
			if detail
				"live.forwardEvent(#{JSON.dump(@id)}, event, #{JSON.dump(detail)})"
			else
				"live.forwardEvent(#{JSON.dump(@id)}, event)"
			end
		end
		
		# Generate JavaScript which forwards a form event and its form data to the server.
		# @parameter detail [Hash | Nil] Additional detail associated with the forwarded event.
		# @returns [String] The generated JavaScript expression.
		def forward_form_event(detail = nil)
			if detail
				"live.forwardFormEvent(#{JSON.dump(@id)}, event, #{JSON.dump(detail)})"
			else
				"live.forwardFormEvent(#{JSON.dump(@id)}, event)"
			end
		end
		
		# Bind this tag to a dynamically updating page.
		# @parameter page [Live::Page]
		def bind(page)
			@page = page
		end
		
		# Detach the element from its page.
		def close
			@page = nil
		end
		
		# Handle a client event, typically as triggered by {#forward_event}.
		# @parameter event [String] The type of the event.
		def handle(event)
		end
		
		# Enqueue a remote procedure call to the currently bound page.
		# @parameter method [Symbol] The name of the remote function to invoke.
		# @parameter arguments [Array]
		def rpc(*arguments)
			if @page
				# This update might not be sent right away. Therefore, mutable arguments may be serialized to JSON at a later time (or never). This could be a race condition:
				@page.enqueue(arguments)
			else
				# This is a programming error, as it probably means the element is still part of the logic of the server side (e.g. async loop), but it is not bound to a page, so there is nothing to update/access/rpc.
				raise PageError, "Element is not bound to a page, make sure to implement #close!"
			end
		end
		
		# Execute JavaScript in the context of the client-side element.
		# @parameter code [String] The JavaScript source code to execute.
		# @parameter options [Hash] Options for the remote procedure call.
		def script(code, **options)
			rpc(:script, @id, code, options)
		end
		
		# Update the content of the client-side element by rendering this view.
		def update!(**options)
			rpc(:update, @id, self.to_html, options)
		end
		
		# Replace the content of the client-side element by rendering this view.
		# @parameter selector [String] The CSS selector to replace.
		# @parameter node [String] The HTML to replace.
		def replace(selector, fragment = nil, **options, &block)
			fragment ||= XRB::Builder.fragment(&block)
			
			rpc(:replace, selector, fragment.to_s, options)
		end
		
		# Prepend to the content of the client-side element by appending the specified element.
		# @parameter selector [String] The CSS selector to prepend to.
		# @parameter node [String] The HTML to prepend.
		def prepend(selector, fragment = nil, **options, &block)
			fragment ||= XRB::Builder.fragment(&block)
			
			rpc(:prepend, selector, fragment.to_s, options)
		end
		
		# Append to the content of the client-side element by appending the specified element.
		# @parameter selector [String] The CSS selector to append to.
		# @parameter node [String] The HTML to prepend.
		def append(selector, fragment = nil, **options, &block)
			fragment ||= XRB::Builder.fragment(&block)
			
			rpc(:append, selector, fragment.to_s, options)
		end
		
		# Remove the specified element from the client-side element.
		# @parameter selector [String] The CSS selector to remove.
		def remove(selector, **options)
			rpc(:remove, selector, options)
		end
		
		# Dispatch an event to each client-side element matching the selector.
		# @parameter selector [String] The CSS selector for the target elements.
		# @parameter type [String] The event type to dispatch.
		# @parameter options [Hash] The event initialization options.
		def dispatch_event(selector, type, **options)
			rpc(:dispatchEvent, selector, type, options)
		end
		
		# Render the element.
		# @parameter builder [XRB::Builder] The HTML builder.
		def render(builder)
			builder.text(self.class.name)
		end
		
		# Append this element's markup to the specified output buffer.
		# @parameter output [Object] The output buffer which receives the markup.
		def append_markup(output)
			build_markup(::XRB::Builder.new(output))
		end
		
		# Build this element's markup with the specified builder.
		# @parameter builder [XRB::Builder] The builder which receives the markup.
		def build_markup(builder)
			render(builder)
		end
		
		# @returns [Object] The generated HTML.
		def to_html
			XRB::Builder.fragment(&self.method(:build_markup))
		end
		
		# Convenience method for rendering the view as a string.
		# @returns [String] The generated HTML.
		def to_s
			to_html.to_s
		end
	end
end
