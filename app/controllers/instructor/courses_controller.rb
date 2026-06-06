class Instructor::CoursesController < Instructor::BaseController
  load_and_authorize_resource

  def index
    @pagy, @courses = pagy(current_user
    .created_courses.order(updated_at: :desc))
  end

  def show
    @course_modules = @course.course_modules
                             .includes(:lessons).order(:order_index)
    @big_quizzes = @course.quizzes.big
  end

  def new
    @course = Course.new
    # Build empty learning outcomes for the form
    4.times { @course.course_learning_outcomes.build }
  end

  def create
    @course.creator = current_user
    if @course.save
      redirect_to instructor_course_path(@course),
                  notice: "Tạo thành công. Thêm bài học và gửi duyệt nhé!"
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

      # Additional logic: If the course has been rejected,
      # after editing it you may want to automatically change it back to draft
      # or keep it as rejected, depending on business requirements.
      # Here, we keep the basic logic unchanged.s

      redirect_to instructor_course_path(@course),
                  notice: "Cập nhật thông tin thành công."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @course.published?
      redirect_to instructor_courses_path,
                  alert: "Không thể xóa khóa học đang hoạt động."
    else
      @course.destroy
      redirect_to instructor_courses_path, notice: "Đã xóa khóa học."
    end
  end

  def submit_for_review
    return redirect_if_not_submittable unless submittable_status?
    return redirect_if_no_lessons if @course.lessons.empty?

    submit_course
  end

  # GET /instructor/courses/:id/students
  def students
    @search = params[:q].presence
    @status_filter = params[:status].presence

    enrollment_scope = @course.enrollments.includes(:user)

    if @search.present?
      enrollment_scope = enrollment_scope
        .where("users.name ILIKE ? OR users.email ILIKE ?", "%#{@search}%", "%#{@search}%")
    end

    case @status_filter
    when "active"
      enrollment_scope = enrollment_scope.where(status: :active)
    when "completed"
      completed_user_ids = @course.progress_trackings
        .completed.group(:user_id).count.keys
      enrollment_scope = enrollment_scope.where(user_id: completed_user_ids)
    when "inactive"
      enrollment_scope = enrollment_scope
        .where(status: :active)
        .where.not(user_id: @course.progress_trackings.select(:user_id))
    end

    @pagy, @enrollments = pagy(enrollment_scope.order(created_at: :desc), items: 20)

    # Stats
    @total_students = @course.enrollments.count
    @active_students = @course.enrollments.active.count
    completed_ids = @course.progress_trackings.completed.select(:user_id).distinct.pluck(:user_id)
    @completed_students = @course.enrollments.where(user_id: completed_ids).count
    @avg_progress = @course.average_progress_percentage
    @avg_quiz_score = @course.average_quiz_score

    # Charts
    @enrollment_trend = build_enrollment_trend

    completed = @completed_students
    in_progress = [@active_students - completed, 0].max
    not_started = @total_students - @active_students
    @completion_chart = {
      "Hoan thanh" => completed,
      "Dang hoc" => in_progress,
      "Chua hoc" => not_started
    }
  end

  private

  def course_params
    params.require(:course).permit(:title, :description, :price,
                                   :thumbnail_url, :category_id, :allow_admin_discounts,
                                   course_learning_outcomes_attributes: [:id, :content, :order_index, :_destroy])
  end

  def submittable_status?
    return true if @course.draft? || @course.rejected?

    redirect_invalid_status
    false
  end

  def submit_course
    if @course.pending!
      redirect_success
    else
      redirect_error
    end
  end

  def redirect_if_no_lessons
    redirect_to instructor_course_path(@course),
                alert: "Khóa học chưa có nội dung.
                Vui lòng thêm bài học trước khi gửi duyệt."
  end

  def redirect_invalid_status
    message =
      if @course.pending?
        "Khóa học này đang chờ duyệt rồi."
      elsif @course.published?
        "Khóa học đã được xuất bản."
      end

    redirect_to instructor_course_path(@course), alert: message
  end

  def redirect_success
    redirect_to instructor_course_path(@course),
                notice: "Đã gửi yêu cầu duyệt thành công.
                 Vui lòng chờ Admin xử lý."
  end

  def redirect_error
    redirect_to instructor_course_path(@course),
                alert: "Có lỗi xảy ra. Vui lòng thử lại."
  end

  def build_enrollment_trend
    start_date = 12.weeks.ago.to_date
    end_date = Date.today
    trend = Hash.new(0)

    @course.enrollments
      .where("DATE(created_at) >= ?", start_date)
      .where("DATE(created_at) <= ?", end_date)
      .pluck("DATE(created_at)")
      .each { |d| trend[d.to_s] += 1 }

    trend.sort.to_h
  end
end
