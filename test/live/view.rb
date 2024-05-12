require 'live/view'

describe Live::View do
	let(:view) {subject.new('test-id')}
	
	with "#to_s" do
		it "can generate string representation" do
			expect(view.to_s).to be == <<~HTML.chomp
				<div id="test-id" class="live" data-class="Live::View">
				</div>
			HTML
		end
	end
end