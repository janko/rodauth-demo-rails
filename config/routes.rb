Rails.application.routes.draw do
  resources :posts
  root to: "home#index"
end
