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
	
	with "#root" do
		it "constructs an allowed view" do
			view = resolver.root(view_class, "root", data: {mode: "test"})
			
			expect(view).to be_a(view_class)
			expect(view.id).to be == "root"
			expect(view.data[:mode]).to be == "test"
		end
		
		it "rejects a view which is not allowed" do
			other_view = Class.new(Live::View)
			
			expect do
				resolver.root(other_view)
			end.to raise_exception(ArgumentError, message: be =~ /View class is not allowed: "#<Class:/)
		end
		
		it "passes constructor options to the view" do
			dependency = Object.new
			view_class = Class.new(Live::View) do
				def self.name
					"ViewWithDependency"
				end
				
				def initialize(id = self.class.unique_id, data = {}, dependency:)
					super(id, data)
					@dependency = dependency
				end
				
				attr :dependency
			end
			resolver = subject.allow(view_class)
			
			view = resolver.root(view_class, dependency:)
			
			expect(view.dependency).to be_equal(dependency)
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
	
	with "#make" do
		it "is shared by explicit and resolved construction" do
			constructions = []
			resolver_class = Class.new(subject) do
				private
				
				define_method(:make) do |view_class, id, data, **options|
					constructions << [view_class, id, data, options]
				end
			end
			resolver = resolver_class.allow(view_class)
			
			resolver.root(view_class, "made", data: {source: "root"}, dependency: true)
			resolver.call("called", {class: view_class.name, source: "call"})
			
			expect(constructions).to be == [
				[view_class, "made", {source: "root"}, {dependency: true}],
				[view_class, "called", {class: view_class.name, source: "call"}, {}],
			]
		end
	end
end
