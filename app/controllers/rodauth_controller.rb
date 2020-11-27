class RodauthController < ApplicationController
  # used by Rodauth for rendering views and CSRF protection

  def omniauth
    auth = request.env["omniauth.auth"]

    # attempt to find existing identity directly
    identity = AccountIdentity.find_by(provider: auth["provider"], uid: auth["uid"])

    if identity
      # update any external info changes
      identity.update!(info: auth["info"])
      # set account from identity
      account = identity.account
    end

    # attempt to find an existing account by email
    account ||= Account.find_by(email: auth["info"]["email"])

    # disallow login if account is not verified
    if account && account.status != rodauth.account_open_status_value
      redirect_to rodauth.login_path, alert: rodauth.unverified_account_message
      return
    end

    # create new account if it doesn't exist and make it verified
    unless account
      account = Account.create!(email: auth["info"]["email"], status: rodauth.account_open_status_value)
      account.create_profile!(name: auth["info"]["name"])
    end

    # create new identity if it doesn't exist
    unless identity
      account.identities.create!(provider: auth["provider"], uid: auth["uid"], info: auth["info"])
    end

    # login with Rodauth
    rodauth.account_from_login(account.email)
    rodauth.login("omniauth")
  end
end
