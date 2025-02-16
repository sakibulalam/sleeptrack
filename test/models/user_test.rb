require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "should require name" do
    @user.name = nil
    assert_not @user.valid?
  end

  test "should require password_digest" do
    @user.password_digest = nil
    assert_not @user.valid?
  end

  test "should have many sleep records" do
    assert_respond_to @user, :sleep_records
  end

  test "should have many active follows" do
    assert_respond_to @user, :active_follows
  end

  test "should have many passive follows" do
    assert_respond_to @user, :passive_follows
  end

  test "should have many following" do
    assert_respond_to @user, :following
  end

  test "should have many followers" do
    assert_respond_to @user, :followers
  end

  test "as_json should exclude password_digest and updated_at" do
    json = @user.as_json
    assert_not_includes json.keys, "password_digest"
    assert_not_includes json.keys, "updated_at"
  end
end
