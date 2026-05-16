# frozen_string_literal: true

class QuizAnswer < ApplicationRecord
  belongs_to :quiz_attempt
  belongs_to :question

  serialize :selected_option_ids, Array

  validates :question_id, presence: true
  validates :quiz_attempt_id, presence: true

  before_save :check_correctness
  before_validation :ensure_selected_option_ids_is_array

  private

  def ensure_selected_option_ids_is_array
    self.selected_option_ids = Array(selected_option_ids).compact.map(&:to_i).uniq if selected_option_ids.present?
    self.selected_option_ids ||= []
  end

  def check_correctness
    return if is_correct_changed?

    if question.single?
      check_single_choice
    elsif question.multiple?
      check_multiple_choice
    end

    self.is_correct = false if is_correct.nil?
  end

  def check_single_choice
    return if selected_option_ids.blank?

    correct_option_id = question.question_options.find_by(is_correct: true)&.id
    self.is_correct = selected_option_ids.first.to_i == correct_option_id
  end

  def check_multiple_choice
    return if selected_option_ids.blank?

    correct_option_ids = question.question_options.where(is_correct: true).pluck(:id).sort
    user_option_ids = selected_option_ids.map(&:to_i).sort
    self.is_correct = (correct_option_ids == user_option_ids)
  end
end
