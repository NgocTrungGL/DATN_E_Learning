class QuizAnswersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quiz_attempt
  before_action :set_quiz

  def create
    return if render_forbidden_if_finished

    authorize! :update, @quiz_attempt

    @answer = find_answer
    update_answer_selection if @answer

    redirect_after_save
  end

  private

  def set_quiz_attempt
    @quiz_attempt = QuizAttempt.find(params[:quiz_attempt_id])
    return if @quiz_attempt.user == current_user

    redirect_to root_path, alert: "Access Denied"
  end

  def set_quiz
    @quiz = @quiz_attempt.quiz
  end

  # ===== Guard clauses =====

  def render_forbidden_if_finished
    return false unless @quiz_attempt.completed? || @quiz_attempt.expired?

    render json: { error: "Bài thi đã kết thúc" }, status: :forbidden
    true
  end

  # ===== Business logic =====

  def find_answer
    @quiz_attempt.quiz_answers.find_by(
      question_id: params.dig(:quiz_answer, :question_id)
    )
  end

  def update_answer_selection
    @answer.update(
      selected_option_ids: normalized_selected_option_ids
    )
  end

  def normalized_selected_option_ids
    Array(params.dig(:quiz_answer, :selected_option_ids))
      .reject(&:blank?)
  end

  # ===== Redirect =====

  def redirect_after_save
    target_question_id =
      params[:next_question_id].presence || @answer.question_id

    redirect_to(
      quiz_attempt_path(@quiz_attempt, question_id: target_question_id),
      notice: "Đã lưu."
    )
  end
end
