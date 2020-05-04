class ApplicationController < ActionController::Base
  before_action :check_account

  private

  def check_account
    current_account if rodauth.authenticated?
  rescue ActiveRecord::RecordNotFound
    rodauth.logout
    redirect_to rodauth.login_path, alert: "The account was deleted"
  end

  def current_account
    @current_account ||= Account.find(rodauth.session_value)
  end
  helper_method :current_account
end
