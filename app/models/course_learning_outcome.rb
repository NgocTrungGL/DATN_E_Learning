# CourseLearningOutcome Model
# Represents a learning outcome ("What You'll Learn") item for a course
class CourseLearningOutcome < ApplicationRecord
  belongs_to :course

  validates :content, presence: true, length: { maximum: 500 }
  validates :order_index, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(order_index: :asc) }

  # Auto-set order_index on create if not provided
  before_validation :set_default_order, on: :create

  private

  def set_default_order
    return if order_index.present?

    self.order_index = (course.course_learning_outcomes.maximum(:order_index) || -1) + 1
  end
end
