class RodauthAdmin < RodauthBase
  configure do
    enable :lockout, :password_complexity, :disallow_common_passwords,
      :pwned_password, :internal_request

    rails_controller { Admin::RodauthController }

    prefix "/admin"
    session_key_prefix "admin_"

    # disallow creating accounts via the UI
    create_account_route nil

    # Don't allow OmniAuth login to auto-create admin accounts.
    omniauth_create_account? false

    # Amount of invalid logins allowed before the account is locked.
    max_invalid_logins 3

    # Expire sessions 12 hours after login.
    session_lifetime_deadline 12.hours.to_i

    # Delete the account record when the user has closed their account.
    delete_account_on_close? true

    create_unlock_account_email do
      RodauthMailer.unlock_account(self.class.configuration_name, account_id, unlock_account_key_value)
    end

    password_pwned? { |password| false } if Rails.env.test?
    password_allowed_pwned_count 5
    pwned_request_options open_timeout: 1, read_timeout: 2
    after_login do
      super()
      db.after_commit do # better to make HTTP requests outside of transactions
        if param_or_nil(password_param) && password_pwned?(param(password_param))
          set_redirect_error_flash "Your password has previously appeared in a data breach and should never be used. We strongly recommend you change your password."
        end
      end
    end

    unlock_account_redirect { two_factor_auth_path }
    default_redirect { logged_in? ? "/admin" : "/" }
  end
end
