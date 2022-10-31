class ApplicationController < ActionController::Base
  private

  def current_account
    rodauth.rails_account
  end
  helper_method :current_account

  def authenticate
    rodauth.require_account
  end
end
