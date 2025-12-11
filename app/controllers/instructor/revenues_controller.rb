class Instructor::RevenuesController < Instructor::BaseController
  def index
    @wallet = current_user.wallet || current_user.create_wallet(balance: 0)

    @pagy, @transactions = pagy(@wallet
    .wallet_transactions.order(created_at: :desc))
  end
end
