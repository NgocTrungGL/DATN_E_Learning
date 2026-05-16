# frozen_string_literal: true

class Subscription < ApplicationRecord
  belongs_to :user

  # 0 = free, 1 = pro, 2 = premium
  enum plan_type: { free: 0, pro: 1, premium: 2 }

  # Status synced with Stripe
  enum status: {
    active: "active",
    canceled: "canceled",
    past_due: "past_due",
    unpaid: "unpaid"
  }

  validates :plan_type, :status, presence: true

  # A subscription is "active" when status=active AND the billing period hasn't ended.
  scope :currently_active, -> {
    where(status: :active).where("current_period_end > ? OR current_period_end IS NULL", Time.current)
  }

  def currently_active?
    active? && (current_period_end.nil? || current_period_end > Time.current)
  end

  # Convenience: human-readable price in VND
  PLAN_PRICES = {
    "free" => 0,
    "pro" => 499_000,
    "premium" => 999_000
  }.freeze

  PLAN_LABELS = {
    "free" => "Free",
    "pro" => "Pro",
    "premium" => "Premium"
  }.freeze
end
