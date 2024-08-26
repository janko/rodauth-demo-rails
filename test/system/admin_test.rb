require "test_helper"

class AdminTest < ActionDispatch::SystemTestCase
  include ActiveJob::TestHelper
  driven_by :rack_test

  test "login" do
    visit "/admin/login"
    fill_in "Login", with: accounts(:one).email
    click_on "Login"
    assert_match "no matching login", page.text

    create_account(email: "admin@example.com", password: "Sekret197")
    fill_in "Login", with: "admin@example.com"
    click_on "Login"
    assert_match "Login recognized", page.text
    fill_in "Password", with: "Sekret197"
    click_on "Login"
    assert_match "This account has not been setup for multifactor authentication", page.text

    click_on "Setup TOTP Authentication"
    fill_in "Password", with: "Sekret197"
    totp = ROTP::TOTP.new(page.text[/Secret: (\w+)/, 1])
    fill_in "Authentication Code", with: totp.now
    click_on "Setup TOTP Authentication"
    assert_match "TOTP authentication is now setup", page.text

    visit "/admin"
    assert_match "Hello from Admin", page.text
  end

  test "lockout" do
    create_account(email: "admin@example.com", password: "Sekret197")
    setup_otp(email: "admin@example.com")

    login(email: "admin@example.com", password: "incorrect secret")
    assert_match "There was an error logging in", page.text

    login(email: "admin@example.com", password: "incorrect secret")
    assert_match "There was an error logging in", page.text

    login(email: "admin@example.com", password: "incorrect secret")
    assert_match "There was an error logging in", page.text

    login(email: "admin@example.com")
    assert_match "This account is currently locked out and cannot be logged in to", page.text

    click_on "Request Account Unlock"
    assert_match "An email has been sent to you with a link to unlock your account", page.text

    visit email_link
    click_on "Unlock Account"
    assert_match "Your account has been unlocked", page.text
    assert_equal "/admin/multifactor-auth", current_path
  end

  def create_account(email:, password:)
    RodauthApp.rodauth(:admin).create_account(login: "admin@example.com", password: "Sekret197")
  end

  def setup_otp(email:)
    otp_setup_params = RodauthApp.rodauth(:admin).otp_setup_params(account_login: "admin@example.com")
    otp_setup_params[:otp_auth] = ROTP::TOTP.new(otp_setup_params[:otp_setup]).now

    RodauthApp.rodauth(:admin).otp_setup(account_login: "admin@example.com", **otp_setup_params)
  end

  def login(email:, password: nil)
    visit "/admin/login"
    fill_in "Login", with: email
    click_on "Login"

    if password
      assert_match "Login recognized, please enter your password", page.text
      fill_in "Password", with: password
      click_on "Login"
    end
  end

  def email_link
    perform_enqueued_jobs
    RodauthMailer.deliveries.last.body.to_s[%r{https?://\S+}]
  end
end
