class ReviewsController < ApplicationController
  before_action :authenticate_user!

  def create
    @course = Course.find_by(id: params[:course_id])

    unless @course
      return redirect_to courses_path,
                         alert: "Khóa học không tồn tại."
    end

    @review = @course.reviews.build(review_params)
    @review.user = current_user

    if @review.save
      redirect_to course_path(@course), notice: "Cảm ơn bạn đã đánh giá!"
    else
      redirect_to course_path(@course), alert: "Không thể gửi đánh giá."
    end
  end

  private

  def review_params
    params.require(:review).permit(:rating, :content)
  end
end
