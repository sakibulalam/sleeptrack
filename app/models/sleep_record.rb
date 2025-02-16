class SleepRecord < ApplicationRecord
  belongs_to :user

  validates :start_time, presence: true, on: :create
  validates :end_time, presence: true, on: :update

  validates_comparison_of :start_time, less_than: :end_time, if: :end_time, message: "must be less than end time"
  before_save :calculate_duration

  private

  def calculate_duration
    return if self.end_time.blank?
    self.duration = self.end_time - self.start_time
  end
end
