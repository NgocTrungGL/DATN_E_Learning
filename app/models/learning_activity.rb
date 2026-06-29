class LearningActivity < ApplicationRecord
  ACTIVITY_TYPES = %w[
    course_start lesson_view lesson_complete note_taken quiz_start
    quiz_attempt quiz_complete page_view session_start
  ].freeze

  belongs_to :user
  belongs_to :course, optional: true
  belongs_to :lesson, optional: true

  validates :activity_type, presence: true, inclusion: { in: ACTIVITY_TYPES }
  validates :activity_date, presence: true

  scope :by_user, ->(user) { where(user_id: user.id) }
  scope :by_date_range, ->(start_date, end_date) { where(activity_date: start_date..end_date) }
  scope :lesson_completions, -> { where(activity_type: :lesson_complete) }
  scope :quiz_completions, -> { where(activity_type: :quiz_complete) }

  def self.activity_type_labels
    {
      "course_start" => "Bắt đầu khóa học",
      "lesson_view" => "Xem bài học",
      "lesson_complete" => "Hoàn thành bài học",
      "note_taken" => "Ghi chú",
      "quiz_start" => "Bắt đầu bài thi",
      "quiz_attempt" => "Làm bài thi",
      "quiz_complete" => "Hoàn thành bài thi",
      "page_view" => "Xem trang",
      "session_start" => "Bắt đầu phiên học"
    }
  end
end
