# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "sus/fixtures/async/http/server_context"
require "sus/fixtures/async/webdriver/session_context"

require "async/websocket"
require "async/websocket/adapters/http"

require "protocol/http"
require "protocol/http/body/file"

require "live"

class TestResolver < Live::Resolver
	def initialize(...)
		super
		
		@bound = {}
	end
	
	attr :bound
	
	def call(id, data)
		super.tap do |element|
			@bound[id] = element
		end
	end
end

class TestTag < Live::View
	# Used for binding the tag instance to the client-side element via the resolver.
	def self.name
		"TestTag"
	end
	
	def bind(...)
		super
		
		self.update!
	end
	
	def render(builder)
		builder.tag("p") do
			builder.text Time.now.to_s
		end
	end
end

describe "website" do
	include Sus::Fixtures::Async::HTTP::ServerContext
	include Sus::Fixtures::Async::WebDriver::SessionContext
	
	let(:root) {File.expand_path(".website", __dir__)}
	
	def content_type(path)
		case File.extname(path)
		when ".html"
			"text/html"
		when ".css"
			"text/css"
		when ".js"
			"application/javascript"
		else	
			"application/octet-stream"
		end
	end
	
	let(:resolver) {TestResolver.allow(TestTag)}
	
	def app
		::Protocol::HTTP::Middleware.for do |request|
			local_path = File.join(root, request.path)
			
			if File.file?(local_path)
				Protocol::HTTP::Response[200, {"content-type" => content_type(local_path)}, ::Protocol::HTTP::Body::File.open(local_path)]
			elsif request.path == "/live"
				Async::WebSocket::Adapters::HTTP.open(request) do |connection|
					Live::Page.new(resolver).run(connection)
				end
			else
				Protocol::HTTP::Response[404, {"content-type" => "text/plain"}, ["Not found"]]
			end
		end
	end
	
	it "can load website" do
		navigate_to("/index.html")
		
		expect(session.document_title).to be == "Live Test"
		
		expect(find_element(css: "#test p")).to have_attributes(
			text: be =~ /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/
		)
		
		expect(resolver.bound).not.to be(:empty?)
	end
	
	it "can prepend content" do
		navigate_to("/index.html")
		
		# Wait for the page to load.
		find_element(css: "#test p")
		
		tag = resolver.bound.values.first
		
		tag.prepend("ul.test", '<li class="prepended">Prepended</li>')
		
		# find_element(css: "ul.test li.prepended")
		
		expect(find_element(css: "ul.test").text).to be =~ /Prepended.*?Middle/m
	end
	
	it "can append content" do
		navigate_to("/index.html")
		
		# Wait for the page to load.
		find_element(css: "#test p")
		
		tag = resolver.bound.values.first
		
		tag.append("ul.test", '<li class="appended">Appended</li>')
		
		# find_element(css: "ul.test li.appended")

		expect(find_element(css: "ul.test").text).to be =~ /Middle.*?Appended/m
	end
	
	it "can execute scripts" do
		navigate_to("/index.html")
		
		# Wait for the page to load.
		find_element(css: "#test p")
		
		tag = resolver.bound.values.first
		
		tag.script("document.title = 'Executed'")
		
		expect(session.document_title).to be == "Executed"
	end
	
	it "can handle disconnects" do
		navigate_to("/index.html")
		
		# Wait for the page to load.
		find_element(css: "#test p")
		
		tag = resolver.bound.values.first
		
		# Disconnect the session:
		2.times{navigate_to("about:blank")}
		
		expect do
			tag.update!
		end.to raise_exception(Live::PageError, message: be =~ /not bound/)
	end
end
