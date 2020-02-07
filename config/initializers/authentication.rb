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
