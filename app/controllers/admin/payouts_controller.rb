class Admin::PayoutsController < Admin::BaseController
  skip_load_and_authorize_resource

  def index
    authorize! :read, PayoutRequest

    @pagy, @payouts = pagy(PayoutRequest.order(created_at: :desc))
  end

  def approve
    payout = find_and_authorize_payout
    return insufficient_balance_redirect if insufficient_balance?(payout)

    approve_payout!(payout)
    success_redirect
  rescue StandardError => e
    error_redirect(e)
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
  private

  def find_and_authorize_payout
    payout = PayoutRequest.find(params[:id])
    authorize! :update, payout
    payout
  end

  def insufficient_balance? payout
    payout.user.wallet.balance < payout.amount
  end

  def insufficient_balance_redirect
    redirect_back fallback_location: admin_payouts_path,
                  alert: "Số dư giảng viên không đủ."
  end

  def approve_payout! payout
    ActiveRecord::Base.transaction do
      payout.approved!
      create_wallet_transaction(payout)
    end
  end

  def create_wallet_transaction payout
    WalletTransaction.create!(
      wallet: payout.user.wallet,
      amount: -payout.amount,
      transaction_type: :withdrawal,
      source: payout
    )
  end

  def success_redirect
    redirect_back fallback_location: admin_payouts_path,
                  notice: "Đã duyệt yêu cầu."
  end

  def error_redirect error
    redirect_back fallback_location: admin_payouts_path,
                  alert: "Lỗi: #{error.message}"
  end
end
