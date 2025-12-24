class PayoutRequest < ApplicationRecord
  belongs_to :user
  has_many :wallet_transactions, as: :source, dependent: :nullify

  enum status: {pending: 0, approved: 1, rejected: 2}

  validate :must_have_enough_balance, on: :create
  validates :bank_name, :bank_account_num, :bank_account_name, presence: true
  validates :amount, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 100_000,
    message: "tối thiểu phải là 100.000₫"
  }
  private

  def must_have_enough_balance
    return unless user.wallet.balance < amount

    errors.add(:amount, "vượt quá số dư hiện tại trong ví.")
  end
end
