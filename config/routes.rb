Rails.application.routes.draw do
  root to: "home#index"
  resources :posts
  get "/auth/:provider/callback", to: "rodauth#omniauth"

  namespace :admin do
    root to: "home#index"
  end
end
