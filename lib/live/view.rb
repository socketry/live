# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require_relative 'element'
require 'xrb/builder'

module Live
	# Represents a single division of content on the page an provides helpers for rendering the content.
	class View < Element
		# Update the content of the client-side element by rendering this view.
		def update!(**options)
			rpc(:update, @id, self.to_html, options)
		end
		
		# Replace the content of the client-side element by rendering this view.
		# @parameter selector [String] The CSS selector to replace.
		# @parameter node [String] The HTML to replace.
		def replace(selector, fragment = nil, **options, &block)
			fragment ||= XRB::Builder.fragment(&block)
			
			rpc(:replace, selector, fragment.to_s, options)
		end
		
		# Prepend to the content of the client-side element by appending the specified element.
		# @parameter selector [String] The CSS selector to prepend to.
		# @parameter node [String] The HTML to prepend.
		def prepend(selector, fragment = nil, **options, &block)
			fragment ||= XRB::Builder.fragment(&block)
			
			rpc(:prepend, selector, fragment.to_s, options)
		end
		
		# Append to the content of the client-side element by appending the specified element.
		# @parameter selector [String] The CSS selector to append to.
		# @parameter node [String] The HTML to prepend.
		def append(selector, fragment = nil, **options, &block)
			fragment ||= XRB::Builder.fragment(&block)
			
			rpc(:append, selector, fragment.to_s, options)
		end
		
		# Remove the specified element from the client-side element.
		# @parameter selector [String] The CSS selector to remove.
		def remove(selector, **options)
			rpc(:remove, selector, options)
		end
		
		def dispatch_event(selector, type, **options)
			rpc(:dispatch_event, selector, event, options)
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
