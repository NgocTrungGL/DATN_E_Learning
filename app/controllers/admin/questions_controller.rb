class Admin::QuestionsController < Admin::BaseController
  before_action :set_question, only: [:show, :edit, :update, :destroy]
  before_action :check_usage, only: [:destroy]
  before_action :load_courses, only: [:new, :edit]

  def index
    @questions = Question.includes(:course, :lesson).all
  end

  def show; end

  def new
    @question = Question.new
    4.times{@question.question_options.build}
  end

  def create
    @question = Question.new(question_params)
    @question.creator = current_user

    if @question.save
      redirect_to admin_questions_path, notice: t(".success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    (4 - @question.question_options.count).times do
      @question.question_options.build
    end
  end

  def update
    if @question.update(question_params)
      redirect_to admin_questions_path, notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @question.destroy
      redirect_to admin_questions_path, notice: t(".success")
    else
      redirect_to admin_questions_path,
                  alert: @question.errors.full_messages.to_sentence
    end
  end

  private

  def set_question
    @question = Question.includes(:question_options).find_by(id: params[:id])
    return if @question.present?

    redirect_to admin_questions_path, alert: t(".not_found")
  end

  def question_params
    params.require(:question).permit(
      :question_text,
      :question_type,
      :difficulty,
      :course_id,
      :lesson_id,
      question_options_attributes: [:id, :option_text, :is_correct, :_destroy]
    )
  end

  def check_usage
    return unless @question.quizzes.any?

    @question.errors.add(:base, t(".in_use"))
    redirect_to admin_questions_path, alert: t(".in_use")
  end

  def load_courses
    @courses = Course.order(:title)
  end
end
