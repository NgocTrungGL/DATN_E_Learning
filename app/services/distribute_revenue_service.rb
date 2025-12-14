class DistributeRevenueService
  def initialize enrollment
    @enrollment = enrollment
    @course = enrollment.course
    @instructor = @course.creator

    @amount = @enrollment.price || @course.price
  end

  def perform
    return unless @amount.positive?

    ActiveRecord::Base.transaction do
      platform_share = @amount * 0.3
      instructor_share = @amount * 0.7

      instructor_wallet = @instructor.wallet
      WalletTransaction.create!(
        wallet: instructor_wallet,
        amount: instructor_share,
        transaction_type: :sale_commission,
        source: @enrollment
      )

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
