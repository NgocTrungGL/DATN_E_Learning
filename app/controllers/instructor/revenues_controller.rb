class Instructor::RevenuesController < Instructor::BaseController
  def index
    @wallet = current_user.wallet || current_user.create_wallet(balance: 0)

    @pagy, @transactions = pagy(@wallet
    .wallet_transactions.order(created_at: :desc))
    @income_chart_data = @wallet.wallet_transactions
                                .where(transaction_type: "sale_commission")
                                .group_by_day(:created_at,
                                              range: 30.days.ago..Time.zone.now)
                                .sum(:amount)
  end
end
