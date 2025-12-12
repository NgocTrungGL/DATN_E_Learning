class Admin::PayoutsController < Admin::BaseController
  skip_load_and_authorize_resource

  def index
    authorize! :read, PayoutRequest

    @pagy, @payouts = pagy(PayoutRequest.order(created_at: :desc))
  end

  def approve
    @payout = PayoutRequest.find(params[:id])
    authorize! :update, @payout

    if @payout.user.wallet.balance < @payout.amount
      redirect_back fallback_location: admin_payouts_path,
                    alert: "Số dư giảng viên không đủ."
      return
    end

    ActiveRecord::Base.transaction do
      @payout.approved!
      WalletTransaction.create!(
        wallet: @payout.user.wallet,
        amount: -@payout.amount,
        transaction_type: :withdrawal,
        source: @payout
      )
    end
    redirect_back fallback_location: admin_payouts_path,
                  notice: "Đã duyệt yêu cầu."
  rescue StandardError => e
    redirect_back fallback_location: admin_payouts_path,
                  alert: "Lỗi: #{e.message}"
  end

  def reject
    @payout = PayoutRequest.find(params[:id])
    authorize! :update, @payout

    if @payout.rejected!
      redirect_back fallback_location: admin_payouts_path, notice: "Đã từ chối."
    else
      redirect_back fallback_location: admin_payouts_path,
                    alert: "Lỗi hệ thống."
    end
  end
end
