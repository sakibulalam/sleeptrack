require "test_helper"

class Api::V1::SleepRecordsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @token = JWT.encode({ user_id: @user.id }, Rails.application.credentials.secret_key_base)
    @base_time = Time.zone.parse("2024-02-15 10:00:00")
  end

  test "should not allow access without token" do
    post api_v1_sleep_records_clock_in_path, params: { start_time: @base_time }, as: :json
    assert_response :unauthorized
    assert_equal({ "error" => "Invalid token" }, JSON.parse(@response.body))
  end

  test "should create sleep record on clock in" do
    assert_difference("SleepRecord.count") do
      post api_v1_sleep_records_clock_in_path, params: { start_time: @base_time }, as: :json,
           headers: { Authorization: "Bearer #{@token}" }
      assert_response :created
    end

    assert_response :created
    sleep_record = JSON.parse(@response.body)
    assert_not_nil sleep_record["start_time"]
    assert_nil sleep_record["end_time"]
  end

  test "should handle missing start_time parameter" do
    post api_v1_sleep_records_clock_in_path, params: {}, as: :json,
         headers: { Authorization: "Bearer #{@token}" }

    assert_response :unprocessable_entity
    response_body = JSON.parse(@response.body)
    assert_includes response_body["errors"], "Start time can't be blank"
  end

  test "should not allow clock in with active sleep record" do
    # Create initial sleep record
    post api_v1_sleep_records_clock_in_path, params: { start_time: @base_time }, as: :json,
         headers: { Authorization: "Bearer #{@token}" }
    assert_response :created

    # Attempt to create another sleep record
    post api_v1_sleep_records_clock_in_path, params: { start_time: @base_time + 1.hour }, as: :json,
         headers: { Authorization: "Bearer #{@token}" }

    assert_response :unprocessable_entity
    assert_equal({ "error" => "You already have an active sleep record" }, JSON.parse(@response.body))
  end

  test "should update sleep record on clock out" do
    # Create a sleep record first
    post api_v1_sleep_records_clock_in_path, params: { start_time: @base_time }, as: :json,
         headers: { Authorization: "Bearer #{@token}" }
    assert_response :created

    post api_v1_sleep_records_clock_out_path, params: { end_time: @base_time + 8.hours }, as: :json,
         headers: { Authorization: "Bearer #{@token}" }

    assert_response :success
    sleep_record = JSON.parse(@response.body)
    assert_not_nil sleep_record["start_time"]
    assert_not_nil sleep_record["end_time"]
  end

  test "should handle missing end_time parameter" do
    # Create a sleep record first
    post api_v1_sleep_records_clock_in_path, params: { start_time: @base_time }, as: :json,
         headers: { Authorization: "Bearer #{@token}" }

    post api_v1_sleep_records_clock_out_path, params: {}, as: :json,
         headers: { Authorization: "Bearer #{@token}" }

    assert_response :unprocessable_entity
    response_body = JSON.parse(@response.body)
    assert_includes response_body["errors"], "End time can't be blank"
  end

  test "should return error when clocking out without active sleep record" do
    post api_v1_sleep_records_clock_out_path, params: { end_time: @base_time }, as: :json,
         headers: { Authorization: "Bearer #{@token}" }

    assert_response :not_found
    assert_equal({ "error" => "No active sleep record found" }, JSON.parse(@response.body))
  end

  test "should list sleep records" do
    # Create a sleep record
    post api_v1_sleep_records_clock_in_path, params: { start_time: @base_time }, as: :json,
         headers: { Authorization: "Bearer #{@token}" }

    get api_v1_sleep_records_path,
        headers: { Authorization: "Bearer #{@token}" }

    assert_response :success
    sleep_records = JSON.parse(@response.body)
    assert_kind_of Array, sleep_records
  end

  test "should order sleep records by created time" do
    # Create multiple sleep records
    2.times do |index|
      post api_v1_sleep_records_clock_in_path, params: { start_time: @base_time + index.days }, as: :json,
           headers: { Authorization: "Bearer #{@token}" }
      post api_v1_sleep_records_clock_out_path, params: { end_time: @base_time + index.days + 8.hours }, as: :json,
           headers: { Authorization: "Bearer #{@token}" }
    end

    get api_v1_sleep_records_path,
        headers: { Authorization: "Bearer #{@token}" }

    assert_response :success
    sleep_records = JSON.parse(@response.body)
    assert_equal sleep_records.first["created_at"], sleep_records.sort_by { |r| r["created_at"] }.reverse.first["created_at"]
  end

  test "should validate sleep record response structure" do
    post api_v1_sleep_records_clock_in_path, params: { start_time: @base_time }, as: :json,
         headers: { Authorization: "Bearer #{@token}" }

    sleep_record = JSON.parse(@response.body)
    required_fields = %w[id user_id start_time end_time duration created_at updated_at]
    required_fields.each do |field|
      assert_includes sleep_record.keys, field
    end
  end
end
