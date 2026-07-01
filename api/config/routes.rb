Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :webhooks, only: [:index, :show] do
        resources :replays, only: [:create]
      end
      post "webhooks/:source", to: "webhooks#create"
    end
  end
end