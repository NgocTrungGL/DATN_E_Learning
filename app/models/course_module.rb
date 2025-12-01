class CourseModule < ApplicationRecord
  belongs_to :course
  before_create :assign_next_order_index
  has_many :lessons, dependent: :destroy

  # --- Validations ---
  validates :title, presence: true

  default_scope{order(order_index: :asc)}
  private

  def assign_next_order_index
    max_order = course.course_modules.maximum(:order_index) || 0
    self.order_index = max_order + 1
  end
end
