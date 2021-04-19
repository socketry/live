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
				return klass.new(id, **data)
			end
		end
	end
end
