class Admin::CoursesController < Admin::BaseController
  def index
    @pagy, @courses = pagy(
      Course.includes(:category, :creator)
            .order(status: :asc, created_at: :desc).recent
    )
  end

  def show
    @big_quizzes = @course.quizzes.big
  end

  def new
    @course = Course.new
    # Build empty learning outcomes for the form
    4.times { @course.course_learning_outcomes.build }
  end

  def create
    @course = Course.new(course_params)
    @course.creator = current_user

    @course.status = :published

    if @course.save
      redirect_to admin_course_path(@course),
                  notice: t("admin.courses.create.success")
    else
      # Ensure at least 4 empty outcomes for the form
      (4 - @course.course_learning_outcomes.size).times { @course.course_learning_outcomes.build }
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Ensure at least 4 empty outcomes for the form
    @course.course_learning_outcomes.load
    (4 - @course.course_learning_outcomes.size).times { @course.course_learning_outcomes.build }
  end

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
      alert_message = error_message
                      .presence || t("admin.courses.destroy.failure")
      redirect_to admin_courses_path, alert: alert_message
    end
  end

  def lessons
    course = Course.find_by(id: params[:id])

    return render json: { error: "Course not found" }, status: :not_found if course.nil?

    @lessons = Lesson.joins(:course_module)
                     .where(course_modules: { course_id: course.id })
                     .order("course_modules.order_index", "lessons.order_index")
                     .select(:id, :title)

    render json: @lessons
  end

  private

  def set_course
    @course = Course.find_by(id: params[:id])

    return unless @course.nil?

    redirect_to admin_courses_path, alert: "Khóa học không tồn tại."
  end

  def course_params
    params.require(:course).permit(:title, :description, :category_id,
                                   :thumbnail_url, :price,
                                   course_learning_outcomes_attributes: [:id, :content, :order_index, :_destroy])
  end
end
