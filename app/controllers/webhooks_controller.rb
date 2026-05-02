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
    user = User.find_by(id: user_id)
    return unless user

    if session.metadata["type"] == "cart"
      course_ids = session.metadata["course_ids"].split(",")
      courses = Course.where(id: course_ids)

      courses.each do |course|
        enroll_user(user, course, session.amount_total / courses.count)
      end

      # Increment coupon usage
      promo_code = session.metadata["promo_code"]
      if promo_code.present?
        coupon = Coupon.find_by(code: promo_code)
        coupon.use! if coupon
      end
    else
      course_id = session.metadata["course_id"]
      course = Course.find_by(id: course_id)
      enroll_user(user, course, session.amount_total) if course
    end
  end

  def enroll_user user, course, amount
    enrollment = Enrollment.find_or_initialize_by(user:, course:)
    enrollment.update(
      price: amount,
      status: :active
    )
  end
end
