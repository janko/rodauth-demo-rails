require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  test "should require authentication" do
    get posts_url

    assert_redirected_to "/login"

    login

    get posts_url

    assert_response :success
  end

  private

  def login(login: "user@example.com", password: "secret123")
    post "/create-account", params: {
      "name"             => "Janko",
      "login"            => login,
      "password"         => password,
      "password-confirm" => password,
    }

    post "/login", params: {
      "login"    => login,
      "password" => password,
    }
  end
end
