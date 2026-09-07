# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require_relative "element"

module Live
	# Resolves a client-side tag into a server-side instance.
	class Resolver
		# Creates an instance of the resolver, allowing the specified classes to be resolved.
		def self.allow(*arguments)
			self.new.allow(*arguments).freeze
		end
		
		def initialize
			@allowed = {}
		end
		
		# @attribute [Hash(String, Class)] A map of allowed class names.
		attr :allowed
		
		def freeze
			return self unless frozen?
			
			@allowed.freeze
			
			super
		end
		
		# Allow the specified classes to be resolved.
		def allow(*arguments)
			arguments.each do |klass|
				@allowed[klass.name] = klass
			end
			
			return self
		end
		
		# Construct an allowed view from its class.
		# @parameter view_class [Class] The view class to construct.
		# @parameter id [String] The unique identifier for the view.
		# @parameter data [Hash] The data associated with the view.
		# @returns [Element] A new view instance.
		# @raises [ArgumentError] If the view class is not allowed.
		def make(view_class, id: view_class.unique_id, data: {})
			unless @allowed[view_class.name].equal?(view_class)
				raise ArgumentError, "View class is not allowed: #{view_class.to_s.dump}!"
			end
			
			return construct(view_class, id, data)
		end
		
		# Resolve a tag.
		# @parameter id [String] The unique identifier for the tag.
		# @parameter data [Hash] The data associated with the tag. Should include the `:class` key.
		# @returns [Element] The element instance if it was allowed.
		def call(id, data)
			if view_class = @allowed[data[:class]]
				return construct(view_class, id, data)
			end
		end
		
		private
		
		def construct(view_class, id, data)
			view_class.new(id, data)
		end
	end
end
