class Quiz < ApplicationRecord
  belongs_to :course
  belongs_to :lesson, optional: true
  belongs_to :creator, class_name: User.name, foreign_key: "created_by",
optional: true

  has_many :quiz_questions, dependent: :destroy
  has_many :questions, through: :quiz_questions
  has_many :quiz_attempts, dependent: :destroy
  scope :big, ->{where(lesson_id: nil).order(:created_at)}
  enum scoring_type: { equal: 0, weighted: 1 }

  validates :title, presence: true
  validate :validate_question_counts
  validates :title, presence: true
  validate :validate_question_counts_logic
  validate :validate_question_bank_sufficiency
  def manual_selection?
    lesson_id.present?
  end

  def random_selection?
    lesson_id.nil?
  end

  private

  def validate_question_counts
    return unless random_selection?

    total_config = (easy_count || 0) + (medium_count || 0) + (hard_count || 0)

    return unless total_config != total_questions

    errors.add(:base,
               "Tổng số lượng câu hỏi (Dễ + Vừa + Khó) là #{total_config},
               nhưng tổng số câu hỏi yêu cầu là #{total_questions}.
               Vui lòng điều chỉnh lại cho khớp.")
  end

  def validate_question_counts_logic
    return unless random_selection?

    total_config = (easy_count || 0) + (medium_count || 0) + (hard_count || 0)
    return unless total_config != total_questions

    errors.add(:total_questions,
               "Tổng số câu hỏi cấu hình (#{total_config})
               không khớp với tổng số câu hỏi yêu cầu (#{total_questions}).")
  end

  def validate_question_bank_sufficiency
    return unless random_selection?
    return unless course

    validate_difficulty_counts
    validate_total_question_pool
  end

  def validate_difficulty_counts
    available = available_questions_by_difficulty

    validate_difficulty(:easy, easy_count, available[:easy], "Dễ")
    validate_difficulty(:medium, medium_count, available[:medium],
                        "Trung bình")
    validate_difficulty(:hard, hard_count, available[:hard], "Khó")
  end

  def available_questions_by_difficulty
    {
      easy: course.questions.where(difficulty: "easy").count,
      medium: course.questions.where(difficulty: "medium").count,
      hard: course.questions.where(difficulty: "hard").count
    }
  end

  def validate_difficulty field, required_count, available_count, label
    required = required_count || 0
    return unless required > available_count

    errors.add(
      field,
      "Ngân hàng chỉ có #{available_count} câu #{label} (yêu cầu #{required})."
    )
  end

  def validate_total_question_pool
    total_available = total_available_questions
    required_pool_size = total_questions * 3

    return unless total_available < required_pool_size

    errors.add(
      :base,
      "Để đảm bảo tính ngẫu nhiên,
     Ngân hàng câu hỏi cần có ít nhất #{required_pool_size} câu
     (Gấp 3 lần số câu hỏi của đề).
     Hiện tại chỉ có #{total_available} câu."
    )
  end

  def total_available_questions
    available_questions_by_difficulty.values.sum
  end
end
