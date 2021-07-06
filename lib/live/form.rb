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
        def handleForm(details=false)
            if details 
                return "live.handleForm(this.id, event, #{details})"
            else 
                return "live.handleForm(this.id, event)"
            end 
        end 

        # Render the element
        def to_html()

            Trenni::Builder.fragment do |builder|
                builder.tag :form, method: "post", id: @id, class: 'live', onsubmit: handleForm, data: @data do
                    render(builder)
                end
            end
        end 

        # Handles an incoming event.
        def handle(event, message)
        end         

    end 
end 
