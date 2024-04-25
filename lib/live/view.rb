# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require_relative 'element'
require 'xrb/builder'

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
		# @parameter builder [XRB::Builder] The HTML builder.
		def render(builder)
		end
		
		# @returns [Object] The generated HTML.
		def to_html
			XRB::Builder.fragment do |builder|
				builder.tag :div, id: @id, class: 'live', data: @data do
					render(builder)
				end
			end
		end
	end
end
