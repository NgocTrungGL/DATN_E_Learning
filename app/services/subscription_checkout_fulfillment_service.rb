# frozen_string_literal: true

class SubscriptionCheckoutFulfillmentService
  def initialize session
    @session = session
    @metadata = session.metadata || {}
  end

  def call
    return unless subscription_checkout?
    return unless completed_checkout?

    user = User.find_by(id: metadata["user_id"])
    plan = metadata["plan"].to_s
    return unless user && Subscription.plan_types.key?(plan)

    subscription = upsert_subscription(user, subscription_attributes(plan))
    record_subscription_revenue(subscription)
    subscription
  end

  private

  attr_reader :session, :metadata

  def subscription_checkout?
    metadata["type"] == "subscription"
  end

  def completed_checkout?
    session.payment_status == "paid" || session.status == "complete"
  end

  def subscription_attributes plan
    {
      plan_type: plan,
      status: local_subscription_status,
      stripe_subscription_id: session.subscription,
      stripe_customer_id: session.customer,
      current_period_start: current_period_start,
      current_period_end: current_period_end,
      cancel_at_period_end: stripe_value(stripe_subscription, :cancel_at_period_end) || false,
      canceled_at: timestamp_to_time(stripe_value(stripe_subscription, :canceled_at))
    }
  end

  def local_subscription_status
    status = stripe_value(stripe_subscription, :status).to_s
    return status if Subscription.statuses.key?(status)

    "active"
  end

  def current_period_start
    timestamp = stripe_subscription_period_start
    return Time.current unless timestamp

    Time.zone.at(timestamp)
  end

  def current_period_end
    timestamp = stripe_subscription_period_end
    return 1.month.from_now unless timestamp

    Time.zone.at(timestamp)
  end

  def stripe_subscription_period_start
    stripe_value(stripe_subscription, :current_period_start) ||
      stripe_value(stripe_subscription_item, :current_period_start)
  end

  def stripe_subscription_period_end
    stripe_value(stripe_subscription, :current_period_end) ||
      stripe_value(stripe_subscription_item, :current_period_end)
  end

  def stripe_subscription_item
    stripe_subscription&.items&.data&.first
  end

  def stripe_value object, key
    object&.[](key.to_s)
  rescue NoMethodError
    nil
  end

  def timestamp_to_time timestamp
    Time.zone.at(timestamp) if timestamp
  end

  def stripe_subscription
    return if session.subscription.blank?

    @stripe_subscription ||= Stripe::Subscription.retrieve(session.subscription)
  end

  def upsert_subscription user, attrs
    if user.subscription
      user.subscription.update!(attrs)
      user.subscription
    else
      user.create_subscription!(attrs)
    end
  end

  def record_subscription_revenue subscription
    SubscriptionRevenueService.new(
      source: subscription,
      amount: session.amount_total,
      external_reference: subscription_payment_reference
    ).perform
  end

  def subscription_payment_reference
    return "stripe_invoice:#{session.invoice}" if session.invoice.present?

    "stripe_checkout:#{session.id}"
  end
end
