class ApplicationController < ActionController::Base
  private

  def authenticate
    rodauth.require_account
  end
end
