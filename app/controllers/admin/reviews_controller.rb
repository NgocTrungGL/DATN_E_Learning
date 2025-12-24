class Admin::ReviewsController < Admin::BaseController
  load_and_authorize_resource class: Review.name

  def index
    @pagy, @reviews = pagy(@reviews.includes(:user,
                                             :course).order(created_at: :desc))
  end

  def destroy
    @review.destroy
    redirect_to admin_reviews_path, notice: "Đã xóa đánh giá thành công."
  end
end
