# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require 'json'
require 'securerandom'

module Live
	class PageError < RuntimeError
	end
	
	# Represents a single dynamic content area on the page.
	class Element
		def self.unique_id
			SecureRandom.uuid
		end
		
		# @parameter id [String] The unique identifier within the page.
		# @parameter data [Hash] The data associated with the element, typically stored as `data-` attributes.
		def initialize(id = Element.unique_id, **data)
			@id = id
			@data = data
			@data[:class] ||= self.class.name
			
			@page = nil
		end
		
		# The unique id within the bound page.
		attr :id
		
		# The data associated with the element.
		attr :data
		
		# Generate a JavaScript string which forwards the specified event to the server.
		# @parameter detail [Hash] The detail associated with the forwarded event.
		def forward_event(detail = nil)
			if detail
				"live.forwardEvent(#{JSON.dump(@id)}, event, #{JSON.dump(detail)})"
			else
				"live.forwardEvent(#{JSON.dump(@id)}, event)"
			end
		end
		
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
		
		def close
			@page = nil
		end
		
		# Handle a client event, typically as triggered by {#forward}.
		# @parameter event [String] The type of the event.
		def handle(event)
		end
		
		# Enqueue a remote procedure call to the currently bound page.
		# @parameter method [Symbol] The name of the remote functio to invoke.
		# @parameter arguments [Array]
		def rpc(*arguments)
			if @page
				# This update might not be sent right away. Therefore, mutable arguments may be serialized to JSON at a later time (or never). This could be a race condition:
				@page.updates.enqueue(arguments)
			else
				# This is a programming error, as it probably means the element is still part of the logic of the server side (e.g. async loop), but it is not bound to a page, so there is nothing to update/access/rpc.
				raise PageError, "Element is not bound to a page, make sure to implement #close!"
			end
		end
	end
end
