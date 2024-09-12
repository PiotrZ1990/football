Rails.application.routes.draw do
  devise_for :users
  root 'teams#index'

  resources :leagues do
    get 'rankings', to: 'teams#league_rankings'
    post 'compare_teams', on: :member
  end

  resources :teams do
    member do
      get 'history'
    end
    collection do
      get 'export_all_to_excel'
    end
  end

  resources :matches do
    resources :tickets, only: [:create, :show]
  end

  get 'up' => 'rails/health#show', as: :rails_health_check
end
