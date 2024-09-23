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
		
		# Resolve a tag.
		# @parameter id [String] The unique identifier for the tag.
		# @parameter data [Hash] The data associated with the tag. Should include the `:class` key.
		# @returns [Element] The element instance if it was allowed.
		def call(id, data)
			if klass = @allowed[data[:class]]
				return klass.new(id, data)
			end
		end
	end
end
