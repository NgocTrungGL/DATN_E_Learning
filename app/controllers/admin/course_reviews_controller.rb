class Admin::CourseReviewsController < Admin::BaseController
  skip_load_and_authorize_resource
  before_action :set_course, only: [:approve, :reject]
  authorize_resource class: "Course"
  def index
    @pagy, @pending_courses = pagy(
      Course.pending.includes(:creator, :category).order(updated_at: :asc),
      items: 10
    )
  end

  def approve
    if @course.pending? && @course.published!
      # TODO: email approve notification to instructor can be added here
      redirect_back fallback_location: admin_course_reviews_path,
                    notice: "Đã duyệt khóa học '#{@course.title}' thành công."
    else
      redirect_back fallback_location: admin_course_reviews_path,
                    alert: "Khóa học không ở đã duyệt hoặc có lỗi xảy ra."
    end
  end

  def reject
    if @course.pending? && @course.rejected!
      # TODO: email reject notification to instructor can be added here
      redirect_back fallback_location: admin_course_reviews_path,
                    alert: "Đã từ chối khóa học '#{@course.title}'."
    else
      redirect_back fallback_location: admin_course_reviews_path,
                    alert: "Khóa học không ở trạng thái chờ duyệt."
    end
  end

  private

  def set_course
    @course = Course.find_by(id: params[:id])

    return unless @course.nil?

    redirect_to admin_course_reviews_path, alert: "Khóa học không tồn tại."
  end
end
