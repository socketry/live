# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require 'live/element'

describe Live::Element do
	it "can generate a unique id" do
		expect(Live::Element.unique_id).to be_a(String)
		
		ids = 10.times.map do
			Live::Element.unique_id
		end
		
		expect(ids.uniq.size).to be == ids.size
	end
	
	it "can be initialized with an id and data" do
		element = subject.new("test", {name: "Test"})
		
		expect(element.id).to be == "test"
		expect(element.data[:name]).to be == "Test"
	end
	
	it "can be initialized with a default class" do
		element = subject.new
		
		expect(element.id).to be_a(String)
		expect(element.data[:class]).to be == "Live::Element"
	end
	
	with "#mount" do
		it "can mount subview" do
			parent = subject.new("parent")
			child = subject.mount(parent, "child")
			
			expect(child.id).to be == "parent:child"
		end
	end
end
