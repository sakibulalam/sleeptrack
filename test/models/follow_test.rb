require "test_helper"

class FollowTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @follow = Follow.new(follower: @user, followed: @other_user)
  end

  test "should be valid" do
    assert @follow.valid?
  end

  test "should require follower_id" do
    @follow.follower_id = nil
    assert_not @follow.valid?
  end

  test "should require followed_id" do
    @follow.followed_id = nil
    assert_not @follow.valid?
  end

  test "should not allow self-following" do
    follow = Follow.new(follower: @user, followed: @user)
    assert_not follow.valid?
    assert_includes follow.errors.full_messages, "Follower can't follow self"
  end

  test "should belong to follower" do
    assert_equal @user, @follow.follower
  end

  test "should belong to followed user" do
    assert_equal @other_user, @follow.followed
  end
end
