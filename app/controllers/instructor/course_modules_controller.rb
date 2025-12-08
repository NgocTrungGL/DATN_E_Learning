class Instructor::CourseModulesController < Instructor::BaseController
  before_action :set_course, only: [:new, :create]
  before_action :set_course_module,
                only: [:edit, :update, :destroy]

  # GET /instructor/courses/1/course_modules/new
  def new
    @course_module = @course.course_modules.build

    max_order = @course.course_modules.maximum(:order_index) || 0
    @course_module.order_index = max_order + 1

    load_course_content
  end

  # POST /instructor/courses/1/course_modules
  def create
    @course_module = @course.course_modules.build(
      course_module_params
    )

    if @course_module.save
      redirect_to(
        new_instructor_course_course_module_path(@course),
        notice: "Đã thêm chương mới."
      )
    else
      load_course_content
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @course = @course_module.course
    load_course_content
  end

  def update
    if @course_module.update(course_module_params)
      redirect_to(
        new_instructor_course_course_module_path(
          @course_module.course
        ),
        notice: "Cập nhật thành công."
      )
    else
      @course = @course_module.course
      load_course_content
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @course = @course_module.course
    @course_module.destroy
    redirect_to(
      instructor_course_path(@course),
      notice: "Đã xóa chương."
    )
  end

  # PATCH /instructor/course_modules/sort
  def sort
    params[:course_module].each_with_index do |id, index|
      CourseModule
        .joins(:course)
        .where(
          id:,
          courses: {created_by: current_user.id}
        )
        .update_all(order_index: index + 1)
    end
    head :ok
  end

  private

  def set_course
    @course = current_user.created_courses.find(
      params[:course_id]
    )
  end

  def set_course_module
    @course_module = CourseModule
                     .joins(:course)
                     .where(
                       courses: {
                         created_by: current_user.id
                       }
                     )
                     .find(params[:id])
  end

  def course_module_params
    params.require(:course_module)
          .permit(:title, :description, :order_index)
  end

  def load_course_content
    @modules = @course.course_modules.order(:order_index)
    @big_quizzes = @course.quizzes.big.order(:created_at)
  end
end
