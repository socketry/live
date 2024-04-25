# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require_relative 'element'
require_relative 'resolver'

require 'async'
require 'async/queue'

require 'protocol/websocket/json_message'

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
		# @parameter details [Hash] The associated details if any.
		# @returns [Object] The result of the element handler, if the element was found.
		# @returns [Nil] If the element could not be found.
		def handle(id, event)
			if element = @elements[id]
				return element.handle(event)
			else
				Console.logger.warn(self, "Could not handle event:", event, details)
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
			if id = message[:bind] and data = message[:data]
				if element = self.resolve(id, data)
					self.bind(element)
				else
					Console.logger.warn(self, "Could not resolve element:", message)
				end
			elsif id = message[:id]
				self.handle(id, message[:event])
			else
				Console.logger.warn(self, "Unhandled message:", message)
			end
		end
		
		# Run the event handling loop with the given websocket connection.
		# @parameter connection [Async::WebSocket::Connection]
		def run(connection)
			queue_task = Async do
				while update = @updates.dequeue
					Console.logger.debug(self, "Sending update:", update)
					
					connection.write(::Protocol::WebSocket::JSONMessage.generate(update))
					connection.flush if @updates.empty?
				end
			end
			
			while message = connection.read
				Console.logger.debug(self, "Reading message:", message)
				
				if json_message = ::Protocol::WebSocket::JSONMessage.wrap(message)
					process_message(json_message.parse)
				else
					Console.logger.warn(self, "Unhandled message:", message)
				end
			end
		ensure
			self.close
			queue_task&.stop
		end
	end
end
