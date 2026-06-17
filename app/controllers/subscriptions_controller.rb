class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :fulfill_checkout_session, only: :index

  PLAN_PRICES = Subscription::PLAN_PRICES.freeze
  STRIPE_PRICES = {
    "pro" => 499_000,
    "premium" => 999_000
  }.freeze

  # GET /subscriptions
  # Dedicated pricing/subscription management page
  def index
    @current_subscription = current_user.active_subscription
    @current_plan         = current_user.current_plan
  end

  # POST /subscriptions
  # Initiate a Stripe Checkout session for a paid plan
  def create
    plan = params[:plan].to_s.downcase
    unless STRIPE_PRICES.key?(plan)
      redirect_to subscriptions_path, alert: t("subscriptions.invalid_plan")
      return
    end

    if current_user.active_subscription&.stripe_subscription_id
      redirect_to subscriptions_path, alert: t("subscriptions.already_active")
      return
    end

    session = Stripe::Checkout::Session.create(
      locale:               "en",
      payment_method_types: %w(card),
      line_items:           [subscription_line_item(plan)],
      mode:                 "subscription",
      customer_email:       current_user.email,
      custom_text:          checkout_custom_text(plan),
      success_url:          subscriptions_url(subscribed: true, session_id: "{CHECKOUT_SESSION_ID}"),
      cancel_url:           subscriptions_url,
      metadata:             {
        user_id: current_user.id,
        plan:,
        type: "subscription"
      }
    )

    redirect_to session.url, allow_other_host: true
  end

  # DELETE /subscriptions/:id
  # Cancel the user's active Stripe subscription (marks as canceled in Stripe)
  def destroy
    subscription = current_user.active_subscription
    unless subscription&.stripe_subscription_id
      redirect_to subscriptions_path, alert: t("subscriptions.no_active_subscription")
      return
    end

    begin
      # Set to cancel at the end of the current period instead of immediate termination
      stripe_subscription = Stripe::Subscription.update(subscription.stripe_subscription_id,
                                                        { cancel_at_period_end: true })
      subscription.update!(
        cancel_at_period_end: true,
        canceled_at: stripe_timestamp_to_time(stripe_value(stripe_subscription, :canceled_at))
      )
      redirect_to subscriptions_path, notice: t("subscriptions.canceled_successfully")
    rescue Stripe::StripeError => e
      redirect_to subscriptions_path, alert: e.message
    end
  end

  private

  def fulfill_checkout_session
    return if params[:session_id].blank?

    session = Stripe::Checkout::Session.retrieve(params[:session_id])
    subscription = SubscriptionCheckoutFulfillmentService.new(session).call
    return unless subscription&.user == current_user

    flash.now[:notice] = t("subscriptions.activated_successfully",
                           default: "Your subscription is now active.")
  rescue Stripe::StripeError => e
    flash.now[:alert] = e.message
  end

  def stripe_timestamp_to_time timestamp
    Time.zone.at(timestamp) if timestamp
  end

  def stripe_value object, key
    object&.[](key.to_s)
  rescue NoMethodError
    nil
  end

  def subscription_line_item plan
    {
      price_data: {
        currency: "vnd",
        unit_amount: STRIPE_PRICES[plan],
        recurring: { interval: "month" },
        product_data: {
          name: "#{plan.capitalize} Plan - E-Learning",
          description: plan_description(plan),
          images: ["https://placehold.co/600x400?text=E-Learning+#{plan.capitalize}"]
        }
      },
      quantity: 1
    }
  end

  def checkout_custom_text plan
    {
      submit: {
        message: "You are subscribing to the #{plan.capitalize} plan. Your plan will be activated after successful payment."
      }
    }
  end

  def plan_description plan
    case plan
    when "pro"     then "Access courses under 1M VND + AI Study Assistant"
    when "premium" then "Access ALL courses + Certificates + Priority Support"
    else ""
    end
  end
end
