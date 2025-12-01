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

  def show
    @quiz_attempt = QuizAttempt.find(params[:id])
    @quiz = @quiz_attempt.quiz

    check_expiration

    if @quiz_attempt.completed?
      @quiz_is_finished = true
      render :show
      return
    end

    load_quiz_data

    set_current_question
    prepare_answer_form if @current_question
  end

  # PATCH /quiz_attempts/:id/finish
  def finish
    @quiz_attempt = QuizAttempt.find(params[:id])

    if @quiz_attempt.user == current_user && !@quiz_attempt.completed?
      finalize_attempt!
      flash[:notice] = "Đã nộp bài thành công!"
    end

    redirect_to quiz_attempt_path(@quiz_attempt)
  end
  private

  def set_quiz_attempt
    @quiz_attempt = QuizAttempt.find(params[:id])

    return if @quiz_attempt.user == current_user

    redirect_to root_path,
                alert: t("admin.authorization.denied")
  end

  def finalize_attempt!
    score = calculate_score
    is_passed = score >= @quiz_attempt.quiz.pass_score

    @quiz_attempt.update!(
      status: :completed,
      finished_at: Time.current,
      score:,
      is_passed:
    )

    update_progress_tracking if is_passed
  end

  def calculate_score
    correct_count = @quiz_attempt.quiz_answers.where(is_correct: true).count
    total_questions = @quiz_attempt.quiz.questions.count

    return 0 unless total_questions.positive?

    (correct_count.to_f / total_questions) * 100
  end

  def update_progress_tracking
    ProgressTracking.find_or_create_by!(
      user: current_user,
      quiz: @quiz_attempt.quiz,
      progress_type: "quiz"
    ) do |progress|
      progress.status = :completed
      progress.progress_value = 100
    end
  end

  def check_expiration
    finalize_attempt! if @quiz_attempt.in_progress? && @quiz_attempt.expired?
  end

  def load_quiz_data
    @all_questions = @quiz.questions.order(:id)

    @answered_ids = @quiz_attempt.quiz_answers.pluck(:question_id).index_with do
      true
    end

    @unanswered_count = @all_questions.count - @answered_ids.count
  end

  def set_current_question
    if params[:question_id].present?
      @current_question = @all_questions.find do |q|
        q.id == params[:question_id].to_i
      end
    end

    return unless @current_question.nil?

    @current_question = @all_questions.first
  end

  def prepare_answer_form
    @quiz_answer = @quiz_attempt.quiz_answers.new(question: @current_question)

    existing_answer = @quiz_attempt
                      .quiz_answers.find_by(question_id: @current_question.id)

    return unless existing_answer

    @quiz_answer.question_option_id = existing_answer.question_option_id
  end
end
