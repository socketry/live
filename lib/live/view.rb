# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require_relative "element"
require "xrb/builder"

module Live
	# Represents a single division of content on the page an provides helpers for rendering the content.
	class View < Element
		def tag_name
			"live-view"
		end
		
		# @returns [Object] The generated HTML.
		def build_markup(builder)
			builder.inline_tag self.tag_name, id: @id, data: @data do
				render(builder)
			end
		end
	end
end
