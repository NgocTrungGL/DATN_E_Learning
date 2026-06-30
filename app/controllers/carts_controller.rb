class CartsController < ApplicationController
  before_action :authenticate_user!

  def show
    @cart = current_cart
    @items = @cart.cart_items.includes(:course)
    @wishlists = current_user.wishlists.includes(:course).order(created_at: :desc)
    set_cart_recommendations
  end

  def apply_coupon
    @cart = current_cart
    code = params[:promo_code].to_s.strip.upcase

    if code.blank?
      @cart.update(promo_code: nil)
      redirect_to cart_path, notice: "Đã gỡ mã giảm giá."
      return
    end

    coupon = Coupon.find_by(code:)

    if coupon&.active_and_current?
      @cart.update(promo_code: code)
      redirect_to cart_path, notice: "Áp dụng mã giảm giá thành công!"
    else
      redirect_to cart_path, alert: "Mã giảm giá không hợp lệ hoặc đã hết hạn."
    end
  end

  # API endpoint for applying coupon from course page (returns JSON)
  def apply_coupon_api
    code = params[:coupon_code].to_s.strip.upcase
    course_id = params[:course_id]

    if code.blank?
      render json: { success: false, message: "Please enter a coupon code." }
      return
    end

    coupon = Coupon.find_by(code: code)

    if coupon&.active_and_current?
      # Check if coupon applies to this course
      if coupon.specific_course? && coupon.course_id != course_id.to_i
        render json: {
          success: false,
          message: "This coupon is only valid for a different course."
        }
        return
      end

      # Check if this is a global coupon and course already has discount
      if coupon.global? && Course.find_by(id: course_id)&.has_discount?
        render json: {
          success: false,
          message: "This course already has its own discount."
        }
        return
      end

      # Store coupon in session with course_id
      session[:course_coupons] ||= {}
      session[:course_coupons][course_id] = code

      # Calculate new price
      course = Course.find_by(id: course_id)
      if coupon.percentage?
        new_price = course.price * (1 - coupon.discount_value / 100.0)
      else
        new_price = [course.price - coupon.discount_value, 0].max
      end
      # Format price manually
      new_price_display = "#{new_price.round.to_s.reverse.gsub(/...(?=.)/, '\&.').reverse} ₫"

      render json: {
        success: true,
        message: "Coupon applied successfully!",
        new_price: new_price_display
      }
    else
      render json: { success: false, message: "Invalid or expired coupon code." }
    end
  end

  private

  def set_cart_recommendations
    @cart_recommendation_results = recommended_course_results(limit: 4)
    # Tạo danh sách gợi ý bằng AI Embedding để demo so sánh trực tiếp trên trang giỏ hàng.
    @cart_ai_recommendation_results = Recommendations::AiEmbeddingFilter
                                      .new(current_user)
                                      .call(limit: 4)
  end
end
