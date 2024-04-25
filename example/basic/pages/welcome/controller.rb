# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require 'async/websocket/adapters/rack'
require 'reactor_status'

prepend Actions

RESOLVER = Live::Resolver.allow(ReactorStatus)

on 'live' do |request|
	Console.logger.info("Incoming live connection...")
	
	adapter = Async::WebSocket::Adapters::Rack.open(request.env) do |connection|
		Live::Page.new(RESOLVER).run(connection)
	end
	
	respond?(adapter) or fail!
end

on 'index' do
	@tag = ReactorStatus.new('reactor-status')
end
