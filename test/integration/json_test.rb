require "test_helper"

class JsonTest < ActionDispatch::IntegrationTest
  test "registration and login" do
    post "/login", params: { login: "user@example.com", password: "secret123" }, as: :json
    assert_equal 401, response.status
    assert_equal "There was an error logging in", response.parsed_body.fetch("error")

    post "/create-account", params: { login: "user@example.com", name: "User", password: "secret123" }, as: :json
    assert_equal 200, response.status
    assert_equal "An email has been sent to you with a link to verify your account", response.parsed_body.fetch("success")

    post "/verify-account", params: { key: email_link[/key=(.+)/, 1] }, as: :json
    assert_equal 200, response.status
    assert_equal "Your account has been verified", response.parsed_body.fetch("success")

    post "/login", params: { login: "user@example.com", password: "secret123" }, as: :json
    assert_equal 200, response.status
    assert_equal "You have been logged in", response.parsed_body.fetch("success")
  end

  test "change password" do
    Account.create!(email: "user@example.com", password: "secret123", status: "verified")

    post "/login", params: { login: "user@example.com", password: "secret123" }, as: :json
    assert_equal 200, response.status

    post "/change-password", params: { password: "secret123", "new-password": "new secret" }, as: :json,
      env: { "HTTP_AUTHORIZATION" => response.headers["Authorization"] }
    assert_equal 200, response.status
    assert_equal "Your password has been changed", response.parsed_body.fetch("success")

    post "/login", params: { login: "user@example.com", password: "new secret" }, as: :json
    assert_equal 200, response.status
  end

  private

  def email_link
    perform_enqueued_jobs
    RodauthMailer.deliveries.last.body.to_s[%r{https?://\S+}]
  end
end
