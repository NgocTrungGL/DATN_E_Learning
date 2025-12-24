class QuizAttemptsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quiz_attempt, only: [:show, :finish]
  layout "learning", only: [:show]

  # POST /quizzes/:quiz_id/quiz_attempts
  def create
    @quiz = Quiz.find(params[:quiz_id])

    @quiz_attempt = @quiz.quiz_attempts.new(
      user: current_user,
      started_at: Time.current,
      status: :in_progress
    )

    if @quiz_attempt.save
      QuizGeneratorService.new(@quiz_attempt).call

      redirect_to quiz_attempt_path(@quiz_attempt)
    else
      redirect_to lesson_path(@quiz.lesson || @quiz.course),
                  alert: "Không thể bắt đầu bài thi."
    end
  end

  # GET /quiz_attempts/:id
  def show
    if @quiz_attempt.completed?
      render :result
      return
    end

    if @quiz_attempt.expired?
      finalize_attempt!
      redirect_to quiz_attempt_path(@quiz_attempt),
                  alert: "Đã hết thời gian làm bài!"
      return
    end

    @quiz_answers = @quiz_attempt.quiz_answers
                                 .includes(question: :question_options)
                                 .order(:id)

    @current_answer = if params[:question_id]
                        @quiz_answers.find_by(question_id: params[:question_id])
                      else
                        @quiz_answers.first
                      end
  end

  # PATCH /quiz_attempts/:id/finish
  def finish
    return if @quiz_attempt.completed?

    finalize_attempt!
    redirect_to quiz_attempt_path(@quiz_attempt),
                notice: "Đã nộp bài thành công!"
  end

  private

  def set_quiz_attempt
    @quiz_attempt = QuizAttempt.find(params[:id])
    return unless @quiz_attempt.user != current_user

    redirect_to root_path, alert: "Bạn không có quyền truy cập."
  end

  def finalize_attempt!
    score = QuizScoringService.new(@quiz_attempt).calculate!

    is_passed = score >= (@quiz_attempt.quiz.pass_score || 0)

    @quiz_attempt.update!(
      status: :completed,
      finished_at: Time.current,
      score:,
      is_passed:
    )

    update_progress if is_passed
  end

  def update_progress
    ProgressTracking.find_or_create_by!(
      user: current_user,
      quiz: @quiz_attempt.quiz,
      progress_type: "quiz"
    ) do |progress|
      progress.status = :completed
      progress.progress_value = 100
    end
  end
end
