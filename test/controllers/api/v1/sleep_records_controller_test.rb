require "test_helper"

class Api::V1::SleepRecordsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @token = JWT.encode({ user_id: @user.id }, Rails.application.credentials.secret_key_base)
    @base_time = Time.zone.parse("2024-02-15 10:00:00")
    @header = { Authorization: "Bearer #{@token}" }
  end

  class AuthenticationTests < Api::V1::SleepRecordsControllerTest
    test "should not allow access without token" do
      post api_v1_sleep_records_clock_in_path, params: { start_time: @base_time }, as: :json
      assert_response :unauthorized
      assert_equal({ "error" => "Invalid token" }, JSON.parse(@response.body))
    end
  end

  class ClockInOperationsTests < Api::V1::SleepRecordsControllerTest
    test "should create sleep record on clock in" do
      assert_difference("SleepRecord.count") do
        post api_v1_sleep_records_clock_in_path, params: { start_time: @base_time }, as: :json,
             headers: @header
        assert_response :created
      end

      assert_response :created
      sleep_record = JSON.parse(@response.body)
      assert_not_nil sleep_record["start_time"]
      assert_nil sleep_record["end_time"]
    end

    test "should handle missing start_time parameter" do
      post api_v1_sleep_records_clock_in_path, params: {}, as: :json,
           headers: @header

      assert_response :unprocessable_entity
      response_body = JSON.parse(@response.body)
      assert_includes response_body["errors"], "Start time can't be blank"
    end

    test "should not allow clock in with active sleep record" do
      # Create initial sleep record
      post api_v1_sleep_records_clock_in_path, params: { start_time: @base_time }, as: :json,
           headers: @header
      assert_response :created

      # Attempt to create another sleep record
      post api_v1_sleep_records_clock_in_path, params: { start_time: @base_time + 1.hour }, as: :json,
           headers: @header

      assert_response :unprocessable_entity
      assert_equal({ "error" => "You already have an active sleep record" }, JSON.parse(@response.body))
    end
  end

  class ClockOutOperationsTests < Api::V1::SleepRecordsControllerTest
    test "should update sleep record on clock out" do
      # Create a sleep record first
      post api_v1_sleep_records_clock_in_path, params: { start_time: @base_time }, as: :json,
           headers: @header
      assert_response :created

      post api_v1_sleep_records_clock_out_path, params: { end_time: @base_time + 8.hours }, as: :json,
           headers: @header

      assert_response :success
      sleep_record = JSON.parse(@response.body)
      assert_not_nil sleep_record["start_time"]
      assert_not_nil sleep_record["end_time"]
    end

    test "should handle missing end_time parameter" do
      # Create a sleep record first
      post api_v1_sleep_records_clock_in_path, params: { start_time: @base_time }, as: :json,
           headers: @header

      post api_v1_sleep_records_clock_out_path, params: {}, as: :json,
           headers: @header

      assert_response :unprocessable_entity
      response_body = JSON.parse(@response.body)
      assert_includes response_body["errors"], "End time can't be blank"
    end

    test "should return error when clocking out without active sleep record" do
      post api_v1_sleep_records_clock_out_path, params: { end_time: @base_time }, as: :json,
           headers: @header

      assert_response :not_found
      assert_equal({ "error" => "No active sleep record found" }, JSON.parse(@response.body))
    end
  end

  class RecordListingTests < Api::V1::SleepRecordsControllerTest
    test "should list sleep records" do
      # Create a sleep record
      post api_v1_sleep_records_clock_in_path, params: { start_time: @base_time }, as: :json,
           headers: @header

      get api_v1_sleep_records_path,
          headers: @header

      assert_response :success
      sleep_records = JSON.parse(@response.body)
      assert_kind_of Array, sleep_records
    end

    test "should order sleep records by created time" do
      # Create multiple sleep records
      2.times do |index|
        post api_v1_sleep_records_clock_in_path, params: { start_time: @base_time + index.days }, as: :json,
             headers: @header
        post api_v1_sleep_records_clock_out_path, params: { end_time: @base_time + index.days + 8.hours }, as: :json,
             headers: @header
      end

      get api_v1_sleep_records_path,
          headers: @header

      assert_response :success
      sleep_records = JSON.parse(@response.body)
      assert_equal sleep_records.first["created_at"], sleep_records.sort_by { |r| r["created_at"] }.reverse.first["created_at"]
    end

    test "should validate sleep record response structure" do
      post api_v1_sleep_records_clock_in_path, params: { start_time: @base_time }, as: :json,
           headers: @header

      sleep_record = JSON.parse(@response.body)
      required_fields = %w[id user_id start_time end_time duration created_at updated_at]
      required_fields.each do |field|
        assert_includes sleep_record.keys, field
      end
    end
  end

  class FollowingRecordsTests < Api::V1::SleepRecordsControllerTest
    test "should get following records" do
      Timecop.freeze(@base_time)

      # Create a follow relationship
      Follow.create!(follower: @user, followed: @other_user)

      # Create sleep records for the followed user
      SleepRecord.create!(
        user: @other_user,
        start_time: @base_time,
        end_time: @base_time + 8.hours
      )

      get api_v1_sleep_records_following_path,
          headers: @header

      assert_response :success
      response_data = JSON.parse(@response.body)

      assert_kind_of Array, response_data
      assert_not_empty response_data

      record = response_data.first
      assert_equal @other_user.id, record["user"]["id"]
      assert_equal @other_user.name, record["user"]["name"]
      assert_equal 8.hours.to_i, record["duration"]
    end

    test "should not include records older than a week" do
      Timecop.freeze(@base_time)

      # Create a follow relationship
      Follow.create!(follower: @user, followed: @other_user)

      # Create an old sleep record
      old_record = SleepRecord.create!(
        user: @other_user,
        start_time: 2.weeks.ago,
        end_time: 2.weeks.ago + 8.hours
      )

      # Create a recent record for comparison
      recent_record = SleepRecord.create!(
        user: @other_user,
        start_time: 2.days.ago,
        end_time: 2.days.ago + 8.hours
      )

      get api_v1_sleep_records_following_path,
          headers: @header

      assert_response :success
      response_data = JSON.parse(@response.body)

      record_ids = response_data.map { |r| r["id"] }
      assert_not_includes record_ids, old_record.id
      assert_includes record_ids, recent_record.id
    end

    test "should order records by duration" do
      Timecop.freeze(@base_time)

     # Create a follow relationship
     Follow.create!(follower: @user, followed: @other_user)

      # Create sleep records with different durations
      SleepRecord.create!(
        user: @other_user,
        start_time: @base_time,
        end_time: @base_time + 6.hours
      )

     SleepRecord.create!(
        user: @other_user,
        start_time: @base_time,
        end_time: @base_time + 8.hours
      )

      get api_v1_sleep_records_following_path,
          headers: @header

      assert_response :success
      response_data = JSON.parse(@response.body)

      assert_equal 8.hours.to_i, response_data.first["duration"]
      assert_equal 6.hours.to_i, response_data.last["duration"]
    end

    test "should require authentication" do
      get api_v1_sleep_records_following_path

      assert_response :unauthorized
    end

    test "should handle case with no followers" do
      Timecop.freeze(@base_time)

      get api_v1_sleep_records_following_path,
          headers: @header

      assert_response :success
      response_data = JSON.parse(@response.body)
      assert_empty response_data
    end

    test "should not include records without end_time" do
      Timecop.freeze(@base_time)

      # Create a follow relationship
      follow = Follow.create!(follower: @user, followed: @other_user)

      # Create an incomplete sleep record
      incomplete_record = SleepRecord.create!(
        user: @other_user,
        start_time: @base_time
      )

      get api_v1_sleep_records_following_path,
          headers: @header

      assert_response :success
      response_data = JSON.parse(@response.body)

      record_ids = response_data.map { |r| r["id"] }
      assert_not_includes record_ids, incomplete_record.id
    end
  end
end
