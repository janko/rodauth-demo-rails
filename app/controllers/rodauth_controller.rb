class RodauthController < ApplicationController
  protected

  def set_webauthn_setup
    cookies.permanent[:webauthn_setup] = current_account.webauthn_keys.any?
  end
end
