require "sequel/core"

class RodauthBase < Rodauth::Rails::Auth
  configure do
    enable :create_account, :login, :email_auth, :logout,
      :reset_password, :change_password, :change_password_notify,
      :change_login, :verify_login_change,
      :otp, :sms_codes, :recovery_codes, :webauthn,
      :close_account

    # Initialize Sequel and have it reuse Active Record's database connection.
    db Sequel.postgres(extensions: :activerecord_connection, keep_reference: false)

    title_instance_variable :@page_title

    # Store account status in an integer column without foreign key constraint.
    account_status_column :status
    # Store password hash in a column instead of a separate table.
    account_password_hash_column :password_hash

    # Passwords shorter than 8 characters are considered weak according to OWASP.
    password_minimum_length 8
    # bcrypt has a maximum input length of 72 bytes, truncating any extra bytes.
    password_maximum_bytes 72

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
    create_password_changed_email do
      RodauthMailer.password_changed(self.class.configuration_name, account_id)
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

    # don't display error flash when requesting MFA after we've just logged in
    two_factor_need_authentication_error_flash { flash[:notice] == login_notice_flash ? nil : super() }
    # display generic message after multifactor authentication
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
