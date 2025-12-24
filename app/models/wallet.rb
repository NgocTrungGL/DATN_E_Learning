class Wallet < ApplicationRecord
  belongs_to :user
  has_many :wallet_transactions, dependent: :destroy

  def can_withdraw? amount
    balance >= amount
  end
end
