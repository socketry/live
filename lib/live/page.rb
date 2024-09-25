# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require_relative "element"
require_relative "resolver"

require "async"
require "async/queue"

require "protocol/websocket"
require "protocol/websocket/message"

require "console/event/failure"

module Live
	# Represents a connected client page with bound dynamic content areas.
	class Page
		# @parameter resolver [Live::Resolver] Used to resolve client-side elements to server-side element instances.
		def initialize(resolver)
			@resolver = resolver
			
			@elements = {}
			@attached = {}
			
			@updates = Async::Queue.new
		end
		
		# Bind a client-side element to a server side element.
		# @parameter element [Live::Element] The element to bind.
		def bind(element)
			@elements[element.id] = element
			
			element.bind(self)
		end
		
		# Attach a pre-existing element to the page, so that it may later be bound to this exact instance.
		# You must later detach the element when it is no longer needed.
		def attach(element)
			@attached[element.id] = element
		end
		
		def detach(element)
			if @attached.delete(element.id)
				element.close
			end
		end
		
		# Resolve a client-side element to a server side instance.
		# @parameter id [String] The unique identifier within the page.
		# @parameter data [Hash] The data associated with the element, typically stored as `data-` attributes.
		def resolve(id, data = {})
			@attached.fetch(id) do
				@resolver.call(id, data)
			end
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
				begin
					element.close
				rescue => error
					Console::Event::Failure.for(error).emit(self)
				end
			end
		end
		
		def enqueue(update)
			@updates.enqueue(::Protocol::WebSocket::TextMessage.generate(update))
		end
		
		# Process a single incoming message from the network.
		def process_message(message)
			case message[0]
			when "bind"
				# Bind a client-side element to a server-side element.
				if element = self.resolve(message[1], message[2])
					self.bind(element)
				else
					Console.warn(self, "Could not resolve element:", message)
					self.enqueue(["error", message[1], "Could not resolve element!"])
				end
			when "unbind"
				# Unbind a client-side element from a server-side element.
				if element = @elements.delete(message[1])
					element.close unless @attached.key?(message[1])
				else
					Console.warn(self, "Could not unbind element:", message)
					self.enqueue(["error", message[1], "Could not unbind element!"])
				end
			when "event"
				# Handle an event from the client.
				self.handle(message[1], message[2])
			else
				Console.warn(self, "Unhandled message:", message)
			end
		end
		
		# Run the event handling loop with the given websocket connection.
		# @parameter connection [Async::WebSocket::Connection]
		def run(connection, keep_alive: 10)
			Sync do |task|
				last_update = Async::Clock.now
				
				queue_task = task.async do
					while update = @updates.dequeue
						update.send(connection)
						
						# Flush the output if there are no more updates:
						if @updates.empty?
							connection.flush
						end
					end
				end
				
				keep_alive_task = task.async do
					while true
						sleep(keep_alive)
						
						duration = Async::Clock.now - last_update
						
						# We synchronize all writes to the update queue:
						if duration > keep_alive
							@updates.enqueue(::Protocol::WebSocket::PingMessage.new)
						end
					end
				end
				
				while message = connection.read
					last_update = Async::Clock.now
					process_message(message.parse)
				end
			ensure
				keep_alive_task&.stop
				
				self.close
				
				queue_task&.stop
			end
		end
	end
end
