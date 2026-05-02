class Admin::CouponsController < Admin::BaseController
  before_action :set_coupon, only: [:show, :edit, :update, :destroy]

  def index
    @coupons = Coupon.all.order(created_at: :desc)
  end

  def show; end

  def new
    @coupon = Coupon.new
    @courses = Course.all
  end

  def edit
    @courses = Course.all
  end

  def create
    @coupon = current_user.coupons.new(coupon_params)

    if @coupon.save
      redirect_to admin_coupons_path,
                  notice: "Mã giảm giá đã được tạo thành công."
    else
      @courses = Course.all
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @coupon.update(coupon_params)
      redirect_to admin_coupons_path, notice: "Mã giảm giá đã được cập nhật."
    else
      @courses = Course.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @coupon.destroy
    redirect_to admin_coupons_path, notice: "Mã giảm giá đã được xóa."
  end

  private

  def set_coupon
    @coupon = Coupon.find(params[:id])
  end

  def coupon_params
    params.require(:coupon).permit(
      :code, :discount_type, :discount_value,
      :start_at, :end_at, :target_type,
      :course_id, :usage_limit, :status
    )
  end
end
