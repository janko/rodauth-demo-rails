require "sequel/core"

class RodauthBase < Rodauth::Rails::Auth
  configure do
    enable :create_account, :login, :email_auth, :logout, :active_sessions,
      :reset_password, :change_password, :change_login, :verify_login_change,
      :otp, :otp_unlock, :sms_codes, :recovery_codes,
      :webauthn, :webauthn_login,
      :close_account, :argon2, :omniauth, :audit_logging

    # Initialize Sequel and have it reuse Active Record's database connection.
    db Sequel.sqlite(extensions: :activerecord_connection, keep_reference: false)

    # Avoid DB queries on accounts table schema at boot time.
    convert_token_id_to_integer? { Account.columns_hash["id"].type == :integer }

    title_instance_variable :@page_title

    # Store account status in an integer column without foreign key constraint.
    account_status_column :status
    # Store password hash in a column instead of a separate table.
    account_password_hash_column :password_hash
    # Change login param from default "login".
    login_param "email"

    # Set up password pepper for argon2.
    argon2_secret Rails.application.credentials.argon2_secret
    # We're using argon2, so don't load bcrypt gem.
    require_bcrypt? false

    # Passwords shorter than 8 characters are considered weak according to OWASP.
    password_minimum_length 8
    # Having a maximum password length set prevents long password DoS attacks.
    password_maximum_length 64

    # Redirect back to originally requested location after authentication.
    login_return_to_requested_location? true
    two_factor_auth_return_to_requested_location? true

    before_create_account { account[:type] = account_type }

    create_reset_password_email do
      RodauthMailer.reset_password(self.class.configuration_name, account_id, reset_password_key_value)
    end
    create_verify_login_change_email do |_login|
      RodauthMailer.verify_login_change(self.class.configuration_name, account_id, verify_login_change_key_value)
    end
    create_email_auth_email do
      RodauthMailer.email_auth(self.class.configuration_name, account_id, email_auth_key_value)
    end
    send_email do |email|
      # queue email delivery on the mailer after the transaction commits
      db.after_commit { email.deliver_later }
    end

    # Print SMS codes to console in development
    sms_send do |phone_number, message|
      Rails.logger.info "\n#{phone_number} =====> #{message}\n"
    end

    # Automatically generate recovery codes after TOTP setup.
    auto_add_recovery_codes? true

    # Automatically remove recovery codes after disabling last MFA method.
    auto_remove_recovery_codes? true

    # Display recovery codes after TOTP setup.
    after_otp_setup do
      set_notice_now_flash "#{otp_setup_notice_flash}, please make note of your recovery codes"
      return_response add_recovery_codes_view
    end

    # Require setting a nickname for WebAuthn credentials.
    before_webauthn_setup do
      throw_error_status(422, "nickname", "must be set") if param("nickname").empty?
    end
    webauthn_key_insert_hash do |credential|
      super(credential).merge(nickname: param("nickname"))
    end

    # Count login via passkey with biometrics/PIN verification as two factors.
    webauthn_login_user_verification_additional_factor? true

    if github = Rails.application.credentials.github
      omniauth_provider :github, github[:client_id], github[:client_secret]
    end

    omniauth_identity_insert_hash { super().merge(created_at: Time.now) }
    omniauth_identity_update_hash { { updated_at: Time.now } }

    audit_log_metadata_for :login do
      { "provider" => omniauth_provider } if authenticated_by.include?("omniauth")
    end

    # Redirect directly to MFA auth page if using MFA.
    login_redirect { two_factor_partially_authenticated? ? two_factor_auth_required_redirect : super() }
    # Let the user know they also need to authenticate with 2nd factor.
    login_notice_flash { two_factor_partially_authenticated? ? "Please authenticate with 2nd factor" : super() }
    # Display general logged in message after multifactor authentication.
    two_factor_auth_notice_flash { login_notice_flash }

    # Redirect to home page after logout.
    logout_redirect "/"

    # Redirect to login page after password reset.
    reset_password_redirect { login_path }
  end

  private

  def account_table_ds
    super.where(type: account_type)
  end

  def account_type
    self.class.configuration_name&.to_s || "main"
  end
end
