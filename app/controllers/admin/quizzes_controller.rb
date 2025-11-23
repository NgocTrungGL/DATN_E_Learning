class Admin::QuizzesController < Admin::BaseController
  before_action :set_quiz, only: [:show, :edit, :update, :destroy]
  before_action :load_collections, only: [:new, :create, :edit, :update]
  before_action :check_enrollment_access, only: [:show]
  # GET /admin/quizzes
  def index
    @quizzes = Quiz.includes(:course, :lesson).all
  end

  # GET /admin/quizzes/1
  def show
    @quiz_questions = @quiz.quiz_questions.includes(:question)
    @available_questions = @quiz.course.questions
                                .where.not(id: @quiz.question_ids)
  end

  # GET /admin/quizzes/new
  def new
    @quiz = Quiz.new
  end

  # POST /admin/quizzes
  def create
    @quiz = Quiz.new(quiz_params)
    @quiz.creator = current_user

    if @quiz.save
      redirect_to admin_quiz_path(@quiz),
                  notice: t("admin.quizzes.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /admin/quizzes/1/edit
  def edit; end

  # PATCH/PUT /admin/quizzes/1
  def update
    if @quiz.update(quiz_params)
      redirect_to admin_quiz_path(@quiz),
                  notice: t("admin.quizzes.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/quizzes/1
  def destroy
    if @quiz.destroy
      redirect_to admin_quizzes_path, notice: t("admin.quizzes.destroy.success")
    else
      redirect_to admin_quizzes_path,
                  alert: @quiz.errors.full_messages.to_sentence
    end
  end

  private

  def set_quiz
    @quiz = Quiz.includes(:course).find_by(id: params[:id]) ||
            redirect_to(admin_quizzes_path, alert: t("admin.quizzes.not_found"))
  end

  def load_collections
    @courses = Course.order(:title)
    @lessons = Lesson.order(:title)
  end

  def quiz_params
    params.require(:quiz).permit(
      :title,
      :description,
      :course_id,
      :lesson_id,
      :total_questions,
      :time_limit,
      :pass_score,
      :random_mode
    )
  end

  def check_enrollment_access
    course = @lesson.course
    return if current_user&.can_access_course?(course)

    redirect_to course_path(course),
                alert: "Bạn cần đăng ký (hoặc chờ duyệt) để xem bài học này."
  end
end
