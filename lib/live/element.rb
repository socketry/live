# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require 'json'

module Live
	# Represents a single dynamic content area on the page.
	class Element
		# @parameter id [String] The unique identifier within the page.
		# @parameter data [Hash] The data associated with the element, typically stored as `data-` attributes.
		def initialize(id, **data)
			@id = id
			@data = data
			@data[:class] ||= self.class.name
			
			@page = nil
		end
		
		# The unique id within the bound page.
		attr :id
		
		# Generate a JavaScript string which forwards the specified event to the server.
		# @parameter details [Hash] The details associated with the forwarded event.
		def forward_event(details = nil)
			if details
				"live.forwardEvent(#{JSON.dump(@id)}, event, #{JSON.dump(details)})"
			else
				"live.forwardEvent(#{JSON.dump(@id)}, event)"
			end
		end
		
		def forward_form_event(details = nil)
			if details
				"live.forwardFormEvent(#{JSON.dump(@id)}, event, #{JSON.dump(details)})"
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
		def rpc(method, arguments)
			# This update might not be sent right away. Therefore, mutable arguments may be serialized to JSON at a later time (or never). This could be a race condition:
			@page.updates.enqueue([method, arguments])
		end
	end
end
