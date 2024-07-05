# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require_relative 'element'
require 'xrb/builder'

module Live
	# Represents a single division of content on the page an provides helpers for rendering the content.
	class View < Element
		# @returns [Object] The generated HTML.
		def to_html
			XRB::Builder.fragment do |builder|
				builder.inline_tag :div, id: @id, class: 'live', data: @data do
					render(builder)
				end
			end
		end
	end
end
