require "roda"

module MyApp
  class Authentication
    class Middleware < Roda
      plugin :middleware

      plugin :render, views: "app/views", layout: false

      plugin :rodauth, csrf: :route_csrf, flash: false do
        enable :login, :create_account, :logout

        account_password_hash_column :password_hash

        require_login_confirmation? false

        login_view          { rails_render("login") }
        create_account_view { rails_render("register") }

        login_error_flash "Email or password was invalid"

        create_account_route "register"
        logout_redirect "/"

        login_param "email"
        password_confirm_param "confirm_password"

        auth_class_eval do
          def rails_render(template)
            renderer = ActionController::Renderer.new(AuthenticationController, scope.env, {})
            renderer.render template: "authentication/#{template}"
          end
        end
      end

      route do |r|
        env["auth"] = Object.new(rodauth)

        r.rodauth

        r.on "photos" do
          rodauth.require_authentication
        end
      end

      # store flash messages in Rails' flash object
      def flash
        env[ActionDispatch::Flash::KEY] ||= ActionDispatch::Flash::FlashHash.from_session_value(session["flash"])
      end
    end

    class Object
      attr_reader :rodauth

      def initialize(rodauth)
        @rodauth = rodauth
      end

      def field_error(name)
        rodauth.field_error(name.to_s)
      end

      def login_path
        "/#{rodauth.login_route}"
      end

      def register_path
        "/#{rodauth.create_account_route}"
      end

      def logout_path
        "/#{rodauth.logout_route}"
      end

      def logged_in?
        rodauth.logged_in?
      end
    end
  end
end
