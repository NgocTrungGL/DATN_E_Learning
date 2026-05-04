class QuizAnswersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quiz_attempt
  before_action :set_quiz

  def create
    return if redirect_if_random_quiz
    return if render_forbidden_if_finished

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

  def redirect_if_random_quiz
    return false unless @quiz.random_selection?

    redirect_to(
      admin_quiz_path(@quiz),
      alert: "Không thể thêm câu hỏi thủ công vào bài thi Random."
    )
    true
  end

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
      params[:next_question_id] || @answer.question_id

    redirect_to(
      quiz_attempt_path(@quiz_attempt, question_id: target_question_id),
      notice: "Đã lưu."
    )
  end
end
