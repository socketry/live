# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require_relative '../../../lib/live'

class ClickCounter < Live::View
	def initialize(id, **data)
		super
		
		@data[:count] ||= 0
	end
	
	def handle(event, details)
		@data[:count] = Integer(@data[:count]) + 1
		
		replace!
	end
	
	def render(builder)
		builder.tag :button, onclick: forward do
			builder.text("Add an image. (#{@data[:count]} images so far).")
		end
		
		builder.tag :div do
			Integer(@data[:count]).times do
				builder.tag :img, src: "https://picsum.photos/200/300"
			end
		end
	end
end
