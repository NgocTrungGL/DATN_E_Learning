class Quiz < ApplicationRecord
  belongs_to :course
  belongs_to :lesson, optional: true
  belongs_to :creator, class_name: User.name,
optional: true

  has_many :quiz_questions, dependent: :destroy
  has_many :questions, through: :quiz_questions
  has_many :quiz_attempts, dependent: :destroy
  scope :big_quizzes, ->{where(lesson_id: nil).order(:created_at)}
end
