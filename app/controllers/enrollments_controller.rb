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

    unless @course.free?
      redirect_to course_path(@course),
                  alert: "Vui lòng thanh toán để tham gia khóa học này."
      return
    end

    @enrollment = current_user.enrollments.new(
      course: @course,
      status: :active,
      price: 0
    )

    if @enrollment.save
      redirect_to course_path(@course),
                  notice: "Đăng ký thành công! Bạn có thể bắt đầu học ngay."
    else
      redirect_to course_path(@course),
                  alert: "Không thể đăng ký. Vui lòng thử lại."
    end
  end
end
