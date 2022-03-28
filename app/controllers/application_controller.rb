class ApplicationController < ActionController::Base
  private

  def authenticate
    rodauth.require_authentication
  end
end
