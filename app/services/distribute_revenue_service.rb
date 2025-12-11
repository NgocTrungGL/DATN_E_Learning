class DistributeRevenueService
  def initialize enrollment
    @enrollment = enrollment
    @course = enrollment.course
    @instructor = @course.creator

    # SỬA Ở ĐÂY: Lấy giá từ enrollment (giá thực tế lúc mua)
    # Nếu enrollment.price nil (do dữ liệu cũ) thì mới fallback về course.price
    @amount = @enrollment.price || @course.price
  end

  def perform
    return unless @amount > 0

    ActiveRecord::Base.transaction do
      # 1. Tính toán
      platform_share = @amount * 0.3 # Admin hưởng 30%
      instructor_share = @amount * 0.7 # Giảng viên hưởng 70%

      # 2. Cộng tiền cho Giảng viên
      instructor_wallet = @instructor.wallet
      WalletTransaction.create!(
        wallet: instructor_wallet,
        amount: instructor_share,
        transaction_type: :sale_commission,
        source: @enrollment # Tiền này đến từ việc enrollment này thành công
      )

      # 3. Cộng tiền cho Admin (Tìm user Admin đầu tiên hoặc ví hệ thống)
      admin_user = User.find_by(role: "admin")
      if admin_user
        WalletTransaction.create!(
          wallet: admin_user.wallet,
          amount: platform_share,
          transaction_type: :platform_fee,
          source: @enrollment
        )
      end
    end
  end
end
