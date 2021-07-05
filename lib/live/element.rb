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
		def forward(details = nil)
			if details
				"live.forward(#{JSON.dump(@id)}, event, #{JSON.dump(details)})"
			else
				"live.forward(#{JSON.dump(@id)}, event)"
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
