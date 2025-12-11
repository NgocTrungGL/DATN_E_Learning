class WalletTransaction < ApplicationRecord
  belongs_to :wallet
  belongs_to :source, polymorphic: true, optional: true

  enum transaction_type: {
    deposit: 0,
    withdrawal: 1,
    sale_commission: 2,
    platform_fee: 3
  }

  after_create :update_wallet_balance

  private

  def update_wallet_balance
    wallet.update!(balance: wallet.balance + amount)
  end
end
