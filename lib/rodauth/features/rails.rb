require "sequel"

module Rodauth
  Feature.define(:rails, :Rails) do
    auth_value_method :activerecord_config, ApplicationRecord.configurations.default_hash
    auth_value_method :rails_controller, ApplicationController
    auth_value_method :rails_view_directory, nil
    auth_value_method :rails_mailer, nil
    auth_value_method :rails_mailer_deliver_method, :deliver_now

    auth_methods(
      :rails_render_view,
      :rails_send_email,
      :rails_create_email,
      :rails_flash,
      :rails_verify_authenticity_token,
    )

    def post_configure
      activerecord_connect unless db

      # go to the Rodauth::Auth class level
      self.class.class_eval do
        routes.each do |route_method|
          route_name = route_method.to_s.sub(/^handle_/, "")

          define_method(:"#{route_name}_path") { route_path(route_name) }
          define_method(:"#{route_name}_url")  { route_url(route_name) }
        end

        instance_methods.grep(/^send_(.+)_email$/) do |send_email_method|
          action = send_email_method.match(/^send_(.+)_email$/)[1]

          define_method(send_email_method) do
            rails_mailer ? rails_send_email(action) : super
          end
        end

        roda_class.class_eval do
          plugin :middleware
          plugin :render, views: "app/views", layout: false
          plugin :pass
          plugin :hooks

          before { env["rodauth"] = rodauth }
        end
      end

      super
    end

    def view(page, title)
      action = page.tr("-", "_")
      rails_render_view(action)
    end

    # verify CSRF token before each rodauth route
    def before_rodauth
      rails_verify_authenticity_token
      super
    end

    # override flash to use Rails flash
    def flash
      rails_flash
    end

    # renders templates using ActionController renderer
    def rails_render_view(action)
      renderer = ActionController::Renderer.new(rails_controller, scope.env, {})
      renderer.render template: "#{rails_view_directory}/#{action}"
    end

    # sends email using ActionMailer
    def rails_send_email(action)
      email = rails_create_email(action)
      email.public_send(rails_mailer_deliver_method)
    end

    # creates email using ActionMailer
    def rails_create_email(action)
      rails_mailer.public_send(action, self)
    end

    # uses ActionDispatch flash for flash messages
    def rails_flash
      scope.env[ActionDispatch::Flash::KEY] ||= ActionDispatch::Flash::FlashHash.from_session_value(session["flash"])
    end

    # verifies CSRF token from Rails forms
    def rails_verify_authenticity_token
      controller = rails_controller.new
      controller.set_request! ActionDispatch::Request.new(scope.env)
      controller.send(:verify_authenticity_token)
    end

    # generates URL for the route
    def route_url(route_name)
      "#{request.base_url}#{rails_route_path(route_name)}"
    end

    # generate path for the route
    def route_path(route_name)
      "#{prefix}/#{public_send(:"#{route_name}_route")}"
    end

    private

    # connects to the same database as ActiveRecord
    def activerecord_connect
      Sequel.connect(
        adapter:  activerecord_config.fetch("adapter"),
        database: activerecord_config.fetch("database"),
      )
    end
  end
end
