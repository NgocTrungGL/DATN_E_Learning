class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    event = build_stripe_event
    return head :bad_request unless event

    handle_event(event)

    head :ok
  end

  private

  def build_stripe_event
    Stripe::Webhook.construct_event(
      request.body.read,
      request.env["HTTP_STRIPE_SIGNATURE"],
      ENV["STRIPE_SIGNING_SECRET"]
    )
  rescue JSON::ParserError, Stripe::SignatureVerificationError
    nil
  end

  def handle_event event
    return unless event["type"] == "checkout.session.completed"

    session = event["data"]["object"]
    activate_enrollment(session["metadata"]["enrollment_id"])
  end

  def activate_enrollment enrollment_id
    enrollment = Enrollment.find_by(id: enrollment_id)
    return unless enrollment && !enrollment.active?

    ActiveRecord::Base.transaction do
      enrollment.update!(status: :active)
      DistributeRevenueService.new(enrollment).perform
    end
  end
end
