# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

describe Live do
	it "has a version number" do
		expect(Live::VERSION).to be =~ /\d+\.\d+\.\d+/
	end
end
