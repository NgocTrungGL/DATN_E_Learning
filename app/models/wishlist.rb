class Wishlist < ApplicationRecord
  belongs_to :user
  belongs_to :course

  validates :user_id, uniqueness: { scope: :course_id }

  after_create_commit :queue_recommendation_update

  def queue_recommendation_update
    last_computed = UserRecommendation.where(user_id: user_id).maximum(:computed_at)
    return if last_computed && last_computed > 5.minutes.ago

    RecommendationJob.perform_later(user_id)
  end
end
