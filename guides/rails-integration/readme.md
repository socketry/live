# Rails Integration

This guide explains how to use the `live` gem with Ruby on Rails.

## Tag Implementation

Here is a simple implementation of a real-time clock tag:

```ruby
class ClockTag < Live::Tag
	def initialize(name)
		@name = name
	end
	
	def bind(page)
		super
		
		# Schedule a refresh every second:
		Async do
			while true
				sleep 1
				replace!
			end
		end
	end
	
	def render(builder)
		builder.tag('div') do
			builder.text(Time.now.to_s)
		end
	end
end
```

## Controller

Implement a controller to render the clock tag:

```ruby
require 'async/websocket/adapters/rails'

class ClockController < ApplicationController
  RESOLVER = Live::Resolver.allow(ClockTag)

  def index
    @tag = ClockTag.new('flappy')
  end

  skip_before_action :verify_authenticity_token, only: :live

  def live
    self.response = Async::WebSocket::Adapters::Rails.open(request) do |connection|
      Live::Page.new(RESOLVER).run(connection)
    end
  end
```

## View

Render the tag in your view layer:

```erb
<h1>Clock</h1>

<%= raw @tag.to_html %>
```

## Routes

Add a route to the controller:

```ruby
Rails.application.routes.draw do
  # Clock page:
  get "clock/index"
	
	# Live WebSocket:
  match "clock/live", via: [:get, :connect]
end
```