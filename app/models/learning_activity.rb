class LearningActivity < ApplicationRecord
  belongs_to :user
  belongs_to :course, optional: true
  belongs_to :lesson, optional: true

  validates :activity_type, presence: true
  validates :activity_date, presence: true

  scope :by_user, ->(user) { where(user_id: user.id) }
  scope :by_date_range, ->(start_date, end_date) { where(activity_date: start_date..end_date) }
  scope :lesson_completions, -> { where(activity_type: :lesson_complete) }
  scope :quiz_completions, -> { where(activity_type: :quiz_complete) }

  ACTIVITY_TYPES = %w[lesson_view lesson_complete quiz_start quiz_complete page_view session_start].freeze

  def self.activity_type_labels
    {
      "lesson_view" => "Xem bài học",
      "lesson_complete" => "Hoàn thành bài học",
      "quiz_start" => "Bắt đầu bài thi",
      "quiz_complete" => "Hoàn thành bài thi",
      "page_view" => "Xem trang",
      "session_start" => "Bắt đầu phiên học"
    }
  end
end
