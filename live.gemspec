# frozen_string_literal: true

require_relative "lib/live/version"

Gem::Specification.new do |spec|
	spec.name = "live"
	spec.version = Live::VERSION
	
	spec.summary = "Live HTML tags updated via a WebSocket."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/live"
	
	spec.files = Dir.glob('{lib}/**/*', File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 2.5.0"
	
	spec.add_dependency "async-websocket", "~> 0.22.0"
	spec.add_dependency "trenni"
	
	spec.add_development_dependency "async-rspec", "~> 1.1"
	spec.add_development_dependency "bundler"
	spec.add_development_dependency "covered", "~> 0.10"
	spec.add_development_dependency "rspec", "~> 3.6"
end
