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
      handle_subscription_checkout(user, session)
    elsif cart_checkout?(session)
      handle_cart_checkout(user, session)
    else
      handle_course_checkout(user, session)
    end
  end

  def cart_checkout? session
    session.metadata["type"] == "cart"
  end

  def handle_cart_checkout user, session
    courses = Course.where(id: session.metadata["course_ids"].split(","))
    courses.each do |course|
      enroll_user(user, course, session.amount_total / courses.count)
    end
    use_coupon(session.metadata["promo_code"])
  end

  def handle_course_checkout user, session
    course = Course.find_by(id: session.metadata["course_id"])
    enroll_user(user, course, session.amount_total) if course
  end

  def handle_subscription_checkout user, session
    plan = session.metadata["plan"]
    return if plan.blank?

    upsert_subscription(user, subscription_attributes(plan, session))
  end

  def use_coupon promo_code
    return if promo_code.blank?

    Coupon.find_by(code: promo_code)&.use!
  end

  def enroll_user user, course, amount
    enrollment = Enrollment.find_or_initialize_by(user:, course:)
    enrollment.update(
      price: amount,
      status: :active
    )
  end

  # -- Subscription lifecycle handlers --

  # Called on `customer.subscription.updated`
  # Handles plan upgrades, downgrades, and monthly renewals.
  def sync_subscription stripe_sub
    subscription = Subscription.find_by(stripe_subscription_id: stripe_sub.id)
    return unless subscription

    subscription.update!(
      status:               stripe_sub.status,
      current_period_start: Time.zone.at(stripe_sub.current_period_start),
      current_period_end:   Time.zone.at(stripe_sub.current_period_end)
    )
  end

  # Called on `customer.subscription.deleted`
  # Marks the local subscription as canceled when Stripe ends it.
  def cancel_subscription stripe_sub
    subscription = Subscription.find_by(stripe_subscription_id: stripe_sub.id)
    return unless subscription

    subscription.update!(status: :canceled)
  end

  # Called on `invoice.payment_failed`
  # Marks the subscription as past_due when renewal payment fails.
  def mark_subscription_past_due invoice
    return if invoice.subscription.blank?

    subscription = Subscription.find_by(stripe_subscription_id: invoice.subscription)
    return unless subscription

    subscription.update!(status: :past_due)
  end

  def subscription_attributes plan, session
    {
      plan_type: plan,
      status: "active",
      stripe_subscription_id: session.subscription,
      stripe_customer_id: session.customer,
      current_period_start: Time.current,
      current_period_end: subscription_period_end(session)
    }
  end

  def subscription_period_end session
    return 1.month.from_now if session.subscription.blank?

    stripe_sub = Stripe::Subscription.retrieve(session.subscription)
    Time.zone.at(stripe_sub.current_period_end)
  end

  def upsert_subscription user, attrs
    if user.subscription
      user.subscription.update!(attrs)
    else
      user.create_subscription!(attrs)
    end
  end
end
