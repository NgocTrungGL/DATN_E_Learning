class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    event = nil

    endpoint_secret = ENV["STRIPE_SIGNING_SECRET"]

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
    rescue JSON::ParserError
      return head :bad_request
    rescue Stripe::SignatureVerificationError
      return head :bad_request
    end

    if event["type"] == "checkout.session.completed"
      session = event["data"]["object"]

      enrollment_id = session["metadata"]["enrollment_id"]

      enrollment = Enrollment.find_by(id: enrollment_id)

      if enrollment && !enrollment.active?
        ActiveRecord::Base.transaction do
          enrollment.update!(status: :active)

          DistributeRevenueService.new(enrollment).perform
        end
      end
    end

    head :ok
  end
end
