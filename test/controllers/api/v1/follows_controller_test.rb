require "test_helper"
require "set"

class Api::V1::FollowsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @token = JWT.encode({ user_id: @user.id }, Rails.application.credentials.secret_key_base)
    @header = { Authorization: "Bearer #{@token}" }
  end

  class AuthenticationTests < Api::V1::FollowsControllerTest
    test "should not allow access without token" do
      post api_v1_follow_path, params: { user_id: @other_user.id }, as: :json
      assert_response :unauthorized
      assert_equal({ "error" => "Invalid token" }, JSON.parse(@response.body))
    end

    test "should not allow following without authentication" do
      post api_v1_follow_path, params: { user_id: @other_user.id }, as: :json
      assert_response :unauthorized
      assert_equal({ "error" => "Invalid token" }, JSON.parse(@response.body))
    end

    test "should not allow unfollowing without authentication" do
      delete api_v1_unfollow_path, params: { user_id: @other_user.id }, as: :json
      assert_response :unauthorized
      assert_equal({ "error" => "Invalid token" }, JSON.parse(@response.body))
    end

    test "should not allow accessing following list without authentication" do
      get api_v1_following_path, as: :json
      assert_response :unauthorized
      assert_equal({ "error" => "Invalid token" }, JSON.parse(@response.body))
    end

    test "should not allow accessing followers list without authentication" do
      get api_v1_followers_path, as: :json
      assert_response :unauthorized
      assert_equal({ "error" => "Invalid token" }, JSON.parse(@response.body))
    end
  end

  class FollowUnfollowTests < Api::V1::FollowsControllerTest
    test "should follow a user" do
      assert_difference("Follow.count") do
        post api_v1_follow_path, params: { user_id: @other_user.id }, as: :json,
             headers: @header
      end

      assert_response :created
      assert_equal({ "message" => "Successfully followed user" }, JSON.parse(@response.body))
      assert @user.following.include?(@other_user)
    end

    test "should not allow following self" do
      post api_v1_follow_path, params: { user_id: @user.id }, as: :json,
           headers: @header

      assert_response :unprocessable_entity
      response_body = JSON.parse(@response.body)
      assert_includes response_body["errors"], "Follower can't follow self"
      assert_not @user.following.include?(@user)
    end

    test "should not allow following same user twice" do
      # First follow
      post api_v1_follow_path, params: { user_id: @other_user.id }, as: :json,
           headers: @header
      assert_response :created

      # Try to follow again
      post api_v1_follow_path, params: { user_id: @other_user.id }, as: :json,
           headers: @header
      assert_response :unprocessable_entity
    end

    test "should unfollow a user" do
      # First follow the user
      post api_v1_follow_path, params: { user_id: @other_user.id }, as: :json,
           headers: @header
      assert_response :created

      assert_difference("Follow.count", -1) do
        delete api_v1_unfollow_path(@other_user), params: { user_id: @other_user.id }, as: :json,
               headers: @header
      end

      assert_response :ok
      assert_equal({ "message" => "Successfully unfollowed user" }, JSON.parse(@response.body))
    end

    test "should return not found when unfollowing non-followed user" do
      delete api_v1_unfollow_path, params: { user_id: @other_user.id }, as: :json,
             headers: @header

      assert_response :not_found
      assert_equal({ "error" => "You are not following this user" }, JSON.parse(@response.body))
    end

    test "should return not found when following non-existent user" do
      post api_v1_follow_path, params: { user_id: 999999 }, as: :json,
           headers: @header

      assert_response :not_found
      assert_equal({ "error" => "User not found" }, JSON.parse(@response.body))
    end
  end

  class ListingTests < Api::V1::FollowsControllerTest
    test "should get following list" do
      # First follow a user
      post api_v1_follow_path, params: { user_id: @other_user.id }, as: :json,
           headers: @header

      get api_v1_following_path, headers: @header

      assert_response :ok
      following = JSON.parse(@response.body)
      assert_includes following.map { |u| u["id"] }, @other_user.id
    end

    test "should get followers list" do
      # First have other_user follow the user
      other_token = JWT.encode({ user_id: @other_user.id }, Rails.application.credentials.secret_key_base)
      post api_v1_follow_path, params: { user_id: @user.id }, as: :json,
           headers: { Authorization: "Bearer #{other_token}" }
      assert_response :created

      get api_v1_followers_path, headers: @header

      assert_response :ok
      followers = JSON.parse(@response.body)
      assert_includes followers.map { |u| u["id"] }, @other_user.id
    end
  end

  class ResponseStructureTests < Api::V1::FollowsControllerTest
    test "should return proper JSON structure for following list" do
      # First follow a user
      post api_v1_follow_path, params: { user_id: @other_user.id }, as: :json,
           headers: @header

      get api_v1_following_path, headers: @header
      assert_response :ok
      following = JSON.parse(@response.body)
      assert_kind_of Array, following
      assert_not_empty following
      following_user = following.first
      assert_equal %w[id name created_at].to_set, following_user.keys.to_set
    end

    test "should return proper JSON structure for followers list" do
      # First have other_user follow the user
      other_token = JWT.encode({ user_id: @other_user.id }, Rails.application.credentials.secret_key_base)
      post api_v1_follow_path, params: { user_id: @user.id }, as: :json,
           headers: { Authorization: "Bearer #{other_token}" }

      get api_v1_followers_path, headers: @header
      assert_response :ok
      followers = JSON.parse(@response.body)
      assert_kind_of Array, followers
      assert_not_empty followers
      follower = followers.first
      assert_equal %w[id name created_at].to_set, follower.keys.to_set
    end
  end
end
