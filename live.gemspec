# frozen_string_literal: true

require_relative "lib/live/version"

Gem::Specification.new do |spec|
	spec.name = "live"
	spec.version = Live::VERSION
	
	spec.summary = "Live HTML tags updated via a WebSocket."
	spec.authors = ["Samuel Williams", "Olle Jonsson"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/live"
	
	spec.metadata = {
		"documentation_uri" => "https://socketry.github.io/live/",
		"source_code_uri" => "https://github.com/socketry/live.git",
	}
	
	spec.files = Dir.glob(['{lib}/**/*', '*.md'], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.1"
	
	spec.add_dependency "async-websocket", "~> 0.27"
	spec.add_dependency "xrb"
end
