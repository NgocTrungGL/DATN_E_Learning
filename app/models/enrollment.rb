class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :course

  enum status: { pending: "pending", active: "active", rejected: "rejected" }
  scope :active, ->{where(status: :active)}
  validates :user_id, uniqueness: { scope: :course_id }
  def current_progress_percentage
    user.course_progress_percentage(course)
  end

  def can_review?
    current_progress_percentage >= 70
  end
end
