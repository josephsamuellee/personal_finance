Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  resource :session, only: [ :new, :create, :destroy ]
  resources :users, only: [ :new, :create ]

  root "home#index"
  get "settings", to: "settings#show"
  patch "settings", to: "settings#update"

  get "quick-expense", to: "quick_expenses#new", as: :quick_expense
  post "quick-expense", to: "quick_expenses#create"

  resources :expenses
  resources :expense_imports, only: [ :new, :create ] do
    collection do
      get :preview
      post :confirm
      delete :cancel
    end
    member do
      post :reverse
    end
  end

  resources :accounts
  resources :securities, only: [ :create ]
  get "assets/maintenance", to: "asset_maintenance#show", as: :asset_maintenance
  get "assets", to: "holdings#index"
  get "holdings/:account_id/:security_id", to: "holdings#show", as: :holding
  post "holdings/positions", to: "holdings#update_position", as: :holding_positions
  post "holdings/balances", to: "holdings#update_balance", as: :holding_balances

  resources :reviews, only: [ :index, :show, :new, :create ], controller: "financial_reviews"
  resources :decisions, controller: "financial_decisions"
  resources :recurring_items, except: [ :show ]
  resources :savings_goals, except: [ :show ]
  resources :market_prices, only: [ :create ] do
    collection do
      post :refresh
    end
  end

  get "compare", to: "comparisons#show", as: :compare
  get "benchmark", to: "benchmarks#show", as: :benchmark
  get "charts/observations", to: "charts#observations", as: :chart_observations
  get "charts/net_worth", to: "charts#net_worth", as: :chart_net_worth
end
