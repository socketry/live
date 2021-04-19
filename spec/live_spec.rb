# frozen_string_literal: true

RSpec.describe Live do
	it "has a version number" do
		expect(Live::VERSION).not_to be nil
	end
end
