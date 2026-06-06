class UserRecommendation < ApplicationRecord
  belongs_to :user
  belongs_to :course

  scope :fresh, -> { where("computed_at > ?", 24.hours.ago) }
  scope :by_score, -> { order(score: :desc) }
end
