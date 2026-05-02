class QuizAttempt < ApplicationRecord
  enum status: { in_progress: "in_progress", completed: "completed" }

  belongs_to :quiz
  belongs_to :user
  has_many :quiz_answers, dependent: :destroy
  def expired?
    return false if quiz.time_limit.blank?

    Time.current > (started_at + quiz.time_limit.minutes + 10.seconds)
  end
end
