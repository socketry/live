# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require_relative 'element'
require_relative 'resolver'

require 'async'
require 'async/queue'

require 'protocol/websocket'
require 'protocol/websocket/message'

module Live
	# Represents a connected client page with bound dynamic content areas.
	class Page
		# @parameter resolver [Live::Resolver] Used to resolve client-side elements to server-side element instances.
		def initialize(resolver)
			@resolver = resolver
			
			@elements = {}
			@updates = Async::Queue.new
		end
		
		# The queue of outstanding events to be sent to the client.
		attr :updates
		
		# Bind a client-side element to a server side element.
		# @parameter element [Live::Element] The element to bind.
		def bind(element)
			@elements[element.id] = element
			
			element.bind(self)
		end
		
		# Resolve a client-side element to a server side instance.
		# @parameter id [String] The unique identifier within the page.
		# @parameter data [Hash] The data associated with the element, typically stored as `data-` attributes.
		def resolve(id, data)
			@resolver.call(id, data)
		end
		
		# Handle an event from the client. If the element could not be found, it is silently ignored.
		# @parameter id [String] The unique identifier of the element which forwarded the event.
		# @parameter event [String] The type of the event.
		# @returns [Object] The result of the element handler, if the element was found.
		# @returns [Nil] If the element could not be found.
		def handle(id, event)
			if element = @elements[id]
				return element.handle(event)
			else
				Console.warn(self, "Could not handle event:", id:, event:)
			end
			
			return nil
		end
		
		def close
			@elements.each do |id, element|
				element.close
			end
		end
		
		# Process a single incoming message from the network.
		def process_message(message)
			case message[0]
			when 'bind'
				# Bind a client-side element to a server-side element.
				if element = self.resolve(message[1], message[2])
					self.bind(element)
				else
					Console.warn(self, "Could not resolve element:", message)
					@updates.enqueue(['error', message[1], "Could not resolve element!"])
				end
			when 'unbind'
				# Unbind a client-side element from a server-side element.
				if element = @elements.delete(message[1])
					element.close
				else
					Console.warn(self, "Could not unbind element:", message)
					@updates.enqueue(['error', message[1], "Could not unbind element!"])
				end
			when 'event'
				# Handle an event from the client.
				self.handle(message[1], message[2])
			else
				Console.warn(self, "Unhandled message:", message)
			end
		end
		
		# Run the event handling loop with the given websocket connection.
		# @parameter connection [Async::WebSocket::Connection]
		def run(connection)
			queue_task = Async do
				while update = @updates.dequeue
					Console.debug(self, "Sending update:", update)
					::Protocol::WebSocket::TextMessage.generate(update).send(connection)
					connection.flush if @updates.empty?
				end
			end
			
			while message = connection.read
				Console.debug(self, "Reading message:", message)
				process_message(message.parse)
			end
		ensure
			self.close
			queue_task&.stop
		end
	end
end
