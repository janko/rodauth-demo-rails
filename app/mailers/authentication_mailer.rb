class AuthenticationMailer < ApplicationMailer
  default from: "postmaster@myapp.com"

  def verify_account(email:, link:)
    @confirmation_link = link

    mail to: email, subject: "Verify Account"
  end

  def reset_password(email:, link:)
    @confirmation_link = link

    mail to: email, subject: "Reset Password"
  end
end
