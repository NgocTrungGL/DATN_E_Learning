class Instructor::LessonsController < Instructor::BaseController
  before_action :set_course_module, only: [:new, :create]
  before_action :set_lesson, only: [:edit, :update, :destroy]

  def new
    @lesson = @course_module.lessons.build

    max_order = @course_module.lessons.maximum(
      :order_index
    ) || 0
    @lesson.order_index = max_order + 1

    @lessons = @course_module.lessons.order(:order_index)
  end

  def create
    @lesson = @course_module.lessons.build(
      lesson_params
    )

    if @lesson.save
      redirect_to(
        new_instructor_course_module_lesson_path(
          @course_module
        ),
        notice: "Đã thêm bài học."
      )
    else
      @lessons = @course_module.lessons.order(:order_index)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @course_module = @lesson.course_module
    @lessons = @course_module.lessons.order(:order_index)
  end

  def update
    if @lesson.update(lesson_params)
      redirect_to(
        new_instructor_course_module_lesson_path(
          @lesson.course_module
        ),
        notice: "Cập nhật thành công."
      )
    else
      @course_module = @lesson.course_module
      @lessons = @course_module.lessons.order(:order_index)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @course_module = @lesson.course_module
    @lesson.destroy
    redirect_to(
      instructor_course_path(@course_module.course),
      notice: "Đã xóa bài học."
    )
  end

  def sort
    params[:lesson].each_with_index do |id, index|
      Lesson
        .joins(course_module: :course)
        .where(
          id:,
          courses: {created_by: current_user.id}
        )
        .update_all(order_index: index + 1)
    end

    head :ok
  end

  private

  def set_course_module
    @course_module = CourseModule
                     .joins(:course)
                     .where(
                       courses: {
                         created_by: current_user.id
                       }
                     )
                     .find(params[:course_module_id])
  end

  def set_lesson
    @lesson = Lesson
              .joins(course_module: :course)
              .where(
                id: params[:id],
                courses: {
                  created_by: current_user.id
                }
              )
              .find(params[:id])
  end

  def lesson_params
    params.require(:lesson)
          .permit(
            :title,
            :description,
            :video_url,
            :attachment_url,
            :order_index
          )
  end
end
