class Admin::CourseModulesController < Admin::BaseController
  before_action :set_course, only: [:new, :create]
  before_action :set_course_module, only: [:show, :edit, :update, :destroy]

  # GET /admin/courses/1/course_modules/new
  def new
    @course_module = @course.course_modules.build
    load_course_content
  end

  # POST /admin/courses/1/course_modules
  def create
    @course_module = @course.course_modules.build(course_module_params)

    if @course_module.save
      redirect_to new_admin_course_course_module_path(@course),
                  notice: "Đã thêm chương mới thành công."
    else
      load_course_content
      render :new, status: :unprocessable_entity
    end
  end

  # GET /admin/course_modules/1/edit
  def edit
    @course = @course_module.course
    load_course_content
  end

  # GET /admin/course_modules/1
  def show; end

  # PATCH/PUT /admin/course_modules/1
  def update
    if @course_module.update(course_module_params)
      redirect_to new_admin_course_course_module_path(@course_module.course),
                  notice: "Chương đã được cập nhật.
                  Bạn có thể thêm chương tiếp theo."
    else
      @course = @course_module.course
      load_course_content
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @course = @course_module.course

    if @course_module.destroy
      redirect_to admin_course_path(@course),
                  notice: t("admin.course_modules.destroy.success")
    else
      error_message = @course_module.errors.full_messages.join(", ")

      alert_message = error_message.presence ||
                      t("admin.course_modules.destroy.failure")

      redirect_to admin_course_path(@course),
                  alert: alert_message
    end
  end

  # PATCH /admin/course_modules/sort
  def sort
    module_ids = Array(params[:course_module]).map(&:to_i).reject(&:zero?)

    return head :unprocessable_entity if module_ids.empty?

    module_ids.each_with_index do |id, index|
      CourseModule.where(id:).update_all(order_index: index + 1)
    end

    head :ok
  end
  private
  def load_course_content
    @modules = @course.course_modules.order(:order_index)
    @big_quizzes = @course.quizzes.where(lesson_id: nil).order(:created_at)
  end

  def set_course
    @course = Course.find_by(id: params[:course_id])

    return unless @course.nil?

    redirect_to admin_courses_path
  end

  def set_course_module
    @course_module = CourseModule.find_by(id: params[:id])

    return unless @course_module.nil?

    redirect_to admin_courses_path
  end

  def course_module_params
    params.require(:course_module).permit(:title, :description, :order_index)
  end
end
