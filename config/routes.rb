Rails.application.routes.draw do
  get "dashboard/index"
  mount Avo::Engine, at: Avo.configuration.root_path

  devise_for :users

  root "dashboard#index"

  resources :customers
  resources :products
  resources :sales

  # Rutas de salud del sistema (Rails 8)
  get "up" => "rails/health#show", as: :rails_health_check
end