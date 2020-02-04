require "roda"

module MyApp
  class Authentication
    class Middleware < Roda
      plugin :middleware

      plugin :render, views: "app/views", layout: false
      plugin :pass

      plugin :rodauth, csrf: :route_csrf, flash: false do
        enable :login, :create_account, :verify_account, :reset_password, :logout

        # flow changes
        account_password_hash_column :password_hash
        require_login_confirmation? false
        verify_account_skip_resend_email_within 1

        # views
        login_view                  { rails_render("login")                  }
        create_account_view         { rails_render("register")               }
        verify_account_view         { rails_render("verify_account")         }
        resend_verify_account_view  { rails_render("verify_account_resend")  }
        reset_password_request_view { rails_render("reset_password_request") }
        reset_password_view         { rails_render("reset_password")         }

        # route changes
        create_account_route "register"

        # action redirects
        verify_account_redirect "/posts"
        login_redirect "/posts"
        logout_redirect "/"

        # param changes
        login_param "email"
        password_confirm_param "confirm_password"

        # emails
        send_verify_account_email do
          rails_send_email :verify_account,
            email: account.fetch(:email),
            link:  verify_account_email_link
        end
        send_reset_password_email do
          rails_send_email :reset_password,
            email: account.fetch(:email),
            link:  reset_password_email_link
        end

        auth_class_eval do
          # render templates with Rails renderer instead of Tilt
          def rails_render(template)
            renderer = ActionController::Renderer.new(AuthenticationController, scope.env, {})
            renderer.render template: "authentication/#{template}"
          end

          def rails_send_email(template, **params)
            AuthenticationMailer.public_send(template, **params).deliver_now
          end
        end
      end

      route do |r|
        env["auth"] = Object.new(rodauth)

        r.rodauth

        r.on "posts" do
          rodauth.require_authentication

          r.pass
        end
      end

      # store flash messages in Rails' flash object instead of Roda's
      def flash
        env[ActionDispatch::Flash::KEY] ||= ActionDispatch::Flash::FlashHash.from_session_value(session["flash"])
      end
    end

    class Object
      attr_reader :rodauth

      def initialize(rodauth)
        @rodauth = rodauth
      end

      def account_id
        rodauth.account_from_session.fetch(:id)
      end

      def param(name)
        rodauth.param_or_nil(name)
      end

      def field_error(name)
        rodauth.field_error(name.to_s)
      end

      def register_path
        create_account_path
      end

      def logged_in?
        rodauth.logged_in?
      end

      private

      # Catches all *_path methods and calls corresponding *_route methods
      def method_missing(name, *args, **options, &block)
        if name =~ /_path$/
          route_method = name.to_s.sub(/_path$/, "_route")
          route        = rodauth.public_send(route_method)

          "/#{route}"
        else
          super
        end
      end
    end
  end
end
