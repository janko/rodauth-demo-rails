require "sequel"

database_config = ActiveRecord::Base.configurations.default_hash

# Sequel connection is needed for Rodauth
Sequel.connect(
  adapter:  database_config.fetch("adapter"),
  database: database_config.fetch("database"),
)

class AuthenticationMiddleware
  def initialize(app)
    @app = app
  end

  # hack to allow MyApp::Authentication to still be reloadable
  def call(env)
    MyApp::Authentication::Middleware.new(@app).call(env)
  end
end

Rails.application.config.middleware.use AuthenticationMiddleware
