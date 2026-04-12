# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2026, by Samuel Williams.

require "live/element"

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
	
	with "#forward_event" do
		let(:element) {subject.new("test-element")}
		
		it "generates JavaScript without detail" do
			result = element.forward_event
			
			expect(result).to be =~ /live\.forwardEvent/
			expect(result).to be =~ /"test-element"/
		end
		
		it "generates JavaScript with detail" do
			result = element.forward_event({key: "value"})
			
			expect(result).to be =~ /live\.forwardEvent/
			expect(result).to be =~ /"test-element"/
			expect(result).to be =~ /"key"/
		end
	end
	
	with "#forward_form_event" do
		let(:element) {subject.new("test-element")}
		
		it "generates JavaScript without detail" do
			result = element.forward_form_event
			
			expect(result).to be =~ /live\.forwardFormEvent/
			expect(result).to be =~ /"test-element"/
		end
		
		it "generates JavaScript with detail" do
			result = element.forward_form_event({action: "submit"})
			
			expect(result).to be =~ /live\.forwardFormEvent/
			expect(result).to be =~ /"test-element"/
			expect(result).to be =~ /"action"/
		end
	end
	
	with "a mock page" do
		let(:page) do
			page = Object.new
			page.define_singleton_method(:enqueued){@enqueued ||= []}
			page.define_singleton_method(:enqueue){|args| enqueued << args}
			page
		end
		
		let(:element) do
			el = subject.new("rpc-test")
			el.bind(page)
			el
		end
		
		with "#rpc" do
			it "enqueues arguments to the page" do
				element.rpc(:test_method, "arg1", "arg2")
				
				expect(page.enqueued.last).to be == [:test_method, "arg1", "arg2"]
			end
			
			it "raises PageError when not bound" do
				unbound = subject.new("unbound")
				
				expect do
					unbound.rpc(:test)
				end.to raise_exception(Live::PageError)
			end
		end
		
		with "#update!" do
			it "enqueues an update RPC with the element id" do
				element.update!
				
				args = page.enqueued.last
				expect(args[0]).to be == :update
				expect(args[1]).to be == "rpc-test"
			end
		end
		
		with "#script" do
			it "enqueues a script RPC with the element id and code" do
				element.script("console.log('hello')")
				
				args = page.enqueued.last
				expect(args[0]).to be == :script
				expect(args[1]).to be == "rpc-test"
				expect(args[2]).to be == "console.log('hello')"
			end
		end
		
		with "#replace" do
			it "enqueues a replace RPC" do
				element.replace("#target", "<div>new</div>")
				
				args = page.enqueued.last
				expect(args[0]).to be == :replace
				expect(args[1]).to be == "#target"
			end
		end
		
		with "#prepend" do
			it "enqueues a prepend RPC" do
				element.prepend("#target", "<div>first</div>")
				
				args = page.enqueued.last
				expect(args[0]).to be == :prepend
				expect(args[1]).to be == "#target"
			end
		end
		
		with "#append" do
			it "enqueues an append RPC" do
				element.append("#target", "<div>last</div>")
				
				args = page.enqueued.last
				expect(args[0]).to be == :append
				expect(args[1]).to be == "#target"
			end
		end
		
		with "#remove" do
			it "enqueues a remove RPC" do
				element.remove("#target")
				
				args = page.enqueued.last
				expect(args[0]).to be == :remove
				expect(args[1]).to be == "#target"
			end
		end
		
		with "#dispatch_event" do
			it "enqueues a dispatchEvent RPC with correct type" do
				element.dispatch_event("#my-element", "click")
				
				args = page.enqueued.last
				expect(args[0]).to be == :dispatchEvent
				expect(args[1]).to be == "#my-element"
				expect(args[2]).to be == "click"
			end
			
			it "passes options through" do
				element.dispatch_event("[data-id=\"test\"]", "gametick", detail: {score: 42}, bubbles: true)
				
				args = page.enqueued.last
				expect(args[0]).to be == :dispatchEvent
				expect(args[1]).to be == "[data-id=\"test\"]"
				expect(args[2]).to be == "gametick"
				expect(args[3]).to be == {detail: {score: 42}, bubbles: true}
			end
		end
	end
	
	with "#bind and #close" do
		let(:element) {subject.new("lifecycle-test")}
		
		it "tracks the bound page" do
			expect(element.page).to be_nil
			
			page = Object.new
			element.bind(page)
			expect(element.page).to be == page
			
			element.close
			expect(element.page).to be_nil
		end
	end
end
