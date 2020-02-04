class ApplicationController < ActionController::Base
  private

  def auth
    request.env["auth"]
  end
  helper_method :auth
end
