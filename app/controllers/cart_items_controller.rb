class CartItemsController < ApplicationController
  before_action :authenticate_user!

  def create
    @course = Course.find(params[:course_id])

    if current_user.enrolled_in?(@course)
      handle_already_enrolled
    elsif current_cart.cart_items.create(course: @course)
      handle_added_to_cart
    else
      handle_add_failure
    end
  end

  def destroy
    @cart_item = current_cart.cart_items.find(params[:id])
    @course = @cart_item.course
    @cart_item.destroy

    respond_to do |format|
      format.html{redirect_back(fallback_location: cart_path, notice: "Đã xóa khỏi giỏ hàng.")}
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("cart-action-course-#{@course.id}",
                               partial: "courses/cart_action",
                               locals: { course: @course }),
          turbo_stream.replace("navbar-cart-icon", partial: "layouts/navbar_cart_icon")
        ]
      end
    end
  end

  private

  def handle_already_enrolled
    message = "Bạn đã sở hữu khóa học này rồi!"
    respond_to do |format|
      format.html{redirect_to course_path(@course), alert: message}
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("flash", partial: "shared/flash",
                                                          locals: { alert: message })
      end
    end
  end

  def handle_added_to_cart
    respond_to do |format|
      format.html{redirect_back(fallback_location: root_path, notice: "Đã thêm khóa học vào giỏ!")}
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("cart-action-course-#{@course.id}",
                               partial: "courses/cart_action",
                               locals: { course: @course }),
          turbo_stream.replace("navbar-cart-icon", partial: "layouts/navbar_cart_icon")
        ]
      end
    end
  end

  def handle_add_failure
    message = "Khóa học này đã có trong giỏ hàng."
    respond_to do |format|
      format.html{redirect_back(fallback_location: root_path, alert: message)}
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("flash", partial: "shared/flash",
                                                          locals: { alert: message })
      end
    end
  end
end
