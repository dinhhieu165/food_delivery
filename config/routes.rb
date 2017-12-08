Rails.application.routes.draw do
  resources :users
  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  get "/logout", to: "sessions#destroy"
  resources :account_activations
  resources :password_resets,     only: [:new, :create, :edit, :update]
  post "sessions/create" => "sessions#create"
end
