class Wishlist < ApplicationRecord
  belongs_to :user
  belongs_to :course

  validates :user_id, uniqueness: { scope: :course_id }

  after_commit :queue_recommendation_update, on: [:create, :destroy]

  def queue_recommendation_update
    Recommendations::CacheInvalidator.call(user_id)
  end
end
