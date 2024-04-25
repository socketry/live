# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

Rails.application.routes.draw do
  get "/", to: "application#index"
  get "/live", to: "application#live"
end
