class CartItemsController < ApplicationController
  before_action :authenticate_user!

  def create
    @course = Course.find(params[:course_id])

    if current_user.enrolled_in?(@course)
      redirect_to course_path(@course), alert: "Bạn đã sở hữu khóa học này rồi!"
      return
    end

    @cart_item = current_cart.cart_items.new(course: @course)

    if @cart_item.save
      redirect_back(fallback_location: root_path,
                    notice: "Đã thêm khóa học vào giỏ!")
    else
      redirect_back(fallback_location: root_path,
                    alert: "Khóa học này đã có trong giỏ hàng.")
    end
  end

  def destroy
    @cart_item = current_cart.cart_items.find(params[:id])
    @cart_item.destroy
    redirect_to cart_path, notice: "Đã xóa khỏi giỏ hàng."
  end
end
