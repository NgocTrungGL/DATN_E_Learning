class Admin::RevenuesController < Admin::BaseController
  skip_load_and_authorize_resource only: :index
  def index
    load_wallet
    load_transactions
    load_system_stats
    load_wallet_stats
    load_top_courses
  end
  private

  def load_wallet
    @wallet = current_user.wallet || current_user.create_wallet(balance: 0)
  end

  def load_transactions
    @pagy, @transactions = pagy(
      @wallet.wallet_transactions.order(created_at: :desc)
    )
  end

  def load_system_stats
    @total_system_balance = Wallet.sum(:balance)
  end

  def load_wallet_stats
    load_platform_revenue
    load_revenue_chart
  end

  def load_platform_revenue
    @total_platform_revenue = @wallet.wallet_transactions
                                     .where(transaction_type: :platform_fee)
                                     .sum(:amount)
  end

  def load_revenue_chart
    @revenue_chart_data = @wallet.wallet_transactions
                                 .where(transaction_type: :platform_fee)
                                 .group_by_day(
                                   :created_at,
                                   range: 30.days.ago..Time.zone.now
                                 )
                                 .sum(:amount)
  end

  def load_top_courses
    @top_courses_data = Enrollment.active
                                  .joins(:course)
                                  .group("courses.title")
                                  .count
                                  .sort_by{|_, v| -v}
                                  .first(5)
                                  .to_h
  end
end
