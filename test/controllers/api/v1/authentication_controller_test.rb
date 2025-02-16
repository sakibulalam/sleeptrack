require "test_helper"

class Api::V1::AuthenticationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should authenticate user with valid credentials" do
    post api_v1_authentication_login_url, params: { name: @user.name, password: "password123" }, as: :json
    assert_response :success
    assert_not_nil JSON.parse(@response.body)["token"]
  end

  test "should not authenticate user with invalid password" do
    post api_v1_authentication_login_url, params: { name: @user.name, password: "wrongpassword" }, as: :json
    assert_response :unauthorized
    assert_equal "Invalid credentials", JSON.parse(@response.body)["error"]
  end

  test "should not authenticate non-existent user" do
    post api_v1_authentication_login_url, params: { name: "nonexistent", password: "password123" }, as: :json
    assert_response :unauthorized
    assert_equal "Invalid credentials", JSON.parse(@response.body)["error"]
  end
end
