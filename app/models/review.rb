class Review < ApplicationRecord
  belongs_to :user
  belongs_to :course

  validates :content, presence: true
  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :user_id,
            uniqueness: { scope: :course_id,
                          message: "đã đánh giá khóa học này rồi" }
  scope :recent, ->{order(created_at: :desc)}

  after_commit :queue_recommendation_update, on: [:create, :update, :destroy]

  def queue_recommendation_update
    Recommendations::CacheInvalidator.call(user_id)
  end
end
