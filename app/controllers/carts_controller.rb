class CartsController < ApplicationController
  before_action :authenticate_user!

  def show
    @cart = current_cart
    @items = @cart.cart_items.includes(:course)
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
end
