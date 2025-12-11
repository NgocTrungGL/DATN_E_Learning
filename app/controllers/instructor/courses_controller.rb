class Instructor::CoursesController < Instructor::BaseController
  load_and_authorize_resource

  def index
    @courses = @courses.order(created_at: :desc)
  end

  def show
    @course_modules = @course.course_modules
                             .includes(:lessons).order(:order_index)
    @big_quizzes = @course.quizzes.big
  end

  def new; end

  def create
    @course.creator = current_user

    if @course.save
      redirect_to instructor_course_path(@course),
                  notice: "Tạo khóa học thành công."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @course.update(course_params)
      redirect_to instructor_course_path(@course),
                  notice: "Cập nhật thành công."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @course.destroy
    redirect_to instructor_courses_path, notice: "Đã xóa khóa học."
  end

  # GET /instructor/courses/:id/students
  def students
    @enrollments = @course.enrollments.includes(:user).order(created_at: :desc)
  end

  private

  def course_params
    params.require(:course).permit(:title, :description, :price,
                                   :thumbnail_url, :category_id)
  end
end
