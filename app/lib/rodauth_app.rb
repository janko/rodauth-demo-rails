class RodauthApp < Rodauth::Rails::App
  configure RodauthMain

  route do |r|
    rodauth.load_memory # autologin remembered users

    r.rodauth # route rodauth requests

    # require MFA if the user is logged in and has MFA setup
    if rodauth.logged_in? && rodauth.uses_two_factor_authentication?
      rodauth.require_two_factor_authenticated
    end

    # require authentication for /posts/* routes
    if r.path.start_with?("/posts")
      rodauth.require_authentication
    end
  end
end
