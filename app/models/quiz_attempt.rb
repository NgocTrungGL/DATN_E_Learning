class QuizAttempt < ApplicationRecord
  enum status: { in_progress: "in_progress", completed: "completed" }

  belongs_to :quiz
  belongs_to :user
  has_many :quiz_answers, dependent: :destroy

  after_commit :track_learning_activity, on: [:update]

  def expired?
    return false if quiz.time_limit.blank?

    Time.current > (started_at + quiz.time_limit.minutes)
  end

  private

  def track_learning_activity
    return unless saved_change_to_status? && completed?

    LearningActivity.create!(
      user: user,
      course: quiz.course,
      lesson: quiz.lesson,
      activity_type: :quiz_complete,
      score: score.to_i,
      duration_seconds: duration_seconds || 0,
      activity_date: Date.current
    )
    user.learning_streak_record.update_streak!(Date.current)
    GoalProgressService.update_user_goals(user)
  end
end
