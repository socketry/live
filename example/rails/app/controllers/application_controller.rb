require 'click_counter'
require 'async/websocket/adapters/rails'

class ApplicationController < ActionController::Base
  RESOLVER = Live::Resolver.allow(ClickCounter)

  def index
    @tag = ClickCounter.new('click-counter')
  end

  def live
    self.response = Async::WebSocket::Adapters::Rails.open(request) do |connection|
      Live::Page.new(RESOLVER).run(connection)
    end
  end
end
