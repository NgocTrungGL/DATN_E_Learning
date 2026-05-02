class Review < ApplicationRecord
  belongs_to :user
  belongs_to :course

  validates :content, presence: true
  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :user_id,
            uniqueness: { scope: :course_id,
                          message: "đã đánh giá khóa học này rồi" }
  scope :recent, ->{order(created_at: :desc)}
end
