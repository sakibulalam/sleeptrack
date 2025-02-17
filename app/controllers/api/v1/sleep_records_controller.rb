class Api::V1::SleepRecordsController < ApplicationController
  include Authenticatable

  def index
    sleep_records = current_user.sleep_records.order(created_at: :desc)
    render json: sleep_records
  end

  def clock_in
    if current_user.sleep_records.exists?(end_time: nil)
      render json: { error: "You already have an active sleep record" }, status: :unprocessable_entity
      return
    end

    sleep_record = current_user.sleep_records.new(start_time: params[:start_time])

    if sleep_record.save
      render json: sleep_record, status: :created
    else
      render json: { errors: sleep_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def clock_out
    sleep_record = current_user.sleep_records.find_by(end_time: nil)

    if sleep_record
      if sleep_record.update(end_time: params[:end_time])
        render json: sleep_record
      else
        render json: { errors: sleep_record.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: "No active sleep record found" }, status: :not_found
    end
  end

  def following_records
    sleep_records = SleepRecord.from_followed_users(current_user)
    render json: sleep_records, include: { user: { only: [ :id, :name ] } }
  end
end
