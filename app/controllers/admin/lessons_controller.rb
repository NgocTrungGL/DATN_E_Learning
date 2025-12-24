class Admin::LessonsController < Admin::BaseController
  before_action :set_course_module, only: [:new, :create]
  before_action :set_lesson, only: [:show, :edit, :update, :destroy]
  # GET /admin/lessons/1
  def show; end

  # GET /admin/course_modules/1/lessons/new
  def new
    @lesson = @course_module.lessons.build

    max_order = @course_module.lessons.maximum(:order_index) || 0
    @lesson.order_index = max_order + 1

    @lessons = @course_module.lessons.order(:order_index)
  end

  # POST /admin/course_modules/1/lessons
  def create
    @lesson = @course_module.lessons.build(lesson_params)

    if @lesson.order_index.blank?
      max_order = @course_module.lessons.maximum(:order_index) || 0
      @lesson.order_index = max_order + 1
    end

    if @lesson.save

      redirect_to new_admin_course_module_lesson_path(@course_module),
                  notice: "Bài học mới đã được thêm."
    else
      @lessons = @course_module.lessons.order(:order_index)
      render :new, status: :unprocessable_entity
    end
  end

  # GET /admin/lessons/1/edit
  def edit; end

  # PATCH/PUT /admin/lessons/1
  def update
    if @lesson.update(lesson_params)
      redirect_to admin_course_path(@lesson.course_module.course),
                  notice: t("admin.lessons.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/lessons/1
  def destroy
    @course = @lesson.course_module.course

    if @lesson.destroy

      redirect_to admin_course_path(@course),
                  notice: t("admin.lessons.destroy.success")
    else

      error_message = @lesson.errors.full_messages.join(", ")

      alert_message = error_message.presence ||
                      t("admin.lessons.destroy.failure")

      redirect_to admin_course_path(@course),
                  alert: alert_message
    end
  end

  # PATCH /admin/lessons/sort
  def sort
    params[:lesson].each_with_index do |id, index|
      Lesson.where(id:).update_all(order_index: index + 1)
    end
    head :ok
  end
  private

  def set_course_module
    @course_module = CourseModule.find_by(id: params[:course_module_id])

    return unless @course_module.nil?

    redirect_to admin_courses_path
  end

  def set_lesson
    @lesson = Lesson.find_by(id: params[:id])

    return unless @lesson.nil?

    redirect_to admin_courses_path
  end

  def lesson_params
    params.require(:lesson).permit(:title, :description, :video_url,
                                   :attachment_url, :order_index)
  end
end
