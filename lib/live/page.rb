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
	class Page
		def initialize(resolver)
			@resolver = resolver
			
			@elements = {}
			@updates = Async::Queue.new
		end
		
		attr :updates
		
		def bind(element)
			@elements[element.id] = element
			
			element.bind(self)
		end
		
		def resolve(id, data)
			@resolver.call(id, data)
		end
		
		def handle(id, event, details)
			if element = @elements[id]
				return element.handle(event, details)
			else
				Console.logger.warn(self, "Could not handle event:", event, details)
			end
			
			return nil
		end
		
		def run(connection)
			reader_task = start_reader(connection)
			
			while update = @updates.dequeue
				Console.logger.debug(self, "Sending update:", update)
				
				connection.write(update)
				connection.flush if @updates.empty?
			end
		ensure
			reader_task&.stop
		end
		
		private
		
		def start_reader(connection)
			Async do
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
			end
		end
	end
end
