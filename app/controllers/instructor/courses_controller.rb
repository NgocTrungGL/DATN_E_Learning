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

  def new; end

  def create
    @course.creator = current_user
    if @course.save
      redirect_to instructor_course_path(@course),
                  notice: "Tạo thành công. Thêm bài học và gửi duyệt nhé!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

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
    @enrollments = @course.enrollments.includes(:user).order(created_at: :desc)
  end

  private

  def course_params
    params.require(:course).permit(:title, :description, :price,
                                   :thumbnail_url, :category_id)
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
end
