class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_enrollment, only: [:create]
  before_action :check_eligibility, only: [:create]
  def create
    @course = find_course or return redirect_missing_course

    @review = build_review

    if @review.save
      handle_success
    elsif already_reviewed?
      handle_already_reviewed
    else
      handle_failed
    end
  end

  def destroy
    @review = Review.find_by(id: params[:id])
    if @review && can?(:destroy, @review)
      @review.destroy
      redirect_back(fallback_location: root_path,
                    notice: "Đã xóa đánh giá.")
    else
      redirect_back(fallback_location: root_path,
                    alert: "Không có quyền xóa hoặc đánh giá không tồn tại.")
    end
  end

  private

  def review_params
    params.require(:review).permit(:rating, :content)
  end

  def check_enrollment
    course = Course.find_by(id: params[:course_id])
    unless course
      redirect_to root_path, alert: "Khóa học không hợp lệ."
      return
    end
    if course.creator == current_user
      redirect_to course_path(course),
                  alert: "Giảng viên không thể tự đánh giá khóa học của mình."
      return
    end
    enrollment = current_user.enrollments.find_by(course:)

    return if enrollment&.active?

    redirect_to course_path(course),
                alert: "Bạn phải tham gia khóa học này mới được phép đánh giá."
  end

  def find_course
    Course.find_by(id: params[:course_id])
  end

  def redirect_missing_course
    redirect_to root_path, alert: "Khóa học không tồn tại."
  end

  def build_review
    @course.reviews.build(review_params.merge(user: current_user))
  end

  def already_reviewed?
    @review.errors[:user_id].present?
  end

  def handle_success
    redirect_to course_path(@course), notice: "Cảm ơn bạn đã đánh giá!"
  end

  def handle_already_reviewed
    redirect_to course_path(@course),
                alert: "Bạn đã đánh giá khóa học này rồi."
  end

  def handle_failed
    redirect_to course_path(@course),
                alert: "Lỗi: #{@review.errors.full_messages.to_sentence}"
  end

  def check_eligibility
    enrollment = current_user.enrollments.find_by(course: @course)

    return if enrollment&.active? && enrollment&.can_review?

    current_percent = enrollment&.current_progress_percentage || 0

    redirect_to course_path(@course),
                alert: "Tiến độ hiện tại: #{current_percent}%
                . Bạn cần đạt ít nhất 70% để đánh giá."
  end
end
