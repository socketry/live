# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2026, by Samuel Williams.

require_relative "element"
require "xrb/builder"

module Live
	# Represents a single division of content on the page and provides helpers for rendering the content.
	class View < Element
		# Get the custom element tag name used to render the view.
		# @returns [String] The custom element tag name.
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
