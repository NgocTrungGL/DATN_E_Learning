class Instructor::QuizzesController < Instructor::BaseController
  load_and_authorize_resource
  skip_load_resource only: :index

  def index
    @pagy, @quizzes = pagy(
      current_user.created_quizzes
                  .includes(:course, :lesson)
                  .order(created_at: :desc)
    )
  end

  def show; end

  def new
    @quiz.total_questions ||= 10
    @quiz.pass_score ||= 70
    @quiz.random_mode = true

    load_form_data
  end

  def create
    if @quiz.save
      redirect_to instructor_quizzes_path,
                  notice: "Tạo bài kiểm tra thành công."
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_data
  end

  def update
    if @quiz.update(quiz_params)
      redirect_to instructor_quizzes_path, notice: "Cập nhật thành công."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @quiz.destroy
    redirect_to instructor_quizzes_path, notice: "Đã xóa bài kiểm tra."
  end

  private

  def load_form_data
    @courses = current_user.created_courses.select(:id, :title)
    @lessons = Lesson.joins(:course_module)
                     .where(course_modules: { course_id: @courses.pluck(:id) })
                     .select(:id, :title)
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
    ).merge(created_by: current_user.id)
  end
end
