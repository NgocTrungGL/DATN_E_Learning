class DistributeRevenueService
  PLATFORM_SHARE_RATE = 0.3
  INSTRUCTOR_SHARE_RATE = 0.7

  def initialize enrollment
    @enrollment = enrollment
    @course = enrollment.course
    @instructor = @course.creator

    @amount = (@enrollment.price || @course.price).to_d
  end

  def perform
    return unless distributable?

    ActiveRecord::Base.transaction do
      @enrollment.with_lock do
        next if revenue_already_distributed?

        platform_share = @amount * PLATFORM_SHARE_RATE
        instructor_share = @amount * INSTRUCTOR_SHARE_RATE

        WalletTransaction.create!(
          wallet: instructor_wallet,
          amount: instructor_share,
          transaction_type: :sale_commission,
          source: @enrollment
        )

        if admin_wallet
          WalletTransaction.create!(
            wallet: admin_wallet,
            amount: platform_share,
            transaction_type: :platform_fee,
            source: @enrollment
          )
        end
      end
    end
  end

  private

  def distributable?
    @amount.positive? && instructor_wallet.present?
  end

  def instructor_wallet
    @instructor_wallet ||= @instructor&.wallet
  end

  def admin_wallet
    @admin_wallet ||= User.find_by(role: "admin")&.wallet
  end

  def revenue_already_distributed?
    WalletTransaction.sale_commission.exists?(source: @enrollment)
  end
end
