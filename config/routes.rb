Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "authentication/login"

      # Sleep Records endpoints
      post "sleep_records/clock_in", to: "sleep_records#clock_in"
      post "sleep_records/clock_out", to: "sleep_records#clock_out"
      get "sleep_records", to: "sleep_records#index"

      # Follows endpoints
      post :follow, to: "follows#create"
      delete :unfollow, to: "follows#destroy"
      get :following, to: "follows#following"
      get :followers, to: "follows#followers"
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"
end
