Rails.application.routes.draw do
  root to: "home#index"
  resources :posts

  namespace :admin do
    root to: "home#index"
  end
end
