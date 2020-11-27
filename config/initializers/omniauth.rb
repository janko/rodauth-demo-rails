Rails.application.config.middleware.use OmniAuth::Builder do
  if facebook = Rails.application.credentials.facebook
    provider :facebook, facebook[:app_id], facebook[:app_secret],
      scope: "email", callback_path: "/auth/facebook/callback"
  end
end
