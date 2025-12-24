# class QuizAnswer < ApplicationRecord
#   belongs_to :quiz_attempt
#   belongs_to :question
#   belongs_to :question_option, optional: true

#   serialize :selected_option_ids, Array
#   before_save :check_correctness

#   private

#   def check_correctness
#     return if is_correct_changed?

#     if question.single?
#       check_single_choice
#     elsif question.multiple?
#       check_multiple_choice
#     end

#     self.is_correct = false if is_correct.nil?
#   end

#   def check_single_choice
#     correct_option_id = question.question_
# options.find_by(is_correct: true)&.id

#     self.is_correct = (question_option_id.to_i == correct_option_id)
#   end

#   def check_multiple_choice
#     correct_option_ids = question.question_options.where(is_correct: true)
#                                  .pluck(:id).sort
#     user_option_ids = (selected_option_ids || []).map(&:to_i).sort
#     self.is_correct = (correct_option_ids == user_option_ids)
#   end
# end
class QuizAnswer < ApplicationRecord
  belongs_to :quiz_attempt
  belongs_to :question

  serialize :selected_option_ids, Array

  validates :question_id, presence: true
end
