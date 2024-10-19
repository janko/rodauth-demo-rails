require "test_helper"
require "webauthn/fake_client"

class AuthenticationTest < ActionDispatch::SystemTestCase
  include ActiveJob::TestHelper
  driven_by :rack_test

  def setup
    super
    visit "/"
  end

  test "create and verify account" do
    click_on "Sign up"
    fill_in "Name", with: "Janko"
    fill_in "Email", with: "janko@hey.com"
    fill_in "Password",         with: "secret123"
    fill_in "Confirm Password", with: "secret123"
    click_on "Create Account"

    assert_match "An email has been sent to you with a link to verify your account", page.text
    assert_equal "/", page.current_path
    assert_match "Janko", page.text

    visit email_link
    click_on "Verify Account"

    assert_match "Your account has been verified", page.text
    assert_equal "/", page.current_path
    assert_match "Janko", page.text
  end

  test "password login" do
    create_account(email: "janko@hey.com", password: "secret123")
    logout

    click_on "Sign in"
    fill_in "Email", with: "janko@hey.com"
    click_on "Login"

    assert_match "Login recognized, please enter your password", page.text

    fill_in "Password", with: "secret123"
    click_on "Login"

    assert_match "You have been logged in", page.text
    assert_equal "/", page.current_path
  end

  test "email login" do
    create_account(email: "janko@hey.com")
    logout

    click_on "Sign in"
    fill_in "Email", with: "janko@hey.com"
    click_on "Login"

    assert_match "Login recognized, please enter your password", page.text

    click_on "Send Login Link Via Email"
    visit email_link
    click_on "Login"

    assert_match "You have been logged in", page.text
    assert_equal "/", page.current_path
  end

  test "logout" do
    create_account

    dropdown_click "Sign out"

    assert_match "You have been logged out", page.text
    assert_equal "/", page.current_path
    refute_match "Janko", page.text
  end

  test "reset password" do
    create_account(email: "janko@hey.com", password: "secret123")
    logout

    click_on "Sign in"
    click_on "Forgot Password?"
    fill_in "Email", with: "janko@hey.com"
    click_on "Request Password Reset"

    assert_match "An email has been sent to you with a link to reset the password", page.text

    visit email_link
    fill_in "Password", with: "new secret"
    fill_in "Confirm Password", with: "new secret"
    click_on "Reset Password"

    assert_match "Your password has been reset", page.text
    assert_equal "/login", page.current_path

    login(email: "janko@hey.com", password: "new secret")
    assert_match "You have been logged in", page.text
  end

  test "change password" do
    create_account(email: "janko@hey.com", password: "secret123")

    dropdown_click "Change password"
    fill_in "Password", with: "secret123"
    click_on "Confirm Password"

    fill_in "New Password", with: "new secret"
    fill_in "Confirm Password", with: "new secret"
    click_on "Change Password"

    assert_match "Your password has been changed", page.text
    assert_equal "/", page.current_path

    logout
    login(email: "janko@hey.com", password: "new secret")
    assert_match "You have been logged in", page.text
  end

  test "change email" do
    create_account(email: "janko@hey.com", password: "secret123")

    dropdown_click "Change email"
    fill_in "Password", with: "secret123"
    click_on "Confirm Password"

    fill_in "Email", with: "janko@bye.com"
    click_on "Change Email"

    assert_match "An email has been sent to you with a link to verify your login change", page.text

    visit email_link
    click_on "Verify Login Change"

    assert_match "Your login change has been verified", page.text
    assert_equal "/", page.current_path

    logout
    login(email: "janko@bye.com", password: "secret123")
    assert_match "You have been logged in", page.text
  end

  test "close account" do
    create_account(email: "janko@hey.com", password: "secret123")

    dropdown_click "Close account"
    fill_in "Password", with: "secret123"
    click_on "Close Account"

    assert_match "Your account has been closed", page.text
    refute_match "Janko", page.text
  end

  test "OTP" do
    create_account(email: "janko@hey.com", password: "secret123")

    dropdown_click "Manage MFA"
    fill_in "Password", with: "secret123"
    click_on "Confirm Password"

    click_on "Setup TOTP Authentication"
    totp = ROTP::TOTP.new(page.text[/Secret: (\w+)/, 1])
    fill_in "Authentication Code", with: totp.now
    click_on "Setup TOTP Authentication"

    assert_match "TOTP authentication is now setup", page.text

    logout
    login(email: "janko@hey.com", password: "secret123")

    Account::OtpKey.update_all(last_use: 1.minute.ago)
    click_on "Authenticate Using TOTP"
    fill_in "Authentication Code", with: totp.now
    click_on "Authenticate Using TOTP"

    assert_match "You have been logged in", page.text
  end

  test "SMS codes" do
    create_account(email: "janko@hey.com", password: "secret123")

    dropdown_click "Manage MFA"
    fill_in "Password", with: "secret123"
    click_on "Confirm Password"

    click_on "Setup TOTP Authentication"
    totp = ROTP::TOTP.new(page.text[/Secret: (\w+)/, 1])
    fill_in "Authentication Code", with: totp.now
    click_on "Setup TOTP Authentication"

    dropdown_click "Manage MFA"
    click_on "Setup Backup SMS Authentication"
    fill_in "Phone Number", with: "0123456789"
    click_on "Setup SMS Backup Number"
    fill_in "SMS Code", with: Account::SmsCode.first.code
    click_on "Confirm SMS Backup Number"

    assert_match "SMS authentication has been setup", page.text

    logout
    login(email: "janko@hey.com", password: "secret123")

    click_on "Authenticate Using SMS Code"
    click_on "Send SMS Code"
    fill_in "SMS Code", with: Account::SmsCode.first.code
    click_on "Authenticate via SMS Code"

    assert_match "You have been logged in", page.text
  end

  test "recovery codes" do
    create_account(email: "janko@hey.com", password: "secret123")

    dropdown_click "Manage MFA"
    fill_in "Password", with: "secret123"
    click_on "Confirm Password"

    click_on "Setup TOTP Authentication"
    totp = ROTP::TOTP.new(page.text[/Secret: (\w+)/, 1])
    fill_in "Authentication Code", with: totp.now
    click_on "Setup TOTP Authentication"

    recovery_codes = page.all(".recovery-code").map(&:text)

    logout
    login(email: "janko@hey.com", password: "secret123")

    click_on "Authenticate Using Recovery Code"
    fill_in "Recovery Code", with: recovery_codes[0]
    click_on "Authenticate via Recovery Code"

    assert_match "You have been logged in", page.text
  end

  test "passkeys" do
    create_account(email: "janko@hey.com", password: "secret123")

    webauthn_client = WebAuthn::FakeClient.new(current_url.chomp("/"))

    dropdown_click "Manage MFA"
    fill_in "Password", with: "secret123"
    click_on "Confirm Password"

    click_on "Setup WebAuthn Authentication"
    fill_in "Nickname", with: "YubiKey"
    challenge = find("#webauthn_setup_challenge", visible: false).value
    find("#webauthn_setup", visible: false).set(webauthn_client.create(challenge: challenge).to_json)
    click_on "Setup WebAuthn Authentication"
    assert_match "WebAuthn authentication is now setup", page.text

    logout
    login(email: "janko@hey.com", password: "secret123")

    click_on "Authenticate Using WebAuthn"
    challenge = find("#webauthn_auth_challenge", visible: false).value
    find("#webauthn_auth", visible: false).set(webauthn_client.get(challenge: challenge).to_json)
    click_on "Authenticate Using WebAuthn"
    assert_match "You have been logged in", page.text

    logout
    click_on "Sign in"
    login(email: "janko@hey.com")
    challenge = find("#webauthn_auth_challenge", visible: false).value
    find("#webauthn_auth", visible: false).set(webauthn_client.get(challenge: challenge).to_json)
    click_on "Authenticate Using WebAuthn"
    assert_match "You have been logged in", page.text
  end

  private

  def create_account(email: "janko@hey.com", password: "secret123")
    click_on "Sign up"
    fill_in "Name", with: "Janko"
    fill_in "Email", with: email
    fill_in "Password",         with: password
    fill_in "Confirm Password", with: password
    click_on "Create Account"

    visit email_link
    click_on "Verify Account"
  end

  def login(email:, password: nil)
    click_on "Sign in"
    fill_in "Email", with: email
    click_on "Login"

    if password
      assert_match "Login recognized, please enter your password", page.text
      fill_in "Password", with: password
      click_on "Login"
    end
  end

  def logout
    dropdown_click "Sign out"
  end

  def dropdown_click(text)
    find(".dropdown-toggle").click
    click_on text
  end

  def email_link
    perform_enqueued_jobs
    email = RodauthMailer.deliveries.last
    email.body.to_s[%r{https?://\S+}]
  end
end
