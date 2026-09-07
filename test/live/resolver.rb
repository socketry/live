# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "live/resolver"
require "live/view"

describe Live::Resolver do
	let(:view_class) do
		Class.new(Live::View) do
			def self.name
				"TestView"
			end
		end
	end
	
	let(:resolver) {subject.allow(view_class)}
	
	with "#make" do
		it "constructs an allowed view" do
			view = resolver.make(view_class, id: "root", data: {mode: "test"})
			
			expect(view).to be_a(view_class)
			expect(view.id).to be == "root"
			expect(view.data[:mode]).to be == "test"
		end
		
		it "rejects a view which is not allowed" do
			other_view = Class.new(Live::View)
			
			expect do
				resolver.make(other_view)
			end.to raise_exception(ArgumentError, message: be =~ /View class is not allowed: "#<Class:/)
		end
	end
	
	with "#call" do
		it "constructs an allowed view" do
			view = resolver.call("resolved", {class: view_class.name})
			
			expect(view).to be_a(view_class)
			expect(view.id).to be == "resolved"
		end
		
		it "returns nil for an unknown view" do
			expect(resolver.call("unknown", {class: "Unknown"})).to be_nil
		end
	end
	
	with "#construct" do
		it "is shared by explicit and resolved construction" do
			constructions = []
			resolver_class = Class.new(subject) do
				private
				
				define_method(:construct) do |view_class, id, data|
					constructions << [view_class, id, data]
				end
			end
			resolver = resolver_class.allow(view_class)
			
			resolver.make(view_class, id: "made", data: {source: "make"})
			resolver.call("called", {class: view_class.name, source: "call"})
			
			expect(constructions).to be == [
				[view_class, "made", {source: "make"}],
				[view_class, "called", {class: view_class.name, source: "call"}],
			]
		end
	end
end
