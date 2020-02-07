class ApplicationController < ActionController::Base
  private

  def current_account
    Account.find rodauth.account_from_session.fetch(:id)
  end
  helper_method :current_account

  def rodauth
    request.env["rodauth"]
  end
  helper_method :rodauth
end
