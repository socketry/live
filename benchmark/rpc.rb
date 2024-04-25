#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require 'benchmark/ips'

require 'json'

ID = "foobar-123"
HTML = "<p>Hello World! Hello World! Hello World! Hello World! Hello World! Hello World! Hello World! Hello World! Hello World! Hello World! Hello World!</p>"

def eval_string(method, arguments)
	"#{method}(...#{JSON.dump(arguments)})"
end

def json_string(method, arguments)
	JSON.dump([method, arguments])
end

Benchmark.ips do |x|
	x.report("eval") do
		eval_string("replace", [ID, HTML])
	end
	
	x.report("json") do
		json_string("replace", [ID, HTML])
	end
	
	# Compare the iterations per second of the various reports!
	x.compare!
end
