class RodauthApp < Rodauth::Rails::App
  configure RodauthMain
  configure RodauthAdmin, :admin

  route do |r|
    rodauth.check_active_session
    rodauth(:admin).check_active_session

    r.rodauth # route rodauth requests
    r.rodauth(:admin)

    if rodauth(:admin).logged_in?
      rodauth(:admin).require_two_factor_setup
    end

    if r.path.start_with?("/admin")
      rodauth(:admin).require_authentication
    end
  end
end
