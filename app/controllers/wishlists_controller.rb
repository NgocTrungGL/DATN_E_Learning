class WishlistsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_course, only: [:toggle]

  def index
    @pagy, @wishlists = pagy(current_user.wishlists.includes(:course).order(created_at: :desc), items: 12)
  end

  def toggle
    @wishlist = current_user.wishlists.find_by(course: @course)

    if @wishlist
      @wishlist.destroy
      @favorited = false
    else
      current_user.wishlists.create(course: @course)
      @favorited = true
    end

    respond_to do |format|
      format.turbo_stream
      format.html{redirect_back fallback_location: courses_path}
    end
  end

  def move_to_cart
    @course = Course.find(params[:course_id])
    @wishlist = current_user.wishlists.find_by(course: @course)
    
    if !current_user.enrolled_in?(@course)
      current_cart.cart_items.find_or_create_by(course: @course)
    end
    
    @wishlist&.destroy
    
    redirect_to cart_path, notice: "Đã chuyển khóa học vào giỏ hàng."
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end
end
