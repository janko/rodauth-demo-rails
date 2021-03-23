class RodauthApp < Rodauth::Rails::App
  configure RodauthMain

  route do |r|
    rodauth.load_memory # autologin remembered users

    r.rodauth # route rodauth requests

    # require authentication for /posts/* routes
    if r.path.start_with?("/posts")
      rodauth.require_authentication
    end
  end
end
