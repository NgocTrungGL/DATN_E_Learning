class Question < ApplicationRecord
  # --- Enums ---
  enum question_type: {single: "single", multiple: "multiple"}
  enum difficulty: {easy: "easy", medium: "medium", hard: "hard"}

  # --- Associations ---
  belongs_to :course
  belongs_to :lesson, optional: true
  belongs_to :creator, class_name: User.name, optional: true,
foreign_key: "created_by"

  has_many :question_options, dependent: :destroy
  has_many :quiz_questions, dependent: :destroy
  has_many :quizzes, through: :quiz_questions

  accepts_nested_attributes_for :question_options,
                                reject_if: :all_blank,
                                allow_destroy: true

  # --- Validations ---
  validates :question_text, presence: true
  validates :course, presence: true
  validates :question_type, presence: true
  validates :difficulty, presence: true

  # --- Custom Validations ---
  validate :minimum_four_options
  validate :validate_correct_answers

  private

  def minimum_four_options
    valid_options = question_options.reject(&:marked_for_destruction?)

    return unless valid_options.size < 4

    errors.add(:base, "Câu hỏi phải có ít nhất 4 lựa chọn trả lời.")
  end

  def validate_correct_answers
    valid_options = question_options.reject(&:marked_for_destruction?)

    correct_count = valid_options.count(&:is_correct)

    if single?
      if correct_count != 1
        errors.add(:base,
                   "Câu hỏi 'Một lựa chọn' phải có duy nhất 1 đáp án đúng.")
      end
    elsif multiple?
      if correct_count < 1
        errors.add(:base,
                   "Câu hỏi 'Nhiều lựa chọn' phải có ít nhất 1 đáp án đúng.")
      end
    end
  end
end
