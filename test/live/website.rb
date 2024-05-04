require 'sus/fixtures/async/http/server_context'
require 'sus/fixtures/async/webdriver/session_context'

require 'async/websocket'
require 'async/websocket/adapters/http'

require 'protocol/http'
require 'protocol/http/body/file'

require 'live/view'

class TestTag < Live::View
	def self.name
		"TestTag"
	end
	
	def bind(...)
		super
		
		@clock ||= Async do
			while true
				self.update!
				sleep 1
			end
		end
	end
	
	def render(builder)
		builder.tag('p') do
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
	
	let(:resolver) {Live::Resolver.allow(TestTag)}
	
	def app
		::Protocol::HTTP::Middleware.for do |request|
			local_path = File.join(root, request.path)
			
			if File.file?(local_path)
				Protocol::HTTP::Response[200, {'content-type' => content_type(local_path)}, ::Protocol::HTTP::Body::File.open(local_path)]
			elsif request.path == "/live"
				Async::WebSocket::Adapters::HTTP.open(request) do |connection|
					Live::Page.new(resolver).run(connection)
				end
			else
				Protocol::HTTP::Response[404, {'content-type' => 'text/plain'}, ["Not found"]]
			end
		end
	end
	
	it "can load website" do
		session.implicit_wait_timeout = 10_000
		
		navigate_to("/index.html")
		
		expect(session.document_title).to be == "Live Test"
		
		expect(find_element(css: "#test p")).to have_attributes(
			text: be =~ /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/
		)
	end
end
