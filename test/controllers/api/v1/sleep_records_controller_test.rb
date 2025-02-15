require "test_helper"

class Api::V1::SleepRecordsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @token = JWT.encode({ user_id: @user.id }, Rails.application.credentials.secret_key_base)
  end

  test "should not allow access without token" do
    post api_v1_sleep_records_clock_in_path
    assert_response :unauthorized
    assert_equal({ "error" => "Invalid token" }, JSON.parse(@response.body))
  end

  test "should create sleep record on clock in" do
    assert_difference('SleepRecord.count') do
      post api_v1_sleep_records_clock_in_path,
           headers: { Authorization: "Bearer #{@token}" }
    end

    assert_response :created
    sleep_record = JSON.parse(@response.body)
    assert_not_nil sleep_record["start_time"]
    assert_nil sleep_record["end_time"]
  end

  test "should not allow clock in with active sleep record" do
    # Create initial sleep record
    post api_v1_sleep_records_clock_in_path,
         headers: { Authorization: "Bearer #{@token}" }
    assert_response :created

    # Attempt to create another sleep record
    post api_v1_sleep_records_clock_in_path,
         headers: { Authorization: "Bearer #{@token}" }
    
    assert_response :unprocessable_entity
    assert_equal({ "error" => "You already have an active sleep record" }, JSON.parse(@response.body))
  end

  test "should update sleep record on clock out" do
    # Create a sleep record first
    post api_v1_sleep_records_clock_in_path,
         headers: { Authorization: "Bearer #{@token}" }
    
    post api_v1_sleep_records_clock_out_path,
         headers: { Authorization: "Bearer #{@token}" }
    
    assert_response :success
    sleep_record = JSON.parse(@response.body)
    assert_not_nil sleep_record["start_time"]
    assert_not_nil sleep_record["end_time"]
  end

  test "should return error when clocking out without active sleep record" do
    post api_v1_sleep_records_clock_out_path,
         headers: { Authorization: "Bearer #{@token}" }
    
    assert_response :not_found
    assert_equal({ "error" => "No active sleep record found" }, JSON.parse(@response.body))
  end

  test "should list sleep records" do
    # Create a sleep record
    post api_v1_sleep_records_clock_in_path,
         headers: { Authorization: "Bearer #{@token}" }
    
    get api_v1_sleep_records_path,
        headers: { Authorization: "Bearer #{@token}" }
    
    assert_response :success
    sleep_records = JSON.parse(@response.body)
    assert_kind_of Array, sleep_records
  end

  test "should order sleep records by created time" do
    # Create multiple sleep records
    2.times do
      post api_v1_sleep_records_clock_in_path,
           headers: { Authorization: "Bearer #{@token}" }
      post api_v1_sleep_records_clock_out_path,
           headers: { Authorization: "Bearer #{@token}" }
    end

    get api_v1_sleep_records_path,
        headers: { Authorization: "Bearer #{@token}" }
    
    assert_response :success
    sleep_records = JSON.parse(@response.body)
    assert_equal sleep_records.first["created_at"], sleep_records.sort_by { |r| r["created_at"] }.reverse.first["created_at"]
  end
end