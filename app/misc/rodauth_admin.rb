class RodauthAdmin < RodauthBase
  configure do
    enable :lockout, :password_complexity, :disallow_common_passwords,
      :pwned_password, :internal_request

    rails_controller { Admin::RodauthController }

    prefix "/admin"
    session_key_prefix "admin_"

    # disallow creating accounts via the UI
    create_account_route nil

    # Amount of invalid logins allowed before the account is locked.
    max_invalid_logins 3

    # Delete the account record when the user has closed their account.
    delete_account_on_close? true

    create_unlock_account_email do
      RodauthMailer.unlock_account(self.class.configuration_name, account_id, unlock_account_key_value)
    end

    # avoid making HTTP requests in tests
    password_pwned? { |password| false } if Rails.env.test?

    # require password to be pwned multiple times
    password_allowed_pwned_count 5

    unlock_account_redirect { two_factor_auth_path }
    default_redirect { logged_in? ? "/admin" : "/" }
  end
end
