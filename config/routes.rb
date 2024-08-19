Rails.application.routes.draw do
  root 'teams#index'
  resources :leagues do
    get 'rankings', to: 'teams#league_rankings'
  end
  resources :teams do
    member do
      get 'history'
      get :quick_edit
      patch :quick_update
    end
  end

  get 'up' => 'rails/health#show', as: :rails_health_check
end
