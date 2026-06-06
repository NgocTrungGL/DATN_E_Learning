class LearningGoal < ApplicationRecord
  belongs_to :user

  validates :goal_type, presence: true
  validates :target_value, presence: true, numericality: { greater_than: 0 }
  validates :week_start, presence: true

  scope :active, -> { where(is_active: true) }
  scope :for_week, ->(week_start) { where(week_start: week_start) }
  scope :current_week, -> { for_week(Time.current.beginning_of_week.to_date) }

  GOAL_TYPES = %w[lessons_per_week hours_per_week courses_per_month quiz_score].freeze

  def progress_percentage
    return 0 if target_value.zero?

    [(current_value.to_f / target_value * 100).round, 100].min
  end

  def self.goal_type_labels
    {
      "lessons_per_week" => "Bài học / tuần",
      "hours_per_week" => "Giờ học / tuần",
      "courses_per_month" => "Khóa học / tháng",
      "quiz_score" => "Điểm quiz trung bình"
    }
  end

  def self.goal_type_hints
    {
      "lessons_per_week" => "Số bài học muốn hoàn thành mỗi tuần",
      "hours_per_week" => "Số giờ học mỗi tuần",
      "courses_per_month" => "Số khóa học hoàn thành mỗi tháng",
      "quiz_score" => "Điểm trung bình mong muốn cho bài thi"
    }
  end
end
