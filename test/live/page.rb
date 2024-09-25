# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

require "live/page"
require "live/view"
require "live/resolver"

require "async/websocket/client"
require "async/websocket/adapters/http"
require "sus/fixtures/async/http/server_context"

class MyView < Live::View
end

describe Live::Page do
	let(:resolver) {Live::Resolver.new}
	
	let(:page) {subject.new(resolver)}
	
	with "#resolve" do
		it "resolves allowed elements" do
			resolver.allowed[Live::View.name] = Live::View
			
			expect(page.resolve("live-view", {class: "Live::View"})).to be_a(Live::View)
		end
		
		it "ignores non-allowed elements" do
			expect(page.resolve("live-view", {class: "Live::View"})).to be_nil
		end
	end
	
	with "#attach" do
		let(:view) {MyView.new}
		
		it "can resolve attached elements" do
			page.attach(view)
			expect(page.resolve(view.id)).to be_equal(view)
			
			page.detach(view)
			expect(page.resolve(view.id)).to be_nil
		end
	end
	
	with "a server" do
		include Sus::Fixtures::Async::HTTP::ServerContext
		
		let(:app) do
			::Protocol::HTTP::Middleware.for do |request|
				Async::WebSocket::Adapters::HTTP.open(request) do |connection|
					Live::Page.new(resolver).run(connection, keep_alive: 0.001)
				end
			end
		end
		
		it "can connect to server and receives ping" do
			Async::WebSocket::Client.connect(client_endpoint) do |connection|
				expect(connection).to receive(:receive_ping)
				
				frame = connection.read_frame
				
				expect(frame).to be_a(Protocol::WebSocket::PingFrame)
			end
		end
	end
end
