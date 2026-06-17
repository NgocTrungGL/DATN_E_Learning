# frozen_string_literal: true

class SubscriptionUpgradeCheckoutService
  TARGET_PLAN = "premium"

  def initialize session
    @session = session
    @metadata = session.metadata || {}
  end

  def call
    return unless upgrade_checkout?
    return unless completed_checkout?
    return unless subscription&.user_id == metadata["user_id"].to_i

    return subscription if already_fulfilled?

    stripe_subscription = update_stripe_subscription
    update_local_subscription(stripe_subscription)
    record_upgrade_revenue

    subscription
  end

  private

  attr_reader :session, :metadata

  def upgrade_checkout?
    metadata["type"] == "subscription_upgrade" && metadata["plan"] == TARGET_PLAN
  end

  def completed_checkout?
    session.payment_status == "paid" || session.status == "complete"
  end

  def subscription
    @subscription ||= Subscription.find_by(id: metadata["subscription_id"])
  end

  def already_fulfilled?
    subscription.premium? && WalletTransaction.exists?(external_reference: external_reference)
  end

  def update_stripe_subscription
    return unless subscription.stripe_subscription_id.present?

    stripe_subscription = Stripe::Subscription.retrieve(subscription.stripe_subscription_id)
    item = stripe_subscription.items.data.first
    return stripe_subscription unless item

    Stripe::Subscription.update(
      subscription.stripe_subscription_id,
      {
        cancel_at_period_end: false,
        proration_behavior: "none",
        items: [
          {
            id: item.id,
            price: premium_price.id
          }
        ],
        metadata: {
          plan: TARGET_PLAN,
          upgraded_from: metadata["from_plan"],
          upgrade_checkout_session_id: session.id
        }
      }
    )
  end

  def premium_price
    @premium_price ||= begin
      product = Stripe::Product.create(name: "Premium Plan - E-Learning")
      Stripe::Price.create(
        currency: "vnd",
        unit_amount: Subscription::PLAN_PRICES.fetch(TARGET_PLAN),
        recurring: { interval: "month" },
        product: product.id
      )
    end
  end

  def update_local_subscription stripe_subscription
    subscription.update!(
      plan_type: TARGET_PLAN,
      status: local_subscription_status(stripe_subscription),
      current_period_start: stripe_period_start(stripe_subscription) || subscription.current_period_start,
      current_period_end: stripe_period_end(stripe_subscription) || subscription.current_period_end,
      cancel_at_period_end: false,
      canceled_at: nil
    )
  end

  def record_upgrade_revenue
    SubscriptionRevenueService.new(
      source: subscription,
      amount: session.amount_total,
      external_reference: external_reference
    ).perform
  end

  def external_reference
    "stripe_checkout:#{session.id}"
  end

  def local_subscription_status stripe_subscription
    status = stripe_value(stripe_subscription, :status).to_s
    return status if Subscription.statuses.key?(status)

    "active"
  end

  def stripe_period_start stripe_subscription
    timestamp = stripe_value(stripe_subscription, :current_period_start) ||
                stripe_value(stripe_subscription_item(stripe_subscription), :current_period_start)
    Time.zone.at(timestamp) if timestamp
  end

  def stripe_period_end stripe_subscription
    timestamp = stripe_value(stripe_subscription, :current_period_end) ||
                stripe_value(stripe_subscription_item(stripe_subscription), :current_period_end)
    Time.zone.at(timestamp) if timestamp
  end

  def stripe_subscription_item stripe_subscription
    stripe_subscription&.items&.data&.first
  end

  def stripe_value object, key
    object&.[](key.to_s)
  rescue NoMethodError
    nil
  end
end
