# --- append inside the Rails.application.routes.draw block ---
namespace :api do
  namespace :v1 do
    resources :webhooks, only: [:index, :show] do
      resources :replays, only: [:create]
    end
    post "webhooks/:source", to: "webhooks#create"
  end
end
