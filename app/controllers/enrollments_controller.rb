class EnrollmentsController < ApplicationController
  before_action :authenticate_user!

  # POST /courses/:course_id/enrollments
  def create
    @course = Course.find(params[:course_id])

    if current_user.enrolled_in?(@course)
      redirect_to course_path(@course),
                  alert: "Bạn đã đăng ký khóa học này rồi."
      return
    end

    @enrollment = current_user.enrollments.new(course: @course)

    if @course.free?
      @enrollment.status = :active
      message = "Đăng ký thành công! Bạn có thể bắt đầu học ngay."
    else

      @enrollment.status = :pending
      message = "Yêu cầu đăng ký đã được gửi.
      Vui lòng chờ Admin duyệt thanh toán."
    end

    if @enrollment.save
      redirect_to course_path(@course), notice: message
    else
      redirect_to course_path(@course),
                  alert: "Không thể đăng ký. Vui lòng thử lại."
    end
  end
end
