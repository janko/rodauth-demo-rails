class RodauthMain < Rodauth::Rails::Auth
  configure do
    # List of authentication features that are loaded.
    enable :create_account, :verify_account, :verify_account_grace_period,
      :login, :email_auth, :remember, :logout,
      :reset_password, :change_password, :change_password_notify,
      :change_login, :verify_login_change,
      :confirm_password, :password_grace_period,
      :otp, :sms_codes, :recovery_codes,
      :close_account, :lockout, :i18n, :jwt

    # JSON API settings (using JWT)
    jwt_secret { ::Rails.application.secret_key_base }
    require_login_confirmation? { use_json? ? false : super() }
    require_password_confirmation? { use_json? ? false : super() }

    # Specify the controller used for view rendering and CSRF verification.
    rails_controller { RodauthController }

    # Store account status in an integer column without foreign key constraint.
    account_status_column :status

    # Ask for password only when verifying the account.
    verify_account_set_password? true

    # Amount of invalid logins allowed before the account is locked.
    max_invalid_logins 3

    # Redirect back to originally requested location after authentication.
    login_return_to_requested_location? true
    two_factor_auth_return_to_requested_location? true

    # Amount of time between asking for password for sensitive actions.
    password_grace_period 1.hour

    # Delete the account record when the user has closed their account.
    delete_account_on_close? true

    # Use our own mailer for sending emails.
    create_reset_password_email do
      RodauthMailer.reset_password(account_id, reset_password_key_value)
    end
    create_verify_account_email do
      RodauthMailer.verify_account(account_id, verify_account_key_value)
    end
    create_verify_login_change_email do |_login|
      RodauthMailer.verify_login_change(account_id, verify_login_change_old_login, verify_login_change_new_login, verify_login_change_key_value)
    end
    create_password_changed_email do
      RodauthMailer.password_changed(account_id)
    end
    create_email_auth_email do
      RodauthMailer.email_auth(account_id, email_auth_key_value)
    end
    create_unlock_account_email do
      RodauthMailer.unlock_account(account_id, unlock_account_key_value)
    end
    send_email do |email|
      # queue email delivery on the mailer after the transaction commits
      db.after_commit { email.deliver_later }
    end

    # Print SMS codes to console in development
    sms_send do |phone_number, message|
      Rails.logger.info "\n#{phone_number} =====> #{message}\n"
    end

    # Remember all logged in users.
    after_login { remember_login }

    # Extend user's remember period when remembered via a cookie
    extend_remember_deadline? true

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
      Profile.create!(account_id: account_id, name: param("name"))
    end

    # Do additional cleanup after the account is closed.
    after_close_account do
      Profile.find_by!(account_id: account_id).destroy
    end

    # Auto generate recovery codes after TOTP setup.
    auto_add_recovery_codes? true

    # Display recovery codes after TOTP setup.
    after_otp_setup do
      set_notice_now_flash "#{otp_setup_notice_flash}, please make note of your recovery codes"
      response.write add_recovery_codes_view
      request.halt # don't process the request any further
    end

    # Redirect the user to the MFA page if they have MFA setup.
    login_redirect do
      if uses_two_factor_authentication?
        two_factor_auth_required_redirect
      else
        "/"
      end
    end

    # Redirect to home page after logout.
    logout_redirect "/"

    # Redirect to wherever login redirects to after account verification.
    verify_account_redirect { login_redirect }

    # Redirect to login page after password reset.
    reset_password_redirect { login_path }
  end
end
