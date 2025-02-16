require "test_helper"

class SleepRecordTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @base_time = Time.zone.parse("2024-02-15 10:00:00")
    @sleep_record = SleepRecord.new(
      user: @user,
      start_time: @base_time
    )
  end

  test "should calculate duration on save" do
    @sleep_record.save
    end_time = @base_time + 8.hours
    @sleep_record.update(end_time: end_time)

    expected_duration = end_time - @sleep_record.start_time
    assert_equal expected_duration, @sleep_record.duration
  end

  test "should not allow end_time before start_time" do
    @sleep_record.save
    @sleep_record.end_time = @sleep_record.start_time - 1.hour

    assert_not @sleep_record.valid?
    assert_includes @sleep_record.errors.full_messages, "Start time must be less than end time"
  end

  test "should not calculate duration without end_time" do
    @sleep_record.save
    assert_nil @sleep_record.duration
  end

  test "should handle timezone differences correctly" do
    Time.use_zone("UTC") do
      start_time = @base_time
      @sleep_record.start_time = start_time
      @sleep_record.save

      Time.use_zone("Asia/Tokyo") do
        end_time = @base_time + 8.hours
        @sleep_record.update(end_time: end_time)

        expected_duration = end_time - start_time
        assert_equal expected_duration, @sleep_record.duration
      end
    end
  end

  test "should require start_time on create" do
    sleep_record = SleepRecord.new(user: @user)
    assert_not sleep_record.valid?
    assert_includes sleep_record.errors.full_messages, "Start time can't be blank"
  end

  test "should require end_time on update" do
    @sleep_record.save
    @sleep_record.end_time = nil
    assert_not @sleep_record.valid?(:update)
    assert_includes @sleep_record.errors.full_messages, "End time can't be blank"
  end
end
