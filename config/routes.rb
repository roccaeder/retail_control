Rails.application.routes.draw do
  get "dashboard/index"
  mount Avo::Engine, at: Avo.configuration.root_path

  devise_for :users, controllers: { registrations: "users/registrations" }

  root "dashboard#index"

  resources :customers
  resources :products do
    get "search", on: :collection
  end
  resources :sales do
    resources :payments, only: [ :new, :create ]
  end

  resources :suppliers
  resources :purchases do
    member { patch :receive }
  end
  resources :supplier_imports, only: [ :index, :new, :create, :show ]

  resources :expenses, only: [ :index, :new, :create, :destroy ]

  # Rutas de salud del sistema (Rails 8)
  get "up" => "rails/health#show", as: :rails_health_check
end
