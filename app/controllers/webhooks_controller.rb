class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  def create
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = ENV["STRIPE_SIGNING_SECRET"]
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
    rescue JSON::ParserError, Stripe::SignatureVerificationError
      head :bad_request
      return
    end

    case event.type
    when "checkout.session.completed"
      session = event.data.object
      handle_checkout_session(session)
    end

    render json: {message: "success"}
  end

  private

  def handle_checkout_session session
    user_id = session.metadata["user_id"]
    course_id = session.metadata["course_id"]

    return if user_id.blank? || course_id.blank?

    user = User.find_by(id: user_id)
    course = Course.find_by(id: course_id)

    return unless user && course

    enrollment = Enrollment.find_or_initialize_by(user:, course:)

    enrollment.update(
      price: session.amount_total,
      status: :active
    )
  end
end
