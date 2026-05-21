Rails.application.routes.draw do
  get "health", to: proc { [200, {}, [{ status: "ok", timestamp: Time.current }.to_json]] }

  scope :auth do
    post "register",        to: "auth#register"
    post "login",           to: "auth#login"
    post "refresh",         to: "auth#refresh"
    post "logout",          to: "auth#logout"
    post "forgot_password", to: "auth#forgot_password"
    post "reset_password",  to: "auth#reset_password"
  end

  get  "me", to: "users#me"
  patch "me", to: "users#update_me"

  resources :social_accounts, only: [:index, :create, :destroy]
  resources :videos, only: [:index, :show]

  scope :analytics do
    get "overview", to: "analytics#overview"
    get "videos/:id", to: "analytics#video", as: :analytics_video
    get "trends", to: "analytics#trends"
  end

  resources :insights, only: [:index] do
    member do
      patch :mark_read
      patch :dismiss
    end
  end

  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq"
end
