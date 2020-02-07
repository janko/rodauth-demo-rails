require "roda"

module MyApp
  class Authentication
    class Middleware < Roda
      plugin :rodauth, csrf: false, flash: false do
        enable :login, :create_account, :verify_account, :reset_password, :logout
        enable :rails # Rails integration

        rails_controller AuthenticationController
        rails_view_directory "authentication"
        rails_mailer AuthenticationMailer

        # flow changes
        account_password_hash_column :password_hash
        require_login_confirmation? false
        verify_account_skip_resend_email_within 1

        # action redirects
        verify_account_redirect "/posts"
        login_redirect "/posts"
        logout_redirect "/"

        # param changes
        login_param "email"
        password_confirm_param "confirm_password"
      end

      route do |r|
        r.rodauth

        r.on "posts" do
          rodauth.require_authentication

          r.pass
        end
      end
    end
  end
end
