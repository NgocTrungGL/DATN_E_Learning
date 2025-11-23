class QuizAttemptsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quiz_attempt, only: [:show]
  # POST /quizzes/:quiz_id/quiz_attempts
  layout "learning", only: [:show]
  def create
    @quiz = Quiz.find(params[:quiz_id])
    @quiz_attempt = @quiz.quiz_attempts.new(
      user: current_user,
      started_at: Time.current,
      status: :in_progress
    )

    if @quiz_attempt.save
      redirect_to quiz_attempt_path(@quiz_attempt)
    else
      redirect_to lesson_path(@quiz.lesson),
                  alert: t("quiz_attempts.create.fail")
    end
  end

  # GET /quiz_attempts/:id
  def show
    @quiz = @quiz_attempt.quiz

    if @quiz_attempt.completed?
      @quiz_is_finished = true
      render :show
      return
    end

    answered_question_ids = @quiz_attempt.quiz_answers.pluck(:question_id)
    @next_question = @quiz.questions.where.not(id: answered_question_ids).first

    if @next_question.nil?
      @quiz_is_finished = true
      finalize_attempt!
    else
      @quiz_answer = @quiz_attempt.quiz_answers.new(question: @next_question)
    end
  end

  private

  def set_quiz_attempt
    @quiz_attempt = QuizAttempt.find(params[:id])

    return if @quiz_attempt.user == current_user

    redirect_to root_path,
                alert: t("admin.authorization.denied")
  end

  def finalize_attempt!
    correct_count = @quiz_attempt.quiz_answers.where(is_correct: true).count
    total_questions = @quiz_attempt.quiz.questions.count

    score = 0
    if total_questions.positive?
      score = (correct_count.to_f / total_questions) * 100
    end

    is_passed = score >= @quiz_attempt.quiz.pass_score

    @quiz_attempt.update!(
      status: :completed,
      finished_at: Time.current,
      score:,
      is_passed:
    )
  end
end
