class QuizAnswersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quiz_attempt

  def create
    return if handle_expired_attempt

    @answer = build_quiz_answer

    if @answer.save
      handle_successful_save
    else
      handle_failed_save
    end
  end

  private

  def set_quiz_attempt
    @quiz_attempt = QuizAttempt.find(params[:quiz_attempt_id])
    return if @quiz_attempt.user == current_user

    redirect_to root_path,
                alert: t("admin.authorization.denied")
  end

  def handle_expired_attempt
    return false unless @quiz_attempt.completed? || @quiz_attempt.expired?

    flash[:alert] = "Đã hết thời gian làm bài!"
    redirect_to quiz_attempt_path(@quiz_attempt)
    true
  end

  def build_quiz_answer
    quiz_params = params[:quiz_answer]
    @quiz_attempt.quiz_answers.new(
      question_id: quiz_params[:question_id],
      question_option_id: quiz_params[:question_option_id]
    )
  end

  def handle_successful_save
    next_id = params[:next_question_id]

    if next_id.present?
      redirect_to quiz_attempt_path(@quiz_attempt, question_id: next_id)
    else
      current_q_id = params[:quiz_answer][:question_id]
      redirect_to quiz_attempt_path(@quiz_attempt, question_id: current_q_id),
                  notice: "Đã lưu câu trả lời cuối cùng."
    end
  end

  def handle_failed_save
    flash[:alert] = "Không thể nộp câu trả lời."
    current_q_id = params[:quiz_answer][:question_id]
    redirect_to quiz_attempt_path(@quiz_attempt, question_id: current_q_id)
  end
end
