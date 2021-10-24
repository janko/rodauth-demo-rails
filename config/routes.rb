Rails.application.routes.draw do
  root to: "home#index"
  resources :posts
  get "/download-recovery-codes", to: "rodauth#download_recovery_codes"
  get "/auth/:provider/callback", to: "rodauth#omniauth"
end
