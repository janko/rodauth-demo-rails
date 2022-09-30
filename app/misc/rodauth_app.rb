class RodauthApp < Rodauth::Rails::App
  configure RodauthMain
  configure RodauthAdmin, :admin

  route do |r|
    rodauth.load_memory # autologin remembered users

    r.rodauth # route rodauth requests
    r.rodauth(:admin)

    # require MFA if the user is logged in and has MFA setup
    if rodauth.uses_two_factor_authentication?
      rodauth.require_two_factor_authenticated
    end

    if rodauth(:admin).logged_in?
      rodauth(:admin).require_two_factor_setup
    end

    if r.path.start_with?("/admin")
      rodauth(:admin).require_authentication
    end
  end
end
