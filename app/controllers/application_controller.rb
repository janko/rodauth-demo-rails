class ApplicationController < ActionController::Base
  before_action :current_account, if: -> { rodauth.logged_in? }

  private

  def current_account
    @current_account ||= Account.find(rodauth.session_value)
  rescue ActiveRecord::RecordNotFound
    rodauth.logout
    rodauth.login_required
  end
  helper_method :current_account
end
