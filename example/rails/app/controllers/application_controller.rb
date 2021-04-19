require 'click_counter'
require 'async/websocket/adapters/rack'

class ApplicationController < ActionController::Base
  RESOLVER = Live::Resolver.allow(ClickCounter)

  def index
    @tag = ClickCounter.new('click-counter')
  end

  def live
    # I'm so sorry for this abomination.
    Console.logger.info("Incoming live connection...")

    adapter = Async::WebSocket::Adapters::Rack.open(request.env) do |connection|
      Live::Page.new(RESOLVER).run(connection)
    end

    # `adapter` is a standard rack response... please just send it back out to falcon...
    if adapter
      # Oh no... we need to use `rack.hijack` and internally route it to the body...
      adapter[1]['rack.hijack'] = lambda do |stream|
        adapter[2].call(stream)
      end

      # Wrap it up in a fake controller response:
      self.response = ActionDispatch::Response.new(adapter[0], adapter[1], nil)

      # Close the response to prevent Rails from... trying to render a view?
      self.response.close
    end
  end
end
