# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require_relative '../../../lib/live'

class ReactorStatus < Live::View
	def initialize(id, **data)
		super
		
		@update = nil
	end
	
	def bind(...)
		super
		
		@update = Async do |task|
			while true
				task.sleep(1.0/2.0)
				self.replace!
			end
		end
	end
	
	def close
		@update.stop
		
		super
	end
	
	def handle(event, details)
		replace!
	end
	
	def render(builder)
		builder.tag :div do
			builder.inline :pre do
				buffer = StringIO.new
				Async::Task.current.reactor.print_hierarchy(buffer, backtrace: false)
				builder.text(buffer.string)
			end
		end
	end
end
