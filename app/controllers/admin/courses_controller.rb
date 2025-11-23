class Admin::CoursesController < Admin::BaseController
  before_action :set_course, only: %i(show edit update destroy)

  def index
    @courses = Course.includes(:category).recent
  end

  def show
    @course = Course.includes(course_modules: :lessons).find_by(id: params[:id])
    return unless @course.nil?

    redirect_to courses_path
  end

  def new
    @course = Course.new
  end

  def create
    @course = Course.new(course_params)
    @course.creator = current_user
    if @course.save
      redirect_to admin_course_path(@course),
                  notice: t("admin.courses.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @course.update(course_params)
      redirect_to admin_course_path(@course),
                  notice: t("admin.courses.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @course.destroy
      redirect_to admin_courses_path,
                  notice: t("admin.courses.destroy.success")
    else

      error_message = @course.errors.full_messages.join(", ")

      alert_message = error_message.presence ||
                      t("admin.courses.destroy.failure")

      redirect_to admin_courses_path,
                  alert: alert_message
    end
  end

  private

  def set_course
    @course = Course.find_by(id: params[:id])

    return unless @course.nil?

    redirect_to admin_courses_path
  end

  def course_params
    params.require(:course).permit(:title, :description, :category_id,
                                   :thumbnail_url, :price)
  end
end
