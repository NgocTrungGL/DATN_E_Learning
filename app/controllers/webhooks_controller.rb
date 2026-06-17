class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  def create
    event = build_stripe_event
    return unless event

    handle_event(event)

    render json: { message: "success" }
  end

  private

  def build_stripe_event
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = ENV["STRIPE_SIGNING_SECRET"]

    Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
  rescue JSON::ParserError, Stripe::SignatureVerificationError
    head :bad_request
    nil
  end

  def handle_event event
    case event.type
    when "checkout.session.completed"
      handle_checkout_session(event.data.object)
    when "customer.subscription.updated"
      sync_subscription(event.data.object)
    when "customer.subscription.deleted"
      cancel_subscription(event.data.object)
    when "invoice.payment_failed"
      mark_subscription_past_due(event.data.object)
    end
  end

  def handle_checkout_session session
    user_id = session.metadata["user_id"]
    user = User.find_by(id: user_id)
    return unless user

    if session.metadata["type"] == "subscription"
      handle_subscription_checkout(session)
    elsif cart_checkout?(session)
      handle_cart_checkout(user, session)
    elsif session.metadata["purchase_type"] == "license"
      handle_license_checkout(user, session)
    else
      handle_course_checkout(user, session)
    end
  end

  def cart_checkout? session
    session.metadata["type"] == "cart"
  end

  def handle_cart_checkout user, session
    courses = Course.where(id: session.metadata["course_ids"].to_s.split(","))
    amounts_by_course_id = cart_course_amounts(session)
    fallback_amount = courses.any? ? session.amount_total.to_i / courses.count : 0

    courses.each do |course|
      amount = amounts_by_course_id.fetch(course.id.to_s, fallback_amount)
      enroll_user(user, course, amount)
    end
    use_coupon(session.metadata["promo_code"])
  end

  def cart_course_amounts session
    JSON.parse(session.metadata["course_amounts"].presence || "{}")
  rescue JSON::ParserError
    {}
  end

  def handle_license_checkout user, session
    LicenseCheckoutFulfillmentService.new(session).call
  end

  def handle_course_checkout user, session
    course = Course.find_by(id: session.metadata["course_id"])
    enroll_user(user, course, session.amount_total) if course
  end

  def handle_subscription_checkout session
    SubscriptionCheckoutFulfillmentService.new(session).call
  end

  def use_coupon promo_code
    return if promo_code.blank?

    Coupon.find_by(code: promo_code)&.use!
  end

  def enroll_user user, course, amount
    enrollment = Enrollment.find_or_initialize_by(user:, course:)
    return unless enrollment.update(
      price: amount,
      status: :active
    )

    DistributeRevenueService.new(enrollment).perform
  end

  # -- Subscription lifecycle handlers --

  # Called on `customer.subscription.updated`
  # Handles plan upgrades, downgrades, and monthly renewals.
  def sync_subscription stripe_sub
    subscription = Subscription.find_by(stripe_subscription_id: stripe_sub.id)
    return unless subscription

    subscription.update!(
      status: normalized_subscription_status(stripe_value(stripe_sub, :status)),
      current_period_start: stripe_period_start(stripe_sub),
      current_period_end: stripe_period_end(stripe_sub),
      cancel_at_period_end: stripe_value(stripe_sub, :cancel_at_period_end) || false,
      canceled_at: stripe_timestamp_to_time(stripe_value(stripe_sub, :canceled_at))
    )
  end

  # Called on `customer.subscription.deleted`
  # Marks the local subscription as canceled when Stripe ends it.
  def cancel_subscription stripe_sub
    subscription = Subscription.find_by(stripe_subscription_id: stripe_sub.id)
    return unless subscription

    subscription.update!(
      status: :canceled,
      cancel_at_period_end: false,
      canceled_at: stripe_timestamp_to_time(stripe_value(stripe_sub, :canceled_at)) || Time.current
    )
  end

  # Called on `invoice.payment_failed`
  # Marks the subscription as past_due when renewal payment fails.
  def mark_subscription_past_due invoice
    return if invoice.subscription.blank?

    subscription = Subscription.find_by(stripe_subscription_id: invoice.subscription)
    return unless subscription

    subscription.update!(status: :past_due)
  end

  def normalized_subscription_status status
    status = status.to_s
    return status if Subscription.statuses.key?(status)

    "active"
  end

  def stripe_period_start stripe_sub
    timestamp = stripe_value(stripe_sub, :current_period_start) ||
                stripe_value(stripe_subscription_item(stripe_sub), :current_period_start)
    Time.zone.at(timestamp) if timestamp
  end

  def stripe_period_end stripe_sub
    timestamp = stripe_value(stripe_sub, :current_period_end) ||
                stripe_value(stripe_subscription_item(stripe_sub), :current_period_end)
    Time.zone.at(timestamp) if timestamp
  end

  def stripe_subscription_item stripe_sub
    stripe_sub&.items&.data&.first
  end

  def stripe_timestamp_to_time timestamp
    Time.zone.at(timestamp) if timestamp
  end

  def stripe_value object, key
    object&.[](key.to_s)
  rescue NoMethodError
    nil
  end

end
