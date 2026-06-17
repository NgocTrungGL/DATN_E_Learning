# frozen_string_literal: true

class SubscriptionRevenueService
  def initialize source:, amount:, external_reference:
    @source = source
    @amount = amount.to_i.to_d
    @external_reference = external_reference.to_s
  end

  def perform
    return unless revenue_recordable?

    WalletTransaction.create!(
      wallet: admin_wallet,
      amount: @amount,
      transaction_type: :platform_fee,
      source: @source,
      external_reference: @external_reference
    )
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  private

  def revenue_recordable?
    @amount.positive? &&
      @external_reference.present? &&
      admin_wallet.present? &&
      !WalletTransaction.exists?(external_reference: @external_reference)
  end

  def admin_wallet
    @admin_wallet ||= User.find_by(role: "admin")&.wallet
  end
end
