class Question < ApplicationRecord
  enum question_type: {single: "single", multiple: "multiple"}
  enum difficulty: {easy: "easy", medium: "medium", hard: "hard"}
  validates :course, presence: true
  validate :minimum_four_options
  validate :has_one_correct_answer
  belongs_to :course
  belongs_to :lesson, optional: true
  belongs_to :creator, class_name: User.name, optional: true

  has_many :question_options, dependent: :destroy
  has_many :quiz_questions, dependent: :destroy
  has_many :quizzes, through: :quiz_questions
  accepts_nested_attributes_for :question_options,
                                reject_if: :all_blank,
                                allow_destroy: true
  private
  def minimum_four_options
    return unless question_options.reject(&:marked_for_destruction?).size < 4

    errors.add(:base, "Câu hỏi phải có ít nhất 4 lựa chọn")
  end

  def has_one_correct_answer?
    return unless question_options.select(&:correct).size != 1

    errors.add(:base, "Phải chọn đúng 1 đáp án đúng")
  end
end
