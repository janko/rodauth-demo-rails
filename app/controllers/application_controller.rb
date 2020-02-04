class ApplicationController < ActionController::Base
  private

  def current_account
    Account.find(auth.account_id)
  end
  helper_method :current_account

  def auth
    request.env["auth"]
  end
  helper_method :auth
end
