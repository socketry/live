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
require 'trenni/builder'

module Live
	# Represents a single division of content on the page an provides helpers for rendering the content.
	class View < Element
		# Replace the content of the client-side element by rendering this view.
		def replace!
			rpc(:replace, [@id, self.to_html])
		end
		
		# Append to the content of the client-side element by appending the specified element.
		# @parameter node [Live::Element] The element to append.
		def append!(element)
			rpc(:append, [@id, element.to_html])
		end
		
		# Prepend to the content of the client-side element by appending the specified element.
		# @parameter node [Live::Element] The element to prepend.
		def prepend!(element)
			rpc(:prepend, [@id, element.to_html])
		end
		
		# Render the element.
		# @parameter builder [Trenni::Builder] The HTML builder.
		def render(builder)
		end
		
		# @returns [Object] The generated HTML.
		def to_html
			Trenni::Builder.fragment do |builder|
				builder.tag :div, id: @id, class: 'live', data: @data do
					render(builder)
				end
			end
		end
	end
end
