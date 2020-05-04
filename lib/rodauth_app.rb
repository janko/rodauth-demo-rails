class RodauthApp < Rodauth::Rails::App
  configure do
    # List of authentication features that are loaded.
    enable :create_account, :verify_account, :verify_account_grace_period,
      :login, :email_auth, :remember, :logout,
      :reset_password, :change_password, :change_password_notify,
      :change_login, :verify_login_change,
      :confirm_password, :password_grace_period,
      :otp, :sms_codes, :recovery_codes,
      :close_account, :lockout

    # Specify the controller used for view rendering and CSRF verification.
    rails_controller { RodauthController }

    # Store account status in a text column.
    account_status_column :status
    account_unverified_status_value "unverified"
    account_open_status_value "verified"
    account_closed_status_value "closed"

    # Set password when creating account instead of when verifying.
    verify_account_set_password? false

    # Amount of invalid logins allowed before the account is locked.
    max_invalid_logins 3

    # Redirect back to originally requested location after authentication.
    login_return_to_requested_location? true
    two_factor_auth_return_to_requested_location? true

    # Amount of time between asking for password for sensitive actions.
    password_grace_period 60*60

    # Autologin the user after they have reset their password.
    reset_password_autologin? true

    # Delete the account record when the user has closed their account.
    delete_account_on_close? true

    # Uses our own mailer for sending emails.
    send_reset_password_email do
      RodauthMailer.reset_password(email_to, password_reset_email_link).deliver_later
    end
    send_verify_account_email do
      RodauthMailer.verify_account(email_to, verify_account_email_link).deliver_later
    end
    send_verify_login_change_email do |login|
      RodauthMailer.verify_login_change(login, verify_login_change_old_login, verify_login_change_new_login, verify_login_change_email_link).deliver_later
    end
    send_password_changed_email do
      RodauthMailer.password_changed(email_to).deliver_later
    end
    send_email_auth_email do
      RodauthMailer.email_auth(email_to, email_auth_email_link).deliver_now
    end
    send_unlock_account_email do
      @unlock_account_key_value = get_unlock_account_key
      RodauthMailer.unlock_account(email_to, unlock_account_email_link).deliver_now
    end

    # Print SMS codes to console in development
    sms_send do |phone_number, message|
      puts
      puts "#{phone_number} =====> #{message}"
      puts
    end

    # Remember all logged in users.
    after_login { remember_login }

    # Extend user's remember period when remembered via a cookie
    extend_remember_deadline? true

    # Consider remembered users to be multifactor-authenticated (if using MFA).
    after_load_memory { two_factor_update_session("totp") if two_factor_authentication_setup? }

    # Redirect to password confirmation dialog before these routes
    before_change_password_route    { require_password_authentication }
    before_change_login_route       { require_password_authentication }
    before_two_factor_manage_route  { require_password_authentication }
    before_two_factor_disable_route { require_password_authentication }

    # Validate custom fields in the create account form.
    before_create_account do
      throw_error_status(422, "name", "must be present") if param("name").empty?
    end

    # Perform additional actions after the account is created.
    after_create_account do
      Profile.create!(account_id: account[:id], name: param("name"))
    end

    # Do additional cleanup after the account is closed.
    after_close_account do
      Profile.find_by!(account_id: account[:id]).destroy
    end

    # ==> Redirects
    # Redirect to home page after logout.
    logout_redirect "/"

    # Redirect to wherever login redirects to after account verification.
    verify_account_redirect { login_redirect }

    # Redirect to login page after password reset.
    reset_password_redirect { login_path }
  end

  route do |r|
    rodauth.load_memory # autologin remembered users

    r.rodauth # route rodauth requests

    # require authentication for /posts/* routes
    if r.path.start_with?("/posts")
      rodauth.require_authentication
    end
  end
end
