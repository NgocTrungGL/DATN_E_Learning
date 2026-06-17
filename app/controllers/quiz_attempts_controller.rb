class QuizAttemptsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quiz_attempt, only: [:show, :finish, :review]
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
    @quiz = @quiz_attempt.quiz

    if @quiz_attempt.completed?
      @quiz_is_finished = true
      render :show
      return
    end

    if @quiz_attempt.expired?
      handle_expired_attempt
      return
    end

    prepare_quiz_data
  end

  # PATCH /quiz_attempts/:id/finish
  def finish
    return if @quiz_attempt.completed?

    finalize_attempt!
    redirect_to quiz_attempt_path(@quiz_attempt),
                notice: "Đã nộp bài thành công!"
  end

  # GET /quiz_attempts/:id/review
  def review
    is_instructor = @quiz_attempt.quiz.course.created_by == current_user.id

    unless @quiz_attempt.completed?
      redirect_to quiz_attempt_path(@quiz_attempt), alert: "This attempt is not completed yet!"
      return
    end

    unless is_instructor || @quiz_attempt.is_passed?
      redirect_to quiz_attempt_path(@quiz_attempt), alert: "You need to pass the quiz to review the answers!"
      return
    end

    @quiz = @quiz_attempt.quiz
    @quiz_answers = @quiz_attempt.quiz_answers.includes(question: :question_options).order(:id)

    @total_questions = @quiz_answers.count
    @correct_count = @quiz_answers.where(is_correct: true).count
    @incorrect_count = @total_questions - @correct_count
    @accuracy = @total_questions.positive? ? (@correct_count.to_f / @total_questions * 100).round(1) : 0
    @total_marks = 10
    @marks_obtained = (@quiz_attempt.score.to_f / 100 * @total_marks).round(1)
  end

  def handle_expired_attempt
    finalize_attempt!
    redirect_to quiz_attempt_path(@quiz_attempt),
                alert: "Đã hết thời gian làm bài!"
  end

  def prepare_quiz_data
    @quiz_answers = @quiz_attempt.quiz_answers.includes(question: :question_options).order(:id)
    @current_answer = find_current_answer
    @all_questions = @quiz_answers.map(&:question)
    @current_question = @current_answer&.question
    @answered_ids = @quiz_answers.select{|qa| qa.selected_option_ids.present?}.index_by(&:question_id)
    @quiz_is_finished = @quiz_attempt.completed?
    @quiz_answer = @current_answer
    @unanswered_count = @all_questions.count - @answered_ids.count
  end

  def find_current_answer
    if params[:question_id]
      @quiz_answers.find_by(question_id: params[:question_id])
    else
      @quiz_answers.first
    end
  end

  def set_quiz_attempt
    @quiz_attempt = QuizAttempt.find(params[:id])

    authorize! quiz_attempt_authorization_action, @quiz_attempt
  end

  def quiz_attempt_authorization_action
    case action_name
    when "finish" then :finish
    when "review" then :review
    else :read
    end
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
