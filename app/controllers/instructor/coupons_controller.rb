class Instructor::CouponsController < Instructor::BaseController
  before_action :set_coupon, only: [:show, :edit, :update, :destroy]

  def index
    @coupons = current_user.coupons.order(created_at: :desc)
  end

  def show; end

  def new
    @coupon = current_user.coupons.new(target_type: :specific_course)
    @courses = current_user.created_courses
  end

  def edit
    @courses = current_user.created_courses
  end

  def create
    @coupon = current_user.coupons.new(coupon_params)
    @coupon.target_type = :specific_course # Instructors can only create specific course coupons

    if @coupon.save
      redirect_to instructor_coupons_path,
                  notice: "Mã giảm giá đã được tạo thành công."
    else
      @courses = current_user.created_courses
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @coupon.update(coupon_params)
      redirect_to instructor_coupons_path,
                  notice: "Mã giảm giá đã được cập nhật."
    else
      @courses = current_user.created_courses
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @coupon.destroy
    redirect_to instructor_coupons_path, notice: "Mã giảm giá đã được xóa."
  end

  private

  def set_coupon
    @coupon = current_user.coupons.find(params[:id])
  end

  def coupon_params
    params.require(:coupon).permit(
      :code, :discount_type, :discount_value,
      :start_at, :end_at, :course_id, :usage_limit, :status
    )
  end
end
