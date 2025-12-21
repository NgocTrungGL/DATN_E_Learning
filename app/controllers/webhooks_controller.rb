class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    event = construct_event
    return head :bad_request unless event

    handle_checkout_completed(event) if checkout_completed?(event)

    head :ok
  end

  private

  def construct_event
    Stripe::Webhook.construct_event(
      request.body.read,
      request.env["HTTP_STRIPE_SIGNATURE"],
      ENV["STRIPE_SIGNING_SECRET"]
    )
  rescue JSON::ParserError, Stripe::SignatureVerificationError
    nil
  end

  def checkout_completed? event
    event["type"] == "checkout.session.completed"
  end

  def handle_checkout_completed event
    session = event["data"]["object"]

    course = Course.find(session.dig("metadata", "course_id"))
    user   = User.find(session.dig("metadata", "user_id"))

    if license_purchase?(session)
      create_licenses(session, course)
    else
      create_enrollment(course, user)
    end
  end

  def license_purchase? session
    session.dig("metadata", "purchase_type") == "license"
  end

  def create_licenses session, course
    organization = Organization.find(session.dig("metadata", "organization_id"))
    quantity     = session.dig("metadata", "quantity").to_i
    total_paid   = session["amount_total"].to_d
    unit_price   = total_paid / quantity

    quantity.times do
      License.create!(
        organization:,
        course:,
        price: unit_price,
        status: :available
      )
    end
  end

  def create_enrollment course, user
    Enrollment.create!(
      course:,
      user:,
      price: course.price
    )
  end
end
