
require 'async/websocket/adapters/rack'
require 'click_counter'

prepend Actions

RESOLVER = Live::Resolver.allow(ClickCounter)

on 'live' do |request|
	Console.logger.info("Incoming live connection...")
	
	adapter = Async::WebSocket::Adapters::Rack.open(request.env) do |connection|
		Live::Page.new(RESOLVER).run(connection)
	end
	
	respond?(adapter) or fail!
end

on 'index' do
	@tag = ClickCounter.new('click-counter')
end
