Rails.application.routes.draw do
  get "/", to: "application#index"
  get "/live", to: "application#live"
end
