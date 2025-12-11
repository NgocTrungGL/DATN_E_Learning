class Admin::RevenuesController < Admin::BaseController
  skip_load_and_authorize_resource only: :index
  def index
    @wallet = current_user.wallet || current_user.create_wallet(balance: 0)

    @pagy, @transactions = pagy(@wallet
                                      .wallet_transactions
                                      .order(created_at: :desc))
    @total_system_balance = Wallet.sum(:balance)

    @total_platform_revenue = @wallet
                              .wallet_transactions
                              .where(transaction_type: "platform_fee")
                              .sum(:amount)
  end
end
