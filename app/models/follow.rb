class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  validates :follower_id, presence: true
  validates :followed_id, presence: true

  validates_comparison_of :follower_id, other_than: :followed_id, message: "can't follow self"
end
