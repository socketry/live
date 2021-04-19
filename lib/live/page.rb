# frozen_string_literal: true

# Copyright, 2021, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative 'element'
require_relative 'resolver'

require 'async'
require 'async/queue'

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
		def handle(id, event, details)
			if element = @elements[id]
				return element.handle(event, details)
			else
				Console.logger.warn(self, "Could not handle event:", event, details)
			end
			
			return nil
		end
		
		# Run the event handling loop with the given websocket connection.
		# @parameter connection [Async::WebSocket::Connection]
		def run(connection)
			queue_task = Async do
				while update = @updates.dequeue
					Console.logger.debug(self, "Sending update:", update)
					
					connection.write(update)
					connection.flush if @updates.empty?
				end
			end
			
			while message = connection.read
				Console.logger.debug(self, "Reading message:", message)
				
				if id = message[:bind] and data = message[:data]
					if element = self.resolve(id, data)
						self.bind(element)
					else
						Console.logger.warn(self, "Could not resolve element:", message)
					end
				elsif id = message[:id]
					self.handle(id, message[:event], message[:details])
				else
					Console.logger.warn(self, "Unhandled message:", message)
				end
			end
		ensure
			queue_task&.stop
		end
	end
end
