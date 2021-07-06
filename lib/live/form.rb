# frozen_string_literal: true

require_relative 'view'
require 'trenni/builder'
require 'json'

module Live 
    # Represents a Form within the view layer
    # Differs from Live::View because the server sends both the 
    # details and a serialized form from the view layer.
    class Form < Live::View 
        
        # returns [String] javascript code to execute when the form is submitted.
        def forward_submit
            "live.handleForm(this.id, event)"
        end 

        # Render the element
        def to_html()

            Trenni::Builder.fragment do |builder|
                builder.tag :form, method: "post", id: @id, class: 'live', onsubmit:forward_submit, data: @data do
                    render(builder)
                end
            end
        end 

        # Handles an incoming event.
        def handle(event)
            self.submit(event)
        end         

        # Processes incoming form data, which can be accesible through @data[:form]
        def submit(event)
            @data[:form] = JSON.parse(event[:details])[1].to_h
        end 

    end 
end 
