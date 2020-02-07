class AuthenticationMailer < ApplicationMailer
  default from: "postmaster@myapp.com"

  def verify_account(rodauth)
    @confirmation_link = rodauth.verify_account_email_link

    mail to: rodauth.account[:email], subject: "Verify Account"
  end

  def reset_password(rodauth)
    @confirmation_link = rodauth.reset_password_email_link

    mail to: rodauth.account[:email], subject: "Reset Password"
  end
end
