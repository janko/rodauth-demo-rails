require "omniauth-github"

class RodauthMain < RodauthBase
  configure do
    # List of authentication features that are loaded.
    enable :verify_account, :verify_account_grace_period, :active_sessions,
      :remember, :confirm_password, :password_grace_period,
      :i18n, :jwt

    # Specify the controller used for view rendering and CSRF verification.
    rails_controller { RodauthController }

    # Ask for password only when verifying the account.
    verify_account_set_password? false

    # Amount of time between asking for password for sensitive actions.
    password_grace_period 1.hour.to_i

    # Expire inactive sessions after 14 days and set infinite lifespan.
    session_inactivity_deadline 14.days.to_i
    session_lifetime_deadline nil

    # Use our own mailer for sending emails.
    create_verify_account_email do
      RodauthMailer.verify_account(self.class.configuration_name, account_id, verify_account_key_value)
    end

    after_login do
      # Remember all logged in users, and consider remembered users multifactor-authenticated.
      remember_login unless uses_two_factor_authentication? && !two_factor_authenticated?
      # Save whether a logged in user had passkeys setup for passkey login button
      rails_controller_instance.send(:set_webauthn_setup)
    end

    after_two_factor_authentication { remember_login }
    after_load_memory { two_factor_update_session("totp") if uses_two_factor_authentication? }

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
      super()
    end

    # Perform additional actions after the account is created.
    after_create_account do
      Profile.create!(account_id: account_id, name: param("name"))
    end

    # Do additional cleanup after the account is closed.
    after_close_account do
      Profile.find_by!(account_id: account_id).destroy
    end

    # Redirect to wherever login redirects to after account verification.
    verify_account_redirect { login_redirect }

    after_omniauth_create_account do
      Profile.create!(account_id: account_id, name: omniauth_name)
    end

    after_webauthn_setup { rails_controller_instance.send(:set_webauthn_setup) }

    # JSON API settings (using JWT)
    jwt_secret { ::Rails.application.secret_key_base }
    require_login_confirmation? { use_json? ? false : super() }
    require_password_confirmation? { use_json? ? false : super() }
  end
end
