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
				task.sleep(1.0/10.0)
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
