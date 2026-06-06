class ProgressTracking < ApplicationRecord
  before_validation :set_course_from_parent
  enum progress_type: { lesson: "lesson", quiz: "quiz" }
  enum status: { not_started: "not_started", in_progress: "in_progress",
                 completed: "completed" }

  belongs_to :user
  belongs_to :course
  belongs_to :lesson, optional: true
  belongs_to :quiz, optional: true

  validates :lesson_id, uniqueness: { scope: :user_id }, allow_nil: true
  validates :quiz_id, uniqueness: { scope: :user_id }, allow_nil: true

  after_commit :check_certificate_issuance, on: [:create, :update]
  after_commit :track_learning_activity, on: [:create, :update]

  private

  def set_course_from_parent
    self.course_id ||= lesson.course&.id if lesson
    return unless quiz

    self.course_id ||= quiz.course_id
  end

  def check_certificate_issuance
    return unless status == "completed"

    Certificate.issue_for(user, course)
  end

  def track_learning_activity
    return unless saved_change_to_status? && completed?

    LearningActivity.create!(
      user: user,
      course: course,
      lesson: lesson,
      activity_type: :lesson_complete,
      activity_date: Date.current
    )
    user.learning_streak_record.update_streak!(Date.current)
    GoalProgressService.update_user_goals(user)
  end
end
